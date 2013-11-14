public with sharing class AFFL_InsertsHandler {

    TDTM_TriggerHandler.DmlWrapper run(List<Sobject> newlist, List<Sobject> oldlist, 
    TDTM_TriggerActionHelper.Action ta, Schema.Describesobjectresult obj) {
        
        TDTM_TriggerHandler.DmlWrapper dmlWrapper = new TDTM_TriggerHandler.DmlWrapper();
    	npe5__Affiliations_Settings__c currentAffiliationsSettings = AFFL_AffiliationsHelper.getAffiliationsSettings();        

        if (currentAffiliationsSettings.npe5__Automatic_Affiliation_Creation_Turned_On__c) {       
            List<Contact> affiliationInserts = new List<Contact>();
            Integer i = 0;
            for (SObject so : newlist) {
            	Contact contact = (Contact)so;
                // AFTER INSERT
                if (ta == TDTM_TriggerActionHelper.Action.AfterInsert && contact.AccountId != null) {
                    //insert affiliations for contacts with an Account
                        affiliationInserts.add(contact);
                }
                
                // AFTER UPDATE
                if (ta == TDTM_TriggerActionHelper.Action.AfterUpdate) {
                	Contact oldContact = (Contact) oldlist[i];
                    if (contact.AccountId != oldContact.AccountId && contact.AccountId != null)
                        affiliationInserts.add(contact);
                }
                i++;
            }
    
            if (affiliationInserts.size() > 0)
                dmlWrapper.objectsToInsert.addAll(insertAffiliation(affiliationInserts));                    
        }
        return dmlWrapper; 
    }
    
    /// <name> insertAffiliation </name>
    /// <summary> Creates a new Affiliation record when a Contact is related to a new non-Individual Account </summary>
    /// <param name="Contact"> List of contacts meeting trigger criteria </param>
    private static List<SObject> insertAffiliation(Contact[] contacts) {
        
        List<Id> accountIds = new List<Id>();
        for(Contact c : contacts)
            accountIds.add(c.AccountId);
        
        //get all the accounts associated wth these contacts
        Map<Id,Account> accountMap = new Map<Id,Account>([Select Id, Name from Account where Id in :accountIds]);

        List<npe5__Affiliation__c> affiliationInserts = new List<npe5__Affiliation__c>();
        for(Contact c : contacts) {
            String cName = c.FirstName;
            cName += ' ';
            cName += c.LastName;
            //check to see if this account isn't an individual. Can't use the real systemisindividual field on account
            //because that would make this dependent on the Contacts and Organizations package
            if ( accountMap.get(c.AccountId).Name != cName && accountMap.get(c.AccountId).Name != 'Individual') {
                npe5__Affiliation__c a = new npe5__Affiliation__c();
                a.npe5__Contact__c = c.Id;
                a.npe5__Organization__c = c.AccountId;
                a.npe5__Status__c = system.label.npe5.DefaultCurrentStatus;
                a.npe5__StartDate__c = System.Today();
                //user title as Role
                if (c.Title != null) {
                    a.npe5__Role__c = c.Title;
                }
                affiliationInserts.add(a);
            }
        }
        
        return affiliationInserts;
    }
}