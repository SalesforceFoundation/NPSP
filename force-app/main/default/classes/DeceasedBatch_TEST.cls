/*
    Copyright (c) 2022 Salesforce.org
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
* @date 2022
* @description Tests for the Deceased Batch class
*/

@IsTest
private class DeceasedBatch_TEST {

    private static IDGenerator generator = new IDGenerator();

    @IsTest
    private static void shouldAddAllMembersToAccountMap() {
        List<Contact> contacts = getContactsWithAccount(3);
        contacts.addAll(getContactsWithAccount(4));
        contacts.addAll(getContactsWithAccount(1));

        DeceasedBatch batch = new DeceasedBatch();
        Map<Id, Boolean> deceasedById = batch.getAllMembersDeceasedById(contacts);

        System.assertEquals(3, deceasedById.size(), 'Three entries should appear in the Id => Boolean map');
    }

    @IsTest
    private static void shouldRemoveOneMemberFromAccountMap() {
        List<Contact> contacts = getContactsWithAccount(3);
        contacts.addAll(getContactsWithAccount(4));
        contacts.addAll(getContactsWithAccount(1));

        DeceasedBatch batch = new DeceasedBatch();
        batch.highLowProcessedIds.add(contacts[0].AccountId);
        Map<Id, Boolean> deceasedById = batch.getAllMembersDeceasedById(contacts);

        System.assertEquals(2, deceasedById.size(), 'One entry should be removed from the Id => Boolean map');
    }

    @IsTest
    private static void shouldRemoveTwoMembersFromAccountMap() {
        List<Contact> contacts = getContactsWithAccount(3);
        contacts.addAll(getContactsWithAccount(4));
        contacts.addAll(getContactsWithAccount(1));

        DeceasedBatch batch = new DeceasedBatch();
        batch.highLowProcessedIds.add(contacts[0].AccountId);
        batch.highLowProcessedIds.add(contacts[contacts.size() - 1].AccountId);
        Map<Id, Boolean> deceasedById = batch.getAllMembersDeceasedById(contacts);

        System.assertEquals(1, deceasedById.size(), 'Two entries should be removed from the Id => Boolean map');
    }

    @IsTest
    private static void shouldRemoveTheOnlyAccountFromAccountMap() {
        List<Contact> contacts = getContactsWithAccount(3);

        DeceasedBatch batch = new DeceasedBatch();
        batch.highLowProcessedIds.add(contacts[0].AccountId);
        Map<Id, Boolean> deceasedById = batch.getAllMembersDeceasedById(contacts);

        System.assertEquals(0, deceasedById.size(), 'The Id => Boolean map should be empty');
    }

    @IsTest
    private static void shouldSaveHighAndLowAccountIdsProcessed() {
        List<Contact> contacts = getContactsWithAccount(3);
        contacts.addAll(getContactsWithAccount(4));
        contacts.addAll(getContactsWithAccount(1));

        DeceasedBatch batch = new DeceasedBatch();
        batch.saveHighAndLowProcessedIds(contacts);

        System.assertEquals(2, batch.highLowProcessedIds.size(), 'High and low processed Id numbers should be saved');
    }

    @IsTest
    private static void shouldSaveOneAccountIdProcessed() {
        List<Contact> contacts = getContactsWithAccount(3);

        DeceasedBatch batch = new DeceasedBatch();
        batch.saveHighAndLowProcessedIds(contacts);

        System.assertEquals(1, batch.highLowProcessedIds.size(), 'One processed Id numbers should be saved');
    }

    @IsTest
    private static void shouldNotUpdateAllMembersDeceasedWhenAllMembersDeceased() {
        List<Contact> unDeceasedContacts = getContactsWithAccount(3);
        List<Contact> deceasedContacts = getContactsWithAccount(3);
        deceasedContacts[0].Account.All_Members_Deceased__c = true;
        setContactsDeceased(deceasedContacts, true, false);

        List<Contact> allContacts = unDeceasedContacts.clone();
        allContacts.addAll(deceasedContacts);

        DeceasedBatch batch = new DeceasedBatch();
        Map<Id, Boolean> deceasedById = batch.getAllMembersDeceasedById(allContacts);
        System.assertEquals(2, deceasedById.size(), 'Two Account entries should exist in the Id => Boolean map');

        List<Account> accountUpdates = batch.getAllMembersDeceasedUpdates(allContacts, deceasedById);
        System.assertEquals(0, accountUpdates.size(), 'No Account updates should be identified');
    }

    @IsTest
    private static void shouldUpdateAllMembersDeceasedToUncheckedWhenAllMembersUndeceased() {
        List<Contact> unDeceasedContacts1 = getContactsWithAccount(3);
        unDeceasedContacts1[0].Account.All_Members_Deceased__c = true;
        List<Contact> unDeceasedContacts2 = getContactsWithAccount(3);
        unDeceasedContacts2[0].Account.All_Members_Deceased__c = true;

        List<Contact> allContacts = unDeceasedContacts1.clone();
        allContacts.addAll(unDeceasedContacts2);

        DeceasedBatch batch = new DeceasedBatch();
        Map<Id, Boolean> deceasedById = batch.getAllMembersDeceasedById(allContacts);
        System.assertEquals(2, deceasedById.size(), 'Two Account entries should exist in the Id => Boolean map');

        List<Account> accountUpdates = batch.getAllMembersDeceasedUpdates(allContacts, deceasedById);
        System.assertEquals(2, accountUpdates.size(), 'Two Account updates should be identified');
        System.assertEquals(false, accountUpdates[0].All_Members_Deceased__c, 'All Members Deceased should be false');
        System.assertEquals(false, accountUpdates[1].All_Members_Deceased__c, 'All Members Deceased should be false');
    }

