/*
    Copyright (c) 2014, Salesforce.org
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
@IsTest
public with sharing class ADDR_Contacts_TEST {

    @IsTest
    private static void newContactUndeliverableStatusShouldSyncToNewAddressAndAccount() {
        UTIL_UnitTestData_TEST.createAccountContactTestData(CAO_Constants.HH_ACCOUNT_TYPE, 1, 1, 0);

        Contact testContact = UTIL_UnitTestData_TEST.getContact();
        testContact.MailingStreet = 'Undeliverable Address';
        testContact.MailingCity = 'Seattle';
        testContact.MailingPostalCode = 'Undeliverable Zip';
        testContact.MailingCountry = 'United States';
        testContact.MailingState = 'Washington';
        testContact.Undeliverable_Address__c = true;
        testContact.AccountId = UTIL_UnitTestData_TEST.listAccT[0].Id;

        Test.startTest();
            insert testContact;
        Test.stopTest();

        Contact updatedContact = [SELECT Current_Address__c, Undeliverable_Address__c
                                  FROM Contact
                                  WHERE Id = :testContact.Id];

        Address__c updatedAddress = [SELECT Undeliverable__c
                                     FROM Address__c
                                     WHERE Id = :updatedContact.Current_Address__c];
        Account updatedAccount = [SELECT Undeliverable_Address__c
                                  FROM Account
                                  WHERE Id = :UTIL_UnitTestData_TEST.listAccT[0].Id];

        System.assertEquals(updatedContact.Undeliverable_Address__c, updatedAddress.Undeliverable__c, 'Contact address ' +
                'undeliverable status should match address undeliverable status.');
        System.assertEquals(updatedContact.Undeliverable_Address__c, updatedAccount.Undeliverable_Address__c,
                'Contact address undeliverable status should match account undeliverable status.');
    }

    @IsTest
    private static void updatedContactUndeliverableStatusShouldSyncToNewAddressAndAccount() {
        UTIL_UnitTestData_TEST.createAccountContactTestData(CAO_Constants.HH_ACCOUNT_TYPE, 1, 1, 0);

        Contact testContact = UTIL_UnitTestData_TEST.getContact();
        testContact.AccountId = UTIL_UnitTestData_TEST.listAccT[0].Id;

        insert testContact;

        Test.startTest();
            Contact contactToUpdate = [SELECT Undeliverable_Address__c FROM Contact WHERE Id = :testContact.Id];
            contactToUpdate.MailingStreet = 'Undeliverable Address';
            contactToUpdate.MailingCity = 'Seattle';
            contactToUpdate.MailingPostalCode = 'Undeliverable Zip';
            contactToUpdate.MailingCountry = 'United States';
            contactToUpdate.MailingState = 'Washington';
            contactToUpdate.Undeliverable_Address__c = true;

            update contactToUpdate;
        Test.stopTest();

        Contact updatedContact = [SELECT Current_Address__c, Undeliverable_Address__c
                                  FROM Contact
                                  WHERE Id = :testContact.Id];
        Address__c updatedAddress = [SELECT Undeliverable__c
                                     FROM Address__c
                                     WHERE Id = :updatedContact.Current_Address__c];
        Account updatedAccount = [SELECT Undeliverable_Address__c
                                  FROM Account
                                  WHERE Id = :UTIL_UnitTestData_TEST.listAccT[0].Id];

        System.assertEquals(updatedContact.Undeliverable_Address__c, updatedAddress.Undeliverable__c,
                'Contact address undeliverable status should match address undeliverable status.');
        System.assertEquals(updatedContact.Undeliverable_Address__c, updatedAccount.Undeliverable_Address__c,
                'Contact address undeliverable status should match account undeliverable status.');
    }

    @IsTest
    private static void updatedContactUndeliverableStatusShouldSyncToExistingAddressAndAccount() {
        UTIL_UnitTestData_TEST.createAccountContactTestData(CAO_Constants.HH_ACCOUNT_TYPE, 1, 1, 0);

        Address__c testAddress = new Address__c();
        testAddress.MailingStreet__c = '123 Existing Address';
        testAddress.MailingCity__c = 'Washington';
        testAddress.MailingPostalCode__c = 'ExistingZip';
        testAddress.MailingCountry__c = 'United States';
        testAddress.MailingState__c = 'Seattle';
        testAddress.Household_Account__c = UTIL_UnitTestData_TEST.listAccT[0].Id;
        insert testAddress;

        Contact testContact = UTIL_UnitTestData_TEST.getContact();
        testContact.AccountId = UTIL_UnitTestData_TEST.listAccT[0].Id;
        testContact.MailingState = testAddress.MailingState__c;
        testContact.MailingCountry = testAddress.MailingCountry__c;
        testContact.MailingPostalCode = testAddress.MailingPostalCode__c;
        testContact.MailingCity = testAddress.MailingCity__c;
        testContact.MailingStreet = testAddress.MailingStreet__c;

        insert testContact;

        Test.startTest();
            Contact contactToUpdate = [SELECT Undeliverable_Address__c FROM Contact WHERE Id = :testContact.Id];
            contactToUpdate.Undeliverable_Address__c = true;

            update contactToUpdate;
        Test.stopTest();

        Contact updatedContact = [SELECT Current_Address__c, Undeliverable_Address__c
                                  FROM Contact
                                  WHERE Id = :testContact.Id];
        Address__c updatedAddress = [SELECT Undeliverable__c
                                     FROM Address__c
                                     WHERE Id = :testAddress.Id];
        Account updatedAccount = [SELECT Undeliverable_Address__c
                                  FROM Account
                                  WHERE Id = :UTIL_UnitTestData_TEST.listAccT[0].Id];

        System.assertEquals(updatedContact.Current_Address__c, testAddress.Id);
        System.assertEquals(updatedContact.Undeliverable_Address__c, updatedAddress.Undeliverable__c,
                'Contact address undeliverable status should match address undeliverable status.');
        System.assertEquals(updatedContact.Undeliverable_Address__c, updatedAccount.Undeliverable_Address__c,
                'Contact address undeliverable status should match account undeliverable status.');
    }
}