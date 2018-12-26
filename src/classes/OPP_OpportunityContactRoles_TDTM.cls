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

    @testVisible private static final String FIELD_NAME_OPPORTUNITY = 'Opportunity__c';
    @testVisible private static final String FIELD_NAME_PRIMARY_CONTACT = 'Primary_Contact__c';
    @testVisible private static final String FIELD_NAME_HONOREE_CONTACT = 'Honoree_Contact__c';
    @testVisible private static final String FIELD_NAME_NOTIFICATION_RECIPIENT_CONTACT = 'Notification_Recipient_Contact__c';

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
            setOpportunityAccountField((List<Opportunity>) newlist);

            updateHonoreeNotificationFields(newlist, null, Opportunity.SobjectType);

        } else if (triggerAction == TDTM_Runnable.Action.BeforeUpdate) {
            //If the Setting is Multiple Tribute Only, we need to prevent updating existing Tribute Fields on Opportunity
            if (TBU_MultipleTributesSettingsFacade.isMultipleTributesLimited()) {
                preventUpdateTributeInfoOnOpportunity((List<Opportunity>) newlist, (List<Opportunity>) oldlist, false);
            }

            //If the Setting allowsa Mixed (Honoree info on Opportunity or on Tributes) mode, 
            // then we only prevent updating Tribute info on the Opportiunity when there is a Tribute record attached to it
            if (TBU_MultipleTributesSettingsFacade.isMultipleTributesFlexible()) {
                preventUpdateTributeInfoOnOpportunity((List<Opportunity>) newlist, (List<Opportunity>) oldlist, true);
            }

            updateHonoreeNotificationFields(newlist, oldlist, Opportunity.SobjectType);

        } else if (triggerAction == TDTM_Runnable.Action.AfterInsert) {
            upsertContactRolesAfterInsert((List<Opportunity>) newlist, null, false);
            try {
                updateOpportunityNames((List<Opportunity>) newList);
            } catch (Exception ex) {
                ERR_Handler.processError(ex, ERR_Handler_API.Context.OPP);
            }

            //If the Setting is Multiple Tribute Only, system should Auto create Tribute record
            if (TBU_MultipleTributesSettingsFacade.isMultipleTributesLimited()) {
                createTributeFromOpportunity((List<Opportunity>) newlist);
            }

        } else if (triggerAction == TDTM_Runnable.Action.AfterUpdate) {
            upsertContactRolesAfterUpdate((List<Opportunity>) newlist, (list<Opportunity>) oldlist, null, null, false);
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

        Map<Id,Account> primaryAccounts = new Map<Id,Account>([SELECT   Id,
                                                                        npe01__One2OneContact__c,
                                                                        npe01__SYSTEM_AccountType__c
                                                               FROM Account 
                                                               WHERE    Id IN :oppAccounts]);
        if (!primaryContactIds.isEmpty()) {
            for (Contact thisContact : [SELECT  AccountId,
                                                Account.Id,
                                                Account.npe01__SYSTEM_AccountType__c 
                                        FROM Contact
                                        WHERE   Id IN :primaryContactIds]) {
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
    * @param listSObjs List of Sobjects from trigger.new
    * @param listOldSObjs List of Sobjects from trigger.old
    * @param objType The Type of the object
    ********************************************************************************************************/
    public static void updateHonoreeNotificationFields(List<Sobject> listSObjs, List<Sobject> listOldSObjs, Schema.SObjectType sObjType) {
        Map<Id, Contact> mapConIdContact = new Map<Id, Contact>();
        
        List<String> listFields = null;

        if (sObjType == Schema.Opportunity.getSObjectType()) { // Opportunity Type
            listFields = new List<String>{FIELD_NAME_HONOREE_CONTACT, FIELD_NAME_NOTIFICATION_RECIPIENT_CONTACT};
        } else {
            listFields = new List<String>{ FIELD_NAME_HONOREE_CONTACT };
        }

        for (Integer i=0; i<listSObjs.size(); i++) {
            Sobject newSObj = listSObjs[i];
            Sobject oldSObj = listOldSObjs!=null && !listOldSObjs.IsEmpty() ? listOldSObjs[i] :  sObjType.newSObject();
            for (String field : listFields) {
                if (newSObj.get(field) != oldSObj.get(field)) {
                    if (newSObj.get(field)!=null)
                        mapConIdContact.put((Id)newSObj.get(field), null);
                    if (oldSObj.get(field)!=null)
                        mapConIdContact.put((Id)oldSObj.get(field), null);
                }
            }
        }

        if (!mapConIdContact.isEmpty()) {
            mapConIdContact = new Map<Id, Contact>([SELECT  Id,
                                                            Name
                                                    FROM Contact
                                                    WHERE   Id IN :mapConIdContact.keySet()]);
            for (Integer i=0; i<listSObjs.size(); i++) {
                Sobject newSObj = listSObjs[i];
                Sobject oldSObj = listOldSObjs!=null && !listOldSObjs.IsEmpty() ? listOldSObjs[i] :  sObjType.newSObject();

                for (String field : listFields) {
                    if (newSObj.get(field) != oldSObj.get(field)) {
                        //get the text name field
                        String nameField = field.replace('Contact', 'Name');

                        String oldName;
                        if (oldSObj.get(field)!=null) {
                            oldName = mapConIdContact.get((Id)oldSObj.get(field)).Name;
                        }

                        //only overwrite the name field if it's blank, or if we've switched contacts and it contained the old name
                        if (newSObj.get(nameField) == null || newSObj.get(nameField) == oldName) {
                            Id newContactId = (Id)newSObj.get(field);

                            if (newContactId != null) {
                                newSObj.put(nameField, mapConIdContact.get(newContactId).Name);
                            } else {
                                newSObj.put(nameField, '');
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
    * @param listOpps List of opportunities meeting trigger criteria
    * @param tributesByOpp Map of List of Tributes, Indexed By Opportunity Id
    * @param processDML Boolean indiciator of whether DML should be processed
    ********************************************************************************************************/
    public void upsertContactRolesAfterInsert(List<Opportunity> listOpps, Map<Id, List<Tribute__c>> tributesByOpp,
            Boolean processDML) {
        Map<Id, OpportunityContactRole> mapOppIdPrimaryOCR = new Map<Id, OpportunityContactRole>();

        // Holds the Opportunity to Map of Contact to OCRs
        Map<Id, Map<Id, OpportunityContactRole>> mapOppIdMapConIdOCR = new Map<Id, Map<Id, OpportunityContactRole>>();

        // Primary Contact OCRs need to be inserted for opportunity naming code that runs after this
        List<OpportunityContactRole> listPrimaryOCRForInsert = new List<OpportunityContactRole>();

        // Holds the OCRs that will be evaluated to ensure compliance with the OCR hierarchy
        Map<Id, List<OpportunityContactRole>> transactionOCRs = new Map<Id, List<OpportunityContactRole>>();

        // Holds the OCRs that need to be deleted immediately to ensure compliance with the OCR hierarchy
        List<OpportunityContactRole> ocrsToDeleteImmediately  = new List<OpportunityContactRole>();

        // Retrieve details/information about the Opportunity's associated Account
        Map<Id, Account> oppAccountDetails = populateAccountDetails(listOpps);

        // Retrieve the Primary Contacts for the Opportunities
        Map<Id, List<Id>> primaryContactsToOpportunities = populatePrimaryContactToOpportunities(listOpps, oppAccountDetails);

        // Retrieve the Account Ids for the Organizational Opportunities
        Map<Id, List<Id>> accountsToOpportunities = populateAccountToOpportunities(listOpps, oppAccountDetails);

        Set<String> uniqueOCRKeys = new Set<String>();

        populateOCRMaps(listOpps, mapOppIdPrimaryOCR, mapOppIdMapConIdOCR, uniqueOCRKeys);

        for (Opportunity opp : listOpps) {
            //cloned opportunity is necessary in order to modify the Primary Contact lookup and update the record in the trigger set
            Opportunity clonedOpp = opp.clone(true, true, false, true);

            List<Tribute__c> tributes = (tributesByOpp != null) ? tributesByOpp.get(opp.Id) : null;

            Set<Id> honoreeContactIdSet = buildHonoreeContactIdSet((Id) opp.Honoree_Contact__c, tributes);
            Map<Id, OpportunityContactRole> contactIdToOCRs = mapOppIdMapConIdOCR.get(clonedOpp.Id);

            processPrimaryOCR(opp, clonedOpp, mapOppIdPrimaryOCR, oppAccountDetails, listPrimaryOCRForInsert);

            //Handles honorees here
            if(tributesByOpp != null && (!tributesByOpp.isEmpty())) {
                // Multiple Tributes
                processHonoreeOCRs(clonedOpp, tributes, uniqueOCRKeys, contactIdToOCRs, transactionOCRs, ocrsToDeleteImmediately);
            } else {
                // Opportunity Only
                processHonoreeOCR(clonedOpp, uniqueOCRKeys, contactIdToOCRs, transactionOCRs, ocrsToDeleteImmediately);
            }

            processNotificationOCR(clonedOpp, honoreeContactIdSet, uniqueOCRKeys, contactIdToOCRs, transactionOCRs, ocrsToDeleteImmediately);
        }

        if (!listPrimaryOCRForInsert.isEmpty()) {
            insert listPrimaryOCRForInsert;
        }

        if (!ocrsToDeleteImmediately.isEmpty()) {
            delete ocrsToDeleteImmediately;
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
        
        //For multiple tribute, we need to process the DML here since Tribute trigger will not call run method
        if(processDML) {
            TDTM_TriggerHandler.disableTDTM = true;
            TDTM_TriggerHandler.processDML(dmlWrapper);
            TDTM_TriggerHandler.disableTDTM = false;
        }
    }

    /*******************************************************************************************************
    * @description Populates the Opportunity Id to Primary Opportunity Contact Role Map, and the 
    * Unique Opportunity Contact Role Keyset
    * @param opps List of Opportunities to be processed
    * @param mapOppIdPrimaryOCR Map to store Opportunity ID to Primary Contact Role
    * @param uniqueOCRKeys Set of Strings containing a unique key for each Opportunity Contact Role.  This will be used to prevent duplicate OCRs when processing records
    ********************************************************************************************************/
    @testVisible private static void populateOCRMaps(List<Opportunity> opps, Map<Id, OpportunityContactRole> mapOppIdPrimaryOCR, Map<Id, Map<Id, OpportunityContactRole>> mapOppIdMapConIdOCR, Set<String> uniqueOCRKeys) {
        //Get existing primary contact roles for the trigger opps. 
        for (OpportunityContactRole ocr : [SELECT   OpportunityId,
                                                    ContactId,
                                                    Role, 
                                                    IsPrimary
                                           FROM OpportunityContactRole
                                           WHERE OpportunityId IN :opps]) {
            if (ocr.IsPrimary) { // add to map if primary
                mapOppIdPrimaryOCR.put(ocr.OpportunityId, ocr);
            }
            
            Map<Id, OpportunityContactRole> contactIdtoOCRs = (mapOppIdMapConIDOCR.containsKey(ocr.OpportunityId)) ? mapOppIdMapConIdOCR.get(ocr.OpportunityId) : new Map<Id, OpportunityContactRole>();
            
            contactIdtoOCRs.put(ocr.ContactId, ocr);
            mapOppIdMapConIdOCR.put(ocr.OpportunityId, contactIdtoOCRs);
            uniqueOCRKeys.add(calcUniqueOCRKey(ocr));
        }
    }

    /*******************************************************************************************************
    * @description Confirms Primary OCR and Primary Contact match.  If they do not, it fixes the Primary Contact on the Opportunity.  if the Primary
    * OCR does not exist, it creates it
    * @param opp Opportunity to be processed
    * @param clonedOpp Opportunity that can be updated if necessary
    * @param mapOppIdPrimaryOCR Map to store Opportunity ID to Primary Contact Role
    * @param listPrimaryOCRForInsert List of Primary OCRs that need to be inserted
    ********************************************************************************************************/
    private void processPrimaryOCR(Opportunity opp, Opportunity clonedOpp, Map<Id, OpportunityContactRole> mapOppIdPrimaryOCR, Map<Id, Account> oppAccountDetails, List<OpportunityContactRole> listPrimaryOCRForInsert) {
        Boolean isIndividualAccount = isIndividualAccount(oppAccountDetails, opp.AccountId);

        //process opportunities that already have a primary OCR
        if (mapOppIdPrimaryOCR.containsKey(opp.Id)) {
            OpportunityContactRole ocr = mapOppIdPrimaryOCR.get(opp.Id);

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
    }

    /*******************************************************************************************************
    * @description Checks to see if HonoreeOCRs are present for Tribute Records.  If not, they are added
    * @param clonedOpp Opportunity that can be updated if necessary
    * @param tributes List of Tributes to Process
    * @param uniqueOCRKeys Set of Strings containing a unique key for each Opportunity Contact Role.  This will be used to prevent duplicate OCRs when processing records
    * @param mapConIdOCRs Map of Contact Ids to Opportunity Contact Roles
    * @param transactionOCRs Map of recently added OCR records by Opportunity ID
    * @param ocrsToDeleteImmediately List of OCR records to delete immediately
    ********************************************************************************************************/
    private void processHonoreeOCRs(Opportunity clonedOpp, List<Tribute__c> tributes, Set<String> uniqueOCRKeys, Map<Id, OpportunityContactRole> mapConIdOCRs, Map<Id, List<OpportunityContactRole>> transactionOCRs, List<OpportunityContactRole> ocrsToDeleteImmediately) {
        for (Tribute__c tri: tributes) {
            //using tri to check if these OCRs need to be managed, as it relies on the Primary Contact field being populated
            if (needsManageOCR(tri, new Tribute__c(), FIELD_NAME_HONOREE_CONTACT, clonedOpp.Primary_Contact__c)) {
                manageOtherOCR(tri, null, mapConIdOCRs, FIELD_NAME_HONOREE_CONTACT, uniqueOCRKeys, transactionOCRs, ocrsToDeleteImmediately);
            }
        }
    }

    /*******************************************************************************************************
    * @description Checks to see if HonoreeOCR is present for Opportunity Record.  If not, it is added
    * @param clonedOpp Opportunity that can be updated if necessary
    * @param uniqueOCRKeys Set of Strings containing a unique key for each Opportunity Contact Role.  This will be used to prevent duplicate OCRs when processing records
    * @param mapConIdOCRs Map of Contact Ids to Opportunity Contact Roles
    * @param transactionOCRs Map of recently added OCR records by Opportunity ID
    * @param ocrsToDeleteImmediately List of OCR records to delete immediately
    ********************************************************************************************************/
    private void processHonoreeOCR(Opportunity clonedOpp, Set<String> uniqueOCRKeys, Map<Id, OpportunityContactRole> mapConIdOCRs, Map<Id, List<OpportunityContactRole>> transactionOCRs, List<OpportunityContactRole> ocrsToDeleteImmediately) {
        //using cloned opp to check if these OCRs need to be managed, as it relies on the Primary Contact field being populated
        if (needsManageOCR(clonedOpp, new Opportunity(), FIELD_NAME_HONOREE_CONTACT, clonedOpp.Primary_Contact__c)) {
            manageOtherOCR(clonedOpp, null, mapConIdOCRs, FIELD_NAME_HONOREE_CONTACT, uniqueOCRKeys, transactionOCRs, ocrsToDeleteImmediately);
        }
    }

    /*******************************************************************************************************
    * @description Checks to see if Notification Recipient OCR is present for Opportunity Record.
    * If not, it is added.  It does check to see if already present as honoree or primary contact, as well
    * @param clonedOpp Opportunity that can be updated if necessary
    * @param honoreeContactIdSet Set of Contact Ids for Honorees
    * @param uniqueOCRKeys Set of Strings containing a unique key for each Opportunity Contact Role.  This will be used to prevent duplicate OCRs when processing records
    * @param mapConIdOCRs Map of Contact Ids to Opportunity Contact Roles
    * @param transactionOCRs Map of recently added OCR records by Opportunity ID
    * @param ocrsToDeleteImmediately List of OCR records to delete immediately
    ********************************************************************************************************/
    private void processNotificationOCR(Opportunity clonedOpp, Set<Id> honoreeContactIdSet, Set<String> uniqueOCRKeys, Map<Id, OpportunityContactRole> mapConIdOCRs, Map<Id, List<OpportunityContactRole>> transactionOCRs, List<OpportunityContactRole> ocrsToDeleteImmediately) {
        if (needsManageOCR(clonedOpp, new Opportunity(), honoreeContactIdSet, true, FIELD_NAME_NOTIFICATION_RECIPIENT_CONTACT, clonedOpp.Primary_Contact__c)) {
            manageOtherOCR(clonedOpp, null, mapConIdOCRs, FIELD_NAME_NOTIFICATION_RECIPIENT_CONTACT, uniqueOCRKeys, transactionOCRs, ocrsToDeleteImmediately);
        }
    }

    /*******************************************************************************************************
    * @description Runs opportunities through opportunity naming.
    * @param listOpps List of opportunities from trigger.new
    ********************************************************************************************************/
    private void updateOpportunityNames(List<Opportunity> listOpps) {
        //name opportunities
        Map<Id, Opportunity> mapOppNaming = new Map<Id, Opportunity>(OPP_OpportunityNaming.getOppNamesAfterInsert(listOpps));
        
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
            if (mapOppNaming.containsKey(opp.Id) && mapOppNaming.get(opp.Id).Name != opp.Name) {
                dmlWrapper.objectsToUpdate.add((sObject) mapOppNaming.get(opp.Id));
            }
        }
    }

    /*******************************************************************************************************
    * @description Detects changes in the opportunity Primary Contact, Honoree Contact, and Notification 
    * Recipient Contact fields and creates, updates or deletes the associated opportunity contact roles.
    * @param listOpps List of opportunities from trigger.new 
    * @param listOldOpps List of opportunities from trigger.old
    ********************************************************************************************************/
    public void upsertContactRolesAfterUpdate(List<Opportunity> listOpps, List<Opportunity> listOldOpps,
            Map<Id, List<Tribute__c>> tributesByOpp, Map<Id, List<Tribute__c>> oldTributesByOpp, Boolean processDML) {

        
        // Map of old Opportunities by Opportunity Id (presumably from Trigger.Old)
        Map<Id, Opportunity> oldOpps = new Map<Id, Opportunity>(listOldOpps);

        // List of Opportunities with field changes relevant to this process.  It will be filtered to only new/changed records
        // where the Primary Contact, Honoree Contact, or Notification Contact have changed
        List<Opportunity> changedOpps = determineOppsRequiringOCREvaluation(listOpps, oldOpps, tributesByOpp, oldTributesByOpp);

        Map<Id, List<Tribute__c>> locTributesByOpp = (tributesByOpp != null) ? tributesByOpp : populateTributesByOpportunityId(changedOpps);
        Map<Id, Tribute__c> oldTribs = convertListOfTributesByOppIdToMapByTributeId(oldTributesByOpp);
        
        // Holds the Opportunity to Map of Contact to OCRs
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
        Map<Id, Account> oppAccountDetails = populateAccountDetails(changedOpps);

        // Retrieve the Primary Contacts for the Opportunities
        Map<Id, List<Id>> primaryContactsToOpportunities = populatePrimaryContactToOpportunities(changedOpps, oppAccountDetails);

        // Retrieve the Account Ids for the Organizational Opportunities
        Map<Id, List<Id>> accountsToOpportunities = populateAccountToOpportunities(changedOpps, oppAccountDetails);

        // find changed opportunities and instantiate a map entry to hold OCRs
        for (Opportunity newOpp : changedOpps) {
            Opportunity oldOpp = oldOpps.get(newOpp.Id);

            // 06/26/2018
            // Updating this to run whenever the AccountId is changed regardless of whether the new or old
            // Account is a Household or Organization
            if (newOpp.Primary_Contact__c != oldOpp.Primary_Contact__c || newOpp.AccountId != oldOpp.AccountId) {
                mapOppIdMapConIdOCR.put(newOpp.Id, new Map<Id, OpportunityContactRole>());
                primaryContactAccountChangeOpptys.add(newOpp);
            }

            List<Tribute__c> tribs = locTributesByOpp.get(newOpp.Id);

            //Handle the Multiple Tribute Here
            if (tribs != null && !tribs.isEmpty()) {
                for (Tribute__c newTri : tribs) {
                    Tribute__c oldTri = oldTribs.get(newTri.Id);

                    if (needsManageOCR(newTri, oldTri, FIELD_NAME_HONOREE_CONTACT, newOpp.Primary_Contact__c)) {
                        mapOppIdMapConIdOCR.put(newOpp.Id, new Map<Id, OpportunityContactRole>());
                    }
                }
            } else {
                if (needsManageOCR(newOpp, oldOpp, FIELD_NAME_HONOREE_CONTACT, newOpp.Primary_Contact__c)) {
                    mapOppIdMapConIdOCR.put(newOpp.Id, new Map<Id, OpportunityContactRole>());
                }
            }

            // Notification Recipient Contact is still on Opportunity, so check should not be in the loop.
            if (needsManageOCR(newOpp, oldOpp, FIELD_NAME_NOTIFICATION_RECIPIENT_CONTACT, newOpp.Primary_Contact__c)) {
                mapOppIdMapConIdOCR.put(newOpp.Id, new Map<Id, OpportunityContactRole>());
            }
        }

        //query for OCRs, hand off to processing methods
        if (!mapOppIdMapConIdOCR.isEmpty()) {
            Set<String> uniqueOCRKeys = new Set<String>();
            for (OpportunityContactRole ocr : [SELECT   OpportunityId,
                                                        ContactId,
                                                        IsPrimary,
                                                        Role
                                               FROM OpportunityContactRole
                                               WHERE OpportunityId IN :mapOppIdMapConIdOCR.keyset()]) {
                mapOppIdMapConIdOCR.get(ocr.OpportunityId).put(ocr.ContactId, ocr);

                uniqueOCRKeys.add(calcUniqueOCRKey(ocr));
            }

            for (Opportunity newOpp: changedOpps) {
                Opportunity oldOpp = oldOpps.get(newOpp.Id);
                
                Boolean isIndividualAccount = isIndividualAccount(oppAccountDetails, newOpp.AccountId);

                List<Tribute__c> tribs = (locTributesByOpp != null) ? locTributesByOpp.get(newOpp.Id) : null;

                Set<Id> honoreeContactIdSet = buildHonoreeContactIdSet((Id) newOpp.Honoree_Contact__c, tribs);

                boolean keyFieldsChanged = hasContactInfoOnOpportunityChanged(oldOpp, newOpp);

                //first, manage primary contact role if the primary contact has changed
                if (needsManageOCR(newOpp, oldOpp, FIELD_NAME_PRIMARY_CONTACT, newOpp.Primary_Contact__c)) {
                    managePrimaryOCR(newOpp, oldOpp, mapOppIdMapConIdOCR.get(newOpp.Id), uniqueOCRKeys, isIndividualAccount, transactionOCRs, ocrsToUpdateImmediately, ocrsToDeleteImmediately);
                }

                if (tribs != null && !tribs.isEmpty()) {
                    // Used to indicate whether we need to re-evaluate unchanged Tribute Records based on changes to key 
                    // Opportunity fields (that may mean the tribute record is now eligible where it previously was not, or is ineligible where it previously was)

                    for (Tribute__c newTri : tribs) {
                        Tribute__c oldTri = oldTribs.get(newTri.Id);

                        //then manage honoree, if it has changed and it's not the same as the primary contact
                        if (needsManageOCR(newTri, oldTri, keyFieldsChanged, FIELD_NAME_HONOREE_CONTACT, newOpp.Primary_Contact__c)) {
                                  manageOtherOCR(newTri, oldTri, mapOppIdMapConIdOCR.get(newOpp.Id), FIELD_NAME_HONOREE_CONTACT, uniqueOCRKeys, transactionOCRs, ocrsToDeleteImmediately);
                        } else if (!String.isBlank(getRole(FIELD_NAME_HONOREE_CONTACT))) {
                            if ((keyFieldsChanged) && (newOpp.Primary_Contact__c == newTri.Honoree_Contact__c)) {
                                // Primary Contact now Matches Honoree Contact.  Make sure OCR is cleaned up, if present
                                cleanupOCR(newTri, mapOppIdMapConIdOCR.get(newOpp.Id), FIELD_NAME_HONOREE_CONTACT, uniqueOCRKeys, ocrsToDeleteImmediately);
                            } else if ((oldTri != null) && (oldTri.Honoree_Contact__c != newTri.Honoree_Contact__c)) {
                                // Honoree was changed to something no longer eligible for an OCR, either to a blank, or to the Primary Contact
                                cleanupOCR(oldTri, mapOppIdMapConIdOCR.get(newOpp.Id), FIELD_NAME_HONOREE_CONTACT, uniqueOCRKeys, ocrsToDeleteImmediately);
                            }
                        }
                    }
                } else {
                    if (newOpp.Honoree_Contact__c != null) {
                        honoreeContactIdSet.add(newOpp.Honoree_Contact__c);
                    }
                    //then manage honoree, if it has changed and it's not the same as the primary contact
                    if (needsManageOCR(newOpp, oldOpp, keyFieldsChanged, FIELD_NAME_HONOREE_CONTACT, newOpp.Primary_Contact__c)) {
                        manageOtherOCR(newOpp, oldOpp, mapOppIdMapConIdOCR.get(newOpp.Id), FIELD_NAME_HONOREE_CONTACT, uniqueOCRKeys, transactionOCRs, ocrsToDeleteImmediately);
                    } else if (!String.isBlank(getRole(FIELD_NAME_HONOREE_CONTACT))) {
                        if ((keyFieldsChanged) && (newOpp.Primary_Contact__c == newOpp.Honoree_Contact__c)) {
                            // Primary Contact now Matches Honoree Contact.  Make sure OCR is cleaned up, if present
                            cleanupOCR(newOpp, mapOppIdMapConIdOCR.get(newOpp.Id), FIELD_NAME_HONOREE_CONTACT, uniqueOCRKeys, ocrsToDeleteImmediately);
                        } else if ((oldOpp != null) && (oldOpp.Honoree_Contact__c != newOpp.Honoree_Contact__c)) {
                            // Honoree was changed to something no longer eligible for an OCR, either to a blank, or to the Primary Contact
                            cleanupOCR(oldOpp, mapOppIdMapConIdOCR.get(newOpp.Id), FIELD_NAME_HONOREE_CONTACT, uniqueOCRKeys, ocrsToDeleteImmediately);
                        }
                    }
                }
                //finally, manage the notification, if it has changed and it's not the same as either contact already dealt with
                if (needsManageOCR(newOpp, oldOpp, honoreeContactIdSet, true, FIELD_NAME_NOTIFICATION_RECIPIENT_CONTACT, newOpp.Primary_Contact__c)) {
                    manageOtherOCR(newOpp, oldOpp, mapOppIdMapConIdOCR.get(newOpp.Id), FIELD_NAME_NOTIFICATION_RECIPIENT_CONTACT, uniqueOCRKeys, transactionOCRs, ocrsToDeleteImmediately);
                } else {
                    if ((keyFieldsChanged) && (newOpp.Primary_Contact__c == newOpp.Notification_Recipient_Contact__c)) {
                        // Primary Contact now Matches Honoree Contact.  Make sure OCR is cleaned up, if present
                        cleanupOCR(newOpp, mapOppIdMapConIdOCR.get(newOpp.Id), FIELD_NAME_NOTIFICATION_RECIPIENT_CONTACT, uniqueOCRKeys, ocrsToDeleteImmediately);
                    } else if ((oldOpp != null) && (oldOpp.Notification_Recipient_Contact__c != newOpp.Notification_Recipient_Contact__c)) {
                        // Notification Recipient was changed to something no longer eligible for an OCR, either to a blank, or to the Primary Contact
                        cleanupOCR(oldOpp, mapOppIdMapConIdOCR.get(newOpp.Id), FIELD_NAME_NOTIFICATION_RECIPIENT_CONTACT, uniqueOCRKeys, ocrsToDeleteImmediately);
                    }
                }
            }

            update ocrsToUpdateImmediately;

            //Query for All the tribute here to handle the multiple tributes
            Map<Id, List<Tribute__c>> allTributesByOpp = new Map<Id, List<Tribute__c>>();
            for (Tribute__c tri: [SELECT    Opportunity__c,
                                            Honoree_Contact__c
                                  FROM Tribute__c
                                  WHERE     Opportunity__c IN :mapOppIdMapConIdOCR.keyset()]) {

                if (allTributesByOpp.get(tri.Opportunity__c) == null) {
                    allTributesByOpp.put(tri.Opportunity__c, new List<Tribute__c>{ tri });
                } else {
                    allTributesByOpp.put(tri.Opportunity__c, (List<Tribute__c>) allTributesByOpp.get(tri.Opportunity__c).add(tri));
                }
            }

            syncHonoreeNotificationContacts(mapOppIdMapConIdOCR, primaryContactAccountChangeOpptys, transactionOCRs, allTributesByOpp, uniqueOCRKeys);

            // Delete OCRs that are associated with Opportunities whose Primary Contact or Account has changed
            clearOCRs(mapOppIdMapConIdOCR, primaryContactAccountChangeOpptys, ocrsToDeleteImmediately, allTributesByOpp);

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

        //For multiple tribute, we need to process the DML here since Tribute trigger will not call run method
        if(processDML) {
            TDTM_TriggerHandler.disableTDTM = true;
            TDTM_TriggerHandler.processDML(dmlWrapper);
            TDTM_TriggerHandler.disableTDTM = false;
        }
    }

    /*******************************************************************************************************
    * @description Determines which opportunities are new, or have changes to fields requiring OCR 
    * reevaluation.
    * @param opps List of New/Updated Opportunites
    * @param oldOpps Map of old version of Opportunities by Opportunity Id, if available
    * @param tributesByOpp Map of New/Updated Lists of Tributes By Opportunity, if available
    * @param oldTributesByOpp Map of old Lists of Tributes By Opportunity, if available
    * @return List<Opportunity> List of Opportunities requiring evaluation/reevaluation
    ********************************************************************************************************/
    @testVisible private static List<Opportunity> determineOppsRequiringOCREvaluation(List<Opportunity> opps, Map<Id, Opportunity> oldOpps, Map<Id, List<Tribute__c>> tributesByOpp, Map<Id, List<Tribute__c>> oldTributesByOpp) {
        List<Opportunity> changedOpps = new List<Opportunity>();

        // Will use passed map, or empty one if not populated
        Map<Id, List<Tribute__c>> lTributesByOpp = (tributesByOpp != null) ? tributesByOpp : new Map<Id, List<Tribute__c>>();

        Map<Id, List<Tribute__c>> lOldTributesByOpp = (oldTributesByOpp != null) ? oldTributesByOpp : new Map<Id, List<Tribute__c>>();

        for (Opportunity opp : opps) {
            Opportunity oldOpp = (oldOpps != null) ? oldOpps.get(opp.Id) : null;

            if (oldOpp == null) { // New Record, should be processed
                changedOpps.add(opp);
            } else if ((opp.Primary_Contact__c != oldOpp.Primary_Contact__c) ||
                       (opp.Honoree_Contact__c != oldOpp.Honoree_Contact__c) || 
                       (opp.Notification_Recipient_Contact__c != oldOpp.NotificatioN_Recipient_Contact__c) || 
                       (opp.AccountId != oldOpp.AccountId)) {
                           changedOpps.add(opp);
            } else if (lTributesByOpp.containsKey(opp.Id)) { // Evaluate Tributes, if present (will only be present for tribute updates)
                List<Tribute__c> tribs = lTributesByOpp.get(opp.Id);
                List<Tribute__c> oldTribs = lOldTributesByOpp.get(opp.Id);

                if (tribs != null) {
                    if ((oldTribs == null) || (tribs.size() != oldTribs.size())) { // Appears to be differences
                        changedOpps.add(opp);
                    } else {
                        Boolean changesPresent = false;
                        for (Integer i=0; (i < tribs.size() && !changesPresent); i++) {
                            Tribute__c trib = tribs[i];
                            Tribute__c oldTrib = oldTribs[i];
                            if (((trib != null) && (oldTrib == null)) ||
                                ((oldTrib != null) && (trib == null)) ||
                                ((trib != null) && (oldTrib != null) && (trib.Honoree_Contact__c != oldTrib.Honoree_Contact__c))) { // Discrepancy between old and new version of Tribute
                                    changedOpps.add(opp);
                                    changesPresent = true;
                            }
                        }
                    }
                }
            }
        }
        return changedOpps;
    }

    /*******************************************************************************************************
    * @description Retrieves Tributes associated with these Opportunities, and places them in a Map of List
    * of Tributes by Opportunity Id
    * @param opps List of Opportunities to retrieve Tributes for
    * @return Map<Id, List<Tribute__c>> Lists of Tributes, in a Map by Opportunity Id
    ********************************************************************************************************/
    @testVisible private static Map<Id, List<Tribute__c>> populateTributesByOpportunityId(List<Opportunity> opps) {
        Map<Id, List<Tribute__c>> tributesByOpp = new Map<Id, List<Tribute__c>>();

        List<Tribute__c> tributes = [SELECT     Id,
                                                Name, 
                                                Honoree_Contact__c,
                                                Opportunity__c
                                    FROM Tribute__c
                                    WHERE       Opportunity__c IN :opps];

        for (Tribute__c trib : tributes) {
            List<Tribute__c> tribs = (tributesByOpp.containsKey(trib.Opportunity__c)) ? tributesByOpp.get(trib.Opportunity__c) : new List<Tribute__c>();
            tribs.add (trib);
            tributesByOpp.put(trib.Opportunity__c, tribs);
        }

        return tributesByOpp;
    }

    /*******************************************************************************************************
    * @description Converts a Map of List of Tributes By Opportunity Id to a Map of Tributes by 
    * Tribute Id
    * @param tributesByOpp Map of List of Tributes By Opportunity Id
    * @return Map<Id, Tribute__c> Map of Tributes by Tribute Id
    ********************************************************************************************************/
    @testVisible private static Map<Id, Tribute__c> convertListOfTributesByOppIdToMapByTributeId(Map<Id, List<Tribute__c>> tributesByOpp) {
        Map<Id, Tribute__c> mapTribs = new Map<Id, Tribute__c>();

        if (tributesByOpp != null) {
            for (Id oppId: tributesByOpp.keySet()) {
                List<Tribute__c> tribs = tributesByOpp.get(oppId);
                if (tribs != null) {
                    for (Tribute__c trib : tribs) {
                        mapTribs.put (trib.Id, trib);
                    }
                }
            }
        }
        return mapTribs;
    }

    /*******************************************************************************************************
    * @description Flags Opportunities that have key field changes indicating the whole hierarchy needs
    * to be reevaluated.
    * @param oldOpp - Old version of Opportunity
    * @param newOpp - New version of Opportunity
    * @return Boolean returns true if any of the following fields changed (Primary Contact Id, Notification Recipient Contact Id, Honoree Contact Id) and false otherwise
    ********************************************************************************************************/
    @testVisible private static Boolean hasContactInfoOnOpportunityChanged(Opportunity oldOpp, Opportunity newOpp) {
        Id oldOppPrimaryContactId = (oldOpp != null) ? oldOpp.Primary_Contact__c : null;
        Id newOppPrimaryContactId = (newOpp != null) ? newOpp.Primary_Contact__c : null;
        Id oldOppNotifContactId = (oldOpp != null) ? oldOpp.Notification_Recipient_Contact__c : null;
        Id newOppNotifContactId = (newOpp != null) ? newOpp.Notification_Recipient_Contact__c : null;
        Id oldOppHonoreeContactId = (oldOpp != null) ? oldOpp.Honoree_Contact__c : null;
        Id newOppHonoreeContactId = (newOpp != null) ? newOpp.Honoree_Contact__c : null;

        return ((oldOppPrimaryContactId != newOppPrimaryContactId) ||
                (oldOppNotifContactId != newOppNotifContactId) ||
                (oldOppHonoreeContactId != newOppHonoreeContactId));
    }

    /*******************************************************************************************************
    * @description Builds a set containing the Contact Ids of all Honorees.
    * @param oppHonoreeContactId - Id of Honoree Contact from Opportunity
    * @param tributes - List of Tributes (must include Honoree Contact)
    * @return Set<Id> containing all contact ids associated with the id and records passed in
    ********************************************************************************************************/
    @testVisible private Set<Id> buildHonoreeContactIdSet(Id oppHonoreeContactId, List<Tribute__c> tributes) {
        Set<Id> honoreeContactIdSet = new Set<Id>();

        if (oppHonoreeContactId != null) { // Add Opportunity Honorees, if present
            honoreeContactIdSet.add(oppHonoreeContactId);
        }

        if (tributes != null) { // Add Tribute Honorees, if present
            for (Tribute__c tribute : tributes) {
                Id honoreeContactId = (Id) tribute.get(FIELD_NAME_HONOREE_CONTACT);
                if (honoreeContactId != null) {
                    honoreeContactIdSet.add(honoreeContactId);
                }
            }
        }

        return honoreeContactIdSet;
    }

    /*******************************************************************************************************
    * @description Manages create and update of the primary Opportunity Contact Role.
    * @param opp The current opportunity from trigger.new
    * @param oldOpp The old opportunity from trigger.old
    * @param mapConIdOCR A map of contact id to Opportunity Contact Role records for this opportunity.
    * @param uniqueOCRKeys A Set of OpportunityId-ContactId-Role values to be checked and augmented to help prevent duplicate roles from being added
    * @param isIndividualAccount The Account's Type: Individual or Organization.
    * @param transactionOCRs Contains the OCRs that will be evaluated to ensure compliance with the OCR hierarchy.
    * @param ocrsToUpdateImmediately Holds Opportunity Contact Roles that need to be updated immediately.
    * @param ocrsToDeleteImmediately Holds Opportunity Contact Roles that need to be deleted immediately.
    * @return void This method adds records to dmlWrapper and returns nothing.
    ********************************************************************************************************/
    private void managePrimaryOCR(Opportunity opp, Opportunity oldOpp, Map<Id,OpportunityContactRole> mapConIdOCR, Set<String> uniqueOCRKeys, Boolean isIndividualAccount,
                                  Map<Id, List<OpportunityContactRole>> transactionOCRs, List<OpportunityContactRole> ocrsToUpdateImmediately,
                                  List<OpportunityContactRole> ocrsToDeleteImmediately) {
        Id idNewPrimaryCon = opp.Primary_Contact__c;
        Id idOldCon = oldOpp.Primary_Contact__c;

        //if we have a primary OCR, separate it from the list
        OpportunityContactRole primaryOCR;
        if (mapConIdOCR != null) {
            for (OpportunityContactRole ocr : mapConIdOCR.values()) {
                if (ocr.IsPrimary) {
                    primaryOCR = ocr;
                    mapConIdOCR.remove(ocr.ContactId);
                }
            }
        }

        //primary contact is blanked out 
        if (idNewPrimaryCon == null) {
            //if we have an existing primary OCR, delete it
            if (primaryOCR != null) {
                ocrsToDeleteImmediately.add(primaryOCR);
                uniqueOCRKeys.remove(calcUniqueOCRKey(primaryOCR));
            }
        //primary contact went from blank to a new contact
        } else if (idNewPrimaryCon != null) {
            //create or update the existing primary OCR
            if (primaryOCR == null) {
                OpportunityContactRole newPrimaryOCR = getOCR(opp, FIELD_NAME_PRIMARY_CONTACT, isIndividualAccount);
                dmlWrapper.objectsToInsert.add(newPrimaryOCR);
                transactionOCRs = populateTransactionOCRs(transactionOCRs, newPrimaryOCR);
                uniqueOCRKeys.remove(calcUniqueOCRKey(primaryOCR));
                uniqueOCRKeys.add(calcUniqueOCRKey(newPrimaryOCR));
            } else { 
                // Delete Old and Insert New
                if (primaryOCR.ContactId != idNewPrimaryCon || String.isBlank(primaryOCR.Role)) {
                    ocrsToDeleteImmediately.add(primaryOCR);
                    uniqueOCRKeys.remove(calcUniqueOCRKey(primaryOCR));
                    OpportunityContactRole newPrimaryOCR = getOCR(opp, FIELD_NAME_PRIMARY_CONTACT, isIndividualAccount);
                    dmlWrapper.objectsToInsert.add(newPrimaryOCR);
                    transactionOCRs = populateTransactionOCRs(transactionOCRs, newPrimaryOCR);
                    uniqueOCRKeys.add(calcUniqueOCRKey(newPrimaryOCR));
                }
            }
        }
    }

    /*******************************************************************************************************
    * @description Manages create and update of the Opportunity Contact Roles for the Honoree and Notification
    * Recipient contact lookup fields.
    * @param obj The current opportunity from trigger.new
    * @param oldObj The old opportunity from trigger.old
    * @param mapConIdOCR A map of contact id to Opportunity Contact Role records for this opportunity.
    * @param fieldName The API name of the field to verify
    * @param uniqueOCRKeys A Set of OpportunityId-ContactId-Role values to be checked and augmented to help prevent duplicate roles from being added
    * @param transactionOCRs Contains the OCRs that will be evaluated to ensure compliance with the OCR hierarchy.
    * @param ocrsToDeleteImmediately Holds Opportunity Contact Roles that need to be deleted immediately.
    * @return void This method adds records to dmlWrapper and returns nothing.
    ********************************************************************************************************/
    private void manageOtherOCR(SObject obj, SObject oldObj, Map<Id, OpportunityContactRole> mapConIdOCR, String fieldName, Set<String> uniqueOCRKeys,
                                Map<Id, List<OpportunityContactRole>> transactionOCRs, List<OpportunityContactRole> ocrsToDeleteImmediately) {
        Id idNewCon = (Id) obj.get(fieldName);
        Id idOldCon = (oldObj != null) ? (Id) oldObj.get(fieldName) : null;

        if (mapConIdOCR == null) // Doing just so repeated null checks are not necessary...
            mapConIdOCR = new Map<Id, OpportunityContactRole>();

        OpportunityContactRole ocrNewCon = mapConIdOCR.get(idNewCon);
        OpportunityContactRole ocrOldCon = mapConIdOCR.get(idOldCon);

        if (idNewCon == null) {
            //if the lookup field was blanked out, and an OCR matches the previous contact with the correct role, delete it
            if (idOldCon != null && ocrOldCon != null) {
                if (ocrOldCon.Role == getRole(fieldName)) {
                    // Remove key from set, since removing role...
                    uniqueOCRKeys.remove(calcUniqueOCRKey(ocrOldCon));
                    ocrsToDeleteImmediately.add(ocrOldCon);
                    mapConIdOCR.remove(idOldCon);
                }
            }
            //the lookup has a new contact
        } else if (idNewCon != null) {
            //net new contact, i.e. no old contact; create a contact role if we don't have one for this contact yet
            if (idOldCon == null && ocrNewCon == null ) {
                OpportunityContactRole ocr = getOCR(obj, fieldName);
                String uniqueOCRKey = calcUniqueOCRKey(ocr);
                if (!uniqueOCRKeys.contains(uniqueOCRKey)) { // Is there already a role present with this value?
                    dmlWrapper.objectsToInsert.add(ocr);
                    uniqueOCRKeys.add(uniqueOCRKey);
                    mapConIdOCR.put(idNewCon, ocr);
                }
            }

            // If the New Contact has an OCR, update it accordingly
            if (idOldCon == null && ocrNewCon != null) {

                // Remove existing unique OCR Key
                uniqueOCRKeys.remove(calcUniqueOCRKey(ocrNewCon));
                
                ocrNewCon.Role = getRole(fieldName);

                String uniqueOCRKey = calcUniqueOCRKey(ocrNewCon);
                if (!uniqueOCRKeys.contains(uniqueOCRKey)) {
                    // Add unique OCR Key for newly updated OCR
                    uniqueOCRKeys.add(uniqueOCRKey);

                    dmlWrapper.objectsToUpdate.add(ocrNewCon);
                    mapConIdOCR.put(idNewCon, ocrNewCon);
                }
            }

            //contact lookup changed from one contact to another
            if ((idOldCon != null) && (!isEquivalentOCR(ocrOldCon, ocrNewCon))) {
                //an OCR for the old contact exists, and has the role for this field
                if (ocrOldCon != null && ocrOldCon.Role == getRole(fieldName)) {
                    //our new contact doesn't yet have an OCR, so update the old one to the new contact
                    if (ocrNewCon == null || (ocrNewCon != null && ocrNewCon.Role != getRole(fieldName))) {
                        uniqueOCRKeys.remove(calcUniqueOCRKey(ocrOldCon));
                        ocrOldCon.ContactId = idNewCon;

                        // Generating key with updated contact
                        String uniqueOCRKey = calcUniqueOCRKey(ocrOldCon);
                        if (!uniqueOCRKeys.contains(uniqueOCRKey)) {
                            // Add unique OCR Key for newly updated OCR
                            uniqueOCRKeys.add(uniqueOCRKey);
                            dmlWrapper.objectsToUpdate.add(ocrOldCon);
                            transactionOCRs = populateTransactionOCRs(transactionOCRs, ocrOldCon);
                        }

                        if (ocrNewCon != null) {
                            uniqueOCRKeys.remove(calcUniqueOCRKey(ocrNewCon));
                            dmlWrapper.objectsToDelete.add(ocrNewCon);
                        }

                        mapConIdOCR.remove(idOldCon);
                        mapConIdOCR.put(idNewCon, ocrNewCon);

                    //our new contact already has an OCR, delete the old one
                    } else {
                        uniqueOCRKeys.remove(calcUniqueOCRKey(ocrOldCon));
                        ocrsToDeleteImmediately.add(ocrOldCon);
                        mapConIdOCR.remove(idOldCon);
                    }
                    //new contact doesn't have an OCR yet, create one with the appropriate role
                } else if (ocrNewCon == null) {
                    OpportunityContactRole ocr = getOCR(obj, fieldName);
                    String uniqueOCRKey = calcUniqueOCRKey(ocr);
                    if (!uniqueOCRKeys.contains(uniqueOCRKey)) {
                        // Add unique OCR Key for newly inserted OCR
                        uniqueOCRKeys.add(uniqueOCRKey);
                        dmlWrapper.objectsToInsert.add(getOCR(obj, fieldName));
                    }
                    mapConIdOCR.put(idNewCon, ocrNewCon);
                } else if (ocrNewCon.Role != getRole(fieldName)) {
                    uniqueOCRKeys.remove(calcUniqueOCRKey(ocrNewCon));
                    ocrNewCon.Role = getRole(fieldName);
                    String uniqueOCRKey = calcUniqueOCRKey(ocrNewCon);
                    if (!uniqueOCRKeys.contains(uniqueOCRKey)) {
                        // Add unique OCR Key for updated OCR
                        uniqueOCRKeys.add(uniqueOCRKey);
                        dmlWrapper.objectsToUpdate.add(ocrNewCon);
                    }
                    mapConIdOCR.put(idNewCon, ocrNewCon);
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
    * @description Cleanup if associated lookup changes, and the new OCR is not eligible because it 
    * conflicts with a higher priority OCR, or if an existing unchanged value is no longer eligible because 
    * a higher precedent record supercedes it
    * @param obj The opportunity in question (could be from Trigger.old)
    * @param mapConIdOCR A map of contact id to Opportunity Contact Role records for this opportunity.
    * @param fieldName The name of the Opportunity or tribute field
    * @param uniqueOCRKeys A Set of OpportunityId-ContactId-Role values to be checked and augmented to help prevent duplicate roles from being added
    * @param ocrsToDeleteImmediately Holds Opportunity Contact Roles that need to be deleted immediately.
    * @return void This method adds records to a list of records to be deleted immediately, but returns nothing
    ********************************************************************************************************/
    private void cleanupOCR(SObject obj, Map<Id, OpportunityContactRole> mapConIdOCR, String fieldName, Set<String> uniqueOCRKeys,
                                List<OpportunityContactRole> ocrsToDeleteImmediately) {
        cleanupOCR(obj, mapConIdOCR, fieldName, null, uniqueOCRKeys, ocrsToDeleteImmediately);
    }

    /*******************************************************************************************************
    * @description Cleanup if associated lookup changes, and the new OCR is not eligible because it 
    * conflicts with a higher priority OCR, or if an existing unchanged value is no longer eligible because 
    * a higher precedent record supercedes it
    * @param obj The opportunity in question (could be from Trigger.old)
    * @param mapConIdOCR A map of contact id to Opportunity Contact Role records for this opportunity.
    * @param fieldName The name of the Opportunity or tribute field
    * @param isIndividualAccount The classification (e.g., Individual) of an Opportunity's associated Account.
    * @param uniqueOCRKeys A Set of OpportunityId-ContactId-Role values to be checked and augmented to help prevent duplicate roles from being added
    * @param ocrsToDeleteImmediately Holds Opportunity Contact Roles that need to be deleted immediately.
    * @return void This method adds records to a list of records to be deleted immediately, but returns nothing
    ********************************************************************************************************/
    private void cleanupOCR(SObject obj, Map<Id, OpportunityContactRole> mapConIdOCR, String fieldName, Boolean isIndividualAccount, Set<String> uniqueOCRKeys,
                                List<OpportunityContactRole> ocrsToDeleteImmediately) {
        Id idCon = (obj != null) ? (Id) obj.get(fieldName) : null;

        if (mapConIdOCR == null) // Doing just so repeated null checks are not necessary...
            mapConIdOCR = new Map<Id, OpportunityContactRole>();

        OpportunityContactRole ocrCon = mapConIdOCR.get(idCon);

        if (idCon != null && ocrCon != null) {
            if (ocrCon.Role == getRole(fieldName, isIndividualAccount)) {
                // Remove key from set, since removing role...
                uniqueOCRKeys.remove(calcUniqueOCRKey(ocrCon));
                ocrsToDeleteImmediately.add(ocrCon);
                mapConIdOCR.remove(idCon);
            }
        }
    }

    /*******************************************************************************************************
    * @description Given an OpportunityContactRole , generates a String value to be treated as unique.  This is generated by 
    * appending OpportunityId, -, ContactId, -, and Role together.  E.g. 0061100000GFDODAA5-0031100001UDh5vAAD-Donor
    * @param ocr OpportunityContactRole
    * @return String The unique key for any OCRs matching this Contact and Role combination
    ********************************************************************************************************/
    @testVisible private static String calcUniqueOCRKey(OpportunityContactRole ocr) {
        return (ocr != null) ? ocr.OpportunityId + '-' + ocr.ContactId + '-' + ocr.Role : null;
    }

    /*******************************************************************************************************
    * @description For a given opportunity contact lookup field, returns the role value associated with that
    * field as defined in settings.
    * @param fieldName The name of the Opportunity field.
    * @return String The role value associated with the field.
    ********************************************************************************************************/
    @testVisible private static String getRole(String fieldName) {
        return getRole(fieldName, null);
    }

    /*******************************************************************************************************
    * @description For a given opportunity contact lookup field, returns the role value associated with that
    * field as defined in settings.
    * @param fieldName The name of the Opportunity field.
    * @param isIndividualAccount The classification (e.g., Individual) of an Opportunity's associated Account.
    * @return String The role value associated with the field.
    ********************************************************************************************************/
    @testVisible private static String getRole(String fieldName, Boolean isIndividualAccount) {
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
    * @param obj The opportunity for which to create an OCR.
    * @param fieldName The name of the opportunity field.
    * @return OpportunityContactRole The newly created OCR.
    ********************************************************************************************************/
    private OpportunityContactRole getOCR(SObject obj, String fieldName) {
        return getOCR(obj, fieldName, null);
    }

    /*******************************************************************************************************
    * @description Returns a new OpportunityContactRole record, based on an Opportunity, the API name of
    * the Contact Lookup field, and the associated Account's _SYSTEM: IsIndividual field.
    * @param opp The opportunity for which to create an OCR.
    * @param fieldName The name of the opportunity field.
    * @param isIndividualAccount The associated Account's _SYSTEM: IsIndividual field value.
    * @return OpportunityContactRole The newly created OCR.
    ********************************************************************************************************/
    private OpportunityContactRole getOCR(SObject obj, String fieldName, Boolean isIndividualAccount) {
        OpportunityContactRole ocr = new OpportunityContactRole();
        //If it is an opportunity, then we just use the id,
        //otherwise we assume that the obj (Such as Tribute) has a lookup (Opportunity__c) field
        if (obj instanceof Opportunity) {
            ocr.OpportunityId = obj.Id;
        } else {
            ocr.OpportunityId = (Id)obj.get(FIELD_NAME_OPPORTUNITY);
        }
        ocr.ContactId = (Id)obj.get(fieldname);
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
    * @param obj The current opportunity from trigger.new
    * @param oldObj The old opportunity from trigger.old
    * @param fieldName The API name of the field to verify
    * @oaram primaryContactId Contact Id associated with Opportunities Primary Contact
     * @return boolean Whether this opportunity and field needs OCR handling.
    ********************************************************************************************************/
    private boolean needsManageOCR(SObject obj, SObject oldObj, String fieldName, Id primaryContactId) {
        return needsManageOCR(obj, oldObj, null, false, fieldName, primaryContactId);
    }

    /*******************************************************************************************************
    * @description Verifies if an opportunity contact lookup needs automatic management of the Opportunity
    * Contact Role associated with that field. For automatic management, the lookup field's associated role custom
    * setting needs a value, the value in the lookup field needs to be new or have changed, and the contact
    * needs to be different from a contact that's already managed.
    * @param obj The current opportunity from trigger.new
    * @param oldObj The old opportunity from trigger.old
    * @param ignoreChangeCheck Indicates whether it should consider a field change as mattering, or if it should continue through the eval process even if it has not changed
    * @param fieldName The API name of the field to verify
    * @oaram primaryContactId Contact Id associated with Opportunities Primary Contact
    * @return boolean Whether this opportunity and field needs OCR handling.
    ********************************************************************************************************/
    private boolean needsManageOCR(SObject obj, SObject oldObj, Boolean ignoreChangeCheck, String fieldName, Id primaryContactId) {
        return needsManageOCR(obj, oldObj, null, ignoreChangeCheck, fieldName, primaryContactId);
    }

    /*******************************************************************************************************
    * @description Verifies if an opportunity contact lookup needs automatic management of the Opportunity
    * Contact Role associated with that field. For automatic management, the lookup field's associated role custom
    * setting needs a value, the value in the lookup field needs to be new or have changed, and the contact
    * needs to be different from a contact that's already managed.
    * @param obj The current opportunity from trigger.new
    * @param oldObj The old opportunity from trigger.old
    * @param honoreeContactIdSet The set of Contacts mapped as honorees, either on the Opportunity or on the associated Tribute record
    * @param ignoreChangeCheck - Indicates whether it should consider a field change as mattering, or if it should continue through the eval process even if it has not changed
    * @param fieldName The API name of the field to verify
    * @oaram primaryContactId Contact Id associated with Opportunities Primary Contact
    * @return boolean Whether this opportunity and field needs OCR handling.
    ********************************************************************************************************/
    @testVisible private static boolean needsManageOCR(SObject obj, SObject oldObj, Set<Id> honoreeContactIdSet, Boolean ignoreChangeCheck, String fieldName, Id primaryContactId) {

        //no role for this field
        if (String.isBlank(getRole(fieldName))) {
            return false;
        }

        // Must re-evaluate if no old values to compare to
        else if ((obj != null) && (oldObj == null)) {

            //the honoree contact is the same as the primary contact, thus is already managed
            if (fieldName == FIELD_NAME_HONOREE_CONTACT && obj.get(FIELD_NAME_HONOREE_CONTACT) == primaryContactId) {
                return false;
            }
            //the notification recipient contact is the same as the primary contact, thus the OCR is already managed
            else if (fieldName == FIELD_NAME_NOTIFICATION_RECIPIENT_CONTACT && obj.get(FIELD_NAME_NOTIFICATION_RECIPIENT_CONTACT) == primaryContactId) {
                return false;
            }

            //the notification recipient contact is the same as one of the honoree contacts, thus the OCR is already managed
            else if ((fieldName == FIELD_NAME_NOTIFICATION_RECIPIENT_CONTACT) && (honoreeContactIdSet != null) 
                     && (obj.get(FIELD_NAME_NOTIFICATION_RECIPIENT_CONTACT) != null && honoreeContactIdSet.contains((Id)obj.get(FIELD_NAME_NOTIFICATION_RECIPIENT_CONTACT)))) {
                return false;
            }

            return true;
        }

        //field value hasn't changed
        else if ((obj.get(fieldName) == oldObj.get(fieldName)) && (!ignoreChangeCheck)) {
            return false;
        } 

        // old and new values are null and ignoreChangeCheck is true
        else if ((obj.get(fieldName) == null) && (oldObj.get(fieldName) == null) && (ignoreChangeCheck)) {
            return false;
        }

        //the honoree contact is the same as the primary contact, thus is already managed
        else if (fieldName == FIELD_NAME_HONOREE_CONTACT && obj.get(FIELD_NAME_HONOREE_CONTACT) == primaryContactId) {
            return false;
        }
        //the notification recipient contact is the same as the primary contact, thus the OCR is already managed
        else if (fieldName == FIELD_NAME_NOTIFICATION_RECIPIENT_CONTACT && obj.get(FIELD_NAME_NOTIFICATION_RECIPIENT_CONTACT) == primaryContactId) {
            return false;
        }

        //the notification recipient contact is the same as one of the honoree contacts, thus the OCR is already managed
        else if ((fieldName == FIELD_NAME_NOTIFICATION_RECIPIENT_CONTACT) && (honoreeContactIdSet != null) 
                 && (obj.get(FIELD_NAME_NOTIFICATION_RECIPIENT_CONTACT) != null && honoreeContactIdSet.contains((Id)obj.get(FIELD_NAME_NOTIFICATION_RECIPIENT_CONTACT)))) {
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

        accountDetails = new Map<Id, Account>([SELECT   Id,
                                                        Name, 
                                                        npe01__SYSTEMIsIndividual__c
                                               FROM Account
                                               WHERE    Id IN :accountIds]);

        return accountDetails;
    }

   /*********************************************************************************************************
    * @description Determines if two OCR records are essentially the same (same Opportunity ID, Contact Id, and Role).
    * If both records are not null, and the Opportunity Id, Contact Id, and Role matches, it will return true.
    * Otherwise, it returns false
    * @param ocr1 1st OpportunityContactRole record
    * @param ocr2 2nd OpportunityContactRole record
    * @return Boolean true if equivalent, false otherwise
    **********************************************************************************************************/
    @testVisible private static Boolean isEquivalentOCR(OpportunityContactRole ocr1, OpportunityContactRole ocr2) {
        if ((ocr1 == null) || (ocr2 == null))
            return false;
        return ((ocr1.OpportunityId == ocr2.OpportunityId) && (ocr1.ContactId == ocr2.ContactId) && (ocr1.Role == ocr2.Role));
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
            if (eachOppty.Primary_Contact__c != null && eachOppty.AccountId != null
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
                                  List<OpportunityContactRole> ocrsToDeleteImmediately, Map<Id, List<Tribute__c>> allTributesByOpp) {

        Map<Id, OpportunityContactRole> ocrsToDelete = new Map<Id, OpportunityContactRole>();

        if (!ocrsToDeleteImmediately.isEmpty()) {
            for (OpportunityContactRole ocr : ocrsToDeleteImmediately) {
                if (ocr.Id != null) {
                    ocrsToDelete.put(ocr.Id, ocr);
                }
            }
        }

        npe01__Contacts_And_Orgs_Settings__c orgContactSettings = UTIL_CustomSettingsFacade.getOrgContactsSettings();
        String honoreeRole = orgContactSettings.Honoree_Opportunity_Contact_Role__c;
        String notificationRole = orgContactSettings.Notification_Recipient_Opp_Contact_Role__c;

        for (Opportunity eachOppty : primaryContactAccountChangeOpptys) {
            for (OpportunityContactRole eachOldOCR : opportunityToContactToOCR.get(eachOppty.Id).values()) {
                List<Tribute__c> tributes = allTributesByOpp.get(eachOppty.Id);
                if ((TBU_MultipleTributesSettingsFacade.isMultipleTributesFlexible() || TBU_MultipleTributesSettingsFacade.isMultipleTributesLimited()) &&
                        (tributes != null && !tributes.isEmpty())) {
                    // Removing this logic entirely for now.  Best course of action is not to do anything here, as the logic as proposed will not work correctly with
                    // Multiple Tributes and this flow will likely be redesigned anyways.  Nic Campbell suggested this, and after reviewing I agree.
                } else {
                    if ((eachOldOCR != null) && (eachOldOCR.Id != null)) {
                       if (!eachOldOCR.isPrimary
                                && (honoreeRole == null || !honoreeRole.equals(eachOldOCR.Role) || (honoreeRole.equals(eachOldOCR.Role) && (eachOppty.Primary_Contact__c == eachOldOCR.ContactId || eachOppty.Honoree_Contact__c != eachOldOCR.ContactId)))
                                && (notificationRole == null || !notificationRole.equals(eachOldOCR.Role) || (notificationRole.equals(eachOldOCR.Role) && (eachOppty.Primary_Contact__c == eachOldOCR.ContactId || eachOppty.Notification_Recipient_Contact__c != eachOldOCR.ContactId)))) {
                            if (!ocrsToDelete.containsKey(eachOldOCR.Id)) {
                                ocrsToDelete.put(eachOldOCR.Id, eachOldOCR);
                            }
                        }
                    }
                }
            }
        }

        if (!ocrsToDelete.isEmpty()) {
            delete ocrsToDelete.values();
        }
    }

    /*********************************************************************************************************
    * @description Checks if an Honoree or Notification Contact is on the Opportunity and missing an
    *              OpportunityContactRole record, then creates it accordingly.  Also checks
    *              Honoree Contacts on the related Tributes, if multiple tributes is enabled. 
    * @param opportunityToContactToOCR Map of Opportunity to a Map of Contact to OpportunityContactRoles.
    * @param primaryContactAccountChangeOpptys List of OpportunityIds whose Primary Contact or Account changed.
    * @param transactionOCRs Contains the OCRs that will be evaluated to ensure compliance with the OCR hierarchy.
    * @param uniqueOCRKeys Set of Strings containing a unique key for each Opportunity Contact Role.  This will be used to prevent duplicate OCRs when processing records
    * @return void
    **********************************************************************************************************/
    @testVisible
    private void syncHonoreeNotificationContacts(Map<Id, Map<Id, OpportunityContactRole>> opportunityToContactToOCR, List<Opportunity> primaryContactAccountChangeOpptys,
                                                     Map<Id, List<OpportunityContactRole>> transactionOCRs, Map<Id, List<Tribute__c>> allTributesByOpp, Set<String> uniqueOCRKeys) {

        for (Opportunity eachOppty : primaryContactAccountChangeOpptys) {
            Set<Id> ocrs = new Set<Id>();

            Id primaryContactId = eachOppty.Primary_Contact__c;

            for (OpportunityContactRole eachOldOCR : opportunityToContactToOCR.get(eachOppty.Id).values()) {
                if (eachOldOCR != null) {
                    ocrs.add(eachOldOCR.ContactId);
                }
            }
            
            List<Tribute__c> tributes = allTributesByOpp.get(eachOppty.Id);
            if ((TBU_MultipleTributesSettingsFacade.isMultipleTributesFlexible() || TBU_MultipleTributesSettingsFacade.isMultipleTributesLimited()) &&
                    tributes != null && !tributes.isEmpty()) {
                for (Tribute__c tri: tributes) {
                    Id honoreeContactId = tri.Honoree_Contact__c;
                   
                    if (honoreeContactId != null && !ocrs.contains(honoreeContactId) && primaryContactId != honoreeContactId) {
                        OpportunityContactRole honoreeOCR = getOCR(tri, FIELD_NAME_HONOREE_CONTACT);
                        String uniqueOCRKey = calcUniqueOCRKey(honoreeOCR);
                        if (!uniqueOCRKeys.contains(uniqueOCRKey)) {
                            uniqueOCRKeys.add(uniqueOCRKey);
                            dmlWrapper.objectsToInsert.add(honoreeOCR);
                            transactionOCRs = populateTransactionOCRs(transactionOCRs, honoreeOCR);
                        }
                    }
                }
            } else {
                Id honoreeContactId = eachOppty.Honoree_Contact__c;
                
                if (honoreeContactId != null && !ocrs.contains(honoreeContactId) && primaryContactId != honoreeContactId) {
                    OpportunityContactRole honoreeOCR = getOCR(eachOppty, FIELD_NAME_HONOREE_CONTACT);
                    String uniqueOCRKey = calcUniqueOCRKey(honoreeOCR);
                    if (!uniqueOCRKeys.contains(uniqueOCRKey)) {
                        uniqueOCRKeys.add(uniqueOCRKey);
                        dmlWrapper.objectsToInsert.add(honoreeOCR);
                        transactionOCRs = populateTransactionOCRs(transactionOCRs, honoreeOCR);
                    }
                }
            }
            // Since notification fields are still on the Opportunity, need to check the Notification Recipient Contact field  on the Opportunity
            Id notificationContactId = eachOppty.Notification_Recipient_Contact__c;
            if (notificationContactId != null && !ocrs.contains(notificationContactId) && primaryContactId != notificationContactId) {
                OpportunityContactRole notificationOCR = getOCR(eachOppty, FIELD_NAME_NOTIFICATION_RECIPIENT_CONTACT);
                String uniqueOCRKey = calcUniqueOCRKey(notificationOCR);
                if (!uniqueOCRKeys.contains(uniqueOCRKey)) {
                    uniqueOCRKeys.add(uniqueOCRKey);
                    dmlWrapper.objectsToInsert.add(notificationOCR);
                    transactionOCRs = populateTransactionOCRs(transactionOCRs, notificationOCR);
                }
            }
        }
    }

    /**
     * @description Returns the value Account.npe01__SYSTEMIsIndividual__c or null if the AccountId is null
     * @param accountMap Map of Accounts by Id
     * @param accountId AccountId
     * @return True or null
     */
    private static Boolean isIndividualAccount(Map<Id, Account> accountMap, Id accountId) {
        return (accountId != null && accountMap.containsKey(accountId) ? accountMap.get(accountId).npe01__SYSTEMIsIndividual__c  : null);
    }

    /*******************************************************************************************************
     * @description Create the new Tribute record from Opportunity
     * @param listOpps List of Opportunities from trigger.new
     * @return void
     ********************************************************************************************************/
    private static void createTributeFromOpportunity(List<Opportunity> listOpps) {
        List<Tribute__c> tributeToInsert = new List<Tribute__c>();
        for (Opportunity opp : listOpps) {
            if (opp.Honoree_Contact__c != null || opp.Honoree_Name__c != null || opp.Tribute_Type__c != null) {
                //Create new Tribute Record based on the Opportunity Tribute Fields
                tributeToInsert.add(createTributeFromOpportunityHelper(opp));
            }
        }

        //Set a flag in Tribute TDTM to remember to clear the tribute field on Opportunity
        TBU_OpportunityContactRoles_TDTM.clearTributeFieldsFromOpportunity = true;
        insert tributeToInsert;
        TBU_OpportunityContactRoles_TDTM.clearTributeFieldsFromOpportunity = false;
    }

    /*******************************************************************************************************
     * @description The helper method to create the new Tribute record from Opportunity
     * @param opp Opportunity to copy Honoree Info from
     * @return newly populate Tribute__c record, ready for insert
     ********************************************************************************************************/
    private static Tribute__c createTributeFromOpportunityHelper(Opportunity opp) {
        Tribute__c newTribute = new Tribute__c();

        newTribute.Opportunity__c = opp.Id;
        newTribute.Tribute_Type__c = opp.Tribute_Type__c;
        newTribute.Honoree_Contact__c = opp.Honoree_Contact__c;
        newTribute.Honoree_Name__c = opp.Honoree_Name__c;

        return newTribute;
    }

    /*******************************************************************************************************
    * @description Prevent user update Tribute on Opportunity based on the custom setting
    * @param listOpps List of Opportunities from trigger.new
    * @param oldListOpps List of Opportunities from trigger.old
    * @boolean checkTributeRollup
    ********************************************************************************************************/
    private void preventUpdateTributeInfoOnOpportunity(List<Opportunity> listOpps, List<Opportunity> oldListOpps,
            boolean checkTributeRollup) {
        
        Map<Id, Integer> oppToTributeCntMap = new Map<Id, Integer>();
        // Just need to know if there is already at least one tribute
        List<Opportunity> oppTribList = [SELECT Id, 
                                                (SELECT     Id
                                                 FROM Tributes__r LIMIT 1) 
                                        FROM Opportunity
                                        WHERE Id IN :listOpps];

        for (Opportunity opp : oppTribList) {
            oppToTributeCntMap.put (opp.Id, opp.Tributes__r.size());
        }

        for (Integer i = 0; i < listOpps.size(); i ++) {
            Opportunity newOpp = listOpps[i];
            Opportunity oldOpp = oldListOpps[i];

            //We will prevent user update the Tribute info unless user try to clear the field in order to do some correction
            if (newOpp.Tribute_Type__c != oldOpp.Tribute_Type__c && newOpp.Tribute_Type__c != null ||
                    (newOpp.Honoree_Contact__c != oldOpp.Honoree_Contact__c && String.isNotBlank(newOpp.Honoree_Contact__c)) ||
                    (newOpp.Honoree_Name__c != oldOpp.Honoree_Name__c && String.isNotBlank(newOpp.Honoree_Name__c))) {
                if (checkTributeRollup) {
                    if(oppToTributeCntMap.get(newOpp.Id) > 0) {
                        newOpp.AddError(Label.errMultipleTributesEnforceMultiple);
                    }
                } else {
                    newOpp.AddError(Label.errMultipleTributesEnforceMultiple);
                }
            }
        }
    }
}