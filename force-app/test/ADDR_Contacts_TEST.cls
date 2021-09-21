/*
    Copyright (c) 2021, Salesforce.org
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
* @group Address Management
* @description Tests specific to Address Management changes initiated by a DML operation on a contact record.
*/
@IsTest
public with sharing class ADDR_Contacts_TEST {

    @IsTest
    private static void newNonOverrideAddressCreatedFromContactUpdateGetsContactUndeliverableStatus() {
        //skip the test if Advancement is installed
        if (ADV_PackageInfo_SVC.useAdv()) {
            return;
        }

        List<Account> testAccountWithBillingAddress = createTestAccountsWithBillingAddress(1);

        NPSP_Contact npspContact = new NPSP_Contact(UTIL_UnitTestData_TEST.getContact());
        npspContact.getRecord().AccountId = testAccountWithBillingAddress[0].Id;
        insert npspContact.getRecord();

        Test.startTest();
            Contact contactToUpdate = [SELECT Current_Address__c FROM Contact WHERE Id = :npspContact.getRecord().Id];
            NPSP_Contact npspContactToUpdate = new NPSP_Contact(contactToUpdate);
            npspContactToUpdate.setUndeliverableMailingAddress(true);
            npspContactToUpdate.setCurrentAddress(
                    new NPSP_Address(buildAddresses(1, false)[0]));

            update npspContactToUpdate.getRecord();
        Test.stopTest();

        Contact updatedContact = [SELECT AccountId, Undeliverable_Address__c, Current_Address__c
                                  FROM Contact
                                  WHERE Id = :npspContactToUpdate.getRecord().Id];
        Address__c updatedAddress = [SELECT Undeliverable__c FROM Address__c WHERE Id = :updatedContact.Current_Address__c];

        System.assert(updatedContact.Undeliverable_Address__c == true, 'Contact undeliverable status should be true.');
        System.assert(updatedAddress.Undeliverable__c, 'The address undeliverable status should be true.');
        System.assertEquals(updatedContact.Undeliverable_Address__c, updatedAddress.Undeliverable__c, 'The newly ' +
                'created address from the contact should have the same undeliverable status as the contact it was ' +
                'created from.');
    }

    @IsTest
    private static void newOverrideAddressCreatedFromContactUpdateGetsContactUndeliverableStatus() {
        //skip the test if Advancement is installed
        if (ADV_PackageInfo_SVC.useAdv()) {
            return;
        }

        List<Account> testAccountWithBillingAddress = createTestAccountsWithBillingAddress(1);

        NPSP_Contact npspContact = new NPSP_Contact(UTIL_UnitTestData_TEST.getContact());
        npspContact.getRecord().AccountId = testAccountWithBillingAddress[0].Id;
        npspContact.getRecord().is_Address_Override__c = true;
        npspContact.setUndeliverableMailingAddress(true);
        insert npspContact.getRecord();

        Test.startTest();
            Contact contactToUpdate = [SELECT Current_Address__c FROM Contact WHERE Id = :npspContact.getRecord().Id];
            NPSP_Contact npspContactToUpdate = new NPSP_Contact(contactToUpdate);
            npspContactToUpdate.setCurrentAddress(
                    new NPSP_Address(buildAddresses(1, false)[0]));

            update npspContactToUpdate.getRecord();
        Test.stopTest();

        Contact updatedContact = [SELECT AccountId, Undeliverable_Address__c, Current_Address__c
                                  FROM Contact
                                  WHERE Id = :npspContactToUpdate.getRecord().Id];

        Address__c updatedAddress = [SELECT Undeliverable__c
                                     FROM Address__c
                                     WHERE Id = :updatedContact.Current_Address__c];

        System.assertEquals(updatedContact.Undeliverable_Address__c, updatedAddress.Undeliverable__c, 'The newly ' +
                'created address from the contact should have the same undeliverable status as the contact it was ' +
                'created from.');
    }

    @IsTest
    private static void updatedExistingDefaultContactAddressSyncsUndeliverableStatusToContact() {
        //skip the test if Advancement is installed
        if (ADV_PackageInfo_SVC.useAdv()) {
            return;
        }

        List<Account> testAccounts = UTIL_UnitTestData_TEST.createMultipleTestAccounts(1,
                CAO_Constants.HH_ACCOUNT_TYPE);
        insert testAccounts;

        List<Address__c> testAddresses = buildAddresses(2, false);

        NPSP_Address npspAddress = new NPSP_Address(testAddresses[1]);
        npspAddress.setUndeliverable(true);
        npspAddress.getRecord().Household_Account__c = testAccounts[0].Id;
        insert npspAddress.getRecord();

        Contact testContact = UTIL_UnitTestData_TEST.getContact();
        NPSP_Contact npspTestContact = new NPSP_Contact(testContact);
        npspTestContact.getRecord().AccountId = testAccounts[0].Id;
        npspTestContact.setCurrentAddress(
                new NPSP_Address(testAddresses[0]));
        insert npspTestContact.getRecord();

        Test.startTest();
            Contact contactToUpdate = [SELECT Current_Address__c
                                       FROM Contact
                                       WHERE Id = :npspTestContact.getRecord().Id];
            contactToUpdate.MailingStreet = testAddresses[1].MailingStreet__c;
            contactToUpdate.MailingPostalCode = testAddresses[1].MailingPostalCode__c;
            contactToUpdate.MailingCountry = testAddresses[1].MailingCountry__c;
            contactToUpdate.MailingState = testAddresses[1].MailingState__c;
            contactToUpdate.MailingCity = testAddresses[1].MailingCity__c;

            update contactToUpdate;
        Test.stopTest();

        Contact updatedContact = [SELECT AccountId, Undeliverable_Address__c, Current_Address__c
                                  FROM Contact
                                  WHERE Id = :contactToUpdate.Id];
        Address__c updatedAddress = [SELECT Undeliverable__c, Default_Address__c
                                     FROM Address__c
                                     WHERE Id = :updatedContact.Current_Address__c];

        System.assert(updatedAddress.Default_Address__c, 'The contact updated address should be the new household' +
                ' default.');
        System.assert(updatedAddress.Undeliverable__c, 'The new address assigned to the contact should have a true ' +
                'undeliverable status.');
        System.assertEquals(updatedAddress.Undeliverable__c, updatedContact.Undeliverable_Address__c, 'The newly ' +
                'created address from the contact should have the same undeliverable status as the contact it was ' +
                'created from.');
    }

    @IsTest
    private static void updatedExistingNonDefaultContactAddressSyncsAddressUndeliverableStatusToContact() {
        //skip the test if Advancement is installed
        if (ADV_PackageInfo_SVC.useAdv()) {
            return;
        }
        List<Account> testAccountWithBillingAddress = createTestAccountsWithBillingAddress(1);

        Contact testContact = UTIL_UnitTestData_TEST.getContact();
        testContact.AccountId = testAccountWithBillingAddress[0].Id;
        insert testContact;

        List<Address__c> undeliverableAddresses = buildAddresses(1, true);
        undeliverableAddresses[0].Household_Account__c = testAccountWithBillingAddress[0].Id;
        insert undeliverableAddresses;

        System.assert(!testContact.Undeliverable_Address__c, 'The contact address should not ' +
                'be undeliverable.');

        Test.startTest();
            Contact contactToUpdate = [SELECT MailingStreet, Current_Address__c
                                   FROM Contact
                                   WHERE Id = :testContact.Id];
            NPSP_Contact npspContact = new NPSP_Contact(contactToUpdate);
            npspContact.setCurrentAddress(new NPSP_Address(undeliverableAddresses[0]));

            update npspContact.getRecord();
        Test.stopTest();

        Contact updatedContact = [SELECT Undeliverable_Address__c, Current_Address__c
                                  FROM Contact WHERE Id = :contactToUpdate.Id];

        System.assertNotEquals(testContact.Current_Address__c, updatedContact.Current_Address__c, 'The ' +
                'contact address should have changed.');
        System.assertEquals(undeliverableAddresses[0].Id, updatedContact.Current_Address__c, 'The contact should get ' +
                'the newly updated address.');
        System.assert(updatedContact.Undeliverable_Address__c, 'The updated contact mailing address should ' +
                'be undeliverable.');
    }

    @IsTest
    private static void newContactUndeliverableStatusShouldSyncToNewAddressAndAccount() {
        //skip the test if Advancement is installed
        if (ADV_PackageInfo_SVC.useAdv()) {
            return;
        }

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

        Address__c updatedAddress = [SELECT Undeliverable__c, Default_Address__c
                                     FROM Address__c
                                     WHERE Id = :updatedContact.Current_Address__c];
        Account updatedAccount = [SELECT Undeliverable_Address__c
                                  FROM Account
                                  WHERE Id = :UTIL_UnitTestData_TEST.listAccT[0].Id];
        System.assert(updatedAddress.Default_Address__c, 'New address should be set as the default address.');
        System.assertEquals(updatedContact.Undeliverable_Address__c, updatedAddress.Undeliverable__c, 'Contact address ' +
                'undeliverable status should match address undeliverable status.');
        System.assertEquals(updatedContact.Undeliverable_Address__c, updatedAccount.Undeliverable_Address__c,
                'Contact address undeliverable status should match account undeliverable status.');
    }

    @IsTest
    private static void newContactAndUndeliverableStatusShouldNotOverrideAccountOrAddressUndeliverableStatus() {
        //skip the test if Advancement is installed
        if (ADV_PackageInfo_SVC.useAdv()) {
            return;
        }

        Account testAccount = UTIL_UnitTestData_TEST.buildHouseholdAccount();
        testAccount.BillingState = 'Test State';
        testAccount.BillingPostalCode = '12345';
        testAccount.BillingCountry = 'US';
        testAccount.BillingCity = 'Test City';
        testAccount.BillingStreet = 'Test Street';
        testAccount.Undeliverable_Address__c = true;
        insert testAccount;

        Contact testContact = UTIL_UnitTestData_TEST.getContact();
        testContact.MailingState = 'Test State';
        testContact.MailingPostalCode = '12345';
        testContact.MailingCountry = 'US';
        testContact.MailingCity = 'Test City';
        testContact.MailingStreet = 'Test Street';
        testContact.AccountId = testAccount.Id;

        Test.startTest();
            insert testContact;
        Test.stopTest();

        Address__c updatedAddress = [SELECT Undeliverable__c, Default_Address__c
                                     FROM Address__c
                                     WHERE Household_Account__c = :testAccount.Id];

        Account updatedAccount = [SELECT Undeliverable_Address__c
                                  FROM Account
                                  WHERE Id = :testAccount.Id];

        System.assert(updatedAddress.Default_Address__c, 'The address should be marked as default.');
        System.assertEquals(true, updatedAddress.Undeliverable__c, 'The address undeliverable address status ' +
            'should not be overriden by a new contact using the same address.');
        System.assertEquals(true, updatedAccount.Undeliverable_Address__c, 'The account undeliverable address status ' +
            'should not be overriden by a new contact using the same address.');
    }

    @IsTest
    private static void updatedContactUndeliverableStatusShouldSyncToNewAddressAndAccount() {
        //skip the test if Advancement is installed
        if (ADV_PackageInfo_SVC.useAdv()) {
            return;
        }

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
    private static void updatedFalseContactUndeliverableStatusShouldSyncToExistingAddressAndAccount() {
        //skip the test if Advancement is installed
        if (ADV_PackageInfo_SVC.useAdv()) {
            return;
        }

        UTIL_UnitTestData_TEST.createAccountContactTestData(CAO_Constants.HH_ACCOUNT_TYPE, 1, 1, 0);

        Address__c testAddress = new Address__c();
        testAddress.MailingStreet__c = '123 Existing Address';
        testAddress.MailingCity__c = 'Washington';
        testAddress.MailingPostalCode__c = 'ExistingZip';
        testAddress.MailingCountry__c = 'United States';
        testAddress.MailingState__c = 'Seattle';
        testAddress.Household_Account__c = UTIL_UnitTestData_TEST.listAccT[0].Id;
        testAddress.Undeliverable__c = true;
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
            contactToUpdate.Undeliverable_Address__c = false;

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

        System.assertEquals(updatedContact.Current_Address__c, testAddress.Id, 'The contact should have the expected ' +
                'current address lookup assigned.');
        System.assertEquals(false, updatedContact.Undeliverable_Address__c,
                'contact undeliverable status should be false.');
        System.assertEquals(false, updatedAddress.Undeliverable__c,
                'contact undeliverable status should be false.');
        System.assertEquals(updatedAddress.Undeliverable__c, updatedContact.Undeliverable_Address__c,
                'address undeliverable status should match contact address undeliverable status.');
        System.assertEquals(updatedAccount.Undeliverable_Address__c, updatedContact.Undeliverable_Address__c,
                'account address undeliverable status should match contact undeliverable status.');
    }

    @IsTest
    private static void updatedTrueContactUndeliverableStatusShouldSyncToExistingAddressAndAccount() {
        //skip the test if Advancement is installed
        if (ADV_PackageInfo_SVC.useAdv()) {
            return;
        }

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

        System.assertEquals(testAddress.Id, updatedContact.Current_Address__c, 'The contact current address should be' +
                ' the newly created address record id.');
        System.assertEquals(updatedContact.Undeliverable_Address__c, updatedAccount.Undeliverable_Address__c,
                'new contact address undeliverable status should match the household address undeliverable status.');
        System.assertEquals(updatedContact.Undeliverable_Address__c, updatedAddress.Undeliverable__c,
                'new contact address undeliverable status should match the address undeliverable status.');
    }

    @IsTest
    private static void existingHouseholdAddressUndeliverableStatusSyncsToNewContact() {
        //skip the test if Advancement is installed
        if (ADV_PackageInfo_SVC.useAdv()) {
            return;
        }

        UTIL_UnitTestData_TEST.createAccountContactTestData(CAO_Constants.HH_ACCOUNT_TYPE, 1, 0, 0);

        Address__c testAddress = new Address__c();
        testAddress.MailingStreet__c = '123 Existing Address';
        testAddress.MailingCity__c = 'Washington';
        testAddress.MailingPostalCode__c = 'ExistingZip';
        testAddress.MailingCountry__c = 'United States';
        testAddress.MailingState__c = 'Seattle';
        testAddress.Household_Account__c = UTIL_UnitTestData_TEST.listAccT[0].Id;
        testAddress.Default_Address__c = true;
        testAddress.Undeliverable__c = true;
        insert testAddress;

        Contact testContact = UTIL_UnitTestData_TEST.getContact();
        testContact.AccountId = UTIL_UnitTestData_TEST.listAccT[0].Id;

        Test.startTest();
            insert testContact;
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

        System.assertEquals(testAddress.Id, updatedContact.Current_Address__c, 'The contact current address should be' +
                ' the newly created address record id.');
        System.assertEquals(true, updatedAddress.Undeliverable__c, 'The updated address should be marked ' +
                'undeliverable.');
        System.assertEquals(updatedContact.Undeliverable_Address__c, updatedAddress.Undeliverable__c,
                'Contact address undeliverable status should match address undeliverable status.');
        System.assertEquals(updatedContact.Undeliverable_Address__c, updatedAccount.Undeliverable_Address__c,
                'Contact address undeliverable status should match account undeliverable status.');
    }

    private static List<Account> createTestAccountsWithBillingAddress(Integer numberOfAccountsToCreate) {
        List<Account> testAccounts = UTIL_UnitTestData_TEST.createMultipleTestAccounts(
                numberOfAccountsToCreate, CAO_Constants.HH_ACCOUNT_TYPE);

        for (Account account : testAccounts) {
            account.BillingStreet = '123 Household Street';
            account.BillingCity = 'Household City';
            account.BillingPostalCode = '12345';
            account.BillingState = 'Household State';
            account.BillingCountry = 'Household Country';
        }

        insert testAccounts;

        return testAccounts;
    }

    private static List<Address__c> buildAddresses(Integer numberOfAddressesToCreate, Boolean isUndeliverable) {
        List<Address__c> addressesToBuild = new List<Address__c>();
        for (Integer i = 0; i < numberOfAddressesToCreate; i++) {
            Address__c address = new Address__c();
            address.Address_Type__c = 'Home';
            address.MailingStreet__c = 'Washington Street' + i;
            address.MailingCity__c = 'Washington City' + i;
            address.MailingState__c = 'Washington';
            address.MailingPostalCode__c = 'Zip' + i;
            address.MailingCountry__c = 'United States';
            address.Undeliverable__c = isUndeliverable;

            addressesToBuild.add(address);
        }

        return addressesToBuild;
    }
}