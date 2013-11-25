public with sharing class AFFL_UpdatesHandler extends TDTM_Runnable {

    private static Boolean alreadyCalledBefore = false;
    private static Boolean alreadyCalledAfter = false;
    
    public override Boolean wasAlreadyCalledBefore() {
        return alreadyCalledBefore;
    }
    
    public override Boolean wasAlreadyCalledAfter() {
        return alreadyCalledAfter;
    }
    
    public override TDTM_Runnable.DmlWrapper run(List<Sobject> newlist, List<Sobject> oldlist, 
    TDTM_TriggerActionHelper.Action ta, Schema.DescribeSObjectResult obj) {
        
        TDTM_Runnable.DmlWrapper dmlWrapper = new TDTM_Runnable.DmlWrapper();
        if(!alreadyCalledAfter) {
            System.debug('****Running AFFL_UpdatesHandler');
            alreadyCalledAfter = true;
	        npe5__Affiliations_Settings__c currentAffiliationsSettings = AFFL_AffiliationsHelper.getAffiliationsSettings();
	        
	        if (currentAffiliationsSettings.npe5__Automatic_Affiliation_Creation_Turned_On__c) {
	        	System.debug('****Automatic affiliation creation is ON');
	            List<Contact> affiliationUpdates = new List<Contact>();
	            Integer i = 0;
	            for (Sobject so : newlist) {
	            	Contact contact = (Contact)so; 
	            	Contact oldContact = (Contact)oldlist[i];
	                // AFTER UPDATE
	                if (ta == TDTM_TriggerActionHelper.Action.AfterUpdate && contact.AccountId != oldContact.AccountId 
	                && oldContact.AccountId != null) {
	                    affiliationUpdates.add(oldContact);
	                }
	                i++;
	            }
	            
	            if (affiliationUpdates.size() > 0)
	                dmlWrapper.objectsToUpdate.putAll(updateAffiliation(affiliationUpdates));
	        } else {
	        	System.debug('****Automatic affiliation creation is OFF');
	        }
        }
        return dmlWrapper;
    }
    
    /// <name> updateAffiliation </name>
    /// <summary> Updates an existing Affiliation record when a Contact's Account is changed </summary>
    /// <param name="Contact"> List of original contacts before update that met trigger criteria </param>
    public static Map<Id, SObject> updateAffiliation(Contact[] contacts) {
        List<Id> accountIds = new List<Id>();
        List<Id> contactIds = new List<Id>();
        Map<String,Id> conAccMap = new Map<String,Id>();

        for(Contact c : contacts) {
            contactIds.add(c.Id);
            accountIds.add(c.AccountId);
        }

        try {
            List<npe5__Affiliation__c> existingAffiliations = [Select Id, npe5__Contact__c, npe5__Organization__c from npe5__Affiliation__c where npe5__EndDate__c = null and npe5__Contact__c in :contactIds and npe5__Organization__c in :accountIds];
            for(npe5__Affiliation__c a : existingAffiliations) {
                //concatenate the contact and account id for a unique string we can access later
                String unique = a.npe5__Contact__c;
                unique += a.npe5__Organization__c;
                conAccMap.put(unique,a.Id);
            }
        } catch (exception e) { }
        
        Map<Id, npe5__Affiliation__c> affiliationUpdates = new Map<Id, npe5__Affiliation__c>();

        for(Contact contact : contacts) {
            String u = contact.Id;
            u += contact.AccountId;
            //get the affiliation based on that unique string
            if (conAccMap.containsKey(u)) {
                //flag it as former ending today
                npe5__Affiliation__c affiliation = new npe5__Affiliation__c(Id=conAccMap.get(u));
                affiliation.npe5__Status__c = system.label.npe5.DefaultFormerStatus;
                affiliation.npe5__EndDate__c = System.Today();
                System.debug('****Adding affiliation with ID ' + affiliation.Id + ' to the list of updates');
                affiliationUpdates.put(affiliation.Id, affiliation);
            }
        }
        
        return affiliationUpdates;
    }
}