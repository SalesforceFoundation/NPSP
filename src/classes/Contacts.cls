/*
    Copyright (c) 2021 Salesforce.org
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
* @date 2021
* @description Domain class for Contacts in NPSP.
*/
public with sharing class Contacts extends fflib_SObjects {

    HouseholdSettings settings;
    Map<Id, Contact> oldMap;
    List<Contact> contactsNeedingHouseholds = new List<Contact>();
    List<Id> householdsNeedingNamesUpdated = new List<Id>();
    Set<Id> householdIdsNeedingRollup = new Set<Id>();
    List<Id> oldHouseholds = new List<Id>();
    Map<Id, Integer> oldHouseholdSizeById = new Map<Id, Integer>();
    private final String RECORDTYPEID = 'RecordTypeId';

    public Contacts(List<Contact> records) {
        this(records, null, null);
    }

    public Contacts(List<Contact> records, List<Contact> oldList) {
        this(records, oldList, null);
    }

    @TestVisible
    private Contacts(List<Contact> records, List<Contact> oldList, HouseholdSettings
            settings) {
        super(records, Contact.SObjectType);
        this.oldMap = oldList != null ?
                new Map<Id, Contact>(oldList) : new Map<Id, Contact>();
        this.settings = settings == null ? new HouseholdSettings() : settings;
    }

    public void onBeforeInsert() {
        synchronizeNamingExclusionsFieldsBeforeInsert();
    }

    public void onBeforeUpdate() {
        synchronizeNamingExclusionsFieldsBeforeUpdate();
    }

    public void onAfterInsert() {
        processHouseholdsAfterInsert();
    }

    private void processHouseholdsAfterInsert() {
        List<Contact> householdInserts = new List<Contact>();
        List<Contact> contactEvaluations = new List<Contact>();
        for (SObject obj : getRecords()) {
            Contact c = (Contact) obj;

            if (needsHousehold(c)) {
                householdInserts.add(c);
            }
            //If the user has chosen for only Contacts connected to Individual Accounts to have Households
            //add them all to a list for evaluation
            else if (needsEvaluation(c)) {
                contactEvaluations.add(c);
            } else if (needsHouseholdNameUpdated(c)) {
                householdsNeedingNamesUpdated.add(householdIdFor(c));
            }
        }

        if (householdsNeedingNamesUpdated.size() > 0) {
            updateHouseholdNames(householdsNeedingNamesUpdated);
        }

        if (householdInserts.size() > 0) {
            insertHouseholdsAfterInsert(householdInserts);
        }

        if (contactEvaluations.size() > 0) {
            insertHouseholdsAfterInsert(
                    getContactsNeedingHouseholds(contactEvaluations));
        }
    }

    private Id householdIdFor(Contact c) {
        return householdIdFor(c);
    }

    private Boolean needsHouseholdNameUpdated(Contact c) {
        return householdIdFor(c) != null;
    }

    private Boolean needsEvaluation(Contact c) {
        return householdIdFor(c) == null &&
                settings.isAllIndividualsProcessor();
    }

    private Boolean needsHousehold(Contact c) {
        return householdIdFor(c) == null
                && settings.isAllProcessor();
    }

    public void buildOldHouseholdCollections() {
        oldHouseholds.addAll(getOldHouseholdIds());
        buildOldHouseholdSizeMap();
    }

    private void buildOldHouseholdSizeMap() {
        for (AggregateResult a : getMemberCountForOldHouseholds()) {
            oldHouseholdSizeById.put((id) a.get('oldhh'), (integer) a.get('membercount'));
        }

        //an agg query doesn't pick empty HHs, so if we have an ID, and no
        //HH in the ag, we know we have an empty hh
        for (id hhid : oldHouseholds) {
            if (!oldHouseholdSizeById.containskey(hhid))
                oldHouseholdSizeById.put(hhid, 0);
        }
    }

    private List<Id> getOldHouseholdIds() {
        List<Id> oldHouseholdIds = new List<Id>();
        for (SObject sobj : getRecords()) {
            Contact c = (Contact) sobj;
            if (oldMap.get(c.id).npo02__household__c != null) {
                oldHouseholdIds.add(oldMap.get(c.id).npo02__household__c);
            }
        }
        return oldHouseholdIds;
    }

    private List<AggregateResult> getMemberCountForOldHouseholds() {
        return [
                SELECT npo02__Household__c oldhh, count(id) membercount
                FROM Contact
                WHERE npo02__Household__c IN :oldHouseholds
                GROUP BY npo02__Household__c
        ];
    }


    private void updateHouseholdNames(List<Id> contactsNeedingHouseholdNamesUpdated) {
        if (isFutureEligible()) {
            HH_HouseholdNaming.FutureUpdateNames(contactsNeedingHouseholdNamesUpdated);
        } else {
            HH_HouseholdNaming hn = new HH_HouseholdNaming();
            hn.UpdateNames(contactsNeedingHouseholdNamesUpdated);
        }
    }

    private Boolean isFutureEligible() {
        return settings.isAsyncEnabled()
                && !system.isFuture() && !system.isBatch();
    }

    private void synchronizeNamingExclusionsFieldsBeforeUpdate() {
        for (Contact con : (List<Contact>) getRecords()) {
            Contact oldCon = oldMap.get(con.Id);

            //first, copy values from checkboxes to the multiselect picklist if checkboxes have changed
            //then, copy from multiselect to checkboxes if multiselect has changed
            //if both have changed, prefers checkboxes
            if (shouldCopyNamingExclusionsFromCheckboxes(con, oldCon)) {
                copyNamingExclusionsFromCheckboxes(con);
            } else if (shouldCopyNamingExclusionsFromMultiSelectPicklist(con, oldCon)) {
                copyNamingExclusionsFromMSP(con);
            }
        }
    }

    private Boolean shouldCopyNamingExclusionsFromMultiSelectPicklist(Contact con, Contact oldCon) {
        return con.npo02__Naming_Exclusions__c != oldCon.npo02__Naming_Exclusions__c;
    }

    private Boolean shouldCopyNamingExclusionsFromCheckboxes(Contact con, Contact oldCon) {
        return con.Exclude_from_Household_Name__c != oldCon.Exclude_from_Household_Name__c ||
                con.Exclude_from_Household_Informal_Greeting__c != oldCon.Exclude_from_Household_Informal_Greeting__c ||
                con.Exclude_from_Household_Formal_Greeting__c != oldCon.Exclude_from_Household_Formal_Greeting__c;
    }

    private void synchronizeNamingExclusionsFieldsBeforeInsert() {
        for (Contact con : (List<Contact>) getRecords()) {
            //first, copy multiselect exclusions to checkboxes, then recreate multiselect values from checboxes
            //this ensures all values from either source are kept
            if (hasNamingExclusions(con)) {
                copyNamingExclusionsFromMSP(con);
            }
            if (shouldCopyNamingExclusionsFromCheckboxesBeforeInsert(con)) {
                copyNamingExclusionsFromCheckboxes(con);
            }
        }
    }

    private Boolean hasNamingExclusions(Contact con) {
        return con.npo02__Naming_Exclusions__c != null;
    }

    private Boolean shouldCopyNamingExclusionsFromCheckboxesBeforeInsert(Contact con) {
        return con.Exclude_from_Household_Name__c || con.Exclude_from_Household_Informal_Greeting__c || con.Exclude_from_Household_Formal_Greeting__c;
    }

    /*******************************************************************************************************
    * @description Copies the values from the naming exclusions multiselect picklist to the individual
    * checkbox fields.
    * @param con The Contact
    * @return void
    ********************************************************************************************************/
    private static void copyNamingExclusionsFromMSP(Contact con) {
        String strExclusions = con.npo02__Naming_Exclusions__c;
        if (strExclusions == null) {
            strExclusions = '';
        }
        con.Exclude_from_Household_Name__c = strExclusions.contains('Household__c.Name');
        con.Exclude_from_Household_Formal_Greeting__c = strExclusions.contains('Household__c.Formal_Greeting__c');
        con.Exclude_from_Household_Informal_Greeting__c = strExclusions.contains('Household__c.Informal_Greeting__c');
    }

    /*******************************************************************************************************
    * @description Copies the values from the naming exclusions checkboxes to the multiselect picklist.
    * @param con The Contact
    * @return void
    ********************************************************************************************************/
    public void copyNamingExclusionsFromCheckboxes() {
        for (SObject sobj : getRecords()) {
            Contact con = (Contact) sobj;
            copyNamingExclusionsFromCheckboxes(con);
        }
    }

    private void copyNamingExclusionsFromCheckboxes(Contact con) {
        String mspValue = '';

        if (con.Exclude_from_Household_Name__c) {
            mspValue += 'Household__c.Name;';
        }
        if (con.Exclude_from_Household_Formal_Greeting__c) {
            mspValue += 'Household__c.Formal_Greeting__c;';
        }
        if (con.Exclude_from_Household_Informal_Greeting__c) {
            mspValue += 'Household__c.Informal_Greeting__c;';
        }

        if (mspValue.endsWith(';')) {
            mspValue = mspValue.subString(0, mspValue.length() - 1);
        }

        con.npo02__Naming_Exclusions__c = mspValue;
    }

    /*******************************************************************************************************
    * @description Creates a new Household Object for each contact, unless excluded by recordType
    * @param contacts List of Contacts
    * @param isInsertTrigger Whether called from the afterInsert trigger (vs. afterUpdate trigger) on Contacts
    * @return void
    ********************************************************************************************************/
    private void insertHouseholdsForContacts(List<Contact> contacts, Boolean isInsertTrigger) {
        List<npo02__Household__c> householdInserts = getHouseholdsForInsert(contacts);
        if (householdInserts.size() > 0) {
            Database.SaveResult[] householdSaveResults =
                    UTIL_DMLService.insertRecords(householdInserts, false);

            List<Contact> contactsToBeUpdatedWithHouseholdId =
                    processHouseholdSaveResults(contacts, householdSaveResults);
            update contactsToBeUpdatedWithHouseholdId;

            if (isInsertTrigger) {
                updateNamesAfterHouseholdInsert(householdSaveResults);
            }
        }
    }

    private List<Contact> processHouseholdSaveResults(List<Contact> contacts,
            Database.SaveResult[] householdSaveResults) {
        List<Contact> contactsToBeUpdatedWithHouseholdId = new List<Contact>();
        Integer i = 0;
        for (Contact c : contacts) {
            if (isExclusion(c)) {
                Database.SaveResult saveResult = householdSaveResults[i];
                if (saveResult.isSuccess() == true) {
                    //write the new Household Ids to the Contacts
                    Contact cloneContact = c.Clone(true, false);
                    cloneContact.npo02__household__c = saveResult.getId();
                    contactsToBeUpdatedWithHouseholdId.add(cloneContact);
                } else {
                    Database.Error err = saveResult.getErrors()[0];
                    c.addError(err.getMessage());
                }
                i += 1;
            }
        }
        return contactsToBeUpdatedWithHouseholdId;
    }

    private void updateNamesAfterHouseholdInsert(Database.SaveResult[] lsr) {
        List<Id> householdIdsNeedingNamesUpdated = getHouseholdIdsNeedingNamesUpdated(lsr);
        if (!householdIdsNeedingNamesUpdated.isEmpty()) {
            updateHouseholdNames(householdIdsNeedingNamesUpdated);
        }
    }

    private List<Id> getHouseholdIdsNeedingNamesUpdated(Database.SaveResult[] lsr) {
        List<Id> householdIdsNeedingNamesUpdated = new List<Id>();
        for (Database.SaveResult sr : lsr) {
            if (sr.isSuccess())
                householdIdsNeedingNamesUpdated.add(sr.getID());
        }
        return householdIdsNeedingNamesUpdated;
    }

    private List<npo02__Household__c> getHouseholdsForInsert(List<Contact> contacts) {
        List<npo02__household__c> householdInserts_local = new List<npo02__household__c>();
        for (Contact c : contacts) {
            if (isExclusion(c)) {
                npo02__Household__c h = getHouseholdForInsertFromContact(c);
                householdInserts_local.add(h);
            }
        }
        return householdInserts_local;
    }

    private Boolean isExclusion(Contact c) {
        return !isRecordTypesOnContacts()
                || !settings.contactRecordTypesToExclude().contains((id) c.get(RECORDTYPEID));
    }

    private Boolean isRecordTypesOnContacts() {
        return Schema.sObjectType.Contact.fields.getMap().get(RECORDTYPEID) != null;
    }

    private static npo02__Household__c getHouseholdForInsertFromContact(Contact c) {
        npo02__household__c h = new npo02__household__c();
        String hName = c.LastName;
        hName += ' ' + system.label.npo02.DefaultHouseholdName;
        h.Name = hName;
        //sync the primary address block
        h.npo02__MailingStreet__c = c.MailingStreet;
        h.npo02__MailingCity__c = c.MailingCity;
        h.npo02__MailingState__c = c.MailingState;
        h.npo02__MailingPostalCode__c = c.MailingPostalCode;
        h.npo02__MailingCountry__c = c.MailingCountry;
        h.npo02__HouseholdPhone__c = c.HomePhone;
        h.npo02__HouseholdEmail__c = c.Email;
        return h;
    }

    /*******************************************************************************************************
    * @description Determines if a Contact Should have a household object created
    * @param contacts List of Contacts
    * @param isAfterTrigger Whether called from the afterInsert trigger (vs. afterUpdate trigger) on Contacts
    * @param dmlWrapper Not used. Commits are immediate.
    * @return void
    ********************************************************************************************************/
    public void insertHouseholdsAfterInsert(List<Contact> contacts) {
        insertHouseholdsForContacts(contacts, true);
    }

    private Map<Id, Account> getContactAccountMap(List<Contact> contacts) {
        List<Id> accountIds = getAccountIds(contacts);
        //todo: accountSelector
        Map<Id, Account> contactAccountMap = new Map<Id, Account>([Select Id, npe01__SYSTEMIsIndividual__c, Name from Account where Id in :accountIds]);
        return contactAccountMap;
    }

    private List<Id> getAccountIds(List<Contact> contacts) {
        List<Id> accountIds = new List<Id>();
        for (Contact c : contacts) {
            if (c.accountId != null) {
                accountIds.add(c.AccountId);
            }
        }
        return accountIds;
    }

    private List<Contact> getContactsNeedingHouseholds(List<Contact> contacts) {
        //get all the Accounts so we can test to see if they are individuals
        Map<Id, Account> contactAccountMap = getContactAccountMap(contacts);

        List<Contact> householdInserts = new List<Contact>();
        for (Contact c : contacts) {
            if (c.AccountId != null) {
                Account acc = contactAccountMap.get(c.AccountId);
                //check the system field on Account to see if the account is an individual
                if (acc.npe01__SYSTEMIsIndividual__c == true) {
                    householdInserts.add(c);
                }
            } else if (c.AccountId == null) {
                householdInserts.add(c);
            }
        }
        return householdInserts;
    }

    List<npo02__Household__c> emptyHouseholdsToDelete = new List<npo02__Household__c>();
    List<Contact> deletedContactsInHouseholds = new List<Contact>();
    List<Contact> contactEvaluations = new List<Contact>();
    Set<Id> mergedWinningContact = new Set<Id>();
    public TDTM_Runnable.DmlWrapper handleAfterUpdate(TDTM_Runnable.DmlWrapper dmlWrapper) {

        //if its an update, we need to get some data about their
        //old Household for processing
        buildOldHouseholdCollections();
        processHouseholdAndNamingFieldChangesAfterUpdate();

        dmlWrapper.objectsToDelete.addAll(emptyHouseholdsToDelete);

        contactsNeedingHouseholds.addAll(getContactsNeedingHouseholds(contactEvaluations));
        insertHouseholdsForContacts(contactsNeedingHouseholds, false);

        // Note: This set will contain Household__c record Id's only (i.e., legacy models)
        if (householdIdsNeedingRollup.size() > 0) {
            calculateRollups();
        }

        if (householdsNeedingNamesUpdated.size() > 0) {
            updateHouseholdNames(householdsNeedingNamesUpdated);
        }
        return dmlWrapper;
    }

    public void rollupAndRenameHouseholdsAfterDelete(TDTM_Runnable.DmlWrapper dmlWrapper) {
        buildDeletedAndMergedContactCollections();

        if (mergedWinningContact.size() > 0) {
            // this fires off opp rollups, which we aren't going to move to dmlWrapper!
            contactMergeUpdate(mergedWinningContact);
        }

        if (deletedContactsInHouseholds.size() > 0) {
            deleteOrRenameHouseholdsWhenContactDeleted(
                    deletedContactsInHouseholds, dmlWrapper);
        }
    }

    private void processHouseholdAndNamingFieldChangesAfterUpdate() {
        for (Contact c : (List<Contact>) getRecords()) {
            //if we're doing an update, pile up all of the households into a list
            //and send it to our naming code for action
            //first contact's names to their old names, and see if anything changed
            //salutation
            if (!hasHousehold(c)) {
                handleContactHasNoHousehold(c);
            }

            //if they've changed households, we need to query the old
            //household to see if anybody is left, if so, send it for renaming
            //if not, delete it.
            if (householdChanged(c)) {
                handleHouseholdChanged(c);
            } else if (isHouseholdNamingFieldsChanged(c)) {
                householdsNeedingNamesUpdated.add(householdIdFor(c));
            }
        }
    }

    private Boolean isHouseholdNamingFieldsChanged(Contact c) {
        return isNamingExclusionsChanged(c) || isNamingFieldChanged(c);
    }

    Set<String> householdNamingFieldsInUse;
    private Boolean isNamingFieldChanged(Contact c) {
        if (householdNamingFieldsInUse == null) {
            householdNamingFieldsInUse =
                    new HH_HouseholdNaming().getHouseholdNamingContactFields();
        }

        Boolean namingFieldChanged = false;
        if (hasHousehold(c)) {
            for (String fieldName : householdNamingFieldsInUse) {
                Boolean fieldChanged = isFieldChanged(c, fieldName);
                if (fieldChanged) {
                    namingFieldChanged = true;
                    break;
                }
            }
        }
        return namingFieldChanged;
    }

    private Boolean isFieldChanged(Contact c, String fieldName) {
        // make sure to use case sensitive comparison
        String strName = getNewFieldValue(c, fieldName);
        String strNameOld = getOldFieldValue(c, fieldName);
        Boolean isChanged = !strName.equals(strNameOld);
        return isChanged;
    }

    private Boolean hasHousehold(Contact c) {
        return householdIdFor(c) != null;
    }

    private Boolean isNamingExclusionsChanged(Contact c) {
        return c.npo02__Naming_Exclusions__c != oldMap.get(c.id).npo02__Naming_Exclusions__c;
    }

    private void handleHouseholdChanged(Contact c) {
        householdsNeedingNamesUpdated.add(householdIdFor(c));
        householdIdsNeedingRollup.add(householdIdFor(c));

        Id oldHouseholdId = getOldHouseholdId(oldMap, c);
        if (oldHouseholdNeedsRefresh(oldHouseholdSizeById, oldMap, c)) {
            householdsNeedingNamesUpdated.add(oldHouseholdId);
            householdIdsNeedingRollup.add(oldHouseholdId);
        } else if (oldHouseholdIsEmpty(oldHouseholdSizeById, oldMap, c)) {
            emptyHouseholdsToDelete.add(new npo02__Household__c(Id = oldHouseholdId));
        }
    }

    private Boolean oldHouseholdIsEmpty(Map<Id, Integer> oldHouseholdSize, Map<Id, Contact> oldcmap, Contact c) {
        return oldHouseholdSize.get(oldcmap.get(c.id).npo02__household__c) == 0;
    }

    private Id getOldHouseholdId(Map<Id, Contact> oldcmap, Contact c) {
        return oldcmap.get(c.id).npo02__household__c;
    }

    private Boolean oldHouseholdNeedsRefresh(Map<Id, Integer> oldHouseholdSize, Map<Id, Contact> oldcmap, Contact c) {
        return oldHouseholdSize.get(oldcmap.get(c.id).npo02__household__c) > 0;
    }

    private void handleContactHasNoHousehold(Contact c) {
        if (settings.isAllProcessor()) {
            contactsNeedingHouseholds.add(c);
        } else if (settings.isAllIndividualsProcessor()) {
            contactEvaluations.add(c);
        }
    }

    private void buildDeletedAndMergedContactCollections() {
        for (Contact c : (List<Contact>) getRecords()) {
            if (householdIdFor(c) != null) {
                deletedContactsInHouseholds.add(c);
            }

            //check if this Contact is the loser in a merge
            if (c.MasterRecordId != null) {
                mergedWinningContact.add(c.MasterRecordId);
            }
        }
    }

    private Boolean householdChanged(Contact c) {
        return householdIdFor(c) != oldMap.get(c.id).npo02__household__c;
    }

    private String getOldFieldValue(Contact c, String fieldName) {
        String strNameOld = String.valueOf(oldMap.get(c.id).get(fieldName));
        if (strNameOld == null) {
            strNameOld = '';
        }
        return strNameOld;
    }

    private String getNewFieldValue(Contact c, String fieldName) {
        String strName = String.valueOf(c.get(fieldName));
        if (strName == null) {
            strName = '';
        }
        return strName;
    }

    private void calculateRollups() {
        if (System.isFuture() || System.isBatch() || householdIdsNeedingRollup.size() <= 2) {
            RLLP_OppRollup_UTIL oppRollupUtil = new RLLP_OppRollup_UTIL();
            Map<Id, npo02__Household__c> hhmap = new Map<Id, npo02__Household__c>(
                    (List<npo02__Household__c>) Database.query(oppRollupUtil.buildHouseholdQuery() +
                            ' WHERE Id IN :householdIdsNeedingRollup'));
            RLLP_OppRollup rg = new RLLP_OppRollup();
            rg.rollupHouseholds(hhmap);
        } else {
            RLLP_OppRollup.rollupHouseholdsFuture(householdIdsNeedingRollup);
        }
    }

    /*******************************************************************************************************
    * @description Deletes a Household object when no Contacts are related to it. Called by the AfterDelete
    * trigger handler on Contact.  Also detects if other Contacts remain in the Household, and thus the
    * Household needs its names updated.
    * @param contacts List of Contacts being deleted
    * @param dmlWrapper On return, holds the Households to delete.
    * @return void
    ********************************************************************************************************/
    public void deleteOrRenameHouseholdsWhenContactDeleted(List<Contact> contacts, TDTM_Runnable.DmlWrapper dmlWrapper) {

        List<SObject> householdDeletes = new List<SObject>();
        Map<Id, Integer> householdCountMap = new Map<Id, Integer>();
        List<id> contactsNeedingHouseholdsRenamed = new List<id>();

        //Generate a list of Household Ids
        for (Contact c : contacts) {
            if (householdIdFor(c) != null)
                householdCountMap.put(householdIdFor(c), 0);
        }

        //Loop through all Contacts at one of the Household Ids
        for (Contact c : [Select Id, npo02__Household__c from Contact where npo02__Household__c in :householdCountMap.keyset()]) {
            Integer lastCount = householdCountMap.get(householdIdFor(c));
            lastCount += 1;
            householdCountMap.put(householdIdFor(c), lastCount);
        }

        //Loop through all the contacts to determine if they can be deleted
        for (Contact c : contacts) {
            if (householdCountMap.get(householdIdFor(c)) < 1) {
                //If there are no other Contacts on the Account
                householdDeletes.add(new npo02__Household__c(Id = householdIdFor(c)));
            } else {
                //otherwise, we need to update the household
                contactsNeedingHouseholdsRenamed.add(householdIdFor(c));
            }
        }

        if (householdDeletes.size() > 0) {
            dmlWrapper.objectsToDelete.addAll(householdDeletes);
        }

        if (contactsNeedingHouseholdsRenamed.size() > 0) {
            updateHouseholdNames(contactsNeedingHouseholdsRenamed);
        }
    }

    /*******************************************************************************************************
     * @description kicks off Opportunity Rollups after contacts have been merged, but only if NOT using
     * the Household Account model
     * @param winningContacts Set of Contact Id's
     * @return void
     ********************************************************************************************************/
    public static void contactMergeUpdate(Set<Id> winningContacts) {

        npe01__Contacts_And_Orgs_Settings__c candoSettings = UTIL_CustomSettingsFacade.getContactsSettings();
        if (candoSettings.npe01__Account_Processor__c == CAO_Constants.HH_ACCOUNT_PROCESSOR) {
            return;
        }

        Set<Id> oppIds = new Set<Id>();
        for (OpportunityContactRole ocr : [
                SELECT OpportunityId
                FROM OpportunityContactRole
                WHERE ContactId IN :winningContacts AND IsPrimary = True
        ]
        ) {
            oppIds.add(ocr.OpportunityId);
        }

        if (!oppIds.isEmpty()) {
            if (System.isFuture() || System.isBatch()) {
                RLLP_OppRollup.rollupContactsandHouseholdsForTrigger(oppIds);
            } else {
                RLLP_OppRollup.rollupContactsandHouseholdsForTriggerFuture(oppIds);
            }
        }
    }
}