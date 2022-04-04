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
* @description Organization Account tests in NPSP.
*/
@IsTest
private class OrganizationAccountTests_TEST {

    private static Id organizationRecordTypeId =
            Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName()
                    .get('Organization')
                    .getRecordTypeId();

    private static Account orgAccount(String name) {
        return new Account(
                Name = name,
                RecordTypeId = organizationRecordTypeId
        );
    }

    @IsTest
    static void delete_one_contact_from_org_account_should_not_rename_account() {
        // Arrange: GIVEN an Org Account with multiple child Contacts
        Account orgAccount = orgAccount('testOrgAccount');
        insert orgAccount;
        Contact orgContact1 = new Contact(LastName = 'testCon1', AccountId = orgAccount.Id);
        Contact orgContact2 = new Contact(LastName = 'testCon2', AccountId = orgAccount.Id);
        insert new List<Contact>{
                orgContact1, orgContact2
        };

        // Act: WHEN one of the Contacts is deleted
        Test.startTest();
        delete orgContact2;
        Test.stopTest();

        // Assert: THEN the Org Account should not be renamed
        List<Account> orgAccounts = getOrgAccounts();
        System.assertEquals('testOrgAccount', orgAccounts.get(0).Name,
                'The name of the Org Account should not change after deleting a Contact.');
    }

    @IsTest
    static void merge_in_one_household_member_should_not_rename_org_account() {
        // Arrange: GIVEN an Org Account with multiple child Contacts
        Account orgAccount = orgAccount('testOrgAccount');
        insert orgAccount;
        Contact orgContact1 = new Contact(LastName = 'testCon1', AccountId = orgAccount.Id);
        Contact orgContact2 = new Contact(LastName = 'testCon2', AccountId = orgAccount.Id);
        // AND a Household Account Member
        Contact householdContact = TEST_ContactBuilder.dummyContact();
        insert new List<Contact>{
                orgContact1, orgContact2, householdContact
        };

        // Act: WHEN the Household Contact is merged into the Org Account via Contact merge
        Test.startTest();
        ContactMergeService contactMerge = new ContactMergeService();
        contactMerge.mergeContacts(orgContact1, new List<Contact>{
                householdContact
        });
        Test.stopTest();

        // Assert: THEN the Org Account should not be renamed
        List<Account> orgAccounts = getOrgAccounts();
        System.assertEquals('testOrgAccount', orgAccounts.get(0).Name,
                'The name of the Org Account should not change after merging in a' +
                        'Household Contact.');
        // AND the winning Contact should still be in the same Org Account
        Contact mergeWinnerContact = getContact(orgContact1);
        System.assertEquals(orgAccount.Id, mergeWinnerContact.AccountId,
                'The winning Contact should not be removed from its Org Account.');
    }

    @IsTest
    static void merge_two_org_account_contacts_should_not_rename_either_org_account() {
        // Arrange: GIVEN multiple Org Accounts with multiple child Contacts
        Account orgAccount = orgAccount('testOrgAccount');
        Account orgAccount2 = orgAccount('testOrgAccount2');
        insert new List<Account>{
                orgAccount, orgAccount2
        };
        Contact orgContact1 = new Contact(LastName = 'testCon1', AccountId = orgAccount.Id);
        Contact orgContact2 = new Contact(LastName = 'testCon2', AccountId = orgAccount.Id);
        Contact orgContact3 = new Contact(LastName = 'testCon3', AccountId = orgAccount2.Id);
        Contact orgContact4 = new Contact(LastName = 'testCon4', AccountId = orgAccount2.Id);
        insert new List<Contact>{
                orgContact1, orgContact2, orgContact3, orgContact4
        };

        // Act: WHEN one Org Contact is merged into the other Org Account via Contact merge
        Test.startTest();
        ContactMergeService contactMerge = new ContactMergeService();
        contactMerge.mergeContacts(orgContact1, new List<Contact>{
                orgContact3
        });
        Test.stopTest();

        // Assert: THEN neither of the Org Accounts should be renamed
        Map<Id, Account> queriedOrgAccounts = new Map<Id, Account>(getOrgAccounts());
        System.assertEquals('testOrgAccount', queriedOrgAccounts.get(orgAccount.Id).Name,
                'The name of the Org Account should not change after merging in an ' +
                        'Org Contact.');
        System.assertEquals('testOrgAccount2', queriedOrgAccounts.get(orgAccount2.Id).Name,
                'The name of the Org Account should not change after merging in an ' +
                        'Org Contact.');
        // AND the winning Contact should still be in the same Org Account
        Contact mergeWinnerContact = getContact(orgContact1);
        System.assertEquals(orgAccount.Id, mergeWinnerContact.AccountId,
                'The winning Contact should not be removed from its Org Account.');
    }

    private static List<Account> getOrgAccounts() {
        List<Account> orgAccounts = [
                SELECT Name
                FROM Account
                WHERE RecordTypeId = :organizationRecordTypeId
        ];
        return orgAccounts;
    }

    private static Contact getContact(Contact c1) {
        List<Contact> contacts = [
                SELECT AccountId
                FROM Contact
                WHERE Id = :c1.Id
        ];
        Contact queriedContact = (contacts.size() == 1) ? contacts.get(0) : null;
        return queriedContact;
    }
}