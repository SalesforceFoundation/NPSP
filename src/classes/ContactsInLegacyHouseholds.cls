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
* @description Domain class for Contacts that use the legacy Household__c object in NPSP.
*/
public inherited sharing class ContactsInLegacyHouseholds extends fflib_SObjects {

    private HouseholdSettings settings;
    private Map<Id, Contact> oldMap;
    private final String RECORD_TYPE_ID = 'RecordTypeId';

    public ContactsInLegacyHouseholds(List<Contact> records, HouseholdSettings settings) {
        this(records, null, settings);
    }

    public ContactsInLegacyHouseholds(List<Contact> records, Map<Id, Contact> oldMap,
            HouseholdSettings settings) {
        super(records, Contact.SObjectType);
        this.oldMap = oldMap != null ?
                new Map<Id, Contact>(oldMap) : new Map<Id, Contact>();
        this.settings = settings == null ? new HouseholdSettings() : settings;
    }

    public void onAfterDelete() {
        Map<Id, Integer> householdCountMap = getHouseholdCountMap(getRecords());
        deleteEmptyHouseholds(getRecords(), householdCountMap);
        updateOldHouseholdNames(getRecords(), householdCountMap);
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

    private List<Contact> getContactsWithHouseholdIds(Map<Id, Integer> householdCountMap) {
        return [
                SELECT Id, npo02__Household__c
                FROM Contact
                WHERE npo02__Household__c IN :householdCountMap.keyset()
        ];
    }

    private void updateOldHouseholdNames(List<Contact> cons, Map<Id, Integer> householdCountMap) {
        List<Id> nonEmptyHouseholdIds = getNonEmptyHouseholdIds(cons, householdCountMap);
        if (nonEmptyHouseholdIds.size() > 0) {
            updateHouseholdNameAndMemberCount(nonEmptyHouseholdIds);
        }
    }

    private void deleteEmptyHouseholds(List<Contact> cons, Map<Id, Integer> householdCountMap) {
        List<npo02__Household__c> emptyHouseholds = getEmptyHouseholds(cons, householdCountMap);
        delete emptyHouseholds;
    }

    private List<Id> getNonEmptyHouseholdIds(List<Contact> cons,
            Map<Id, Integer> householdCountMap) {
        List<id> householdIdsNeedingNameUpdates = new List<id>();
        for (Contact con : cons) {
            if (!householdIsEmpty(householdCountMap, con)) {
                householdIdsNeedingNameUpdates.add(householdIdFor(con));
            }
        }
        return householdIdsNeedingNameUpdates;
    }

    private List<npo02__Household__c> getEmptyHouseholds(List<Contact> cons,
            Map<Id, Integer> householdCountMap
    ) {
        List<npo02__Household__c> emptyHouseholds = new List<SObject>();
        for (Contact con : cons) {
            if (householdIsEmpty(householdCountMap, con)) {
                emptyHouseholds.add(new npo02__Household__c(Id = householdIdFor(con)));
            }
        }
        return emptyHouseholds;
    }

    private Boolean householdIsEmpty(Map<Id, Integer> householdCountMap, Contact con) {
        return householdCountMap.get(householdIdFor(con)) < 1;
    }

    private Id householdIdFor(Contact con) {
        return con.npo02__Household__c;
    }

    private void updateHouseholdNameAndMemberCount(List<Id> contactsNeedingHouseholdNamesUpdated) {
        if (isFutureEligible()) {
            HouseholdNamingService.updateHouseholdNameAndMemberCountAsynchronously(
                    contactsNeedingHouseholdNamesUpdated);
        } else {
            HouseholdNamingService householdNamingService = new HouseholdNamingService();
            householdNamingService.updateHouseholdNameAndMemberCount(contactsNeedingHouseholdNamesUpdated);
        }
    }

    private Boolean isFutureEligible() {
        return settings.isAsyncEnabled()
                && !System.isFuture() && !System.isBatch();
    }

    public void onAfterUpdate() {
        insertHouseholds();
        fireRollups();
        updateHouseholdNames();
        deleteOldEmptyHouseholds();
    }

    private void deleteOldEmptyHouseholds() {
        delete getEmptyHouseholdsToDelete(contactsThatChangedHouseholds());
    }

    private static Integer timesRun = 0;
    private void updateHouseholdNames() {
        List<Id> householdsNeedingNamesUpdated = new List<Id>();
        householdsNeedingNamesUpdated.addAll(
                householdIdsFor(contactsThatChangedHouseholds()));
        householdsNeedingNamesUpdated.addAll(
                getOldNonEmptyHouseholdIds());
        householdsNeedingNamesUpdated.addAll(householdsWithNamingFieldChanges());
        if (householdsNeedingNamesUpdated.size() > 0 && timesRun < 2) {
            updateHouseholdNameAndMemberCount(householdsNeedingNamesUpdated);
            timesRun++;
        }
    }

    private void fireRollups() {
        Set<Id> householdIdsNeedingRollup = new Set<Id>();
        householdIdsNeedingRollup.addAll(householdIdsFor(contactsThatChangedHouseholds()));
        householdIdsNeedingRollup.addAll(getOldNonEmptyHouseholdIds());
        if (householdIdsNeedingRollup.size() > 0) {
            calculateLegacyHouseholdRollups(householdIdsNeedingRollup);
        }
    }

    private void insertHouseholds() {
        List<Contact> contactsThatDoNotHaveAHousehold =
                (List<Contact>) contactsThatDoNotHaveAHousehold().getRecords();
        List<Contact> contactsNeedingHouseholds = new List<Contact>();
        if (settings.isAllProcessor()) {
            contactsNeedingHouseholds.addAll(contactsThatDoNotHaveAHousehold);
        }
        if (settings.isAllIndividualsProcessor()) {
            contactsNeedingHouseholds.addAll(
                    contactsInIndividualAccounts(
                            contactsThatDoNotHaveAHousehold));
        }
        insertHouseholdsForContacts(contactsNeedingHouseholds, false);
    }

    private Set<Id> getOldNonEmptyHouseholdIds() {
        Set<Id> oldNonEmptyHouseholdIds = new Set<Id>();
        for (Contact con : (List<Contact>) getRecords()) {
            if (getOldHouseholdSizeById().get(oldHouseholdIdFor(con)) > 0) {
                oldNonEmptyHouseholdIds.add(oldHouseholdIdFor(con));
            }
        }
        return oldNonEmptyHouseholdIds;
    }

    private List<Contact> contactsThatChangedHouseholds() {
        List<Contact> contactsThatChangedHouseholds = new List<Contact>();
        for (Contact con : (List<Contact>) getRecords()) {
            if (householdChanged(con)) {
                contactsThatChangedHouseholds.add(con);
            }
        }
        return contactsThatChangedHouseholds;
    }

    private Set<Id> householdIdsFor(List<Contact> contacts) {
        Set<Id> householdIds = new Set<Id>();
        for (Contact con : contacts) {
            householdIds.add(householdIdFor(con));
        }
        return householdIds;
    }

    private fflib_SObjects contactsThatDoNotHaveAHousehold() {
        return selectByFieldValue(Contact.npo02__Household__c, null);
    }

    private List<Contact> contactsInIndividualAccounts(List<Contact> contacts) {
        Map<Id, Account> contactAccountMap = getContactAccountMap(contacts);
        List<Contact> contactsInIndividualAccounts = new List<Contact>();
        for (Contact con : contacts) {
            if (hasAccount(con)) {
                Account acc = contactAccountMap.get(con.AccountId);
                if (isIndividualAccount(acc)) {
                    contactsInIndividualAccounts.add(con);
                }
            } else {
                contactsInIndividualAccounts.add(con);
            }
        }
        return contactsInIndividualAccounts;
    }

    private Boolean hasAccount(Contact con) {
        return con.AccountId != null;
    }

    private Boolean isIndividualAccount(Account acc) {
        return acc.npe01__SYSTEMIsIndividual__c == true;
    }

    private Map<Id, Integer> oldHouseholdSizeById;
    private Map<Id, Integer> getOldHouseholdSizeById() {
        if (oldHouseholdSizeById != null) {
            return oldHouseholdSizeById;
        }
        oldHouseholdSizeById = new Map<Id, Integer>();
        for (AggregateResult aggregateResult : getMemberCountForOldHouseholds()) {
            oldHouseholdSizeById.put(
                    oldHouseholdIdFrom(aggregateResult),
                    memberCountFrom(aggregateResult));
        }
        for (Id hhid : getOldHouseholdIds()) {
            if (!oldHouseholdSizeById.containskey(hhid))
                oldHouseholdSizeById.put(hhid, 0);
        }
        return oldHouseholdSizeById;
    }

    private Integer memberCountFrom(AggregateResult a) {
        return (Integer) a.get('membercount');
    }

    private Id oldHouseholdIdFrom(AggregateResult a) {
        return (Id) a.get('oldhh');
    }

    private Id oldHouseholdIdFor(Contact con) {
        return oldVersionOf(con).npo02__Household__c;
    }

    private Contact oldVersionOf(Contact con) {
        return oldMap.get(con.Id);
    }

    private List<Id> getOldHouseholdIds() {
        List<Id> oldHouseholdIds = new List<Id>();
        for (Contact con : (List<Contact>) getRecords()) {
            if (conWasInAHousehold(con)) {
                oldHouseholdIds.add(oldHouseholdIdFor(con));
            }
        }
        return oldHouseholdIds;
    }

    private List<AggregateResult> getMemberCountForOldHouseholds() {
        return [
                SELECT npo02__Household__c oldhh, count(Id) membercount
                FROM Contact
                WHERE npo02__Household__c IN :getOldHouseholdIds()
                GROUP BY npo02__Household__c
        ];
    }

    private Boolean conWasInAHousehold(Contact con) {
        return oldHouseholdIdFor(con) != null;
    }

    private List<npo02__Household__c> getEmptyHouseholdsToDelete(
            List<Contact> contactsThatChangedHouseholds) {
        List<npo02__Household__c> emptyHouseholdsToDelete = new List<npo02__Household__c>();
        for (Contact con : contactsThatChangedHouseholds) {
            if (getOldHouseholdSizeById().get(oldHouseholdIdFor(con)) == 0) {
                emptyHouseholdsToDelete.add(
                        new npo02__Household__c(Id = oldHouseholdIdFor(con)));
            }
        }
        return emptyHouseholdsToDelete;
    }

    private void insertHouseholdsForContactsInIndividualAccounts() {
        List<SObject> contactsThatDoNotHaveAHouseholdRecord =
                contactsThatDoNotHaveAHousehold().getRecords();
        if (contactsThatDoNotHaveAHouseholdRecord.size() > 0) {
            insertHouseholdsForContacts(
                    contactsInIndividualAccounts(
                            contactsThatDoNotHaveAHouseholdRecord),
                    true);
        }
    }

    public void onAfterInsert() {

        updateHouseholdsNamesForContactsInHouseholds();
        if (allContactsGetHouseholds()) {
            insertHouseholdsForContactsThatDoNotHaveOne();
        }
        if (allIndividualContactsGetHouseholds()) {
            insertHouseholdsForContactsInIndividualAccounts();
        }
    }

    private Boolean allIndividualContactsGetHouseholds() {
        return settings.isAllIndividualsProcessor();
    }

    private Boolean allContactsGetHouseholds() {
        return settings.isAllProcessor();
    }

    private void insertHouseholdsForContactsThatDoNotHaveOne() {
        List<Contact> householdInserts = contactsThatDoNotHaveAHousehold().getRecords();
        if (householdInserts.size() > 0) {
            insertHouseholdsForContacts(householdInserts, true);
        }
    }

    private void updateHouseholdsNamesForContactsInHouseholds() {
        List<Id> contactsThatHaveAHousehold = idsForContactsInHouseholds();
        if (contactsThatHaveAHousehold.size() > 0) {
            updateHouseholdNameAndMemberCount(contactsThatHaveAHousehold);
        }
    }

    private List<Id> idsForContactsInHouseholds() {
        List<Id> idsForContactsInHouseholds = new List<Id>();
        for (Contact con : (List<Contact>) getRecords()) {
            if (hasHousehold(con)) {
                idsForContactsInHouseholds.add(con.Id);
            }
        }
        return idsForContactsInHouseholds;
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

    private Database.SaveResult[] insertHouseholds(
            List<npo02__Household__c> householdInserts) {
        Database.SaveResult[] householdSaveResults =
                UTIL_DMLService.insertRecords(householdInserts, false);
        return householdSaveResults;
    }

    private void putHouseholdIdOntoContacts(List<Contact> contacts,
            Database.SaveResult[] householdSaveResults) {
        List<Contact> contactsToBeUpdatedWithHouseholdId =
                processHouseholdSaveResults(contacts, householdSaveResults);
        update contactsToBeUpdatedWithHouseholdId;
    }

    private void updateNamesAfterHouseholdInsert(Database.SaveResult[] lsr) {
        List<Id> householdIdsNeedingNamesUpdated = getHouseholdIdsNeedingNamesUpdated(lsr);
        if (!householdIdsNeedingNamesUpdated.isEmpty()) {
            updateHouseholdNameAndMemberCount(householdIdsNeedingNamesUpdated);
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
        List<npo02__household__c> households = new List<npo02__household__c>();
        for (Contact con : contacts) {
            if (shouldExcludeForNewHHAccount(con)) {
                households.add(getHouseholdForInsertFromContact(con));
            }
        }
        return households;
    }

    private npo02__Household__c getHouseholdForInsertFromContact(Contact con) {
        npo02__household__c household =
                new npo02__household__c(Name = getDefaultHouseholdName(con));
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

    private String getDefaultHouseholdName(Contact con) {
        String hName = con.LastName;
        return hName += ' ' + System.Label.npo02.DefaultHouseholdName;
    }

    private Boolean shouldExcludeForNewHHAccount(Contact con) {
        return !isRecordTypesOnContacts()
                || !settings.contactRecordTypesToExclude().contains(recordTypeIdFor(con));
    }

    private List<Contact> processHouseholdSaveResults(List<Contact> contacts,
            Database.SaveResult[] householdSaveResults) {
        List<Contact> contactsToBeUpdatedWithHouseholdId = new List<Contact>();
        Integer i = 0;
        for (Contact con : contacts) {
            if (shouldExcludeForNewHHAccount(con)) {
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

    private Id recordTypeIdFor(Contact con) {
        return (Id) con.get(RECORD_TYPE_ID);
    }

    private Boolean isRecordTypesOnContacts() {
        return Schema.sObjectType.Contact.fields.getMap().get(RECORD_TYPE_ID) != null;
    }

    private Boolean hasHousehold(Contact con) {
        return householdIdFor(con) != null;
    }

    private void calculateLegacyHouseholdRollups(Set<Id> householdIds) {
        if (rollupsShouldRunSynchronously(householdIds)) {
            RLLP_OppRollup rg = new RLLP_OppRollup();
            rg.rollupHouseholds(getHouseholdMap(householdIds));
        } else {
            RLLP_OppRollup.rollupHouseholdsFuture(householdIds);
        }
    }

    private Map<Id, npo02__Household__c> getHouseholdMap(Set<Id> householdIds) {
        RLLP_OppRollup_UTIL oppRollupUtil = new RLLP_OppRollup_UTIL();
        Map<Id, npo02__Household__c> hhmap = new Map<Id, npo02__Household__c>(
                (List<npo02__Household__c>) Database.query(oppRollupUtil.buildHouseholdQuery() +
                        ' WHERE Id IN :householdIds'));
        return hhmap;
    }

    private Boolean rollupsShouldRunSynchronously(Set<Id> householdIds) {
        return System.isFuture() || System.isBatch() || householdIds.size() <= 2;
    }

    private List<Id> householdsWithNamingFieldChanges() {
        List<Id> householdsWithNamingFieldChanges = new List<Id>();
        for (Contact con : (List<Contact>) getRecords()) {
            if (isHouseholdNamingFieldsChanged(con)) {
                householdsWithNamingFieldChanges.add(householdIdFor(con));
            }
        }
        return householdsWithNamingFieldChanges;
    }

    private Boolean isHouseholdNamingFieldsChanged(Contact con) {
        return isNamingExclusionsChanged(con) || isNamingFieldChanged(con);
    }

    private Boolean isNamingFieldChanged(Contact con) {
        Boolean namingFieldChanged = false;
        if (hasHousehold(con)) {
            for (String fieldName : getHouseholdNamingFieldsInUse()) {
                if (isFieldChanged(con, fieldName)) {
                    namingFieldChanged = true;
                    break;
                }
            }
        }
        return namingFieldChanged;
    }

    private Set<String> householdNamingFieldsInUse;
    private Set<String> getHouseholdNamingFieldsInUse() {
        if (householdNamingFieldsInUse != null) {
            return householdNamingFieldsInUse;
        }
        householdNamingFieldsInUse = new HouseholdNamingService()
                .getHouseholdNamingContactFields();
        return householdNamingFieldsInUse;
    }

    private Boolean isFieldChanged(Contact con, String fieldName) {
        // make sure to use case sensitive comparison
        String strName = getNewFieldValue(con, fieldName);
        String strNameOld = getOldFieldValue(con, fieldName);
        Boolean isChanged = !strName.equals(strNameOld);
        return isChanged;
    }

    private Boolean isNamingExclusionsChanged(Contact con) {
        HouseholdNamingExclusions exclusions =
                new HouseholdNamingExclusions(namingExclusionsFor(con));
        return exclusions.isNotEqualTo(namingExclusionsFor(oldVersionOf(con)));
    }

    private Boolean householdChanged(Contact con) {
        return householdIdFor(con) != oldHouseholdIdFor(con);
    }

    private String getOldFieldValue(Contact con, String fieldName) {
        String strNameOld = String.valueOf(oldVersionOf(con).get(fieldName));
        return strNameOld == null ? '' : strNameOld;
    }

    private String getNewFieldValue(Contact con, String fieldName) {
        String strName = String.valueOf(con.get(fieldName));
        return strName == null ? '' : strName;
    }

    private String namingExclusionsFor(Contact con) {
        return con.npo02__Naming_Exclusions__c;
    }
}