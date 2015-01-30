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
/**
* @author Salesforce.com Foundation
* @date 2009
*
* @group Affiliations
*
* @description  
*/
public class AFFL_Affiliations_TDTM extends TDTM_Runnable {

    // static flags to prevent recursive call 
    public static boolean hasRunForContacts = false;
    public static boolean hasRunForAffiliations = false;
    public static boolean hasRunForAccounts = false;
    
    // the main entry point for TDTM to invoke our trigger handlers.
    public override DmlWrapper run(List<SObject> newlist, List<SObject> oldlist, 
        TDTM_Runnable.Action triggerAction, Schema.DescribeSObjectResult objResult) {
            
        // dispatch to the correct handler
        if (objResult == Schema.Sobjecttype.Contact && !hasRunForContacts) {
            DmlWrapper wrapper = runContactTriggerHandler(newlist, oldlist, triggerAction, objResult);
            hasRunForContacts = true;
            return wrapper;
        } else if (objResult == Schema.Sobjecttype.npe5__Affiliation__c && !hasRunForAffiliations) {
            DmlWrapper wrapper = runAfflTriggerHandler(newlist, oldlist, triggerAction, objResult);
            hasRunForAffiliations = true;
            return wrapper;
        } else if (objResult == Schema.Sobjecttype.Account && !hasRunForAccounts) {
            DmlWrapper wrapper = runAccountTriggerHandler(newlist, oldlist, triggerAction, objResult);
            hasRunForAccounts = true;
            return wrapper;
        } else {
            return null;
        }
    }
                
    // the trigger handler on Contact for managing Affiliations        
    private DmlWrapper runContactTriggerHandler(List<SObject> newlist, List<SObject> oldlist, 
        TDTM_Runnable.Action triggerAction, Schema.DescribeSObjectResult objResult) {
        DmlWrapper dmlWrapper = new DmlWrapper();
        
        //Passing null basically indicates that the existing setting (in memory) should be used
        npe5__Affiliations_Settings__c currentAffiliationsSettings = UTIL_CustomSettingsFacade.getAffiliationsSettings();
        
        // we have multiple scenarios to support
        // 1. create a new current affiliation, potentially mark primary
        // 2. set an existing affiliation to former
        // 3. set an existing affiliation to non-primary
        // 4. set an existing affiliation to primary
        
        map<string, AfflOps> mapStrComboKeyAfflOps = new map<string, AfflOps>();
        
        Integer i = 0;
        if (currentAffiliationsSettings.npe5__Automatic_Affiliation_Creation_Turned_On__c) {
            
            for (SObject so : newlist) {
                Contact contact = (Contact)so;

                // AFTER INSERT
                if (triggerAction == TDTM_Runnable.Action.AfterInsert) {

                    if (contact.AccountId != null) {
                        string strComboKey = strComboKeyFromContactIdAccountId(contact.Id, contact.AccountId);
                        AfflOps ao = mapStrComboKeyAfflOps.get(strComboKey);
                        if (ao == null) ao = new AfflOps(contact.Id, contact.AccountId);
                        ao.fCurrent = true;
                        ao.strRole = contact.Title;
                        mapStrComboKeyAfflOps.put(strComboKey, ao);
                    }
                    if (contact.Primary_Affiliation__c != null) {
                        string strComboKey = strComboKeyFromContactIdAccountId(contact.Id, contact.Primary_Affiliation__c);                     
                        AfflOps ao = mapStrComboKeyAfflOps.get(strComboKey);
                        if (ao == null) ao = new AfflOps(contact.Id, contact.Primary_Affiliation__c);
                        ao.fPrimary = true;
                        ao.strRole = contact.Title;
                        mapStrComboKeyAfflOps.put(strComboKey, ao);
                    }
                }

                // AFTER UPDATE
                if (triggerAction == TDTM_Runnable.Action.AfterUpdate) {                
                    Contact oldContact = (Contact) oldlist[i];
                    
                    if (contact.AccountId != oldContact.AccountId) {
                        if (contact.AccountId != null) {
                            string strComboKey = strComboKeyFromContactIdAccountId(contact.Id, contact.AccountId);
                            AfflOps ao = mapStrComboKeyAfflOps.get(strComboKey);
                            if (ao == null) ao = new AfflOps(contact.Id, contact.AccountId);
                            ao.fCurrent = true;
                            ao.strRole = contact.Title;
                            mapStrComboKeyAfflOps.put(strComboKey, ao);
                        }
                        if (oldContact.AccountId != null) {
                            string strComboKey = strComboKeyFromContactIdAccountId(oldContact.Id, oldContact.AccountId);
                            AfflOps ao = mapStrComboKeyAfflOps.get(strComboKey);
                            if (ao == null) ao = new AfflOps(oldContact.Id, oldContact.AccountId);
                            ao.fFormer = true;
                            mapStrComboKeyAfflOps.put(strComboKey, ao);
                        }
                    }
    
                    if (contact.Primary_Affiliation__c != oldContact.Primary_Affiliation__c) {
                        if (contact.Primary_Affiliation__c != null) {
                            string strComboKey = strComboKeyFromContactIdAccountId(contact.Id, contact.Primary_Affiliation__c);                     
                            AfflOps ao = mapStrComboKeyAfflOps.get(strComboKey);
                            if (ao == null) ao = new AfflOps(contact.Id, contact.Primary_Affiliation__c);
                            ao.fPrimary = true;
                            ao.strRole = contact.Title;
                            mapStrComboKeyAfflOps.put(strComboKey, ao);
                        }
                        if (oldContact.Primary_Affiliation__c != null) {
                            string strComboKey = strComboKeyFromContactIdAccountId(oldContact.Id, oldContact.Primary_Affiliation__c);                     
                            AfflOps ao = mapStrComboKeyAfflOps.get(strComboKey);
                            if (ao == null) ao = new AfflOps(oldContact.Id, oldContact.Primary_Affiliation__c);
                            ao.fFormer = true;
                            ao.fUnprimary = true;
                            mapStrComboKeyAfflOps.put(strComboKey, ao);
                        }
                    }
                }
    
                i++;
            }
        
            if (mapStrComboKeyAfflOps.size() > 0) {
                processAfflOps(mapStrComboKeyAfflOps, dmlWrapper);
            }

        }
        return dmlWrapper;
    }

