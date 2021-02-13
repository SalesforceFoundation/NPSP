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
public inherited sharing class Contacts extends fflib_SObjects {

    private HouseholdSettings settings;
    private Map<Id, Contact> oldMap;
    private List<Contact> contactsNeedingHouseholds = new List<Contact>();
    private List<Id> householdsNeedingNamesUpdated = new List<Id>();
    private Set<Id> householdIdsNeedingRollup = new Set<Id>();
    private List<Id> oldHouseholds = new List<Id>();
    private Map<Id, Integer> oldHouseholdSizeById = new Map<Id, Integer>();
    private final String RECORD_TYPE_ID = 'RecordTypeId';
    private List<npo02__Household__c> emptyHouseholdsToDelete = new List<npo02__Household__c>();
    private List<Contact> deletedContactsInHouseholds = new List<Contact>();
    private List<Contact> contactEvaluations = new List<Contact>();
    private Set<Id> mergedWinningContact = new Set<Id>();
    private Set<String> householdNamingFieldsInUse;

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
        List<Contact> householdInserts = getHouseholdInserts();
        List<Contact> contactEvaluations = getContactEvaluations();
        updateHouseholdsNeedingNameUpdates();

        if (householdInserts.size() > 0) {
            insertHouseholdsForContacts(householdInserts, true);
        }

        if (contactEvaluations.size() > 0) {
            insertHouseholdsForContacts(
                    getContactsNeedingHouseholds(contactEvaluations), true);
        }
    }

    private void updateHouseholdsNeedingNameUpdates() {
        List<Id> householdsNeedingNamesUpdated = getHouseholdsNeedingNamesUpdated();

        if (householdsNeedingNamesUpdated.size() > 0) {
            updateHouseholdNames(householdsNeedingNamesUpdated);
        }
    }

    private List<Id> getHouseholdsNeedingNamesUpdated() {
        List<Id> householdsNeedingNamesUpdated = new List<Id>();
        for (Contact con : (List<Contact>) getRecords()) {
            //If the user has chosen for only Contacts connected to Individual Accounts to have Households
            //add them all to a list for evaluation
            if (needsHouseholdNameUpdated(con)) {
                householdsNeedingNamesUpdated.add(householdIdFor(con));
            }
        }
        return householdsNeedingNamesUpdated;
    }

    private List<Contact> getContactEvaluations() {
        List<Contact> contactEvaluations = new List<Contact>();
        for (Contact con : (List<Contact>) getRecords()) {
            //If the user has chosen for only Contacts connected to Individual Accounts to have Households
            //add them all to a list for evaluation
            if (needsEvaluation(con)) {
                contactEvaluations.add(con);
            }
        }
        return contactEvaluations;
    }

    private List<Contact> getHouseholdInserts() {
        List<Contact> householdInserts = new List<Contact>();
        for (Contact con : (List<Contact>) getRecords()) {
            if (needsHousehold(con)) {
                householdInserts.add(con);
            }
        }
        return householdInserts;
    }

    private Id householdIdFor(Contact con) {
        return con.npo02__Household__c;
    }

    private Boolean needsHouseholdNameUpdated(Contact con) {
        return householdIdFor(con) != null;
    }

    private Boolean needsEvaluation(Contact con) {
        return householdIdFor(con) == null &&
                settings.isAllIndividualsProcessor();
    }

    private Boolean needsHousehold(Contact con) {
        return householdIdFor(con) == null
                && settings.isAllProcessor();
    }

    private void buildOldHouseholdCollections() {
        oldHouseholds.addAll(getOldHouseholdIds());
        buildOldHouseholdSizeMap();
    }

    private void buildOldHouseholdSizeMap() {
        for (AggregateResult aggregateResult : getMemberCountForOldHouseholds()) {
            oldHouseholdSizeById.put(
                    oldHouseholdIdFrom(aggregateResult),
                    memberCountFrom(aggregateResult));
        }

        populateOldHouseholdSizeMapForEmptyHouseholds();
    }

    private void populateOldHouseholdSizeMapForEmptyHouseholds() {
        for (Id hhid : oldHouseholds) {
            if (oldHouseholdIsEmpty(hhid))
                oldHouseholdSizeById.put(hhid, 0);
        }
    }

    private Boolean oldHouseholdIsEmpty(Id hhid) {
        return !oldHouseholdSizeById.containskey(hhid);
    }

    private Integer memberCountFrom(AggregateResult a) {
        return (Integer) a.get('membercount');
    }

    private Id oldHouseholdIdFrom(AggregateResult a) {
        return (Id) a.get('oldhh');
    }

    private List<Id> getOldHouseholdIds() {
        List<Id> oldHouseholdIds = new List<Id>();
        for (SObject sobj : getRecords()) {
            Contact con = (Contact) sobj;
            if (conWasInAHousehold(con)) {
                oldHouseholdIds.add(oldHouseholdIdFor(con));
            }
        }
        return oldHouseholdIds;
    }

    private Id oldHouseholdIdFor(Contact con) {
        return oldVersionOf(con).npo02__Household__c;
    }

    private Boolean conWasInAHousehold(Contact con) {
        return oldHouseholdIdFor(con) != null;
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
            HH_HouseholdNaming.updateHouseholdNamesAsynchronously(contactsNeedingHouseholdNamesUpdated);
        } else {
            HH_HouseholdNaming hn = new HH_HouseholdNaming();
            hn.updateHouseholdNames(contactsNeedingHouseholdNamesUpdated);
        }
    }

    private Boolean isFutureEligible() {
        return settings.isAsyncEnabled()
                && !System.isFuture() && !System.isBatch();
    }

    private void synchronizeNamingExclusionsFieldsBeforeUpdate() {
        for (Contact con : (List<Contact>) getRecords()) {
            //first, copy values from checkboxes to the multiselect picklist if checkboxes have changed
            //then, copy from multiselect to checkboxes if multiselect has changed
            //if both have changed, prefers checkboxes
            if (shouldCopyNamingExclusionsFromCheckboxes(con)) {
                copyNamingExclusionsFromCheckboxes(con);
            } else if (shouldCopyNamingExclusionsFromMultiSelectPicklist(con)) {
                synchronizeNamingExclusionStringToCheckboxes(
                        new HouseholdNamingExclusions(namingExclusionsFor(con)), con);
            }
        }
    }

    private Boolean shouldCopyNamingExclusionsFromMultiSelectPicklist(Contact con) {
        HouseholdNamingExclusions consHouseholdNamingExclusions =
                new HouseholdNamingExclusions(namingExclusionsFor(con));
        return consHouseholdNamingExclusions.isNotEqualTo(
                namingExclusionsFor(oldVersionOf(con)));
    }

    private Boolean shouldCopyNamingExclusionsFromCheckboxes(Contact con) {
        return isExcludedFromHouseholdName(con) != isExcludedFromHouseholdName(oldVersionOf(con)) ||
                isExcludedFromInformalGreeting(con) != isExcludedFromInformalGreeting(oldVersionOf(con)) ||
                isExcludedFromFormalGreeting(con) != isExcludedFromFormalGreeting(oldVersionOf(con));
    }

    private Boolean isExcludedFromFormalGreeting(Contact con) {
        return con.Exclude_from_Household_Formal_Greeting__c;
    }

    private Boolean isExcludedFromInformalGreeting(Contact con) {
        return con.Exclude_from_Household_Informal_Greeting__c;
    }

    private Boolean isExcludedFromHouseholdName(Contact con) {
        return con.Exclude_from_Household_Name__c;
    }

    private void synchronizeNamingExclusionsFieldsBeforeInsert() {
        for (Contact con : (List<Contact>) getRecords()) {
            HouseholdNamingExclusions exclusions =
                    new HouseholdNamingExclusions(namingExclusionsFor(con));
            if (exclusions.hasNamingExclusions()) {
                synchronizeNamingExclusionStringToCheckboxes(exclusions, con);
            }
            if (hasExclusionCheckboxesChecked(con)) {
                copyNamingExclusionsFromCheckboxes(con);
            }
        }
    }

    private Boolean hasExclusionCheckboxesChecked(Contact con) {
        return isExcludedFromHouseholdName(con)
                || isExcludedFromInformalGreeting(con)
                || isExcludedFromFormalGreeting(con);
    }

    private static void synchronizeNamingExclusionStringToCheckboxes(
            HouseholdNamingExclusions exclusions, Contact con) {
        con.Exclude_from_Household_Name__c = exclusions.isNameExcluded();
        con.Exclude_from_Household_Formal_Greeting__c = exclusions.isFormalGreetingExcluded();
        con.Exclude_from_Household_Informal_Greeting__c = exclusions.isInformalGreetingExcluded();
    }

    private static String namingExclusionsFor(Contact con) {
        return con.npo02__Naming_Exclusions__c;
    }

    /*******************************************************************************************************
    * @description Copies the values from the naming exclusions checkboxes to the multiselect picklist.
    ********************************************************************************************************/
    public void copyNamingExclusionsFromCheckboxes() {
        for (SObject sobj : getRecords()) {
            Contact con = (Contact) sobj;
            copyNamingExclusionsFromCheckboxes(con);
        }
    }

    private void copyNamingExclusionsFromCheckboxes(Contact con) {
        HouseholdNamingExclusions exclusions = buildNamingExclusionsFromCheckboxesFor(con);
        con.npo02__Naming_Exclusions__c = exclusions.getDisplayValue();
    }

    private HouseholdNamingExclusions buildNamingExclusionsFromCheckboxesFor(Contact con) {
        HouseholdNamingExclusions exclusions = new HouseholdNamingExclusions(null);
        if (isExcludedFromHouseholdName(con)) {
            exclusions.excludeName();
        }
        if (isExcludedFromFormalGreeting(con)) {
            exclusions.excludeFormalGreeting();
        }
        if (isExcludedFromInformalGreeting(con)) {
            exclusions.excludeInformalGreeting();
        }
        return exclusions;
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
            Database.SaveResult[] householdSaveResults = insertHouseholds(householdInserts);
            putHouseholdIdOntoContacts(contacts, householdSaveResults);
            if (isInsertTrigger) {
                updateNamesAfterHouseholdInsert(householdSaveResults);
            }
        }
    }

    private Database.SaveResult[] insertHouseholds(List<npo02__Household__c> householdInserts) {
        Database.SaveResult[] householdSaveResults =
                UTIL_DMLService.insertRecords(householdInserts, false);
        return householdSaveResults;
    }

    private void putHouseholdIdOntoContacts(List<Contact> contacts, Database.SaveResult[] householdSaveResults) {
        List<Contact> contactsToBeUpdatedWithHouseholdId =
                processHouseholdSaveResults(contacts, householdSaveResults);
        update contactsToBeUpdatedWithHouseholdId;
    }

    private List<Contact> processHouseholdSaveResults(List<Contact> contacts,
            Database.SaveResult[] householdSaveResults) {
        List<Contact> contactsToBeUpdatedWithHouseholdId = new List<Contact>();
        Integer i = 0;
        for (Contact con : contacts) {
            if (isExclusion(con)) {
                Database.SaveResult saveResult = householdSaveResults[i];
                if (saveResult.isSuccess() == true) {
                    //write the new Household Ids to the Contacts
                    Contact cloneContact = con.Clone(true, false);
                    cloneContact.npo02__household__c = saveResult.getId();
                    contactsToBeUpdatedWithHouseholdId.add(cloneContact);
                } else {
                    Database.Error err = saveResult.getErrors()[0];
                    con.addError(err.getMessage());
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
        for (Contact con : contacts) {
            if (isExclusion(con)) {
                householdInserts_local.add(getHouseholdForInsertFromContact(con));
            }
        }
        return householdInserts_local;
    }

    private Boolean isExclusion(Contact con) {
        return !isRecordTypesOnContacts()
                || !settings.contactRecordTypesToExclude().contains(recordTypeIdFor(con));
    }

    private Id recordTypeIdFor(Contact con) {
        return (Id) con.get(RECORD_TYPE_ID);
    }

    private Boolean isRecordTypesOnContacts() {
        return Schema.sObjectType.Contact.fields.getMap().get(RECORD_TYPE_ID) != null;
    }

    private npo02__Household__c getHouseholdForInsertFromContact(Contact con) {
        npo02__household__c household = new npo02__household__c(Name = getDefaultHouseholdName(con));
        syncPrimaryAddressBlock(household, con);
        return household;
    }

    private void syncPrimaryAddressBlock(npo02__Household__c household, Contact con) {
        household.npo02__MailingStreet__c = con.MailingStreet;
        household.npo02__MailingCity__c = con.MailingCity;
        household.npo02__MailingState__c = con.MailingState;
        household.npo02__MailingPostalCode__c = con.MailingPostalCode;
        household.npo02__MailingCountry__c = con.MailingCountry;
        household.npo02__HouseholdPhone__c = con.HomePhone;
        household.npo02__HouseholdEmail__c = con.Email;
    }

    private static String getDefaultHouseholdName(Contact con) {
        String hName = con.LastName;
        return hName += ' ' + System.Label.npo02.DefaultHouseholdName;
    }

    public void insertHouseholdsAfterInsert(List<Contact> contacts) {
        insertHouseholdsForContacts(contacts, true);
    }

    private Map<Id, Account> getContactAccountMap(List<Contact> contacts) {
        List<Id> accountIds = getAccountIds(contacts);
        Map<Id, Account> contactAccountMap = new Map<Id, Account>([
                SELECT Id, npe01__SYSTEMIsIndividual__c, Name
                FROM Account
                WHERE Id IN :accountIds
        ]);
        return contactAccountMap;
    }

    private List<Id> getAccountIds(List<Contact> contacts) {
        List<Id> accountIds = new List<Id>();
        for (Contact con : contacts) {
            if (con.AccountId != null) {
                accountIds.add(con.AccountId);
            }
        }
        return accountIds;
    }

    private List<Contact> getContactsNeedingHouseholds(List<Contact> contacts) {
        Map<Id, Account> contactAccountMap = getContactAccountMap(contacts);

        List<Contact> householdInserts = new List<Contact>();
        for (Contact con : contacts) {
            if (hasAccount(con)) {
                Account acc = contactAccountMap.get(con.AccountId);
                if (isIndividualAccount(acc)) {
                    householdInserts.add(con);
                }
            } else {
                householdInserts.add(con);
            }
        }
        return householdInserts;
    }

    private Boolean hasAccount(Contact con) {
        return con.AccountId != null;
    }

    private Boolean isIndividualAccount(Account acc) {
        return acc.npe01__SYSTEMIsIndividual__c == true;
    }

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
            rollupContactsAndHouseholdsAfterMerge(mergedWinningContact);
        }

        if (deletedContactsInHouseholds.size() > 0) {
            deleteOrRenameHouseholdsWhenContactDeleted(
                    deletedContactsInHouseholds, dmlWrapper);
        }
    }

    private void processHouseholdAndNamingFieldChangesAfterUpdate() {
        for (Contact con : (List<Contact>) getRecords()) {
            //if we're doing an update, pile up all of the households into a list
            //and send it to our naming code for action
            //first contact's names to their old names, and see if anything changed
            //salutation
            if (!hasHousehold(con)) {
                handleContactHasNoHousehold(con);
            }

            //if they've changed households, we need to query the old
            //household to see if anybody is left, if so, send it for renaming
            //if not, delete it.
            if (householdChanged(con)) {
                handleHouseholdChanged(con);
            } else if (isHouseholdNamingFieldsChanged(con)) {
                householdsNeedingNamesUpdated.add(householdIdFor(con));
            }
        }
    }

    private Boolean isHouseholdNamingFieldsChanged(Contact con) {
        return isNamingExclusionsChanged(con) || isNamingFieldChanged(con);
    }

    private Boolean isNamingFieldChanged(Contact con) {
        if (householdNamingFieldsInUse == null) {
            householdNamingFieldsInUse =
                    new HH_HouseholdNaming().getHouseholdNamingContactFields();
        }

        Boolean namingFieldChanged = false;
        if (hasHousehold(con)) {
            for (String fieldName : householdNamingFieldsInUse) {
                if (isFieldChanged(con, fieldName)) {
                    namingFieldChanged = true;
                    break;
                }
            }
        }
        return namingFieldChanged;
    }

    private Boolean isFieldChanged(Contact con, String fieldName) {
        // make sure to use case sensitive comparison
        String strName = getNewFieldValue(con, fieldName);
        String strNameOld = getOldFieldValue(con, fieldName);
        Boolean isChanged = !strName.equals(strNameOld);
        return isChanged;
    }

    private Boolean hasHousehold(Contact con) {
        return householdIdFor(con) != null;
    }

    private Boolean isNamingExclusionsChanged(Contact con) {
        HouseholdNamingExclusions exclusions =
                new HouseholdNamingExclusions(namingExclusionsFor(con));
        return exclusions.isNotEqualTo(namingExclusionsFor(oldVersionOf(con)));
    }

    private void handleHouseholdChanged(Contact con) {
        householdsNeedingNamesUpdated.add(householdIdFor(con));
        householdIdsNeedingRollup.add(householdIdFor(con));

        if (oldHouseholdNeedsRefresh(con)) {
            householdsNeedingNamesUpdated.add(oldHouseholdIdFor(con));
            householdIdsNeedingRollup.add(oldHouseholdIdFor(con));
        } else if (oldHouseholdIsEmpty(con)) {
            emptyHouseholdsToDelete.add(new npo02__Household__c(Id = oldHouseholdIdFor(con)));
        }
    }

    private Boolean oldHouseholdIsEmpty(Contact con) {
        return oldHouseholdSizeById.get(oldHouseholdIdFor(con)) == 0;
    }

    private Boolean oldHouseholdNeedsRefresh(Contact con) {
        return oldHouseholdSizeById.get(oldHouseholdIdFor(con)) > 0;
    }

    private void handleContactHasNoHousehold(Contact con) {
        if (settings.isAllProcessor()) {
            contactsNeedingHouseholds.add(con);
        } else if (settings.isAllIndividualsProcessor()) {
            contactEvaluations.add(con);
        }
    }

    private void buildDeletedAndMergedContactCollections() {
        for (Contact con : (List<Contact>) getRecords()) {
            if (householdIdFor(con) != null) {
                deletedContactsInHouseholds.add(con);
            }

            if (isLosingRecordInMergeOperation(con)) {
                mergedWinningContact.add(con.MasterRecordId);
            }
        }
    }

    private Boolean isLosingRecordInMergeOperation(Contact con) {
        return con.MasterRecordId != null;
    }

    private Boolean householdChanged(Contact con) {
        return householdIdFor(con) != oldHouseholdIdFor(con);
    }

    private String getOldFieldValue(Contact con, String fieldName) {
        String strNameOld = String.valueOf(oldVersionOf(con).get(fieldName));
        return strNameOld == null ? '' : strNameOld;
    }

    private Contact oldVersionOf(Contact con) {
        return oldMap.get(con.Id);
    }

    private String getNewFieldValue(Contact con, String fieldName) {
        String strName = String.valueOf(con.get(fieldName));
        return strName == null ? '' : strName;
    }

    private void calculateRollups() {
        if (rollupsShouldRunSynchronously()) {
            RLLP_OppRollup rg = new RLLP_OppRollup();
            rg.rollupHouseholds(getHouseholdMap());
        } else {
            RLLP_OppRollup.rollupHouseholdsFuture(householdIdsNeedingRollup);
        }
    }

    private Map<Id, npo02__Household__c> getHouseholdMap() {
        RLLP_OppRollup_UTIL oppRollupUtil = new RLLP_OppRollup_UTIL();
        Map<Id, npo02__Household__c> hhmap = new Map<Id, npo02__Household__c>(
                (List<npo02__Household__c>) Database.query(oppRollupUtil.buildHouseholdQuery() +
                        ' WHERE Id IN :householdIdsNeedingRollup'));
        return hhmap;
    }

    private Boolean rollupsShouldRunSynchronously() {
        return System.isFuture() || System.isBatch() || householdIdsNeedingRollup.size() <= 2;
    }

    /*******************************************************************************************************
    * @description Deletes a Household object when no Contacts are related to it. Called by the AfterDelete
    * trigger handler on Contact.  Also detects if other Contacts remain in the Household, and thus the
    * Household needs its names updated.
    * @param cons List of Contacts being deleted
    * @param dmlWrapper On return, holds the Households to delete.
    * @return void
    ********************************************************************************************************/
    public void deleteOrRenameHouseholdsWhenContactDeleted(List<Contact> cons, TDTM_Runnable.DmlWrapper dmlWrapper) {
        List<SObject> householdDeletes = new List<SObject>();
        List<id> contactsNeedingHouseholdsRenamed = new List<id>();

        Map<Id, Integer> householdCountMap = getHouseholdCountMap(cons);
        for (Contact con : cons) {
            if (householdIsEmpty(householdCountMap, con)) {
                householdDeletes.add(new npo02__Household__c(Id = householdIdFor(con)));
            } else {
                contactsNeedingHouseholdsRenamed.add(householdIdFor(con));
            }
        }

        if (householdDeletes.size() > 0) {
            dmlWrapper.objectsToDelete.addAll(householdDeletes);
        }

        if (contactsNeedingHouseholdsRenamed.size() > 0) {
            updateHouseholdNames(contactsNeedingHouseholdsRenamed);
        }
    }

    private Boolean householdIsEmpty(Map<Id, Integer> householdCountMap, Contact con) {
        return householdCountMap.get(householdIdFor(con)) < 1;
    }

    private List<Contact> getContactsWithHouseholdIds(Map<Id, Integer> householdCountMap) {
        return [
                SELECT Id, npo02__Household__c
                FROM Contact
                WHERE npo02__Household__c IN :householdCountMap.keyset()
        ];
    }

    private Map<Id, Integer> getHouseholdCountMap(List<Contact> contacts) {
        Map<Id, Integer> householdCountMap = new Map<Id, Integer>();
        for (Contact con : contacts) {
            if (householdIdFor(con) != null)
                householdCountMap.put(householdIdFor(con), 0);
        }
        for (Contact con : getContactsWithHouseholdIds(householdCountMap)) {
            Integer lastCount = householdCountMap.get(householdIdFor(con));
            lastCount += 1;
            householdCountMap.put(householdIdFor(con), lastCount);
        }
        return householdCountMap;
    }

    /*******************************************************************************************************
     * @description kicks off Opportunity Rollups after contacts have been merged, but only if NOT using
     * the Household Account model
     * @param winningContacts Set of Contact Id's
     * @return void
     ********************************************************************************************************/
    @TestVisible
    private static void rollupContactsAndHouseholdsAfterMerge(Set<Id> winningContacts) {

        npe01__Contacts_And_Orgs_Settings__c contactsAndOrgsSettings =
                UTIL_CustomSettingsFacade.getContactsSettings();
        if (contactsAndOrgsSettings.npe01__Account_Processor__c ==
                CAO_Constants.HH_ACCOUNT_PROCESSOR) {
            return;
        }

        Set<Id> oppIds = getOppIdsForWinningContacts(winningContacts);
        if (!oppIds.isEmpty()) {
            if (System.isFuture() || System.isBatch()) {
                RLLP_OppRollup.rollupContactsandHouseholdsForTrigger(oppIds);
            } else {
                RLLP_OppRollup.rollupContactsandHouseholdsForTriggerFuture(oppIds);
            }
        }
    }

    private static Set<Id> getOppIdsForWinningContacts(Set<Id> winningContacts) {
        Set<Id> oppIds = new Set<Id>();
        for (OpportunityContactRole ocr : [
                SELECT OpportunityId
                FROM OpportunityContactRole
                WHERE ContactId IN :winningContacts AND IsPrimary = True
        ]
        ) {
            oppIds.add(ocr.OpportunityId);
        }
        return oppIds;
    }

}