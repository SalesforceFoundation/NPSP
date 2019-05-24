/*
    Copyright (c) 2013, Salesforce.org
    All rights reserved.
    
    Redistribution and use in source and binary forms, with or without
    modification, are permitted provided that the following conditions are met:
    
    * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution.
    * Neither the name of Salesforce.org nor the names of
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
* @author Salesforce.org
* @date 2013
* @group Relationships
* @group-content ../../ApexDocContent/Relationships.htm
* @description Trigger Handler on Relationships that implements reciprocal relationships behavior.
*/
public class REL_Relationships_TDTM extends TDTM_Runnable {

    /*********************************************************************
    * @description Set of field names ineligible for syncing across reciprocal pairs  
    */
    private static final Set<String> relSystemFields = new Set<String>{
        'npe4__system_systemcreated__c','npe4__contact__c','npe4__reciprocalrelationship__c','npe4__relatedcontact__c','npe4__type__c'};

    /*********************************************************************
    * @description Set of field names synced across reciprocal pairs  
    */
    private static Set<String> syncFields {
        get { 
            if (syncFields == null) {
                syncFields = new Set<String>();
                npe4__Relationship_Settings__c rs = UTIL_CustomSettingsFacade.getRelationshipSettings();
                
                map<String, Schema.DescribeFieldResult> relFieldDescMap = UTIL_Describe.getAllFieldsDescribe('npe4__Relationship__c'); 
                Set<String> excludedFields = new Set<String>(UTIL_ListCustomSettingsFacade.getMapRelationshipFieldSyncSettings().keySet());              
                excludedFields.addAll(relSystemFields);
                
                //only sync editable custom fields not excluded in settings or constant
                for (string fieldName : relFieldDescMap.keyset()) {
                    if (!excludedFields.contains(fieldName) && relFieldDescMap.get(fieldName).isCustom()  
                        && !relFieldDescMap.get(fieldName).isCalculated() && !relFieldDescMap.get(fieldName).isAutoNumber()
                        && (fieldName.startsWith('npe4__') || rs.Enable_Custom_Field_Sync__c)) {
                        
                            syncFields.add(fieldName); 
                    }    
                }
            } 
            UTIL_Debug.debug('***************** RELATIONSHIP SYNC FIELDS: ' + syncFields);
            return syncFields;
        }
        private set;
    }

    /*******************************************************************************************************
    * @description Overload of run method that casts trigger objects to Relationships and passes them to 
    * runForRelationships() with correct parameters
    * @param newlist Sobjects that are being triggered 
    * @param oldlist Sobjects with values before trigger event 
    * @param triggerAction Trigger action that is occuring 
    * @param objResult Schema.DescribeSobjectResult for npe4__Relationship__c
    * @return DmlWrapper
    */
    public override DmlWrapper run(List<SObject> newlist, List<SObject> oldlist, 
    TDTM_Runnable.Action triggerAction, Schema.DescribeSObjectResult objResult) {
    	
    	List<npe4__Relationship__c> newListCasted = (newList == null ? new List<npe4__Relationship__c>(): (List<npe4__Relationship__c>)newList);
        List<npe4__Relationship__c> oldListCasted = (oldList == null ? new List<npe4__Relationship__c>(): (List<npe4__Relationship__c>)oldList);
    	
		return runForRelationships(newListCasted, oldListCasted, triggerAction);
    }
    