    // the trigger handler on Account for managing Affiliations        
    private DmlWrapper runAccountTriggerHandler(List<SObject> newlist, List<SObject> oldlist, 
        TDTM_Runnable.Action triggerAction, Schema.DescribeSObjectResult objResult) {
        DmlWrapper dmlWrapper = new DmlWrapper();

        //Passing null basically indicates that the existing setting (in memory) should be used
        npe5__Affiliations_Settings__c currentAffiliationsSettings = UTIL_CustomSettingsFacade.getAffiliationsSettings();
        
        // we have multiple scenarios to support
        // 1. insert: create new current affiliation (not primary)
        // 2. update: search for existing affiliations
        //      if one exists and isn't marked current, mark it as current
        //      otherwise create it
        
        map<string, AfflOps> mapStrComboKeyAfflOps = new map<string, AfflOps>();
        map<id, AfflOps> mapConIdToAfflOps = new map<id, AfflOps>();
        
        if (currentAffiliationsSettings.npe5__Automatic_Affiliation_Creation_Turned_On__c) {
            
            for (integer i=0; i<newlist.size(); i++) {
                Account account = (Account)newlist[i];
                //if this account is an organization, and we have a primary contact
                if (account.npe01__SYSTEMIsIndividual__c == false && account.npe01__One2OneContact__c != null) {
                    // AFTER INSERT
                    if (triggerAction == TDTM_Runnable.Action.AfterInsert) {
                        string strComboKey = strComboKeyFromContactIdAccountId(account.npe01__One2OneContact__c, account.id);
                        AfflOps ao = mapStrComboKeyAfflOps.get(strComboKey);
                        if (ao == null) ao = new AfflOps(account.npe01__One2OneContact__c, account.id);
                        ao.fCurrent = true;
                        mapConIdToAfflOps.put(account.npe01__One2OneContact__c, ao);
                        mapStrComboKeyAfflOps.put(strComboKey, ao);
                    }

                    // AFTER UPDATE
                    if (triggerAction == TDTM_Runnable.Action.AfterUpdate) {
                        Account oldAccount = (Account)oldlist[i];
                        
                        if (account.npe01__One2OneContact__c != oldAccount.npe01__One2OneContact__c) {
                            string strComboKey = strComboKeyFromContactIdAccountId(account.npe01__One2OneContact__c, account.id);
                            AfflOps ao = mapStrComboKeyAfflOps.get(strComboKey);
                            if (ao == null) ao = new AfflOps(account.npe01__One2OneContact__c, account.id);
                            ao.fCurrent = true;
                            mapConIdToAfflOps.put(account.npe01__One2OneContact__c, ao);
                            mapStrComboKeyAfflOps.put(strComboKey, ao);
                        }
                    }
                }
    
            }
        
            //we need an extra query here to get the correct role from the contact title
            if (!mapConIdToAfflOps.isEmpty()) {
                for (Contact con : [SELECT Id, Title FROM Contact WHERE Id IN :mapConIdToAfflOps.keySet()])
                    mapConIdToAfflOps.get(con.id).strRole = con.Title;
            }

            if (!mapStrComboKeyAfflOps.isEmpty()) {
                processAfflOps(mapStrComboKeyAfflOps, dmlWrapper);
            }

        }
        return dmlWrapper;
    }


