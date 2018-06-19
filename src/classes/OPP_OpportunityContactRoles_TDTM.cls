/*
    Copyright (c) 2015, Salesforce.org
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

    private static final String FIELD_NAME_PRIMARY_CONTACT = 'Primary_Contact__c';
    private static final String FIELD_NAME_HONOREE_CONTACT = 'Honoree_Contact__c';
    private static final String FIELD_NAME_NOTIFICATION_RECIPIENT_CONTACT = 'Notification_Recipient_Contact__c';


    /** @description DmlWrapper holds dml transactions for processing classes. */
    private DmlWrapper dmlWrapper = new DmlWrapper();


    /*******************************************************************************************************
    * @description Trigger Handler on Opportunity that handles Contact Role support.
    * @param listNew the list of Opportunities from trigger new. 
    * @param listOld the list of Opportunities from trigger old. 
    * @param triggerAction which trigger event (BeforeInsert, AfterInsert, etc.). 
    * @param objResult the describe for Opportunities 
    * @return dmlWrapper Always null. DML can't be deferred in this case as too many of our other opp related
    * triggers depend on Opportunity Contact Roles existing.
    ********************************************************************************************************/
    public override DmlWrapper run(List<SObject> newlist, List<SObject> oldlist, 
    TDTM_Runnable.Action triggerAction, Schema.DescribeSObjectResult objResult) {
            
        if (triggerAction == TDTM_Runnable.Action.BeforeInsert) {
            setOpportunityAccountField((list<Opportunity>) newlist);
            updateHonoreeNotificationFields((list<Opportunity>) newlist, null);

        } else if (triggerAction == TDTM_Runnable.Action.BeforeUpdate) {
            updateHonoreeNotificationFields((list<Opportunity>) newlist, (list<Opportunity>) oldlist);

        } else if (triggerAction == TDTM_Runnable.Action.AfterInsert) {
            upsertContactRolesAfterInsert((list<Opportunity>) newlist);
            try {
                updateOpportunityNames((list<Opportunity>) newList);            
            } catch (Exception ex) {
                ERR_Handler.processError(ex, ERR_Handler_API.Context.OPP);
            }
        } else if (triggerAction == TDTM_Runnable.Action.AfterUpdate) {
            upsertContactRolesAfterUpdate((list<Opportunity>) newlist, (list<Opportunity>) oldlist);
        }

        // we can't defer the dml.  too many of our other opp related triggers depend on the ocr's being saved.
        // disable TDTM so we don't waste resources running through opp triggers a second time while fixing Primary Contact lookup
        TDTM_TriggerHandler.disableTDTM = true;
        TDTM_TriggerHandler.processDML(dmlWrapper);
        TDTM_TriggerHandler.disableTDTM = false;

        return new DmlWrapper();
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
        if (!primaryContactIds.isEmpty()) {
            for (Contact thisContact : [select AccountId,Account.Id,Account.npe01__SYSTEM_AccountType__c from Contact
                    where Id IN :primaryContactIds]) {
                if (thisContact.AccountId != null) {
                    contactsAndOneToOneAccounts.put(thisContact.Id, thisContact.Account);
                }
            }
        }

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
                }            
            }
        }       
    }


    /*******************************************************************************************************
    * @description Detects changes in the opportunity Honoree Contact, and Notification Recipient Contact 
    * fields and updates Honoree Name and Notification Recipient Name fields.
    * @param listOpps List of opportunities from trigger.new
    * @param listOldOpps List of opportunities from trigger.old
    ********************************************************************************************************/
    private static void updateHonoreeNotificationFields(list<Opportunity> listOpps, list<Opportunity> listOldOpps) {
        Map<Id, Contact> mapConIdContact = new Map<Id, Contact>();
        List<String> listFields = new List<String>{FIELD_NAME_HONOREE_CONTACT, FIELD_NAME_NOTIFICATION_RECIPIENT_CONTACT};

        for (Integer i = 0; i < listOpps.size(); i++) {
            Opportunity newOpp = listOpps[i];
            Opportunity oldOpp = listOldOpps != null && !listOldOpps.IsEmpty() ? listOldOpps[i] : new Opportunity();
            for (String field : listFields) {
                if (newOpp.get(field) != oldOpp.get(field)) {
                    if (newOpp.get(field) != null) {
                        mapConIdContact.put((Id)newOpp.get(field), null);
                    }
                    if (oldOpp.get(field) != null) {
                        mapConIdContact.put((Id)oldOpp.get(field), null);
                    }
                }
            }
        }

        if (!mapConIdContact.isEmpty()) {
            mapConIdContact = new map<id,Contact>([SELECT Id, Name FROM Contact WHERE Id IN :mapConIdContact.keySet()]);
            for (Integer i = 0; i < listOpps.size(); i++) {
                Opportunity newOpp = listOpps[i];
                Opportunity oldOpp = listOldOpps != null && !listOldOpps.IsEmpty() ? listOldOpps[i] : new Opportunity();

                for (String field : listFields) {
                    if (newOpp.get(field) != oldOpp.get(field)) {
                        //get the text name field
                        String nameField = field.replace('Contact','Name');

                        String oldName;
                        if (oldOpp.get(field) != null) {
                            oldName = mapConIdContact.get((Id)oldOpp.get(field)).Name;
                        }

                        //only overwrite the name field if it's blank, or if we've switched contacts and it contained the old name
                        if (newOpp.get(nameField) == null || newOpp.get(nameField) == oldName) {
                            Id newContactId = (Id)newOpp.get(field);
                            if (newContactId != null) {
                                newOpp.put(nameField, mapConIdContact.get(newContactId).Name);
                            } else {
                                newOpp.put(nameField, '');
                            }
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
    private void upsertContactRolesAfterInsert(List<Opportunity> listOpps) {
        Map<Id, OpportunityContactRole> mapOppIdPrimaryOCR = new Map<Id, OpportunityContactRole>();

        // Primary Contact OCRs need to be inserted for opportunity naming code that runs after this
        List<OpportunityContactRole> listPrimaryOCRForInsert = new List<OpportunityContactRole>();

        // Holds the OCRs that will be evaluated to ensure compliance with the OCR hierarchy
        Map<Id, List<OpportunityContactRole>> transactionOCRs = new Map<Id, List<OpportunityContactRole>>();

        // Retrieve details/information about the Opportunity's associated Account
        Map<Id, Account> oppAccountDetails = populateAccountDetails(listOpps);

        // Retrieve the Primary Contacts for the Opportunities
        Map<Id, List<Id>> primaryContactsToOpportunities = populatePrimaryContactToOpportunities(listOpps, oppAccountDetails);

        // Retrieve the Account Ids for the Organizational Opportunities
        Map<Id, List<Id>> accountsToOpportunities = populateAccountToOpportunities(listOpps, oppAccountDetails);

        //Get existing primary contact roles for the trigger opps. 
        for (OpportunityContactRole ocr : [SELECT OpportunityId, ContactId, Role, IsPrimary FROM OpportunityContactRole WHERE IsPrimary = true and OpportunityId IN :listOpps]) {
            mapOppIdPrimaryOCR.put(ocr.OpportunityId, ocr);
        }

        for (Opportunity opp : listOpps) {
            //cloned opportunity is necessary in order to modify the Primary Contact lookup and update the record in the trigger set
            Opportunity clonedOpp = opp.clone(true,true,false,true);

            Boolean isIndividualAccount = (oppAccountDetails.containsKey(opp.AccountId))
                                            ? oppAccountDetails.get(opp.AccountId).npe01__SYSTEMIsIndividual__c
                                            : null;

            //process opportunities that already have a primary OCR
            if (mapOppIdPrimaryOCR.containsKey(opp.id)) {
                OpportunityContactRole ocr = mapOppIdPrimaryOCR.get(opp.id);

                //populate blank role
                if (String.isBlank(ocr.Role)) {
                    ocr.Role = getRole(FIELD_NAME_PRIMARY_CONTACT, isIndividualAccount);
                    dmlWrapper.objectsToUpdate.add(ocr);
                }

                //if our primary contact lookup doesn't match the primary OCR, we'll need to fix the opportunity
                if (opp.Primary_Contact__c != ocr.ContactId) {
                    //create new opportunity record to allow DML on current trigger set
                    clonedOpp.Primary_Contact__c = ocr.ContactId;
                    clonedOpp.npe01__Contact_Id_for_Role__c = ocr.ContactId;
                    dmlWrapper.objectsToUpdate.add(clonedOpp);
                }
            //we don't have a primary contact role for this record, create one
            } else {
                if (opp.Primary_Contact__c != null) {
                    listPrimaryOCRForInsert.add(getOCR(opp, FIELD_NAME_PRIMARY_CONTACT, isIndividualAccount));
                //if primary contact is null, still try using the contact id for role field
                //this is done for integrations that populate the npe01__Contact_Id_for_Role__c
                //after our beforeinsert trigger copied it to the primary contact field
                } else if (opp.npe01__Contact_Id_for_Role__c != null) {
                    try {
                        clonedOpp.Primary_Contact__c = opp.npe01__Contact_Id_for_Role__c;
                        listPrimaryOCRForInsert.add(getOCR(clonedOpp, FIELD_NAME_PRIMARY_CONTACT, isIndividualAccount));
                    } catch (Exception ex) {
                        opp.addError(Label.npe01.Opportunity_Contact_Role_Error_Bad_Contact_Id);
                    }
                }
            }
            //using cloned opp to check if these OCRs need to be managed, as it relies on the Primary Contact field being populated
            if (needsManageOCR(clonedOpp, new Opportunity(), FIELD_NAME_HONOREE_CONTACT)) {
                OpportunityContactRole honoreeOCR = getOCR(clonedOpp, FIELD_NAME_HONOREE_CONTACT);
                dmlWrapper.objectsToInsert.add(honoreeOCR);
                transactionOCRs = populateTransactionOCRs(transactionOCRs, honoreeOCR);
            }

            if (needsManageOCR(clonedOpp, new Opportunity(), FIELD_NAME_NOTIFICATION_RECIPIENT_CONTACT)) {
                OpportunityContactRole notificationOCR = getOCR(clonedOpp, FIELD_NAME_NOTIFICATION_RECIPIENT_CONTACT);
                dmlWrapper.objectsToInsert.add(notificationOCR);
                transactionOCRs = populateTransactionOCRs(transactionOCRs, notificationOCR);
            }
        }

        if (!listPrimaryOCRForInsert.isEmpty()) {
            insert listPrimaryOCRForInsert;
        }

        // Create Relationship Soft Credits accordingly
        if (!primaryContactsToOpportunities.isEmpty()) {
            List<sObject> relationshipOCRs
                = OPP_AutomatedSoftCreditsService.createRelationshipOCRs(primaryContactsToOpportunities, transactionOCRs);
            dmlWrapper.objectsToInsert.addAll(relationshipOCRs);
        }

        // Create Affiliation Soft Credits accordingly
        if (!accountsToOpportunities.isEmpty()) {
            List<sObject> affiliationOCRs
                = OPP_AutomatedSoftCreditsService.createAffiliationOCRs(accountsToOpportunities, transactionOCRs);
            dmlWrapper.objectsToInsert.addAll(affiliationOCRs);
        }
    }


    /*******************************************************************************************************
    * @description Runs opportunities through opportunity naming.
    * @param listOpps List of opportunities from trigger.new
    ********************************************************************************************************/
    private void updateOpportunityNames(list<Opportunity> listOpps) {
        //name opportunities
        Map<Id,Opportunity> mapOppNaming = new Map<Id,Opportunity>(OPP_OpportunityNaming.getOppNamesAfterInsert(listOpps));
        
        //update existing dmlWrapper objects with opp name to avoid errors updating the same opportunity twice
        for (sObject dmlObj : dmlWrapper.objectsToUpdate) {
            Id objId = (Id) dmlObj.get('id');
            if (mapOppNaming.containsKey(objId)) {
                dmlObj.put('Name', mapOppNaming.get(objId).Name);
                mapOppNaming.remove(objId);
            }
        }
        
        for (Opportunity opp : listOpps) {
            //add renamed opportunities that weren't updated as part of the contact roles fixing
            if (mapOppNaming.containsKey(opp.Id) && mapOppNaming.get(opp.id).Name != opp.Name) {
                dmlWrapper.objectsToUpdate.add((sObject) mapOppNaming.get(opp.id));
            }
        }
    }


    /*******************************************************************************************************
    * @description Detects changes in the opportunity Primary Contact, Honoree Contact, and Notification 
    * Recipient Contact fields and creates, updates or deletes the associated opportunity contact roles.
    * @param listOpps List of opportunities from trigger.new
    * @param listOldOpps List of opportunities from trigger.old
    ********************************************************************************************************/
    private void upsertContactRolesAfterUpdate(List<Opportunity> listOpps, List<Opportunity> listOldOpps) {
        Map<Id, Map<Id, OpportunityContactRole>> mapOppIdMapConIdOCR = new Map<Id, Map<Id, OpportunityContactRole>>();

        // Holds the OCRs that will be evaluated to ensure compliance with the OCR hierarchy
        Map<Id, List<OpportunityContactRole>> transactionOCRs = new Map<Id, List<OpportunityContactRole>>();

        // Holds the OCRs that need to be updated immediately to ensure compliance with the OCR hierarchy
        List<OpportunityContactRole> ocrsToUpdateImmediately = new List<OpportunityContactRole>();

        // Holds the OCRs that need to be deleted immediately to ensure compliance with the OCR hierarchy
        List<OpportunityContactRole> ocrsToDeleteImmediately  = new List<OpportunityContactRole>();

        // Holds the Opportunities that have had a Primary Contact or Account change
        List<Opportunity> primaryContactAccountChangeOpptys = new List<Opportunity>();

        // Retrieve details/information about the Opportunity's associated Account
        Map<Id, Account> oppAccountDetails = populateAccountDetails(listOpps);

        // Retrieve the Primary Contacts for the Opportunities
        Map<Id, List<Id>> primaryContactsToOpportunities = populatePrimaryContactToOpportunities(listOpps, oppAccountDetails);

        // Retrieve the Account Ids for the Organizational Opportunities
        Map<Id, List<Id>> accountsToOpportunities = populateAccountToOpportunities(listOpps, oppAccountDetails);

        //find changed opportunities and instantiate a map entry to hold OCRs
        for (integer i=0; i<listOpps.size(); i++) {
            if (listOpps[i].Primary_Contact__c != listOldOpps[i].Primary_Contact__c ||
                ((listOpps[i].AccountId != listOldOpps[i].AccountId)
                    && (!oppAccountDetails.get(listOpps[i].AccountId).npe01__SYSTEMIsIndividual__c || !oppAccountDetails.containsKey(listOldOpps[i].Id))) ||
                needsManageOCR(listOpps[i], listOldOpps[i], FIELD_NAME_HONOREE_CONTACT) ||
                needsManageOCR(listOpps[i], listOldOpps[i], FIELD_NAME_NOTIFICATION_RECIPIENT_CONTACT)) {

                mapOppIdMapConIdOCR.put(listOpps[i].Id, new Map<Id, OpportunityContactRole>());
            }

            if (listOpps[i].Primary_Contact__c != listOldOpps[i].Primary_Contact__c ||
                ((listOpps[i].AccountId != listOldOpps[i].AccountId)
                    && (!oppAccountDetails.get(listOpps[i].AccountId).npe01__SYSTEMIsIndividual__c || !oppAccountDetails.containsKey(listOldOpps[i].Id)))) {

                primaryContactAccountChangeOpptys.add(listOpps[i]);
            }
        }

        //query for OCRs, hand off to processing methods
        if (!mapOppIdMapConIdOCR.isEmpty()) {
            for (OpportunityContactRole ocr : [SELECT OpportunityId, ContactId, isPrimary, Role FROM OpportunityContactRole 
                                                    WHERE OpportunityId IN :mapOppIdMapConIdOCR.keyset()]) {
                mapOppIdMapConIdOCR.get(ocr.OpportunityId).put(ocr.ContactId, ocr);
            }

            for (integer i=0; i<listOpps.size(); i++) {
                Opportunity newOpp = listOpps[i];
                Opportunity oldOpp = listOldOpps[i];

                Boolean isIndividualAccount = (oppAccountDetails.containsKey(newOpp.AccountId))
                                            ? oppAccountDetails.get(newOpp.AccountId).npe01__SYSTEMIsIndividual__c
                                            : null;

                //first, manage primary contact role if the primary contact has changed
                if (needsManageOCR(newOpp, oldOpp, FIELD_NAME_PRIMARY_CONTACT)) {
                    managePrimaryOCR(newOpp, oldOpp, mapOppIdMapConIdOCR.get(newOpp.id), isIndividualAccount, transactionOCRs, ocrsToUpdateImmediately, ocrsToDeleteImmediately);
                }
                //then manage honoree, if it has changed and it's not the same as the primary contact
                if (needsManageOCR(newOpp, oldOpp, FIELD_NAME_HONOREE_CONTACT)) {
                    manageOtherOCR(newOpp, oldOpp, mapOppIdMapConIdOCR.get(newOpp.id), FIELD_NAME_HONOREE_CONTACT, transactionOCRs, ocrsToDeleteImmediately);
                }
                //finally, manage the notification, if it has changed and it's not the same as either contact already dealt with
                if (needsManageOCR(newOpp, oldOpp, FIELD_NAME_NOTIFICATION_RECIPIENT_CONTACT)) {
                    manageOtherOCR(newOpp, oldOpp, mapOppIdMapConIdOCR.get(newOpp.id), FIELD_NAME_NOTIFICATION_RECIPIENT_CONTACT, transactionOCRs, ocrsToDeleteImmediately);
                }
            }

            update ocrsToUpdateImmediately;

            syncHonoreeNotificationContacts(mapOppIdMapConIdOCR, primaryContactAccountChangeOpptys, transactionOCRs);

            // Delete OCRs that are associated with Opportunities whose Primary Contact or Account has changed
            clearOCRs(mapOppIdMapConIdOCR, primaryContactAccountChangeOpptys, ocrsToDeleteImmediately);

            // Create Relationship Soft Credits accordingly
            if (!primaryContactsToOpportunities.isEmpty()) {
                List<sObject> relationshipOCRs
                    = OPP_AutomatedSoftCreditsService.createRelationshipOCRs(primaryContactsToOpportunities, transactionOCRs);
                dmlWrapper.objectsToInsert.addAll(relationshipOCRs);
            }

            // Create Affiliation Soft Credits accordingly
            if (!accountsToOpportunities.isEmpty()) {
                List<sObject> affiliationOCRs
                    = OPP_AutomatedSoftCreditsService.createAffiliationOCRs(accountsToOpportunities, transactionOCRs);
                dmlWrapper.objectsToInsert.addAll(affiliationOCRs);
            }
        }
    }


    /*******************************************************************************************************
    * @description Manages create and update of the primary Opportunity Contact Role.
    * @param opp The current opportunity from trigger.new
    * @param oldOpp The old opportunity from trigger.old
    * @param mapConIdOCR A map of contact id to Opportunity Contact Role records for this opportunity.
    * @param isIndividualAccount The Account's Type: Individual or Organization.
    * @param transactionOCRs Contains the OCRs that will be evaluated to ensure compliance with the OCR hierarchy.
    * @param ocrsToUpdateImmediately Holds Opportunity Contact Roles that need to be updated immediately.
    * @param ocrsToDeleteImmediately Holds Opportunity Contact Roles that need to be deleted immediately.
    * @return void This method adds records to dmlWrapper and returns nothing.
    ********************************************************************************************************/
    private void managePrimaryOCR(Opportunity opp, Opportunity oldOpp, Map<id,OpportunityContactRole> mapConIdOCR, Boolean isIndividualAccount,
                                  Map<Id, List<OpportunityContactRole>> transactionOCRs, List<OpportunityContactRole> ocrsToUpdateImmediately,
                                  List<OpportunityContactRole> ocrsToDeleteImmediately) {
        Id idNewPrimaryCon = opp.Primary_Contact__c;
        Id idOldCon = oldOpp.Primary_Contact__c;

        //if we have a primary OCR, separate it from the list
        OpportunityContactRole primaryOCR;
        if (mapConIdOCR!=null) for (OpportunityContactRole ocr : mapConIdOCR.values()) {
            if (ocr.isPrimary) {
                primaryOCR = ocr;
                mapConIdOCR.remove(ocr.ContactId);
            }
        }

        //primary contact is blanked out 
        if (idNewPrimaryCon == null) {
            //if we have an existing primary OCR, delete it
            if (primaryOCR != null) {
                ocrsToDeleteImmediately.add(primaryOCR);
            }

        //primary contact went from blank to a new contact
        } else if (idNewPrimaryCon != null) {
            //create or update the existing primary OCR
            if (primaryOCR == null) {
                OpportunityContactRole newPrimaryOCR = getOCR(opp, FIELD_NAME_PRIMARY_CONTACT, isIndividualAccount);
                dmlWrapper.objectsToInsert.add(newPrimaryOCR);
                transactionOCRs = populateTransactionOCRs(transactionOCRs, newPrimaryOCR);
            } else {
                if (primaryOCR.ContactId != idNewPrimaryCon || String.isBlank(primaryOCR.Role)) {
                    primaryOCR.ContactId = idNewPrimaryCon;
                    if (String.isBlank(primaryOCR.Role)) {
                        primaryOCR.Role = getRole(FIELD_NAME_PRIMARY_CONTACT, isIndividualAccount);
                    }

                    // In order to ensure the Relationships/Affiliations are set accordingly,
                    // The Primary OCR needs to be updated immediately.
                    ocrsToUpdateImmediately.add(primaryOCR);
                }
            }
        }
    }


    /*******************************************************************************************************
    * @description Manages create and update of the Opportunity Contact Roles for the Honoree and Notification
    * Recipient contact lookup fields.
    * @param opp The current opportunity from trigger.new
    * @param oldOpp The old opportunity from trigger.old
    * @param mapConIdOCR A map of contact id to Opportunity Contact Role records for this opportunity.
    * @param fieldName The API name of the field to verify
    * @param transactionOCRs Contains the OCRs that will be evaluated to ensure compliance with the OCR hierarchy.
    * @param ocrsToDeleteImmediately Holds Opportunity Contact Roles that need to be deleted immediately.
    * @return void This method adds records to dmlWrapper and returns nothing.
    ********************************************************************************************************/
    private void manageOtherOCR(Opportunity opp, Opportunity oldOpp, Map<Id, OpportunityContactRole> mapConIdOCR, String fieldName,
                                Map<Id, List<OpportunityContactRole>> transactionOCRs, List<OpportunityContactRole> ocrsToDeleteImmediately) {
        Id idNewCon = (Id)opp.get(fieldName);
        Id idOldCon = (Id)oldOpp.get(fieldName);
        OpportunityContactRole ocrNewCon = mapConIdOCR.get(idNewCon);
        OpportunityContactRole ocrOldCon = mapConIdOCR.get(idOldCon);

        if (idNewCon == null) {
            //if the lookup field was blanked out, and an OCR matches the previous contact with the correct role, delete it
            if (idOldCon!=null && ocrOldCon!=null) {
                if (ocrOldCon.Role == getRole(fieldName)) {
                    ocrsToDeleteImmediately.add(ocrOldCon);
                }
            }
        //the lookup has a new contact
        } else if (idNewCon != null) {
            //net new contact, i.e. no old contact; create a contact role if we don't have one for this contact yet
            if (idOldCon == null && ocrNewCon == null) {
                dmlWrapper.objectsToInsert.add(getOCR(opp,fieldName));
            }

            // If the New Contact has an OCR, update it accordingly
            if (idOldCon == null && ocrNewCon != null) {
                ocrNewCon.Role = getRole(fieldName);
                dmlWrapper.objectsToUpdate.add(ocrNewCon);
            }

            //contact lookup changed from one contact to another
            if (idOldCon != null) {
                //an OCR for the old contact exists, and has the role for this field
                if (ocrOldCon != null && ocrOldCon.Role == getRole(fieldName)) {
                    //our new contact doesn't yet have an OCR, so update the old one to the new contact
                    if (ocrNewCon == null || (ocrNewCon != null && ocrNewCon.Role != getRole(fieldName))) {
                        ocrOldCon.ContactId = idNewCon;
                        dmlWrapper.objectsToUpdate.add(ocrOldCon);
                        transactionOCRs = populateTransactionOCRs(transactionOCRs, ocrOldCon);

                        if (ocrNewCon != null) {
                           dmlWrapper.objectsToDelete.add(ocrNewCon);
                        }

                    //our new contact already has an OCR, delete the old one
                    } else {
                       ocrsToDeleteImmediately.add(ocrOldCon);
                    }
                //new contact doesn't have an OCR yet, create one with the appropriate role
                } else if (ocrNewCon == null) {
                    dmlWrapper.objectsToInsert.add(getOCR(opp, fieldName));
                } else if (ocrNewCon.Role != getRole(fieldName)) {
                    ocrNewCon.Role = getRole(fieldName);
                    dmlWrapper.objectsToUpdate.add(ocrNewCon);
                }
            }
        }

        // When a Contact is removed from the Honoree field and added to the Notification field and vice-versa
        // in the same transaction do not immediately delete the OCR.
        if (ocrsToDeleteImmediately.contains(ocrNewCon)) {
            Integer ocrIndex = ocrsToDeleteImmediately.indexOf(ocrNewCon);
            ocrsToDeleteImmediately.remove(ocrIndex);
        }
    }


    /*******************************************************************************************************
    * @description For a given opportunity contact lookup field, returns the role value associated with that
    * field as defined in settings.
    * @param fieldName The name of the Opportunity field.
    * @return String The role value associated with the field.
    ********************************************************************************************************/
    private String getRole(String fieldName) {
        return getRole(fieldName, null);
    }


    /*******************************************************************************************************
    * @description For a given opportunity contact lookup field, returns the role value associated with that
    * field as defined in settings.
    * @param fieldName The name of the Opportunity field.
    * @param isIndividualAccount The classification (e.g., Individual) of an Opportunity's associated Account.
    * @return String The role value associated with the field.
    ********************************************************************************************************/
    private String getRole(String fieldName, Boolean isIndividualAccount) {
        String result;

        if (fieldName.equals(FIELD_NAME_PRIMARY_CONTACT)) {
            if (OPP_AutomatedSoftCreditsService.isOrganizationalAccount(isIndividualAccount)) {
                result = UTIL_CustomSettingsFacade.getContactsSettings().Contact_Role_for_Organizational_Opps__c;
            } else {
                result = UTIL_CustomSettingsFacade.getContactsSettings().npe01__Opportunity_Contact_Role_Default_role__c;
            }
        } else if (fieldName.equals(FIELD_NAME_HONOREE_CONTACT)) {
            result = UTIL_CustomSettingsFacade.getContactsSettings().Honoree_Opportunity_Contact_Role__c;
        } else if (fieldName.equals(FIELD_NAME_NOTIFICATION_RECIPIENT_CONTACT)) {
            result = UTIL_CustomSettingsFacade.getContactsSettings().Notification_Recipient_Opp_Contact_Role__c;
        }

        return result;
    }


    /*******************************************************************************************************
    * @description Returns a new OpportunityContactRole record, based on an opportunity and the API name of 
    * the contact lookup field.
    * @param opp The opportunity for which to create an OCR.
    * @param fieldName The name of the opportunity field.
    * @return OpportunityContactRole The newly created OCR.
    ********************************************************************************************************/
    private OpportunityContactRole getOCR(Opportunity opp, String fieldName) {
        return getOCR(opp, fieldName, null);
    }


    /*******************************************************************************************************
    * @description Returns a new OpportunityContactRole record, based on an Opportunity, the API name of
    * the Contact Lookup field, and the associated Account's _SYSTEM: IsIndividual field.
    * @param opp The opportunity for which to create an OCR.
    * @param fieldName The name of the opportunity field.
    * @param isIndividualAccount The associated Account's _SYSTEM: IsIndividual field value.
    * @return OpportunityContactRole The newly created OCR.
    ********************************************************************************************************/
    private OpportunityContactRole getOCR(Opportunity opp, String fieldName, Boolean isIndividualAccount) {
        OpportunityContactRole ocr = new OpportunityContactRole();
        ocr.OpportunityId = opp.id;
        ocr.ContactId = (Id)opp.get(fieldname);
        ocr.Role = getRole(fieldName, isIndividualAccount);
        if (fieldName.equals(FIELD_NAME_PRIMARY_CONTACT)) {
            ocr.isPrimary = true;
        }
        return ocr;
    }


    /*******************************************************************************************************
    * @description Verifies if an opportunity contact lookup needs automatic management of the Opportunity
    * Contact Role associated with that field. For automatic management, the lookup field's associated role custom
    * setting needs a value, the value in the lookup field needs to be new or have changed, and the contact
    * needs to be different from a contact that's already managed.
    * @param opp The current opportunity from trigger.new
    * @param oldOpp The old opportunity from trigger.old
    * @param fieldName The API name of the field to verify
    * @return boolean Whether this opportunity and field needs OCR handling.
    ********************************************************************************************************/
    private boolean needsManageOCR(Opportunity opp, Opportunity oldOpp, String fieldName) {
        //no role for this field
        if (String.isBlank(getRole(fieldName))) {
            return false;
        }

        //field value hasn't changed
        else if (opp.get(fieldName) == oldOpp.get(fieldName)) {
            return false;
        }

        //the honoree contact is the same as the primary contact, thus is already managed
        else if (fieldName == FIELD_NAME_HONOREE_CONTACT && opp.Honoree_Contact__c == opp.Primary_Contact__c) {
            return false;
        }

        //the notification recipient contact is the same as the primary contact, thus the OCR is already managed
        else if (fieldName == FIELD_NAME_NOTIFICATION_RECIPIENT_CONTACT && opp.Notification_Recipient_Contact__c == opp.Primary_Contact__c) {
            return false;
        }

        //the notification recipient contact is the same as the honoree contact, thus the OCR is already managed
        else if (fieldName == FIELD_NAME_NOTIFICATION_RECIPIENT_CONTACT && opp.Notification_Recipient_Contact__c == opp.Honoree_Contact__c
                 && (opp.Notification_Recipient_Contact__c != null && opp.Honoree_Contact__c != null)) {
            return false;
        }

        return true;
    }


    /*********************************************************************************************************
    * @description Retrieves details/information about the Opportunity's associated Account.
    * @param currentOpportunities The Opportunities in the 'new' trigger context variable.
    * @return Map<Id, Account> containing the AccountId to Account.
    **********************************************************************************************************/
    @testVisible
    private Map<Id, Account> populateAccountDetails (List<Opportunity> currentOpportunities) {
        Map<Id, Account> accountDetails = null;
        List<Id> accountIds = new List<Id>();

        if (currentOpportunities.isEmpty()) {
            return accountDetails = new Map<Id, Account>();
        }

        for (Opportunity eachOppty : currentOpportunities) {
            if (eachOppty.AccountId != null) {
                accountIds.add(eachOppty.AccountId);
            }
        }

        accountDetails = new Map<Id, Account>([SELECT Id, Name, npe01__SYSTEMIsIndividual__c
                                                FROM Account
                                                WHERE Id IN :accountIds]);

        return accountDetails;
    }


    /*********************************************************************************************************
    * @description Populates a Map of Primary Contact to Opportunity Ids.
    * @param currentOpportunities The Opportunities in the 'new' trigger context variable.
    * @param oppAccountDetails A Map containing the Opportunities' related Accounts.
    * @return Map<Id, List<Id>> contains associated Primary Contacts and Opportunity Ids.
    **********************************************************************************************************/
    @testVisible
    private Map<Id, List<Id>> populatePrimaryContactToOpportunities(List<Opportunity> currentOpportunities, Map<Id, Account> oppAccountDetails) {
        Map<Id, List<Id>> primaryContactToOpportunities = new Map<Id, List<Id>>();

        if (currentOpportunities.isEmpty()) {
            return primaryContactToOpportunities;
        }

        for (Opportunity eachOppty : currentOpportunities) {
            if (eachOppty.Primary_Contact__c != null
                && oppAccountDetails.get(eachOppty.AccountId) != null
                && !OPP_AutomatedSoftCreditsService.isOrganizationalAccount(oppAccountDetails.get(eachOppty.AccountId).npe01__SYSTEMIsIndividual__c)) {
                if (primaryContactToOpportunities.containsKey(eachOppty.Primary_Contact__c)) {
                    List<Id> opportunities = primaryContactToOpportunities.get(eachOppty.Primary_Contact__c);
                    opportunities.add(eachOppty.Id);
                } else {
                    primaryContactToOpportunities.put(eachOppty.Primary_Contact__c, new List<Id>{ eachOppty.Id });
                }
            }
        }

        return primaryContactToOpportunities;
    }


    /*********************************************************************************************************
    * @description Populates a Map of Account Id to Opportunity Ids.
    * @param currentOpportunities The Opportunities in the 'new' trigger context variable.
    * @param oppAccountDetails A Map containing the Opportunities' related Accounts.
    * @return Map<Id, Id> contains associated Primary Contacts and Opportunity Ids.
    **********************************************************************************************************/
    @testVisible
    private Map<Id, List<Id>> populateAccountToOpportunities(List<Opportunity> currentOpportunities, Map<Id, Account> oppAccountDetails) {
        Map<Id, List<Id>> accountToOpportunities = new Map<Id, List<Id>>();

        if (currentOpportunities.isEmpty()) {
            return accountToOpportunities;
        }

        for (Opportunity eachOppty : currentOpportunities) {
            if (eachOppty.AccountId != null
                && OPP_AutomatedSoftCreditsService.isOrganizationalAccount(oppAccountDetails.get(eachOppty.AccountId).npe01__SYSTEMIsIndividual__c)) {
                if (accountToOpportunities.containsKey(eachOppty.AccountId)) {
                    List<Id> opportunities = accountToOpportunities.get(eachOppty.AccountId);
                    opportunities.add(eachOppty.Id);
                } else {
                    accountToOpportunities.put(eachOppty.AccountId, new List<Id>{ eachOppty.Id });
                }
            }
        }

        return accountToOpportunities;
    }


    /*********************************************************************************************************
    * @description Populates the transactionOCRs Map with OpportunityContactRoles being created in the
    *               current transaction.
    * @param transactionOCRs Map of Opportunity Id to OpportunityContactRoles.
    * @param currentOCR The OpportunityContactRole being created in the current transaction.
    * @return Map<Id, List<OpportunityContactRole>> containing the Opportunity Id to OCRs.
    **********************************************************************************************************/
    @testVisible
    private Map<Id, List<OpportunityContactRole>> populateTransactionOCRs(Map<Id, List<OpportunityContactRole>> transactionOCRs, OpportunityContactRole currentOCR) {
        if (transactionOCRs.containsKey(currentOCR.OpportunityId)) {
            List<OpportunityContactRole> ocrs = transactionOCRs.get(currentOCR.OpportunityId);
            ocrs.add(currentOCR);
        } else {
            transactionOCRs.put(currentOCR.OpportunityId, new List<OpportunityContactRole>{ currentOCR });
        }

        return transactionOCRs;
    }


    /*********************************************************************************************************
    * @description Clears the OpportunityContactRole records from the Opportunity whose Primary Contact or
    *               Account changed.
    * @param opportunityToContactToOCR Map of Opportunity to a Map of Contact to OpportunityContactRoles.
    * @param primaryContactAccountChangeOpptys List of OpportunityIds whose Primary Contact or Account changed.
    * @param ocrsToDeleteImmediately List of OpportunityContactRoles that require immediate deletion.
    * @return void
    **********************************************************************************************************/
    @testVisible
    private void clearOCRs(Map<Id, Map<Id, OpportunityContactRole>> opportunityToContactToOCR, List<Opportunity> primaryContactAccountChangeOpptys,
                                  List<OpportunityContactRole> ocrsToDeleteImmediately) {
        List<OpportunityContactRole> ocrsToDelete = new List<OpportunityContactRole>();

        if (!ocrsToDeleteImmediately.isEmpty()) {
            ocrsToDelete.addAll(ocrsToDeleteImmediately);
        }

        npe01__Contacts_And_Orgs_Settings__c orgContactSettings = UTIL_CustomSettingsFacade.getOrgContactsSettings();
        String honoreeRole = orgContactSettings.Honoree_Opportunity_Contact_Role__c;
        String notificationRole = orgContactSettings.Notification_Recipient_Opp_Contact_Role__c;

        for (Opportunity eachOppty : primaryContactAccountChangeOpptys) {
            for (OpportunityContactRole eachOldOCR : opportunityToContactToOCR.get(eachOppty.Id).values()) {
                 if (!eachOldOCR.isPrimary
                    && (honoreeRole == null || !honoreeRole.equals(eachOldOCR.Role) || (honoreeRole.equals(eachOldOCR.Role) && (eachOppty.Primary_Contact__c == eachOldOCR.ContactId || eachOppty.Honoree_Contact__c != eachOldOCR.ContactId)))
                    && (notificationRole == null || !notificationRole.equals(eachOldOCR.Role) || (notificationRole.equals(eachOldOCR.Role) && (eachOppty.Primary_Contact__c == eachOldOCR.ContactId || eachOppty.Notification_Recipient_Contact__c != eachOldOCR.ContactId)))) {
                    if (!ocrsToDelete.contains(eachOldOCR)) {
                        ocrsToDelete.add(eachOldOCR);
                    }
                }
            }
        }

        if (!ocrsToDelete.isEmpty()) {
            delete ocrsToDelete;
        }
    }


    /*********************************************************************************************************
    * @description Checks if an Honoree or Notification Contact is on the Opportunity and missing an
    *               OpportunityContactRole record, then creates it accordingly.
    * @param opportunityToContactToOCR Map of Opportunity to a Map of Contact to OpportunityContactRoles.
    * @param primaryContactAccountChangeOpptys List of OpportunityIds whose Primary Contact or Account changed.
    * @param transactionOCRs Contains the OCRs that will be evaluated to ensure compliance with the OCR hierarchy.
    * @return void
    **********************************************************************************************************/
    @testVisible
    private void syncHonoreeNotificationContacts(Map<Id, Map<Id, OpportunityContactRole>> opportunityToContactToOCR, List<Opportunity> primaryContactAccountChangeOpptys,
                                                     Map<Id, List<OpportunityContactRole>> transactionOCRs) {

        for (Opportunity eachOppty : primaryContactAccountChangeOpptys) {
            Set<Id> ocrs = new Set<Id>();
            Id honoreeContactId = eachOppty.Honoree_Contact__c;
            Id notificationContactId = eachOppty.Notification_Recipient_Contact__c;

            for (OpportunityContactRole eachOldOCR : opportunityToContactToOCR.get(eachOppty.Id).values()) {
                ocrs.add(eachOldOCR.ContactId);
            }

            if (honoreeContactId != null && !ocrs.contains(honoreeContactId)) {
                OpportunityContactRole honoreeOCR = getOCR(eachOppty, FIELD_NAME_HONOREE_CONTACT);
                dmlWrapper.objectsToInsert.add(honoreeOCR);
                transactionOCRs = populateTransactionOCRs(transactionOCRs, honoreeOCR);
            }

            if (notificationContactId != null && !ocrs.contains(notificationContactId)) {
                OpportunityContactRole notificationOCR = getOCR(eachOppty, FIELD_NAME_NOTIFICATION_RECIPIENT_CONTACT);
                dmlWrapper.objectsToInsert.add(notificationOCR);
                transactionOCRs = populateTransactionOCRs(transactionOCRs, notificationOCR);
            }
        }
    }


}