    /*******************************************************************************************************
    * @description Method that implements correct action based on trigger action 
    * @param newlist Relationship objects that are being triggered 
    * @param oldlist Relationships object values before trigger event 
    * @param triggerAction Trigger action that is occuring 
    * @return DmlWrapper
    */
    private DmlWrapper runForRelationships(List<npe4__Relationship__c> newlist, List<npe4__Relationship__c> oldlist, 
    TDTM_Runnable.Action triggerAction) {

        if (TDTM_ProcessControl.isRecursive(TDTM_ProcessControl.flag.REL)) {
            return null;
        }

        DmlWrapper mainWrapper = new DmlWrapper();

        // Relationship list for termination updates
        List<npe4__Relationship__c> origrelationships = new List<npe4__Relationship__c>();
        List<npe4__Relationship__c> relationshipsToCreate = new List<npe4__Relationship__c>();
        List<npe4__Relationship__c> relationshipsToUpdate = new List<npe4__Relationship__c>();
        List<npe4__Relationship__c> relationshipsToDelete = new List<npe4__Relationship__c>();
        List<npe4__Relationship__c> reciprocalsToUpdate = new List<npe4__Relationship__c>();

        // Set the recursion flag up front because there could be DML operations before the main method ends.
        if (triggerAction == TDTM_Runnable.Action.afterUpdate) {
            TDTM_ProcessControl.setRecursionFlag(TDTM_ProcessControl.flag.REL, true);
        }

        Integer i = 0;          // processing counter            
        for(npe4__Relationship__c r : newlist) {
            // AFTER INSERT
            if (triggerAction == TDTM_Runnable.Action.afterInsert) {
                if (r.npe4__ReciprocalRelationship__c == null) {
                    relationshipsToCreate.add(r);
                }
                if (r.npe4__ReciprocalRelationship__c != null) {
                    reciprocalsToUpdate.add(r);
                }
            }
            
            // AFTER UPDATE
            if (triggerAction == TDTM_Runnable.Action.afterUpdate) {   
                if (r.npe4__ReciprocalRelationship__c == oldlist[i].npe4__ReciprocalRelationship__c 
                && r.npe4__RelatedContact__c != null) {
                    relationshipsToUpdate.add(r);
                    origRelationships.add(oldlist[i]);
                }
                if (r.npe4__RelatedContact__c == null) {
                    relationshipsToDelete.add(r);
                }
            }

            i++;
        }

        // AFTER DELETE
        if (triggerAction == TDTM_Runnable.Action.AfterDelete) {
            Map<Id, npe4__Relationship__c> deletedRelMap = new Map<Id, npe4__Relationship__c>(oldlist);
            for (npe4__Relationship__c rel : oldList) {
                
                //check that the recirocal relationship isn't already in the deletion trigger set before adding for deletion
                if (rel.npe4__ReciprocalRelationship__c != null && !deletedRelMap.containsKey(rel.npe4__ReciprocalRelationship__c)) {
                    relationshipsToDelete.add(new npe4__Relationship__c(Id=rel.npe4__ReciprocalRelationship__c));
                }
            }
        }

        if (relationshipsToCreate.size() > 0 ) {
        	DmlWrapper wrapper = createRelationship(relationshipsToCreate);
            mainWrapper.objectsToInsert.addAll(wrapper.objectsToInsert);
            mainWrapper.objectsToUpdate.addAll(wrapper.objectsToUpdate);
        }
        if (relationshipsToUpdate.size() > 0 ) {
            DmlWrapper wrapper = updateRelationship(relationshipsToUpdate, origRelationships);
            mainWrapper.objectsToUpdate.addAll(wrapper.objectsToUpdate);
        }
        if (reciprocalsToUpdate.size() > 0 ) {
            DmlWrapper wrapper = reciprocate(reciprocalsToUpdate);
            mainWrapper.objectsToUpdate.addAll(wrapper.objectsToUpdate);
            
        }
        if (relationshipsToDelete.size() > 0 ) {
            mainWrapper.objectsToDelete.addAll((List<SObject>)relationshipsToDelete);
        }

        TDTM_TriggerHandler.processDML(mainWrapper);
        if (triggerAction == TDTM_Runnable.Action.afterUpdate) {
            TDTM_ProcessControl.setRecursionFlag(TDTM_ProcessControl.flag.REL, false);
        }
        return null;
    }

    /*******************************************************************************************************
    * @description Generates DmlWrapper list of non-SystemCreated relationships that need to be updated with 
    * the Id of their SystemCreated reciprocal 
    * @param Relationships List of Relationships 
    * @return DmlWarapper
    */ 
    public static DmlWrapper reciprocate(npe4__Relationship__c[] Relationships) {
    	DmlWrapper dmlWrapper = new DmlWrapper();
        List<SObject> relationshipsToUpdate = new List<SObject>();
        for(npe4__Relationship__c r : Relationships) {
        	UTIL_Debug.debug('****Creating reciprocal relationship');
            npe4__Relationship__c copy = new npe4__Relationship__c(Id = r.npe4__ReciprocalRelationship__c, 
                                                                    npe4__ReciprocalRelationship__c = r.Id);
            relationshipsToUpdate.add(copy);
        }
        dmlWrapper.objectsToUpdate.addAll(relationshipsToUpdate);
        return dmlWrapper;
    }
    
    /*******************************************************************************************************
    * @description Creates new reciprocal Relationship records for those being Inserted
    * @param Relationships  list of new Relationships being inserted
    * @return DmlWrapper
    */
    public static DmlWrapper createRelationship(npe4__Relationship__c[] Relationships) {
    	
    	DmlWrapper dmlWrapper = new DmlWrapper();
    	
        List<SObject> relationshipsToCreate = new List<SObject>();
                
        for(npe4__Relationship__c r : Relationships) {
        	UTIL_Debug.debug('****Creating relationship in createRelationship method');
            npe4__Relationship__c copy = new npe4__Relationship__c();              
            copy.npe4__Contact__c = r.npe4__RelatedContact__c;
            copy.npe4__RelatedContact__c = r.npe4__Contact__c;
            copy.npe4__ReciprocalRelationship__c = r.Id;
            copy.npe4__SYSTEM_SystemCreated__c = true;
            relationshipsToCreate.add(copy);
        }
        
        //evaluate and add the type
        addType(Relationships, relationshipsToCreate);
        syncRelationshipFields(Relationships, relationshipsToCreate);
        dmlWrapper.objectsToInsert.addAll(relationshipsToCreate);
        //inspectSaveResults(sr, relationshipsToCreate);
        
        return dmlWrapper;
    }