    // temporary class used to track which affiliations need
    // what type of operation performed on them.
    private class AfflOps {

        // constructor
        AfflOps(Id contactId, Id accountId) {
            strComboKey = strComboKeyFromContactIdAccountId(contactId, accountId);
            fCurrent = false;
            fFormer = false;
            fPrimary = false;
            fUnprimary = false;
        }

        string strComboKey;
        boolean fCurrent;
        boolean fFormer;
        boolean fPrimary;
        boolean fUnprimary;
        string strRole;
        
        ID ContactId {
            get {
                if (strComboKey == null) return null;
                return strComboKey.left(strComboKey.indexOf('|'));
            }
        }
        
        ID AccountId {
            get {
                if (strComboKey == null) return null;
                return strComboKey.substring(strComboKey.indexOf('|') + 1);
            }
        }
        
    }
    
    
    // utility to create a string based Combo Key for an affiliation's contactId and accountId
    private static string strComboKeyFromContactIdAccountId(Id contactId, Id accountId) {
        return contactId + '|' + accountId;
    }

    // looks at each affiliation and the possible operations to perform on them
    // and figures out which to insert vs update, and adds them to the dmlWrapper.
    private static void processAfflOps(map<string, AfflOps> mapStrComboKeyAfflOps, DmlWrapper dmlWrapper) {

        // the collections we want to insert/update in the db
        list<npe5__Affiliation__c> listAfflInsert = new list<npe5__Affiliation__c>();
        list<npe5__Affiliation__c> listAfflIdAfflUpdate = new list<npe5__Affiliation__c>();

        // get all the accounts & contacts
        set<Id> setContactId = new set<Id>();
        set<Id> setAccountId = new set<Id>();
        for (AfflOps ao : mapStrComboKeyAfflOps.values()) {
            setContactId.add(ao.ContactId);
            setAccountId.add(ao.AccountId);
        }
        
        Map<Id,Account> mapAccountIdAccount = new Map<Id,Account>([Select Id, npe01__SYSTEMIsIndividual__c from Account where Id in :setAccountId]);
        
        // get existing affiliations
        map<string, npe5__Affiliation__c> mapStrComboKeyAffl = new map<string, npe5__Affiliation__c>();

        for (npe5__Affiliation__c a : [Select Id, npe5__Contact__c, npe5__Organization__c from npe5__Affiliation__c 
            where npe5__EndDate__c = null and npe5__Contact__c in :setContactId and npe5__Organization__c in :setAccountId]) {
            mapStrComboKeyAffl.put(strComboKeyFromContactIdAccountId(a.npe5__Contact__c, a.npe5__Organization__c), a);
        }

        for (AfflOps ao : mapStrComboKeyAfflOps.values()) {
            Id accountId = ao.AccountId;
            Id contactId = ao.ContactId;
            
            if (ao.fCurrent) {
                //check to see if this account isn't an individual.
                Account acc =  mapAccountIdAccount.get(accountId);
                if (acc != null && acc.npe01__SYSTEMIsIndividual__c != true) {
                    npe5__Affiliation__c a = new npe5__Affiliation__c();
                    a.npe5__Contact__c = contactId;
                    a.npe5__Organization__c = accountId;
                    a.npe5__Status__c = system.label.npe5.DefaultCurrentStatus;
                    a.npe5__StartDate__c = System.Today();
                    a.npe5__Role__c = ao.strRole;
                    a.npe5__Primary__c = ao.fPrimary;
                    listAfflInsert.add(a);
                }           
            }
            
            if (!ao.fCurrent && ao.fPrimary) {
               // see if we have an existing current affiliation to use, otherwise create a new one
               npe5__Affiliation__c a = mapStrComboKeyAffl.get(ao.strComboKey);
               if (a != null) {
                   a.npe5__Primary__c = true;
                   listAfflIdAfflUpdate.add(a);
               } else {
                    a = new npe5__Affiliation__c();
                    a.npe5__Contact__c = contactId;
                    a.npe5__Organization__c = accountId;
                    a.npe5__Status__c = system.label.npe5.DefaultCurrentStatus;
                    a.npe5__StartDate__c = System.Today();
                    a.npe5__Role__c = ao.strRole;
                    a.npe5__Primary__c = true;
                    listAfflInsert.add(a);              
               }
            }
            
            if (ao.fFormer || ao.fUnprimary) {
               npe5__Affiliation__c a = mapStrComboKeyAffl.get(ao.strComboKey);
               
               // deal with the affiliation being deleted (if the org or contact was deleted)
               if (a == null) continue;
               
               if (ao.fFormer) {
                    //flag it as former ending today
                    a.npe5__Status__c = system.label.npe5.DefaultFormerStatus;
                    a.npe5__EndDate__c = System.Today();                
               }
               if (ao.fUnprimary) {
                    a.npe5__Primary__c = false;
               }  
               listAfflIdAfflUpdate.add(a);
            }
        }

        if (listAfflInsert.size() > 0) {
            //UTIL_Debug.debug('**** listAfflInsert: ' + JSON.serializePretty(listAfflInsert));
            dmlWrapper.objectsToInsert.addAll((list<SObject>) listAfflInsert);
        }
            
       if (listAfflIdAfflUpdate.size() > 0) {
            //UTIL_Debug.debug('**** listAfflIdAfflUpdate: ' + JSON.serializePretty(listAfflIdAfflUpdate.values()));
            dmlWrapper.objectsToUpdate.addAll((list<SObject>) listAfflIdAfflUpdate);
       }
    }
    
