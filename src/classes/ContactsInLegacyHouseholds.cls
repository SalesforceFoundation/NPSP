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
* These Contact can use either One-To-One Accounts or the Individual "Bucket" Account. In old
* documentation they are referred to as "Individual Contacts". They are also referred to this
* way in Household Settings.
*/
public inherited sharing class ContactsInLegacyHouseholds extends fflib_SObjects {

    private static ContactsInLegacyHouseholds mock;
    @TestVisible
    private static void setMock(ContactsInLegacyHouseholds mockInstance) {
        mock = mockInstance;
    }

    public static ContactsInLegacyHouseholds newInstance(List<Contact> records){
        return mock != null ? mock : new ContactsInLegacyHouseholds(records);
    }

    @TestVisible
    private HouseholdSettings householdSettings {
        get {
            if (householdSettings == null) {
                householdSettings = new HouseholdSettings();
            }
            return householdSettings;
        }
        set;
    }
    @TestVisible
    private HouseholdService householdService {
        get {
            if (householdService == null) {
                householdService = new HouseholdService();
            }
            return householdService;
        }
        set;
    }
    private Map<Id, Contact> oldMap;

    public void onAfterInsert() {
        householdService.createHouseholdsFor(this);
    }

    public void onAfterUpdate() {
        householdService.createHouseholdsFor(this);
        householdService.fireHouseholdRollupsFor(this);
        householdService.updateHouseholdNamesFor(this);
        householdService.deleteEmptyHouseholdsFor(this);
    }

    public void onAfterDelete() {
        householdService.processOldHouseholdsAfterDeletingContacts(this);
    }

    public ContactsInLegacyHouseholds(List<Contact> records) {
        this(records, null);
    }

    public ContactsInLegacyHouseholds(List<Contact> records, Map<Id, Contact> oldMap) {
        super(records, Contact.SObjectType);
        this.oldMap = oldMap != null ?
                new Map<Id, Contact>(oldMap) : new Map<Id, Contact>();
    }

    public List<Contact> contactsWithoutHouseholds() {
        fflib_SObjects contacts = selectByFieldValue(Contact.npo02__Household__c, null);
        return (List<Contact>) contacts.getRecords();
    }

    public Set<Id> householdsWithMembershipChanges() {
        Set<Id> ids = new Set<Id>();
        for (Contact con : contactsThatChangedHouseholds()) {
            ids.add(householdIdFor(con));
            ids.add(oldHouseholdIdFor(con));
        }
        return ids;
    }

    public List<Id> householdsWithMembershipOrNamingFieldChanges() {
        List<Id> householdsNeedingNamesUpdated = new List<Id>();
        householdsNeedingNamesUpdated.addAll(
                householdsWithMembershipChanges());
        householdsNeedingNamesUpdated.addAll(householdsWithNamingFieldChanges());
        return householdsNeedingNamesUpdated;
    }

    public List<Contact> contactsInIndividualAccounts(List<Contact> contacts) {
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

    public List<Contact> contactsInIndividualAccountsWithoutHouseholds() {
        return contactsInIndividualAccounts(contactsWithoutHouseholds());
    }

    public Set<Id> householdIds() {
        Set<Id> householdIds = getIdFieldValues(Contact.npo02__Household__c);
        householdIds.remove(null);
        return new Set<Id>(householdIds);
    }

    public List<Id> oldHouseholdIds() {
        List<Id> oldHouseholdIds = new List<Id>();
        for (Contact con : (List<Contact>) getRecords()) {
            if (conWasInAHousehold(con)) {
                oldHouseholdIds.add(oldHouseholdIdFor(con));
            }
        }
        return oldHouseholdIds;
    }

    private List<Contact> contactsThatChangedHouseholds() {
        List<Contact> contactsThatChangedHouseholds = new List<Contact>();
        for (Contact con : (List<Contact>) getRecords()) {
            if (householdChangedFor(con)) {
                contactsThatChangedHouseholds.add(con);
            }
        }
        return contactsThatChangedHouseholds;
    }

    private Id householdIdFor(Contact con) {
        return con.npo02__Household__c;
    }

    private Boolean hasAccount(Contact con) {
        return con.AccountId != null;
    }

    private Boolean isIndividualAccount(Account acc) {
        return acc.npe01__SYSTEMIsIndividual__c == true;
    }

    private Id oldHouseholdIdFor(Contact con) {
        return oldVersionOf(con).npo02__Household__c;
    }

    private Contact oldVersionOf(Contact con) {
        return oldMap.get(con.Id);
    }

    private Boolean conWasInAHousehold(Contact con) {
        return oldHouseholdIdFor(con) != null;
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

    private Boolean hasHousehold(Contact con) {
        return householdIdFor(con) != null;
    }

    private List<Id> householdsWithNamingFieldChanges() {
        List<Id> householdsWithNamingFieldChanges = new List<Id>();
        for (Contact con : (List<Contact>) contactsInHouseholds()) {
            if (isHouseholdNamingFieldsChanged(con)) {
                householdsWithNamingFieldChanges.add(householdIdFor(con));
            }
        }
        return householdsWithNamingFieldChanges;
    }

    private List<Contact> contactsInHouseholds() {
        List<Contact> contacts = new List<Contact>();
        for (Contact con : (List<Contact>) getRecords()) {
            if (hasHousehold(con)) {
                contacts.add(con);
            }
        }
        return contacts;
    }

    private Boolean isHouseholdNamingFieldsChanged(Contact con) {
        return namingExclusionsChangedFor(con) || namingFieldChangedFor(con);
    }

    private Boolean namingFieldChangedFor(Contact con) {
        for (String fieldName : householdService.fieldsUsedForHouseholdNaming()) {
            if (isFieldChanged(con, fieldName)) {
                return true;
            }
        }
        return false;
    }

    private Boolean isFieldChanged(Contact con, String fieldName) {
        // make sure to use case sensitive comparison
        String strName = getNewFieldValue(con, fieldName);
        String strNameOld = getOldFieldValue(con, fieldName);
        Boolean isChanged = !strName.equals(strNameOld);
        return isChanged;
    }

    private Boolean namingExclusionsChangedFor(Contact con) {
        HouseholdNamingExclusionsString exclusions =
                new HouseholdNamingExclusionsString(con);
        HouseholdNamingExclusionsString oldExclusions =
                new HouseholdNamingExclusionsString(oldVersionOf(con));
        return !exclusions.equals(oldExclusions);
    }

    private Boolean householdChangedFor(Contact con) {
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