    /*******************************************************************************************************
    * @description Updates the Status and/or Type of a relationship After its reciprocal has been updated 
    * @param Relationships  
    * @param oldRelationships 
    * @return DmlWrapper
    */ 
    public static DmlWrapper updateRelationship(npe4__Relationship__c[] Relationships, 
    npe4__Relationship__c[] oldRelationships){
    	
    	DmlWrapper dmlWrapper = new DmlWrapper();
    	
        List<npe4__Relationship__c> originalRelationships = new List<npe4__Relationship__c>();
        List<SObject> relationshipsTypesToUpdate = new List<SObject>();
        List<SObject> reciprocalsToUpdate = new List<SObject>();
        Integer counter = 0;                                            // processing counter       

        for(npe4__Relationship__c r : Relationships) {
        	
            if (needsUpdate(r, oldRelationships[counter])) {
               	UTIL_Debug.debug('****Creating relationship in updateRelationship method');
                npe4__Relationship__c copy = new npe4__Relationship__c(Id=r.npe4__ReciprocalRelationship__c);
                
                //SWA 2009-05-13 - only attempt to modify the Contact field if the Related Contact  has changed
                if(oldRelationships[counter].npe4__RelatedContact__c!=r.npe4__RelatedContact__c) {
                    copy.npe4__Contact__c = r.npe4__RelatedContact__c;
                }

                //synchronize fields if they need it
                if (!syncFields.isEmpty()) {
                    syncRelationshipFields(r,copy);
                }

                //only recalculate type on reciprocal if the original type has changed
                if (r.npe4__Type__c != oldRelationships[counter].npe4__Type__c) {
                    relationshipsTypesToUpdate.add(copy);
                    originalRelationships.add(r);
                } else {
                    reciprocalsToUpdate.add(copy);
                }

            }
            counter++;
        }
        //add type info as needed and update
        if (!originalRelationships.isEmpty() && !relationshipsTypesToUpdate.isEmpty()) {
            addType(originalRelationships, relationshipsTypesToUpdate);
            dmlWrapper.objectsToUpdate.addAll(relationshipsTypesToUpdate);
        }
        //update reciprocals without type change
        if (!reciprocalsToUpdate.isEmpty()){
            dmlWrapper.objectsToUpdate.addAll(reciprocalsToUpdate);
        }
        return dmlWrapper;
    }
    
