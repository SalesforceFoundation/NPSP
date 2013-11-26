/*
    Copyright (c) 2009, Salesforce.com Foundation
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
public class AFFL_Affiliations {
    
    public static npe5__Affiliations_Settings__c affiliationsSettings;

    /// <name> AFFL_Affiliations </name>
    /// <summary> Default Constructor </summary>
    public AFFL_Affiliations()
    {
    }

    /// <name> triggerAction </name>
    /// <summary> contains possible actions for a trigger </summary>
    public enum triggerAction {beforeInsert, beforeUpdate, beforeDelete, afterInsert, afterUpdate, afterDelete, afterUndelete}


    /// <name> AFFL_Affiliations </name>
    /// <summary> Overloads the Affiliation object constructor to handle Affiliation processing </summary>
    /// <param name="contacts"> Contact objects that are being triggered </param>
    /// <param name="oldContacts"> Contact object values before trigger event </param>
    /// <param name="ta"> Trigger action that is occuring </param>
    public AFFL_Affiliations(Contact[] contacts, Contact[] oldContacts, triggerAction ta)
    {
        npe5__Affiliations_Settings__c currentAffiliationsSettings = getAffiliationsSettings();
        
        List<Contact> affiliationInserts = new List<Contact>();
        List<Contact> affiliationUpdates = new List<Contact>();
        
        Integer i = 0;
        if (currentAffiliationsSettings.npe5__Automatic_Affiliation_Creation_Turned_On__c) {
            for (Contact c : contacts) {
                // AFTER INSERT
                if ( ta==triggerAction.afterInsert )
                {
                    //insert affiliations for contacts with an Account
                    if ( c.AccountId != null )
                    {
                        affiliationInserts.add(c);
                    }
                }
                
                // AFTER UPDATE
                if ( ta==triggerAction.afterUpdate )
                {
                    if (c.AccountId != oldContacts[i].AccountId )
                    {
                        if (oldContacts[i].AccountId != null){
                            affiliationUpdates.add(oldContacts[i]);
                        }
                        if (c.AccountId != null){
                            affiliationInserts.add(c);
                        }
                    }
                }
                i += 1;
            }
    
            if (affiliationInserts.size() > 0)
            {
                insertAffiliation(affiliationInserts);
            }
            if (affiliationUpdates.size() > 0)
            {
                updateAffiliation(affiliationUpdates);
            }
        }

    }


    /// <name> insertAffiliation </name>
    /// <summary> Creates a new Affiliation record when a Contact is related to a new non-Individual Account </summary>
    /// <param name="Contact"> List of contacts meeting trigger criteria </param>
    private static void insertAffiliation(Contact[] contacts) {
        List<Id> accountIds = new List<Id>();
        for (Contact c : contacts) {
            accountIds.add(c.AccountId);
        }
        //get all the accounts associated wth these contacts
        Map<Id,Account> accountMap = new Map<Id,Account>([Select Id, npe01__SYSTEMIsIndividual__c from Account where Id in :accountIds]);

        List<npe5__Affiliation__c> affiliationInserts = new List<npe5__Affiliation__c>();
        for(Contact c : contacts) {
            String cName = c.FirstName;
            cName += ' ';
            cName += c.LastName;
            //check to see if this account isn't an individual. 
            if (accountMap.get(c.AccountId).npe01__SYSTEMIsIndividual__c != true) {
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
        if (affiliationInserts.size() > 0) {
            Database.SaveResult[] lsr = Database.insert(affiliationInserts, false);
        }
    }



    /// <name> updateAffiliation </name>
    /// <summary> Updates an existing Affiliation record when a Contact's Account is changed </summary>
    /// <param name="Contact"> List of original contacts before update that met trigger criteria </param>
    private static void updateAffiliation(Contact[] contacts)
    {
        List<Id> accountIds = new List<Id>();
        List<Id> contactIds = new List<Id>();
        Map<String,Id> conAccMap = new Map<String,Id>();

        for(Contact c : contacts)
        {
            contactIds.add(c.Id);
            accountIds.add(c.AccountId);
        }

        try {
            List<npe5__Affiliation__c> existingAffiliations = [Select Id, npe5__Contact__c, npe5__Organization__c from npe5__Affiliation__c where npe5__EndDate__c = null and npe5__Contact__c in :contactIds and npe5__Organization__c in :accountIds];
            for(npe5__Affiliation__c a : existingAffiliations)
            {
                //concatenate the contact and account id for a unique string we can access later
                String unique = a.npe5__Contact__c;
                unique += a.npe5__Organization__c;
                conAccMap.put(unique,a.Id);
            }
        } catch (exception e)
        {
        }
        
        List<npe5__Affiliation__c> affiliationUpdates = new List<npe5__Affiliation__c>();

        for(Contact c : contacts)
        {
            String u = c.Id;
            u += c.AccountId;
            //get the affiliation based on that unique string
            if (conAccMap.containsKey(u))
            {
                //flag it as former ending today
                npe5__Affiliation__c a = new npe5__Affiliation__c(Id=conAccMap.get(u));
                a.npe5__Status__c = system.label.npe5.DefaultFormerStatus;
                a.npe5__EndDate__c = System.Today();
                affiliationUpdates.add(a);
            }
        }
        
        if (affiliationUpdates.size() > 0)
        {
            Database.SaveResult[] lsr = Database.update(affiliationUpdates, false);
        }
    }
    
       //get the settings. handles the case where the managed value doesn't exist yet
    public static npe5__Affiliations_Settings__c getAffiliationsSettings() {
        //if no settings exist, create defaults
        if (affiliationsSettings == null) {
            //first see if we already have settings
            affiliationsSettings = npe5__Affiliations_Settings__c.getOrgDefaults();
            system.debug(npe5__Affiliations_Settings__c.getOrgDefaults());
            if (affiliationsSettings.id == null) { 
                //affiliationsSettings = new npe5__Affiliations_Settings__c();
                affiliationsSettings.npe5__Automatic_Affiliation_Creation_Turned_On__c = true;
               
                affiliationsSettings.Setupownerid = UserInfo.getOrganizationId();

                insert affiliationsSettings;
            }
        }
        return affiliationsSettings;
    }
    
    public static npe5__Affiliations_Settings__c getAffiliationsSettingsForTests(npe5__Affiliations_Settings__c mySettings) {
        
        //clear out whatever settings exist
        delete [select id from npe5__Affiliations_Settings__c limit 100];
        
        //create our own based on what's passed in from the test
        affiliationsSettings = new npe5__Affiliations_Settings__c (
            npe5__Automatic_Affiliation_Creation_Turned_On__c = mySettings.npe5__Automatic_Affiliation_Creation_Turned_On__c
            );
        insert affiliationsSettings;
            
        return affiliationsSettings;
    }
}