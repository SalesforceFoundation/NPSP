/*
    Copyright (c) 2009, Salesforce.org
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
* @date 2011 (1.x)
* @group Opportunity
* @group-content ../../ApexDocContent/Opportunity.htm
* @description Provides opportunity and contact role support for all models  
*/
public without sharing class OPP_OpportunityContactRoles_TDTM extends TDTM_Runnable {

    private DmlWrapper dmlWrapper = new DmlWrapper();

    // the main entry point for TDTM to invoke our trigger handlers.
    public override DmlWrapper run(List<SObject> newlist, List<SObject> oldlist, 
    TDTM_Runnable.Action triggerAction, Schema.DescribeSObjectResult objResult) {
            
        if (triggerAction == TDTM_Runnable.Action.BeforeInsert) {
            setOpportunityAccountField((list<Opportunity>) newlist);
        } else if (triggerAction == TDTM_Runnable.Action.AfterInsert) {
            createOrUpdateContactRoles((list<Opportunity>) newlist);
            
            //name opportunities
            map<id,Opportunity> mapOppNaming = new map<id,Opportunity>(OPP_OpportunityNaming.getOppNamesAfterInsert((list<Opportunity>) newlist));
            
            //update existing dmlWrapper objects with opp name to avoid errors updating the same opportunity twice
            for (sObject dmlObj : dmlWrapper.objectsToUpdate) {
                id objId = (id) dmlObj.get('id');
                if (mapOppNaming.containsKey(objId)) {
                    dmlObj.put('Name',mapOppNaming.get(objId).Name);
                    mapOppNaming.remove(objId);
                }
            }

            dmlWrapper.objectsToUpdate.addAll((list<sObject>) mapOppNaming.values());

        } else if (triggerAction == TDTM_Runnable.Action.AfterUpdate) {
            updateContactRoles((list<Opportunity>) newlist, (list<Opportunity>) oldlist);
        }

        // we can't defer the dml.  too many of our other opp related triggers depend on the ocr's being saved.
        // disable TDTM so we don't waste resources running through opp triggers a second time while fixing Primary Contact lookup
        TDTM_TriggerHandler.disableTDTM = true;
        TDTM_TriggerHandler.processDML(dmlWrapper);
        TDTM_TriggerHandler.disableTDTM = false;

        return new DmlWrapper();
    }

     /*******************************************************************************************************
    * @description Detects changes in the opportunity Primary Contact field and updates or deletes the 
    * associated primary contact role.
    * @param opportunties List of opportunities meeting trigger criteria
    ********************************************************************************************************/
    private void updateContactRoles(list<Opportunity> listOpp, list<Opportunity> listOldOpps) { 
        map<id, id> mapOppIdNewConId = new map<id, id>();
        map<id, id> mapOppIdOldConId = new map<id, id>();
        map<id, map<id,OpportunityContactRole>> mapOppIdMapConIdOCR = new map<id, map<id,OpportunityContactRole>>();

        //find changed opportunities
        for (integer i=0;i<listOpp.size();i++) {
            if (listOpp[i].Primary_Contact__c != listOldOpps[i].Primary_Contact__c) {
                mapOppIdNewConId.put(listOpp[i].id, listOpp[i].Primary_Contact__c);
                mapOppIdOldConId.put(listOldOpps[i].id, listOldOpps[i].Primary_Contact__c);
            }
        }

        //delete or update OCRs
        if (!mapOppIdNewConId.isEmpty()) {
            for (OpportunityContactRole ocr : [SELECT OpportunityId, Opportunity.Primary_Contact__c, ContactId, isPrimary FROM OpportunityContactRole 
                                                    WHERE OpportunityId IN :mapOppIdNewConId.keyset() 
                                                    AND (IsPrimary=TRUE OR ContactId IN :mapOppIdNewConId.values() OR ContactID IN :mapOppIdOldConId.values())]) {
                if (!mapOppIdMapConIdOCR.containsKey(ocr.OpportunityId))
                    mapOppIdMapConIdOCR.put(ocr.OpportunityId,new map<id,OpportunityContactRole>());

                mapOppIdMapConIdOCR.get(ocr.OpportunityId).put(ocr.ContactId, ocr);
            }

            for (Opportunity opp : listOpp) {
                //get all contact and OCR values for this opportunity
                id newCon = mapOppIdNewConId.get(opp.id);
                id oldCon = mapOppIdOldConId.get(opp.id);
                map<id,OpportunityContactRole> mapOCR = mapOppIdMapConIdOCR.get(opp.id);

                //if we have a primary OCR, separate it from the list
                OpportunityContactRole primaryOCR;
                if (mapOCR != null && !mapOCR.isEmpty()) {
                    for (OpportunityContactRole ocr : mapOCR.values()) {
                        if (ocr.isPrimary) {
                            primaryOCR = ocr;
                            mapOCR.remove(ocr.ContactId);
                        }
                    }
                }
                //primary contact is blanked out 
                if (newCon == null) {
                    //if we have a primary OCR, delete it
                    if (primaryOCR != null)
                        dmlWrapper.objectsToDelete.add(primaryOCR);

                //primary contact went from blank to a new contact
                } else if (newCon != null) {
                    //create or update the existing primary OCR
                    if (primaryOCR == null) {
                        insertCR(new list<Opportunity>{opp});
                    } else {
                        if (primaryOCR.ContactId != newCon) {
                            primaryOCR.ContactId = newCon;
                            dmlWrapper.objectsToUpdate.add((SObject)primaryOCR);
                        }
                    }

                    //if we have an existing OCR for the primary contact
                    //update it with the old contact or delete it
                    if (mapOCR.containsKey(newCon)) {
                        OpportunityContactRole newConOCR = mapOCR.get(newCon);
                        if (oldCon != null) {
                            newConOCR.ContactId=oldCon;
                            dmlWrapper.objectsToUpdate.add((SObject)newConOCR);
                            
                            //if we already have a non-primary contact role for oldCon,
                            //delete it to avoid duplicates
                            if (mapOCR.containsKey(oldCon))
                                dmlWrapper.objectsToDelete.add((SObject)newConOCR);

                        //no old contact to switch with, just delete the new contact's old OCR
                        } else {
                            dmlWrapper.objectsToDelete.add((SObject)newConOCR);
                        }
                    }
                }
            }
        }
    }

     /*******************************************************************************************************
    * @description Creates Contact Role records when an opp is inserted and there is no primary CR. Updates
    * existing primary CRs with the correct role value if it is null. Updates existing opps' Primary Contact
    * based on existing CRs.
    * @param opportunties List of opportunities meeting trigger criteria
    ********************************************************************************************************/
    private void createOrUpdateContactRoles(list<Opportunity> listOpp) {
        
        Map<Id, Opportunity> oppsInsertCR = new map<Id, Opportunity>(listOpp);        
        List<OpportunityContactRole> CRUpdates = new List<OpportunityContactRole>();
        List<Opportunity> fixedOpps = new list<Opportunity>();

        //Get existing contact roles for the trigger opps. 
        List<OpportunityContactRole> CRs = [select OpportunityId, ContactId, Role, IsPrimary from OpportunityContactRole where IsPrimary = true and OpportunityId in :oppsInsertCR.keySet()];

        if(!CRs.isEmpty()) {
            for(OpportunityContactRole cr : CRs) {
                //check for missing Role value and update that OCR
                if(cr.Role == null) {
                    cr.Role = getDefaultRole();
                    CRUpdates.add(cr);
                }
                
                Opportunity thisOpp = oppsInsertCR.get(cr.OpportunityId);
                
                //check if our contact lookup field is incorrect and update it
                if (thisOpp.Primary_Contact__c != cr.ContactId) {
                    
                    //create new opp to allow DML on current trigger set
                    fixedOpps.add(new Opportunity(
                        id = thisOpp.id,
                        Primary_Contact__c = cr.ContactId,
                        npe01__Contact_Id_for_Role__c = cr.ContactId
                    ));
                }

                oppsInsertCR.remove(cr.OpportunityId);
            }
        }

        //Create CRs.
        if (!oppsInsertCR.isEmpty()) {
            insertCR(oppsInsertCR.values());
        }

        //Update existing CRs.
        if (!CRUpdates.isEmpty()) {
            update CRUpdates;
        }

        //fix opportunity lookup if out of sync with contact role
        if (!fixedOpps.isEmpty()) {
            dmlWrapper.objectsToUpdate.addAll((List<SObject>)fixedOpps);
        }
    }

    /*******************************************************************************************************
    * @description Return the default role from the custom setting.  Use custom setting for default role value.
    ********************************************************************************************************/
    private static String getDefaultRole() {
        return UTIL_CustomSettingsFacade.getContactsSettings().npe01__Opportunity_Contact_Role_Default_role__c;
    }

    /*******************************************************************************************************
    * @description Creates a new Contact Role record when an opp is inserted and there is no primary CR. 
    * Uses a custom setting for default role value.
    * @param opportunties List of opportunities meeting trigger criteria
    ********************************************************************************************************/
    private void insertCR(Opportunity[] opportunities) {

        List<OpportunityContactRole> CRs = new List<OpportunityContactRole>();
        List<Opportunity> fixedOpps = new list<Opportunity>();

        //Straightforward creation of opp contact role.      
        for(Opportunity o : opportunities) {
            if(o.Primary_Contact__c != null) {
                CRs.add(new OpportunityContactRole(OpportunityId = o.Id, ContactId = o.Primary_Contact__c, Role = getDefaultRole(), IsPrimary = true));
            //if primary contact is null, still try using the contact id for role field
            } else if (o.npe01__Contact_Id_for_Role__c != null) {
                try {
                    CRs.add(new OpportunityContactRole(OpportunityId = o.Id, ContactId = o.npe01__Contact_Id_for_Role__c, Role = getDefaultRole(), IsPrimary = true));
                    fixedOpps.add(new Opportunity(
                        id = o.id,
                        Primary_Contact__c = o.npe01__Contact_Id_for_Role__c
                    ));
                } catch (Exception ex) {
                    o.addError(Label.npe01.Opportunity_Contact_Role_Error_Bad_Contact_Id);
                }
            }
        }
        if (CRs.size() > 0) {
            insert CRs; 
        }
        //fix opportunity lookup if out of sync with contact role
        if (!fixedOpps.isEmpty()) {
            dmlWrapper.objectsToUpdate.addAll((List<SObject>)fixedOpps);
        }
    }
    
    /*******************************************************************************************************
    * @description Fills 1:1 and HH accounts for Opportunities where the Contact Id is supplied. Fills the
    * contact Id with the account's primary contact if the account is supplied but not the contact.
    * @param oppList A list of opportunities in the current transaction.
    *******************************************************************************************************/
    private static void setOpportunityAccountField(List<Opportunity> oppList) {
        
        Map<Id,Account> contactsAndOneToOneAccounts = new Map<Id,Account>();
        Set<String> primaryContactIds = new Set<String>();
        Set<Id> oppAccounts = new Set<Id>();
        
        for (Opportunity o : oppList) {

            //keep new and old contact fields in sync
            if (o.npe01__Contact_Id_for_Role__c == null && o.Primary_Contact__c != null)
                o.npe01__Contact_Id_for_Role__c = o.Primary_Contact__c;

            if (o.npe01__Contact_Id_for_Role__c != null && o.Primary_Contact__c == null) {
                //if the npe01__Contact_Id_for_Role__c isn't a valid ID, null it out
                try {
                    o.Primary_Contact__c = o.npe01__Contact_Id_for_Role__c;
                } catch (Exception e) {
                    o.addError(Label.npe01.Opportunity_Contact_Role_Error_Bad_Contact_Id);
                }
            }
            
            if (o.AccountId != null && o.Primary_Contact__c == null)
                oppAccounts.add(o.AccountId);
            
            if (o.AccountId == null && o.Primary_Contact__c != null)
                primaryContactIds.add(o.Primary_Contact__c);                
        }
        
        Map<Id,Account> primaryAccounts = new Map<Id,Account>([select id, npe01__One2OneContact__c, npe01__SYSTEM_AccountType__c from Account where id IN :oppAccounts]);
        List<Contact> primaryContacts = [select AccountId,Account.Id,Account.npe01__SYSTEM_AccountType__c from Contact where Id IN :primaryContactIds];

        for (Contact thisContact : primaryContacts)
            contactsAndOneToOneAccounts.put(thisContact.Id,thisContact.Account);

        //loop through opps again and then put the right accountid on the opp
        for (Opportunity o : oppList) {

            //add the contact id from the Account. We're guessing this is for the primary contact,
            //in the after insert trigger we'll get the actual value from the contact role
            if (o.AccountId != null && o.Primary_Contact__c == null) {
                Account acc = primaryAccounts.get(o.AccountId);
                if (acc.npe01__SYSTEM_AccountType__c == CAO_Constants.ONE_TO_ONE_ORGANIZATION_TYPE || 
                    acc.npe01__SYSTEM_AccountType__c == CAO_Constants.HH_ACCOUNT_TYPE) {
                    o.Primary_Contact__c = acc.npe01__One2OneContact__c;
                    o.npe01__Contact_Id_for_role__c = acc.npe01__One2OneContact__c;
                }
            }
            
            //add the account ID from the Contact
            if (o.AccountId == null && o.Primary_Contact__c != null) { //using the contact id, pull the account from the map
                
                if (contactsAndOneToOneAccounts.containsKey(o.Primary_Contact__c)) {
                    Account accountForContact = contactsAndOneToOneAccounts.get(o.Primary_Contact__c);
                    //for one-to-one accounts and HH Accounts, set the account id
                    if (accountForContact.npe01__SYSTEM_AccountType__c == CAO_Constants.ONE_TO_ONE_ORGANIZATION_TYPE || 
                        accountForContact.npe01__SYSTEM_AccountType__c == CAO_Constants.HH_ACCOUNT_TYPE) {
                        o.AccountId = accountForContact.Id;
                    }
                } else {
                    o.addError(Label.npe01.Opportunity_Contact_Role_Error_Bad_Contact_Id);
                }            
            }
        }       
    }
}