    @IsTest
    private static void shouldUpdateAllMembersDeceasedToCheckedWhenAllMembersDeceased() {
        List<Contact> deceasedContacts1 = getContactsWithAccount(3);
        List<Contact> deceasedContacts2 = getContactsWithAccount(3);

        List<Contact> allContacts = deceasedContacts1.clone();
        allContacts.addAll(deceasedContacts2);
        setContactsDeceased(allContacts, false, false);

        DeceasedBatch batch = new DeceasedBatch();
        Map<Id, Boolean> deceasedById = batch.getAllMembersDeceasedById(allContacts);
        System.assertEquals(2, deceasedById.size(), 'Two Account entries should exist in the Id => Boolean map');

        List<Account> accountUpdates = batch.getAllMembersDeceasedUpdates(allContacts, deceasedById);
        System.assertEquals(2, accountUpdates.size(), 'Two Account updates should be identified');
        System.assertEquals(true, accountUpdates[0].All_Members_Deceased__c, 'All Members Deceased should be true');
        System.assertEquals(true, accountUpdates[1].All_Members_Deceased__c, 'All Members Deceased should be true');
    }

    @IsTest
    private static void shouldUpdateAllMembersDeceasedWhenMembersAreMixed() {
        List<Contact> mixedContacts1 = getContactsWithAccount(3);
        mixedContacts1[0].Account.All_Members_Deceased__c = true;
        List<Contact> mixedContacts2 = getContactsWithAccount(3);
        mixedContacts2[0].Account.All_Members_Deceased__c = true;

        List<Contact> allContacts = mixedContacts1.clone();
        allContacts.addAll(mixedContacts2);
        setContactsDeceased(allContacts, false, true);

        DeceasedBatch batch = new DeceasedBatch();
        Map<Id, Boolean> deceasedById = batch.getAllMembersDeceasedById(allContacts);
        System.assertEquals(2, deceasedById.size(), 'Two Account entries should exist in the Id => Boolean map');

        List<Account> accountUpdates = batch.getAllMembersDeceasedUpdates(allContacts, deceasedById);
        System.assertEquals(2, accountUpdates.size(), 'Two Account updates should be identified');
        System.assertEquals(false, accountUpdates[0].All_Members_Deceased__c, 'All Members Deceased should be false');
        System.assertEquals(false, accountUpdates[1].All_Members_Deceased__c, 'All Members Deceased should be false');
    }

    @IsTest
    private static void shouldNotUpdateAllMembersDeceasedWhenMembersAreMixed() {
        List<Contact> mixedContacts1 = getContactsWithAccount(3);
        List<Contact> mixedContacts2 = getContactsWithAccount(3);

        List<Contact> allContacts = mixedContacts1.clone();
        allContacts.addAll(mixedContacts2);
        setContactsDeceased(allContacts, false, true);

        DeceasedBatch batch = new DeceasedBatch();
        Map<Id, Boolean> deceasedById = batch.getAllMembersDeceasedById(allContacts);
        System.assertEquals(2, deceasedById.size(), 'Two Account entries should exist in the Id => Boolean map');

        List<Account> accountUpdates = batch.getAllMembersDeceasedUpdates(allContacts, deceasedById);
        System.assertEquals(0, accountUpdates.size(), 'No Account updates should be identified');
    }

    ///// Helpers

    private static List<Contact> getContactsWithAccount(Integer contactsPerAccount) {
        Account testAccount = UTIL_UnitTestData_TEST.buildHouseholdAccount();
        testAccount.All_Members_Deceased__c = false;
        testAccount.Id = generator.generate(Account.SObjectType);

        List<Contact> contacts = UTIL_UnitTestData_TEST.getContacts(contactsPerAccount);
        for (Contact testContact : contacts) {
            testContact.Id = generator.generate(Contact.SObjectType);
            testContact.Account = testAccount;
            testContact.AccountId = testAccount.Id;
            testContact.Deceased__c = false;
        }

        return contacts;
    }

    private static void setContactsDeceased(List<Contact> contacts, Boolean accountMatch, Boolean mixed) {
        Integer contactCount = 0;
        for (Contact testContact : contacts) {
            if (accountMatch) {
                testContact.Deceased__c = testContact.Account.All_Members_Deceased__c;

            } else if (mixed && Math.mod(contactCount++, 2) == 0) {
                testContact.Deceased__c = false;

            } else {
                testContact.Deceased__c = true;
            }
        }
    }

    /**
     * Credit to fflib-apex-mocks fflib_IDGenerator
     * https://github.com/apex-enterprise-patterns/fflib-apex-mocks/blob/master/sfdx-source/apex-mocks/main/classes/fflib_IDGenerator.cls
     */
    private class IDGenerator {
        private Integer fakeIdCount = 0;
        private final String ID_PATTERN = '000000000000';


        private Id generate(Schema.SObjectType sObjectType) {
            String keyPrefix = UTIL_Describe.getObjectDescribe(sObjectType).getKeyPrefix();
            fakeIdCount++;

            String fakeIdPrefix = ID_PATTERN.substring(0, ID_PATTERN.length() - String.valueOf(fakeIdCount).length());

            return Id.valueOf(keyPrefix + fakeIdPrefix + fakeIdCount);
        }
    }
}