    /*******************************************************************************************************
    * @description Updates Type of a list of relationships based on reciprocal method and list settings 
    * @param rList list of old Relationship records   
    * @param rCopy List of SObjects (Relationships) being updated
    * */ 
    public static void addType(list<npe4__Relationship__c> rList, List<SObject> rCopy) {
        
        npe4__Relationship_Settings__c rs = UTIL_CustomSettingsFacade.getRelationshipSettings();
        
        //used for tracking place in array
        integer counter = 0;            
            
        if (rs.npe4__Reciprocal_Method__c == 'List Setting'){            
            map<string, npe4__Relationship_Lookup__c> rlMap = UTIL_ListCustomSettingsFacade.getMapRelationshipLookupSettings().clone();
        
            //remove inactive values
            for (string s : rlMap.keySet()){
                npe4__Relationship_Lookup__c thisRl = rlMap.get(s);
                if (thisRl.npe4__Active__c != true){
                    rlMap.remove(s);
                }
            }
        
            list<id> rIDs = new list<id>();

            for (npe4__Relationship__c r : rList){
            //    rIDs.add(r.npe4__RelatedContact__c);
                if (r.npe4__Contact__c != null) {
                    rIDs.add(r.npe4__Contact__c);
                }
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

                // Skip any records where the related reciprical contact is null
                if (r.npe4__Contact__c == null) {
                    continue;
                }

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
                        if (copy.npe4__Type__c==null)
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

    /*******************************************************************************************************
    * @description Synchronize Relationship fields according to custom settings  
    * @param sourceRel Relationship(s) whose fields are to be copied
    * @param targetRel Relationship(s) whose fields are to be updated
    ********************************************************************************************************/
    public static void syncRelationshipFields(list<npe4__Relationship__c> sourceRel, List<SObject> targetRel) {
        if (!syncFields.isEmpty()) {
            Integer counter = 0;
            for(npe4__Relationship__c r : sourceRel) {
                npe4__Relationship__c copy = (npe4__Relationship__c)targetRel[counter];
                syncRelationshipFields(r, copy);
                counter++;
            }
        }
    }

    public static void syncRelationshipFields(npe4__Relationship__c sourceRel, npe4__Relationship__c targetRel) {
            for (String f : syncFields) {
                targetRel.put(f,sourceRel.get(f));
            }
    }    


    /*******************************************************************************************************
    * @description Utility method to determine if any synced fields have changed
    * @param newRel The Relationship record with new field values
    * @param oldRel The Relationship record with old field values 
    ********************************************************************************************************/

    private static Boolean needsUpdate(npe4__Relationship__c newRel, npe4__Relationship__c oldRel) {
        if (newRel.npe4__ReciprocalRelationship__c != null) {
            for (string f : syncFields) {
                if (newRel.get(f) != oldRel.get(f)) {
                    return true;
                }
            }
            if (newRel.npe4__Type__c != oldRel.npe4__Type__c) {
                return true;
            }
        } 
        return false;
    }
    
    /*******************************************************************************************************
    * @description Remove all duplicate Relationships, for the list of Contacts.  
    * Called by handleContactMergeFixupsFuture() after a Contact Merge has occurred.
    * @param listCon The list of Contacts 
    * @return null
    ********************************************************************************************************/
    public static void cleanupContactRelationships(list<Contact> listCon) {

        // use dmlWrapper to handle all of our database operations
        TDTM_Runnable.DmlWrapper dmlWrapper = new TDTM_Runnable.DmlWrapper();    
        
        // for each Contact, get its list of Relationships in oldest to newest order (of LastModifiedDate)
        map<Id, list<npe4__Relationship__c>> mapConIdListRel = new map<Id, list<npe4__Relationship__c>>();
        
        // first we get all Relationships involved
        list<npe4__Relationship__c> listRel = [select Id, npe4__Contact__c, npe4__RelatedContact__c,
            npe4__Status__c, npe4__Type__c, npe4__Description__c
            from npe4__Relationship__c 
            where npe4__Contact__c in :listCon
            order by npe4__Contact__c, LastModifiedDate asc];

        // now put each contact's relationships on their own list            
        for (npe4__Relationship__c rel : listRel) {
            list<npe4__Relationship__c> listConRel = mapConIdListRel.get(rel.npe4__Contact__c);
            if (listConRel == null) {
                listConRel = new list<npe4__Relationship__c>();
                mapConIdListRel.put(rel.npe4__Contact__c, listConRel);
            }
            listConRel.add(rel);
        }
        
        // now we go through each contact's list of relationships to find duplicates
        for (Contact con : listCon) {
        
            // skip this contact if they have relationships to deal with 
            if (!mapConIdListRel.containsKey(con.Id))
               continue;

            // create a map of relKeys to relationship's to find our duplicates
            map<string, list<npe4__Relationship__c>> mapRelKeyRel = new map<string, list<npe4__Relationship__c>>(); 
            for (npe4__Relationship__c rel : mapConIdListRel.get(con.Id)) {
                string relKey = getRelKey(rel);
                listRel = mapRelKeyRel.get(relKey);
                if (listRel == null) {
                    listRel = new list<npe4__Relationship__c>();
                    mapRelKeyRel.put(relKey, listRel);
                }
                listRel.add(rel);                
            }
            
            // now we have the lists of duplicate relationships, remove the duplicates.            
            for (string relKey : mapRelKeyRel.keySet()) {
                listRel = mapRelKeyRel.get(relKey);
                
                // keep the oldest and delete the others
                for (integer i = 1; i < listRel.size(); i++) {
                    dmlWrapper.objectsToDelete.add(listRel[i]);
                }
            }
        }
        
        // perform our updates & deletes for dealing with the duplicate relationships
        TDTM_TriggerHandler.processDml(dmlWrapper); 
    }

    /*******************************************************************************************************
    * @description Returns a unique string key that represents the data of a Relationship, which can be used
    * to detect duplicate Relationships. 
    * @param rel The Relationship 
    * @return String The relKey
    ********************************************************************************************************/
    private static string getRelKey(npe4__Relationship__c rel) {
        if (rel == null)
            return null;
        string relKey = 
            rel.npe4__Contact__c + ':' + 
            rel.npe4__RelatedContact__c + ':' +
            rel.npe4__Type__c + ':' +
            rel.npe4__Status__c + ':' +
            rel.npe4__Description__c;
        return relKey;
    }
}