    // the trigger handler on Affiliation for managing Affiliations        
    private DmlWrapper runAfflTriggerHandler(List<SObject> newlist, List<SObject> oldlist, 
        TDTM_Runnable.Action triggerAction, Schema.DescribeSObjectResult objResult) {

        DmlWrapper dmlWrapper = new DmlWrapper();
        
        map<Id, Id> mapConIdAccIdPrimary = new map<Id, Id>();
        map<Id, Id> mapConIdAccIdUnprimary = new map<Id, Id>();
        
        integer i = 0;        
        for (SObject so : newlist) {
            npe5__Affiliation__c affl = (npe5__Affiliation__c)so;

            // AFTER INSERT
            if (triggerAction == TDTM_Runnable.Action.AfterInsert) {
                if (affl.npe5__Primary__c && affl.npe5__Contact__c != null && affl.npe5__Organization__c != null) {
                    mapConIdAccIdPrimary.put(affl.npe5__Contact__c, affl.npe5__Organization__c);
                }        
            }
            
            // AFTER UPDATE
            if (triggerAction == TDTM_Runnable.Action.AfterUpdate) {
                npe5__Affiliation__c afflOld = (npe5__Affiliation__c)oldlist[i];
                if (affl.npe5__Primary__c != afflOld.npe5__Primary__c) {
                    if (affl.npe5__Primary__c)    
                        mapConIdAccIdPrimary.put(affl.npe5__Contact__c, affl.npe5__Organization__c);
                    else
                        mapConIdAccIdUnprimary.put(afflOld.npe5__Contact__c, afflOld.npe5__Organization__c);                    
                }
            }
            
        i++;            
        }
       
        // update all our contacts as appropriate
        list<Contact> listCon = new list<Contact>();
        for (Id contactId : mapConIdAccIdPrimary.keySet()) {
            Contact con = new Contact(Id = contactId);
            con.Primary_Affiliation__c = mapConIdAccIdPrimary.get(contactId);
            listCon.add(con);
        }
        for (Id contactId : mapConIdAccIdUnprimary.keySet()) {
            Contact con = new Contact(Id = contactId);
            con.Primary_Affiliation__c = null;
            listCon.add(con);
        }
    
        if (listCon.size() > 0) {
            dmlWrapper.objectsToUpdate.addAll((List<SObject>)listCon);
        }
        return dmlWrapper;
    }

}