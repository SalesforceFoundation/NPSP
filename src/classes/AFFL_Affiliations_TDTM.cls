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
public class AFFL_Affiliations_TDTM extends TDTM_Runnable {

    /// <name> AFFL_Affiliations </name>
    /// <summary> Overloads the Affiliation object constructor to handle Affiliation processing </summary>
    /// <param name="newlist"> Contact objects that are being triggered </param>
    /// <param name="oldlist"> Contact object values before trigger event </param>
    /// <param name="triggerAction"> Trigger action that is occuring </param>
    public override DmlWrapper run(List<SObject> newlist, List<SObject> oldlist, 
    TDTM_TriggerActionHelper.Action triggerAction, Schema.DescribeSObjectResult objResult) {
        
        DmlWrapper dmlWrapper = new DmlWrapper();
        
        npe5__Affiliations_Settings__c currentAffiliationsSettings = AFFL_Affiliations_UTIL.getAffiliationsSettings();
        
        List<Contact> affiliationInserts = new List<Contact>();
        List<Contact> affiliationUpdates = new List<Contact>();
        
        Integer i = 0;
        if (currentAffiliationsSettings.npe5__Automatic_Affiliation_Creation_Turned_On__c) {
            for (SObject so : newlist) {
            	Contact contact = (Contact)so;
                // AFTER INSERT
                if (triggerAction == TDTM_TriggerActionHelper.Action.AfterInsert) {
                    //insert affiliations for contacts with an Account
                    if (contact.AccountId != null) {
                        affiliationInserts.add(contact);
                    }
                }
                
                // AFTER UPDATE
                if ( triggerAction == TDTM_TriggerActionHelper.Action.AfterUpdate) {
                    Contact oldContact = (Contact) oldlist[i];
                    if (contact.AccountId != oldContact.AccountId) {
                        if (oldContact.AccountId != null)
                            affiliationUpdates.add(oldContact);
                        if (contact.AccountId != null)
                            affiliationInserts.add(contact);
                    }
                }
                i++;
            }
    
            if (affiliationInserts.size() > 0) {
            	System.debug('****Number of contacts that need new affiliations: ' + affiliationInserts.size());
                dmlWrapper.objectsToInsert.addAll(processInserts(affiliationInserts));
            }
            
            if (affiliationUpdates.size() > 0) {
            	System.debug('****Number of contacts that need updated affiliations: ' + affiliationUpdates.size());
                dmlWrapper.objectsToUpdate.putAll(processUpdates(affiliationUpdates));
            }
        }
        return dmlWrapper;
    }


    /// <name> insertAffiliation </name>
    /// <summary> Creates a new Affiliation record when a Contact is related to a new non-Individual Account </summary>
    /// <param name="Contact"> List of contacts meeting trigger criteria </param>
    private static List<SObject> processInserts(Contact[] contacts) {

        List<SObject> affiliationInserts = new List<SObject>();
                
        List<Id> accountIds = new List<Id>();
        for(Contact c : contacts) {
            accountIds.add(c.AccountId);
        }
        //get all the accounts associated wth these contacts
        Map<Id,Account> accountMap = new Map<Id,Account>([Select Id, npe01__SYSTEMIsIndividual__c from Account 
                                                            where Id in :accountIds]);

        for(Contact c : contacts) {
            String cName = c.FirstName;
            cName += ' ';
            cName += c.LastName;
            //check to see if this account isn't an individual. 
            Account acct = accountMap.get(c.AccountId);
            if (acct != null) {
                if (acct.npe01__SYSTEMIsIndividual__c != true) {
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
            } else {
                // This situation should never occur as init filters contacts with a null id.  However, we were hitting
                // NullPointerExceptions after looking up an account that debug shows was in the accountMap but a get by
                // c.AccountId returned null.  Attempting to look at a field on the null result raised the exception.
                // This error only occurred from tests run as part of an ant deployment.  The same tests run through the 
                // web ui after a deploy passed.  The tests that experienced the issue all created a contact without
                // an AccountId set and relied on ACCT_IndividualAccount triggers to create the account and link the Contact.
                String message = 'Failed to find account with id ' + c.AccountId + ' in ' + accountMap;
                System.debug('****' + message);
                Exception e = new NullPointerException();
                e.setMessage(message);
                Error__c error = ERR_Handler.createError(e);
                affiliationInserts.add(error);   
            }
        }
        return affiliationInserts;
    }



    /// <name> updateAffiliation </name>
    /// <summary> Updates an existing Affiliation record when a Contact's Account is changed </summary>
    /// <param name="Contact"> List of original contacts before update that met trigger criteria </param>
    private static Map<Id, SObject> processUpdates(Contact[] contacts) {
        List<Id> accountIds = new List<Id>();
        List<Id> contactIds = new List<Id>();
        Map<String,Id> conAccMap = new Map<String,Id>();

        for(Contact c : contacts) {
            contactIds.add(c.Id);
            accountIds.add(c.AccountId);
        }

        try {
            List<npe5__Affiliation__c> existingAffiliations = [Select Id, npe5__Contact__c, npe5__Organization__c 
                    from npe5__Affiliation__c where npe5__EndDate__c = null and npe5__Contact__c in :contactIds 
                    and npe5__Organization__c in :accountIds];
            
            for(npe5__Affiliation__c a : existingAffiliations) {
                //concatenate the contact and account id for a unique string we can access later
                String unique = a.npe5__Contact__c;
                unique += a.npe5__Organization__c;
                conAccMap.put(unique,a.Id);
            }
        } catch (Exception e) {
        	System.debug('****Exception caught in AFFL_Affiliations_TDTM.processUpdates');
            ERR_Handler.processError(e, null);
        }
        
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
                affiliationUpdates.put(affiliation.Id, affiliation);
            }
        }
        
        return affiliationUpdates;
    }
}