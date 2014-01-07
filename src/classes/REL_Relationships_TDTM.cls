/*
    Copyright (c) 2013, Salesforce.com Foundation
    All rights reserved.
    
    Redistribution and use in source and binary forms, with or without
    modification, are permitted provided that the following conditions are met:
    
    * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution.
    * Neither the name of the Salesforce.com Foundation nor the names of
      its contributors may be used to endorse or promote products derived
      from this software without specific prior written permission.
 
    THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
    "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT 
    LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS 
    FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE 
    COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, 
    INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, 
    BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; 
    LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER 
    CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT 
    LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN 
    ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE 
    POSSIBILITY OF SUCH DAMAGE.
*/
/**
* @author Salesforce.com Foundation
* @description Implements relationships behavior 
*/
public with sharing class REL_Relationships_TDTM extends TDTM_Runnable {

    public override DmlWrapper run(List<SObject> newlist, List<SObject> oldlist, 
    TDTM_TriggerActionHelper.Action triggerAction, Schema.DescribeSObjectResult objResult) {
    	
    	DmlWrapper emptyWrapper = new DmlWrapper();
    	
    	//We need all the casting done here because you get an exception if you try to cast a null list or
    	//if you pass null to a map constructor.
    	if(objResult.getSObjectType() == Contact.getSObjectType()) {
    		List<Contact> newListCasted = (newList == null ? new List<Contact>(): (List<Contact>)newList);
    		List<Contact> oldListCasted = (oldList == null ? new List<Contact>(): (List<Contact>)oldList);
    		Map<Id, Contact> oldMapCasted = new Map<Id, Contact>(oldListCasted);
    		return runForContacts(newListCasted, oldMapCasted, triggerAction);
    	
    	} else if(objResult.getSObjectType() == CampaignMember.getSObjectType()) {
    		List<CampaignMember> newListCasted = (newList == null ? new List<CampaignMember>(): (List<CampaignMember>)newList);
            List<CampaignMember> oldListCasted = (oldList == null ? new List<CampaignMember>(): (List<CampaignMember>)oldList);
            Map<Id, CampaignMember> oldMapCasted = new Map<Id, CampaignMember>(oldListCasted);
    		return runForCampaignMembers(newListCasted, oldMapCasted, triggerAction);
    	
    	} else if(objResult.getSObjectType() == npe4__Relationship__c.getSObjectType()) {
    		List<npe4__Relationship__c> newListCasted = (newList == null ? new List<npe4__Relationship__c>(): (List<npe4__Relationship__c>)newList);
            List<npe4__Relationship__c> oldListCasted = (oldList == null ? new List<npe4__Relationship__c>(): (List<npe4__Relationship__c>)oldList);

            if(triggerAction != TDTM_TriggerActionHelper.Action.afterDelete) {
    		  return runForRelationships(newListCasted, oldListCasted, triggerAction);
            } else {
              return runForRelationships(oldListCasted, null, triggerAction);
            }
    	}
    	
    	return emptyWrapper; //We should never get here
    }
    
    private DmlWrapper runForContacts(List<Contact> newlist, Map<Id, Contact> oldMap, 
    TDTM_TriggerActionHelper.Action triggerAction) {
    	
    	DmlWrapper dmlWrapper = new DmlWrapper();
    	
        List<Id> ContactIds = new List<Id>();
        List<Id> ReciprocalIds = new List<Id>();
        List<String> Types = new List<String>();        
        
        if(newlist != null && newlist.size() > 0) {
	        for (Contact c : newlist){
	            for(String s : REL_Utils.getAutoCreateMap().keySet()){
	                npe4__Relationship_Auto_Create__c rac = REL_Utils.getAutoCreateMap().get(s);
	                if (rac.npe4__Object__c == 'Contact'){
	                    Id relatedContactId;
	                    try{
	                        //get the id from the field                        
	                        relatedContactId = (Id)c.get(rac.npe4__Field__c);
	                    }catch(Exception e){
	                        c.addError(system.Label.npe4.AutoCreateFieldError);
	                    }    
	                    
	                    if(triggerAction == TDTM_TriggerActionHelper.Action.afterInsert && relatedContactId != null) {                        
	                        ContactIds.add(c.Id);
	                        ReciprocalIds.add(relatedContactId);
	                        Types.add(rac.npe4__Relationship_Type__c);
	                    }
	                    else if (triggerAction == TDTM_TriggerActionHelper.Action.afterUpdate && relatedContactId != null 
	                    && relatedContactId != oldMap.get(c.id).get(rac.npe4__Field__c)){
	                        ContactIds.add(c.Id);
	                        ReciprocalIds.add(relatedContactId);
	                        Types.add(rac.npe4__Relationship_Type__c);
	                    }
	                }               
	            }           
	        }
        }
        
        if(triggerAction == TDTM_TriggerActionHelper.Action.afterDelete) {
        	DmlWrapper w = deleteEmptyRelationships();
        	dmlWrapper.objectsToDelete.addAll(w.objectsToDelete);
        }
        
        if (!ContactIds.isEmpty()){
            DmlWrapper w = createNewRelationships(ContactIds, ReciprocalIds, Types);
            dmlWrapper.objectsToInsert.addAll(w.objectsToInsert);
        }
        return dmlWrapper;
    }
    
    private DmlWrapper runForCampaignMembers(List<CampaignMember> newlist, Map<Id, CampaignMember> oldMap, 
    TDTM_TriggerActionHelper.Action triggerAction) {
    	System.debug('****Running for CampaignMember on ' + triggerAction);
    	DmlWrapper dmlWrapper = new DmlWrapper();
    	
    	List<Id> ContactIds = new List<Id>();
        List<Id> ReciprocalIds = new List<Id>();
        List<String> Types = new List<String>();
        List<Id> cIds = new List<Id>();  
        
        //CREATE CAMPAIGN MAP BASED ON newMAP KEYSET, THEN GET TYPE AND USE THAT MAP TO DETERMINE IF TYPE MATCHED 
        //rac.CMType requery newMap to get Campaign type
        for (CampaignMember cm : newlist){
            cIds.add(cm.CampaignId);
        }
        
        map<Id, Campaign> cMap = new Map<Id, Campaign>([select id, Type from Campaign where Id IN :cIds]);
                
        for (CampaignMember cm : newlist){
            if (cm.ContactId != null){
                for(String s : REL_Utils.getAutoCreateMap().keySet()){
                    npe4__Relationship_Auto_Create__c rac = REL_Utils.getAutoCreateMap().get(s);
                    //retrieve the campaign for matching type
                    Campaign c = cMap.get(cm.CampaignId);
                    System.debug('****Current Campaign Type: ' + c.Type);
                    //create a set from the rac
                    if (rac.npe4__Object__c == 'CampaignMember'){
                        List<String> cTypeList = rac.npe4__Campaign_Types__c.split(';');
                        System.debug('****All Campaign Types: ' + cTypeList);
                        Set<String> cTypeSet = new Set<String>();
                        cTypeSet.addAll(cTypeList);                                             
                        if (cTypeSet.contains(c.Type)){                     
                            Id relatedContactId;
                            try{
                                //get the id from the field                        
                                relatedContactId = (Id)cm.get(rac.npe4__Field__c);
                            }catch(Exception e) {
                                cm.addError(system.Label.npe4.AutoCreateFieldError); 
                            }
                            if(triggerAction == TDTM_TriggerActionHelper.Action.afterInsert && relatedContactId != null) {                        
                                ContactIds.add(cm.ContactId);
                                ReciprocalIds.add(relatedContactId);
                                Types.add(rac.npe4__Relationship_Type__c);
                            }
                            else if (triggerAction == TDTM_TriggerActionHelper.Action.afterUpdate && relatedContactId != null 
                            && relatedContactId != oldMap.get(cm.id).get(rac.npe4__Field__c)){
                                ContactIds.add(cm.ContactId);
                                ReciprocalIds.add(relatedContactId);
                                Types.add(rac.npe4__Relationship_Type__c);
                            }
                        }                           
                    }               
                }
            }           
        }   

        if (!ContactIds.isEmpty()) {
            DmlWrapper w = createNewRelationships(ContactIds, ReciprocalIds, Types);
            dmlWrapper.objectsToInsert.addAll(w.objectsToInsert);
        }
        return dmlWrapper;
    }

    /// <name> REL_Relationships </name>
    /// <summary> Overloads the REL_Relationships object constructor to handle Relationship processing </summary>
    /// <param name="Relationships"> Relationship objects that are being triggered </param>
    /// <param name="oldRelationships"> Relationships object values before trigger event </param>
    /// <param name="ta"> Trigger action that is occuring </param>
    private DmlWrapper runForRelationships(List<npe4__Relationship__c> newlist, List<npe4__Relationship__c> oldlist, 
    TDTM_TriggerActionHelper.Action triggerAction) {
    	
    	DmlWrapper mainWrapper = new DmlWrapper();
    	
        // Relationship list for termination updates
        List<npe4__Relationship__c> origrelationships = new List<npe4__Relationship__c>();
        List<npe4__Relationship__c> relationshipsToCreate = new List<npe4__Relationship__c>();
        List<npe4__Relationship__c> relationshipsToUpdate = new List<npe4__Relationship__c>();
        List<npe4__Relationship__c> relationshipsToDelete = new List<npe4__Relationship__c>();
        List<npe4__Relationship__c> reciprocalsToUpdate = new List<npe4__Relationship__c>();
        
        if (triggerAction == TDTM_TriggerActionHelper.Action.afterUpdate) {
            REL_ProcessControl.hasRun = true;
        }
        
        Integer i = 0;          // processing counter            
        for(npe4__Relationship__c r : newlist) {
            // AFTER INSERT
            if (triggerAction == TDTM_TriggerActionHelper.Action.afterInsert) {
            	System.debug('****Running REL_Relationships on npe4__Relationship__c after insert');
                if (r.npe4__ReciprocalRelationship__c == null) {
                    relationshipsToCreate.add(r);
                }
                if (r.npe4__ReciprocalRelationship__c != null) {
                    reciprocalsToUpdate.add(r);
                }
            }
            
            // AFTER UPDATE
            if (triggerAction == TDTM_TriggerActionHelper.Action.afterUpdate) {   
            	System.debug('****Running REL_Relationships on npe4__Relationship__c after update');            
                if (r.npe4__ReciprocalRelationship__c == oldlist[i].npe4__ReciprocalRelationship__c 
                && r.npe4__RelatedContact__c != null) {
                    relationshipsToUpdate.add(r);
                    origRelationships.add(oldlist[i]);
                }
                if (r.npe4__RelatedContact__c == null) {
                    relationshipsToDelete.add(r);
                }
            }

            // AFTER DELETE
            if (triggerAction == TDTM_TriggerActionHelper.Action.afterDelete) {
            	System.debug('****Running REL_Relationships on npe4__Relationship__c after delete');
                if (r.npe4__ReciprocalRelationship__c != null) {
                    relationshipsToDelete.add(r);
                }
            }

            i++;
        }

        if (relationshipsToCreate.size() > 0 ) {
        	DmlWrapper wrapper = createRelationship(relationshipsToCreate);
            mainWrapper.objectsToInsert.addAll(wrapper.objectsToInsert);
            mainWrapper.objectsToUpdate.putAll(wrapper.objectsToUpdate);
        }
        if (relationshipsToUpdate.size() > 0 ) {
            DmlWrapper wrapper = updateRelationship(relationshipsToUpdate, origRelationships);
            mainWrapper.objectsToUpdate.putAll(wrapper.objectsToUpdate);
        }
        if (reciprocalsToUpdate.size() > 0 ) {
            DmlWrapper wrapper = reciprocate(reciprocalsToUpdate);
            mainWrapper.objectsToUpdate.putAll(wrapper.objectsToUpdate);
            
        }
        //@TODO: Why are we doing this twice? Is it a bug?
        if (relationshipsToUpdate.size() > 0 ) {
            DmlWrapper wrapper = updateRelationship(relationshipsToUpdate, origRelationships);
            mainWrapper.objectsToUpdate.putAll(wrapper.objectsToUpdate);
        }
        if (relationshipsToDelete.size() > 0 ) {
            DmlWrapper wrapper = deleteRelationships(relationshipsToDelete);
            mainWrapper.objectsToDelete.addAll(wrapper.objectsToDelete);
        }

        if (triggerAction == TDTM_TriggerActionHelper.Action.afterUpdate) {
            REL_ProcessControl.hasRun = false;
        }
        return mainWrapper;
    }


    /// <name> deleteRelationships </name>
    /// <summary> Deletes Reciprocal Relationships when a Relationship is deleted </summary>
    /// <param name="relationships">  </param>
    public static DmlWrapper deleteRelationships(npe4__Relationship__c[] relationships) {
    	System.debug('****Deleting relationships: ' + relationships);
    	DmlWrapper dmlWrapper = new DmlWrapper();
        List<SObject> relationshipsToDelete = new List<SObject>();
        for(npe4__Relationship__c r : Relationships) {
        	npe4__Relationship__c relationshipToDelete;
            if(r.npe4__ReciprocalRelationship__c != null) {
            	relationshipToDelete = new npe4__Relationship__c(Id = r.npe4__ReciprocalRelationship__c);
            } else if(r.npe4__RelatedContact__c == null) {
            	relationshipToDelete = new npe4__Relationship__c(Id = r.Id);
	        }
	        relationshipsToDelete.add(relationshipToDelete);
        }
        if ( relationshipsToDelete.size() > 0 ) {
            dmlWrapper.objectsToDelete.addAll(relationshipsToDelete);
        }
        return dmlWrapper;
    }

    /// <name> deleteEmptyRelationships </name>
    /// <summary> Deletes Relationships when a Contact is deleted </summary>
    /// <param name="contacts"> List of Contacts that were deleted </param>
    public static DmlWrapper deleteEmptyRelationships() {
    	DmlWrapper dmlWrapper = new DmlWrapper();
        List<SObject> relationshipsToDelete = new List<SObject>();
        for (npe4__Relationship__c r : [Select Id from npe4__Relationship__c where npe4__RelatedContact__c = null]) {
            relationshipsToDelete.add(new npe4__Relationship__c(Id = r.Id));
        }
        if ( relationshipsToDelete.size() > 0 ) {
            dmlWrapper.objectsToDelete.addAll(relationshipsToDelete);
        }
        return dmlWrapper;
    }
    
    /// <name> reciprocate </name>
    /// <summary>  </summary>
    /// <param name="Relationships">  </param>
    public static DmlWrapper reciprocate(npe4__Relationship__c[] Relationships) {
    	DmlWrapper dmlWrapper = new DmlWrapper();
        Map<Id, SObject> relationshipsToUpdate = new Map<Id, SObject>();
        for(npe4__Relationship__c r : Relationships) {
        	System.debug('****Creating reciprocal relatioship');
            npe4__Relationship__c copy = new npe4__Relationship__c(Id = r.npe4__ReciprocalRelationship__c, 
                                                                    npe4__ReciprocalRelationship__c = r.Id);
            relationshipsToUpdate.put(copy.Id, copy);
        }
        dmlWrapper.objectsToUpdate.putAll(relationshipsToUpdate);
        return dmlWrapper;
    }
    
    /// <name> createRelationship </name>
    /// <summary> Inserts a new reciprocal Relationship After a relationship is Inserted</summary>
    /// <param name="Relationships">  </param>
    public static DmlWrapper createRelationship(npe4__Relationship__c[] Relationships) {
    	
    	DmlWrapper dmlWrapper = new DmlWrapper();
    	
        List<SObject> relationshipsToCreate = new List<SObject>();
                
        for(npe4__Relationship__c r : Relationships) {
        	System.debug('****Creating relationship in createRelationship method');
            npe4__Relationship__c copy = new npe4__Relationship__c();              
            copy.npe4__Contact__c = r.npe4__RelatedContact__c;
            copy.npe4__RelatedContact__c = r.npe4__Contact__c;
            copy.npe4__Status__c = r.npe4__Status__c;
            copy.npe4__ReciprocalRelationship__c = r.Id;
            copy.npe4__Description__c = r.npe4__Description__c;
            copy.npe4__SYSTEM_SystemCreated__c = true;
            relationshipsToCreate.add(copy);
        }
        
        //evaluate and add the type
        addType(Relationships, relationshipstoCreate);      
        dmlWrapper.objectsToInsert.addAll(relationshipsToCreate);
        //inspectSaveResults(sr, relationshipsToCreate);
        
        return dmlWrapper;
    }

    /// <name> updateRelationship </name>
    /// <summary> Updates the Status and/or Type of a relationship After its reciprocal has been updated </summary>
    /// <param name="Relationships">  </param>
    /// <param name="oldRelationships">  </param>
    public static DmlWrapper updateRelationship(npe4__Relationship__c[] Relationships, 
    npe4__Relationship__c[] oldRelationships){
    	
    	DmlWrapper dmlWrapper = new DmlWrapper();
    	
        List<npe4__Relationship__c> originalRelationships = new List<npe4__Relationship__c>();
        Map<Id, SObject> relationshipsToUpdate = new Map<Id, SObject>();
        Integer counter = 0;                                            // processing counter       

        for(npe4__Relationship__c r : Relationships) {
        	
            //SWA 2009-05-13 removed a duplicate check for change to npe4__Status__c from this OR statement
            if ((r.npe4__Status__c != oldRelationships[counter].npe4__Status__c 
            || r.npe4__Type__c != oldRelationships[counter].npe4__Type__c 
            || r.npe4__Description__c != oldRelationships[counter].npe4__Description__c) 
            && r.npe4__ReciprocalRelationship__c != null) {
            	System.debug('****Creating relationship in updateRelationship method');
                npe4__Relationship__c copy = new npe4__Relationship__c(Id=r.npe4__ReciprocalRelationship__c);
                
                //SWA 2009-05-13 - only attempt to modify the Contact field if the Related Contact  has changed
                if(oldRelationships[counter].npe4__RelatedContact__c!=r.npe4__RelatedContact__c) {
                    copy.npe4__Contact__c = r.npe4__RelatedContact__c;
                }
                copy.npe4__Status__c = r.npe4__Status__c;
                copy.npe4__Description__c = r.npe4__Description__c;
                relationshipsToUpdate.put(copy.Id, copy);
                originalRelationships.add(r);
            }
            counter++;
        }
        //add type info as needed
        if (!originalRelationships.isEmpty() && !relationshipsToUpdate.isEmpty()) {
            addType(originalRelationships, relationshipstoUpdate.values());
            dmlWrapper.objectsToUpdate.putAll(relationshipsToUpdate);        
            //inspectSaveResults(sr, relationshipsToUpdate);
        }
        return dmlWrapper;
    }
    
    public static DmlWrapper createNewRelationships(List<Id> ContactIds, List<Id> RelatedContactIds, List<String> Types) {
        
        DmlWrapper dmlWrapper = new DmlWrapper();
        Integer i = 0;
        List<SObject> relationshipsForInsert = new List<SObject>();
        
        //used to hold existing relationships for the group of contacts and check for dupes
        List<npe4__Relationship__c> existingRelationships = new List<npe4__Relationship__c>();
        Map<Id, List<npe4__Relationship__c>> relationshipsByContact = new Map<Id, List<npe4__Relationship__c>>();
        
        if (!REL_Utils.getRelationshipSettings().npe4__Allow_AutoCreated_Duplicates__c) {
        	
            existingRelationships = [select Id, npe4__Contact__c, npe4__RelatedContact__c, npe4__Type__c 
            from npe4__Relationship__c where npe4__Contact__c IN :ContactIds limit 2000];
            
            //sort by npe4__Contact__c so we can pull relationships based on the inserted Contact
            for(npe4__Relationship__c r : existingRelationships){
                if(relationshipsByContact.containsKey(r.npe4__Contact__c)){
                    List<npe4__Relationship__c> rList = relationshipsByContact.get(r.npe4__Contact__c);
                    rList.add(r);
                    relationshipsByContact.put(r.npe4__Contact__c, rList);
                }
                else{
                    relationshipsByContact.put(r.npe4__Contact__c, new List<npe4__Relationship__c>{r});
                }               
            }        
        }        
            
        for (Id conId : ContactIds){
            boolean doNotCreate = false;
            
            //prevent duplicates from being created if they exist and setting is enabled
            if (relationshipsByContact.containsKey(conId)){
                for (npe4__Relationship__c r : relationshipsByContact.get(conId)){
                    if (r.npe4__Type__c == Types[i] && r.npe4__RelatedContact__c == RelatedContactIds[i]){
                        doNotCreate = true;                     
                        break;
                    }                   
                }    
            }
            
            if (!doNotCreate){
            	System.debug('****Creating relationship in createNewRelationships method');
                npe4__Relationship__c r = new npe4__Relationship__c(
                    npe4__Contact__c = conId, 
                    npe4__RelatedContact__c = RelatedContactIds[i],
                    npe4__Type__c = Types[i],           
                    npe4__Status__c = 'Current'                 
                );
                relationshipsForInsert.add(r);
            }
            i++;
        }       
        
        if (!relationshipsForInsert.isEmpty()){
            dmlWrapper.objectsToInsert.addAll(relationshipsForInsert);
            //inspectSaveResults(sr, relationshipsForInsert);
        }
        
        return dmlWrapper;
    }
    
    private static void addType(list<npe4__Relationship__c> rList, List<SObject> rCopy) {
        
        npe4__Relationship_Settings__c rs = REL_Utils.getRelationshipSettings();
        
        //used for tracking place in array
        integer counter = 0;            
            
        if (rs.npe4__Reciprocal_Method__c == 'List Setting'){            
            map<string, npe4__Relationship_Lookup__c> rlMap = npe4__Relationship_Lookup__c.getAll().clone();
        
            //remove inactive values
            for (string s : rlMap.keySet()){
                if (rlMap.get(s).npe4__Active__c != true){
                    rlMap.remove(s);
                }
            }
        
            list<id> rIDs = new list<id>();
                
            for (npe4__Relationship__c r : rList){
            //    rIDs.add(r.npe4__RelatedContact__c);
                rIDs.add(r.npe4__Contact__c);
            }            
            
            String query_string = 'select id, Salutation';            
            String gender_field = '';
            
            if (rs.npe4__Gender_Field__c != null){
                gender_field = rs.npe4__Gender_Field__c;
                query_string += ', ' + gender_field;                
            }
            
            query_string += ' from Contact where Id IN :rIDs';                         
            
            map<id, Contact> cMap = new map<id,Contact>((List<Contact>)database.query(query_string));
            
            for(npe4__Relationship__c r : rList){
                
                npe4__Relationship__c copy = (npe4__Relationship__c)rCopy[counter];

                Contact relatedContact = cMap.get(r.npe4__Contact__c);
            
                if (rlMap.containsKey(r.npe4__Type__c)){
                    
                    List<String> malelist = system.label.npe4.Male.split(',');                                                                                                        
                    List<String> femalelist = system.label.npe4.Female.split(',');
                    
                    Set<String> maleset = new Set<String>();
                    Set<String> femaleset = new Set<String>();
                    maleset.addAll(malelist);
                    femaleset.addAll(femalelist);                    
                                        
                    //was a gender field defined? 
                    if (gender_field != null && gender_field != '' && relatedContact.get(gender_field) != null){                        
                        
                        String contact_gender = (String)relatedContact.get(gender_field);                                               
                        String match_type = '';                        
                        
                        //try male
                        for (String s : malelist){
                            if (contact_gender.toLowerCase() == s.toLowerCase().trim()){
                                match_type = 'male';
                                break;
                            }
                        }
                        //if we haven't found it, try female
                        if(match_type == ''){
                            for (String s : femalelist){
                                if (contact_gender.toLowerCase() == s.toLowerCase().trim()){
                                    match_type = 'female';
                                    break;
                                }
                            }
                        }     
                        
                        if (match_type == 'male' && rlMap.get(r.npe4__Type__c).npe4__Male__c != null)
                            copy.npe4__Type__c = rlMap.get(r.npe4__Type__c).npe4__Male__c;
                        else if (match_type == 'female' && rlMap.get(r.npe4__Type__c).npe4__Female__c != null)                            
                            copy.npe4__Type__c = rlMap.get(r.npe4__Type__c).npe4__Female__c;
                        else
                            copy.npe4__Type__c = rlMap.get(r.npe4__Type__c).npe4__Neutral__c;
                    }
                    else if ((relatedContact.Salutation == 'Mr.' || maleset.contains(relatedContact.Salutation))  
                    && rlMap.get(r.npe4__Type__c).npe4__Male__c != null){
                        copy.npe4__Type__c = rlMap.get(r.npe4__Type__c).npe4__Male__c;
                    }
                    else if (((relatedContact.Salutation == 'Ms.' || relatedContact.Salutation == 'Mrs.') 
                    || femaleset.contains(relatedContact.Salutation)) && rlMap.get(r.npe4__Type__c).npe4__Female__c 
                    != null){
                        copy.npe4__Type__c = rlMap.get(r.npe4__Type__c).npe4__Female__c;
                    }
                    
                    //can't match up gender, bad field or otherwise
                    else{                       
                        copy.npe4__Type__c = rlMap.get(r.npe4__Type__c).npe4__Neutral__c;                     
                    }          
                }                            
                //no matching custom list setting, use provided type
                else{
                    copy.npe4__Type__c = r.npe4__Type__c;
                }                
                counter++;
            }            
        }
        
        else if(rs.npe4__Reciprocal_Method__c == 'Value Inversion'){
            for (npe4__Relationship__c r : rList){                           
                //instead lets split the type
                List<string> splitrelationship = r.npe4__Type__c.split(system.label.npe4.Relationship_Split);
                String newstring = '';
                if (splitrelationship.size() > 1)
                    newstring = splitrelationship[1] + system.label.npe4.Relationship_Split + splitrelationship[0];
                else
                    newstring = r.npe4__Type__c;
            
                npe4__Relationship__c castedObject = (npe4__Relationship__c)rCopy[counter];
                castedObject.npe4__Type__c = newstring;
                counter++;
            }
        }
        else{
            for (npe4__Relationship__c r : rList){
            	npe4__Relationship__c castedObject = (npe4__Relationship__c)rCopy[counter];
                castedObject.npe4__Type__c = r.npe4__Type__c;
                counter++; 
            }   
        }
    }
}