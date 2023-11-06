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
* @description Selector class for Contact Merge in NPSP.
*/
public with sharing class ContactMergeSelector {

    private final Integer SOSL_LIMIT = 100;

    @TestVisible
    private static OrgConfig orgConfig {
        get {
            if (orgConfig == null) {
                orgConfig = new OrgConfig();
            }
            return orgConfig;
        }
        set;
    }

    /***********************************************************************************************
    * @description The list of contact field names that are used in search and displayed in Found
    * Contacts.
    */
    private List<String> listStrContactField {
        get {
            if (listStrContactField == null) {
                listStrContactField = UTIL_Describe.listStrFromFieldSet
                        ('Contact', UTIL_Namespace.StrTokenNSPrefix('ContactMergeFoundFS'));
                Set<String> setStr = new Set<String>(listStrContactField);
                // now add additional fields we know we need
                setStr.add('Id');
                setStr.add('Name');
                listStrContactField.clear();
                listStrContactField.addAll(setStr);
            }
            return listStrContactField;
        }
        set;
    }

    public List<SObject> selectContactsById(Set<Id> contactIds) {
        String queryString = new UTIL_Query()
            .withFrom(Contact.SObjectType)
            .withSelectFields(listStrContactField)
            .withWhere('Id IN :contactIds')
            .build();

        return Database.query(queryString);
    }

    public List<SObject> selectContactsByName(String name) {
        UTIL_Finder finder = new UTIL_Finder(Contact.SObjectType);
        finder.withSelectFields(listStrContactField)
                .withSearchQuery(name)
                .withWildcard()
                .withOrderBy(Contact.LastName)
                .withLimit(SOSL_LIMIT);

        return finder.executeSearch();
    }

    public List<SObject> selectDuplicateRecordSetById(Id duplicateRecordSetId, List<String> drsFieldNames) {
        String whereString = new UTIL_Query()
                .withFrom('DuplicateRecordItem')
                .withSelectFields(drsFieldNames)
                .withWhere('DuplicateRecordSetId =:duplicateRecordSetId')
                .build();
        whereString = 'Id IN ('+ whereString + ')';
        String queryString = new UTIL_Query()
                .withFrom('Contact')
                .withSelectFields(listStrContactField)
                .withWhere(whereString)
                .build();
        return Database.query(queryString);
    }

    public List<Account> getAccountsFor(Set<Id> accountIds) {
        return Database.query(buildAccountSoql(accountIds));
    }

    public List<Account> getHouseholdAndOrgAccountsFor(Set<Id> accountIds) {
        return [
                SELECT Id, npe01__SYSTEMIsIndividual__c, npe01__SYSTEM_AccountType__c, Name
                FROM Account a
                WHERE
                Id IN :accountIds
                AND (
                        npe01__SYSTEM_AccountType__c = :CAO_Constants.ONE_TO_ONE_ORGANIZATION_TYPE
                        OR (
                                npe01__SYSTEM_AccountType__c = :CAO_Constants.HH_ACCOUNT_TYPE
                                AND Number_of_Household_Members__c = 1
                        )
                )
        ];
    }

    @TestVisible
    private String buildAccountSoql(Set<Id> accountIds) {
        List<String> selectFields = getAccountFields();

        return new UTIL_Query()
                .withSelectFields(selectFields)
                .withFrom(String.valueOf(Account.SObjectType))
                .withWhere('Id IN :accountIds')
                .build();
    }

    public List<String> getAccountFields() {
        List<String> selectFields = new List<String> {
                String.valueOf(Account.Name),
                String.valueOf(Account.npe01__SYSTEM_AccountType__c)
        };

        if (orgConfig.isPersonAccountsEnabled()) {
            selectFields.add(String.valueOf('PersonContactId'));
        }

        return selectFields;
    }

    public List<Contact> getContactsWithAccountFields(List<Contact> contacts) {
        return Database.query(buildContactSoqlOrderById(contacts));
    }

    @TestVisible
    private String buildContactSoqlOrderById(List<Contact> contacts) {
        List<String> selectFields = getContactSelectionFields();

        return new UTIL_Query()
                .withSelectFields(selectFields)
                .withFrom(String.valueOf(Contact.SObjectType))
                .withWhere('Id IN :contacts')
                .withOrderBy('Id')
                .build();
    }

    private List<String> getContactSelectionFields() {
        List<String> selectFields = new List<String>{
                'Id', 'npe01__Private__c', 'AccountId', 'Account.npe01__SYSTEMIsIndividual__c',
                'Account.npe01__SYSTEM_AccountType__c', 'Account.npe01__One2OneContact__c',
                'npe01__Organization_Type__c', 'Account.Name',
                'FirstName', 'LastName', 'OwnerId', 'Salutation', 'npo02__Naming_Exclusions__c',
                'npo02__Household_Naming_Order__c',
                'MailingStreet', 'MailingCity', 'MailingState', 'MailingPostalCode',
                'MailingCountry', 'MailingLatitude', 'MailingLongitude',
                'OtherStreet', 'OtherCity', 'OtherState', 'OtherPostalCode',
                'OtherCountry', 'OtherLatitude', 'OtherLongitude',
                'Phone', 'Fax'
        };

        if (orgConfig.isStateCountryPicklistsEnabled()) {
            selectFields.add('MailingCountryCode');
            selectFields.add('MailingStateCode');
            selectFields.add('OtherCountryCode');
            selectFields.add('OtherStateCode');
        }

        if (orgConfig.isPersonAccountsEnabled()) {
            selectFields.add('isPersonAccount');
        }

        return selectFields;
    }
}