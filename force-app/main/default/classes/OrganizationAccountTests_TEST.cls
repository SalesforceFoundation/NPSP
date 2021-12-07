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
            Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Organization')
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
        Contact c1 = new Contact(LastName = 'testCon1', AccountId = orgAccount.Id);
        Contact c2 = new Contact(LastName = 'testCon2', AccountId = orgAccount.Id);
        insert new List<Contact>{
                c1, c2
        };

        // Act: WHEN one of the Contacts is deleted
        delete c2;

        // Assert: THEN the Org Account should not be renamed
        List<Account> orgAccounts = getOrgAccounts();
        System.assertEquals('testOrgAccount', orgAccounts.get(0).Name,
                'The name of the Org Account should not change after deleting a Contact.');
    }

    private static List<Account> getOrgAccounts() {
        List<Account> orgAccounts = [
                SELECT Name
                FROM Account
                WHERE RecordTypeId = :organizationRecordTypeId
        ];
        return orgAccounts;
    }
}