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
            npspContactToUpdate.setCurrentAddress(
                    new NPSP_Address(buildAddresses(1, true)[0]));

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
            // Fetch the contact and simulate an address update
            Contact contactToUpdate = [SELECT Current_Address__c FROM Contact WHERE Id = :npspContact.getRecord().Id];
            // Simulate updating the contact's address with the new undeliverable address
            NPSP_Contact npspContactToUpdate = new NPSP_Contact(contactToUpdate);
            npspContactToUpdate.setCurrentAddress(
                    new NPSP_Address(buildAddresses(1, false)[0]));

            update npspContactToUpdate.getRecord();
        Test.stopTest();

        // Fetch the updated contact to check the address change
        Contact updatedContact = [SELECT AccountId, Undeliverable_Address__c, Current_Address__c
                                  FROM Contact
                                  WHERE Id = :npspContactToUpdate.getRecord().Id];
       
        // Fetch the updated address and verify the undeliverable status
        Address__c updatedAddress = [SELECT Undeliverable__c
                                     FROM Address__c
                                    WHERE Id = :updatedContact.Current_Address__c];
        // Assert that the contact's undeliverable status matches the address's undeliverable status
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
        testAccount.BillingState = 'Washington';
        testAccount.BillingPostalCode = '12345';
        testAccount.BillingCountry = 'United States';
        testAccount.BillingCity = 'Test City';
        testAccount.BillingStreet = 'Test Street';
        testAccount.Undeliverable_Address__c = true;
        insert testAccount;

        Contact testContact = UTIL_UnitTestData_TEST.getContact();
        testContact.MailingState = 'Washington';
        testContact.MailingPostalCode = '12345';
        testContact.MailingCountry = 'United States';
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
        testAddress.MailingCity__c = 'Seattle';
        testAddress.MailingPostalCode__c = 'ExistingZip';
        testAddress.MailingCountry__c = 'United States';
        testAddress.MailingState__c = 'Washington';
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
        testAddress.MailingCity__c = 'Seattle';
        testAddress.MailingPostalCode__c = 'ExistingZip';
        testAddress.MailingCountry__c = 'United States';
        testAddress.MailingState__c = 'Washington';
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
        testAddress.MailingCity__c = 'Seattle';
        testAddress.MailingPostalCode__c = 'ExistingZip';
        testAddress.MailingCountry__c = 'United States';
        testAddress.MailingState__c = 'Washington';
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

    /**
     * @description Validates that the address logic works properly when State and Country Picklsits are enabled in an org
     * and the OtherAddress fields sync properly from Contact to Account
     */
    @IsTest
    private static void shouldRetainCountyAndStateWhenContactOtherAddressIsUsed() {
        //skip the test if Advancement is installed
        if (ADV_PackageInfo_SVC.useAdv()) {
            return;
        }

        OrgConfig orgConfig = new OrgConfig();
        Boolean isStateCountryEnabled = orgConfig.isStateCountryPicklistsEnabled();

        final String TEST_STREET = '123 Household Street';
        final String TEST_CITY = 'Seattle';
        final String TEST_STATE = 'Washington';
        final String TEST_STATE_CODE = 'WA';
        final String TEST_POSTAL = '08534';
        final String TEST_COUNTRY = 'United States';
        final String TEST_COUNTRY_CODE = 'US';

        final String TEST_OTHER_STREET = '321 Work Street';
        final String TEST_OTHER_COUNTRY = 'Canada';
        final String TEST_OTHER_COUNTRY_CODE = 'CA';
        final String TEST_OTHER_STATE = 'Alberta';
        final String TEST_OTHER_STATE_CODE = 'AB';

        Contact testContact = new Contact(
            FirstName = CAO_Constants.CONTACT_FIRSTNAME_FOR_TESTS,
            LastName = CAO_Constants.CONTACT_LASTNAME_FOR_TESTS + UTIL_UnitTestData_TEST.getUniqueString()
        );
        testContact.MailingStreet = TEST_STREET;
        testContact.MailingCity = TEST_CITY;
        testContact.MailingPostalCode = TEST_POSTAL;
        testContact.OtherStreet = TEST_OTHER_STREET;
        if (isStateCountryEnabled) {
            testContact.put('MailingStateCode', TEST_STATE_CODE);
            testContact.put('MailingCountryCode', TEST_COUNTRY_CODE);
            testContact.put('OtherStateCode', TEST_OTHER_STATE_CODE);
            testContact.put('OtherCountryCode', TEST_OTHER_COUNTRY_CODE);
        } else {
            testContact.put('MailingState', TEST_STATE);
            testContact.put('MailingCountry', TEST_COUNTRY);
            testContact.put('OtherState', TEST_OTHER_STATE);
            testContact.put('OtherCountry', TEST_OTHER_COUNTRY);
        }

        Test.startTest();
        insert testContact;
        Test.stopTest();

        String contactSOQL = 'SELECT Id, AccountId, Current_Address__c, ' 
                        + 'MailingStreet, MailingCity, MailingState, MailingPostalCode, MailingCountry, '
                        + 'OtherStreet, OtherCity, OtherState, OtherCountry';
        if (isStateCountryEnabled) {
            contactSOQL += ', MailingStateCode, MailingCountryCode, OtherStateCode, OtherCountryCode';
        }
        contactSOQL += ' FROM Contact WHERE Id = \'' + testContact.Id +'\'';
        testContact = Database.query(contactSOQL);

        Address__c addr = [SELECT MailingStreet__c, MailingCity__c, MailingState__c, MailingPostalCode__c, MailingCountry__c
                                    FROM Address__c
                                    WHERE Id = :testContact.Current_Address__c
                                    LIMIT 1];

        String accountSOQL = 'SELECT Id, BillingStreet, BillingCity, BillingState, BillingPostalCode, BillingCountry, '
                        + 'ShippingStreet, ShippingCity, ShippingState, ShippingCountry';
        if (isStateCountryEnabled) {
            accountSOQL += ', BillingStateCode, BillingCountryCode, ShippingStateCode, ShippingCountryCode';
        }
        accountSOQL += ' FROM Account WHERE Id = \'' + testContact.AccountId +'\'';
        Account acct = Database.query(accountSOQL);

        System.assertEquals(testContact.MailingStreet, TEST_STREET);
        System.assertEquals(testContact.MailingCity, TEST_CITY);
        System.assertEquals(testContact.MailingPostalCode, TEST_POSTAL);
        System.assertEquals(testContact.MailingState, TEST_STATE, 'The MailingState field should have a value');
        System.assertEquals(testContact.MailingCountry, TEST_COUNTRY, 'The MailingCountry field should have a value');

        System.assertEquals(testContact.OtherStreet, TEST_OTHER_STREET);
        System.assertEquals(testContact.OtherState, TEST_OTHER_STATE);
        System.assertEquals(testContact.OtherCountry, TEST_OTHER_COUNTRY, 'The MailingCountry field should have a value');

        if (isStateCountryEnabled) {
            System.assertEquals(testContact.get('MailingStateCode'), TEST_STATE_CODE, 'The MailingStateCode field should have a value');
            System.assertEquals(testContact.get('MailingCountryCode'), TEST_COUNTRY_CODE, 'The MailingCountryCode field should have a value');
            System.assertEquals(testContact.get('OtherStateCode'), TEST_OTHER_STATE_CODE, 'The OtherStateCode field should have a value');
            System.assertEquals(testContact.get('OtherCountryCode'), TEST_OTHER_COUNTRY_CODE, 'The OtherCountryCode field should have a value');
        }

        System.assertEquals(acct.BillingStreet, TEST_STREET);
        System.assertEquals(acct.BillingCity, TEST_CITY);
        System.assertEquals(acct.BillingPostalCode, TEST_POSTAL);
        System.assertEquals(acct.BillingState, TEST_STATE, 'The BillingState field should have a value');
        System.assertEquals(acct.BillingCountry, TEST_COUNTRY, 'The BillingCountry field should have a value');
        
        System.assertEquals(acct.ShippingStreet, TEST_OTHER_STREET);
        System.assertEquals(acct.ShippingState, TEST_OTHER_STATE);
        System.assertEquals(acct.ShippingCountry, TEST_OTHER_COUNTRY, 'The ShippingCountry field should have a value');

        if (isStateCountryEnabled) {
            System.assertEquals(acct.get('BillingStateCode'), TEST_STATE_CODE, 'The BillingStateCode field should have a value');
            System.assertEquals(acct.get('BillingCountryCode'), TEST_COUNTRY_CODE, 'The BillingCountryCode field should have a value');
            System.assertEquals(acct.get('ShippingStateCode'), TEST_OTHER_STATE_CODE, 'The ShippingStateCode field should have a value');
            System.assertEquals(acct.get('ShippingCountryCode'), TEST_OTHER_COUNTRY_CODE, 'The ShippingCountryCode field should have a value');
        }

        System.assertEquals(addr.MailingStreet__c, TEST_STREET);
        System.assertEquals(addr.MailingCity__c, TEST_CITY);
        System.assertEquals(addr.MailingPostalCode__c, TEST_POSTAL);
        System.assert(addr.MailingState__c != null, 'The MailingState field should have a value');
        System.assert(addr.MailingCountry__c != null, 'The MailingCountry field should have a value');
    }

    /**
     * @description Validates that the address logic works properly when State and Country Picklsits are enabled in an org
     */
    @IsTest
    private static void shouldCreateAddressForContactWithAllFieldsFilledIn() {
        //skip the test if Advancement is installed
        if (ADV_PackageInfo_SVC.useAdv()) {
            return;
        }

        OrgConfig orgConfig = new OrgConfig();
        Boolean isStateCountryEnabled = orgConfig.isStateCountryPicklistsEnabled();

        final String TEST_STREET = '123 Household Street';
        final String TEST_CITY = 'Seattle';
        final String TEST_STATE = 'Washington';
        final String TEST_STATE_CODE = 'WA';
        final String TEST_POSTAL = '08534';
        final String TEST_COUNTRY = 'United States';
        final String TEST_COUNTRY_CODE = 'US';

        Contact testContact = new Contact(
            FirstName = CAO_Constants.CONTACT_FIRSTNAME_FOR_TESTS,
            LastName = CAO_Constants.CONTACT_LASTNAME_FOR_TESTS + UTIL_UnitTestData_TEST.getUniqueString()
        );
        testContact.MailingStreet = TEST_STREET;
        testContact.MailingCity = TEST_CITY;
        testContact.MailingPostalCode = TEST_POSTAL;
        if (isStateCountryEnabled) {
            testContact.put('MailingStateCode', TEST_STATE_CODE);
            testContact.put('MailingCountryCode', TEST_COUNTRY_CODE);
        } else {
            testContact.put('MailingState', TEST_STATE);
            testContact.put('MailingCountry', TEST_COUNTRY);
        }

        Test.startTest();
        insert testContact;
        Test.stopTest();

        String contactSOQL = 'SELECT Id, AccountId, Current_Address__c, ' 
                        + 'MailingStreet, MailingCity, MailingState, MailingPostalCode, MailingCountry';
        if (isStateCountryEnabled) {
            contactSOQL += ', MailingStateCode, MailingCountryCode';
        }
        contactSOQL += ' FROM Contact WHERE Id = \'' + testContact.Id +'\'';
        testContact = Database.query(contactSOQL);

        Address__c addr = [SELECT MailingStreet__c, MailingCity__c, MailingState__c, MailingPostalCode__c, MailingCountry__c
                                    FROM Address__c
                                    WHERE Id = :testContact.Current_Address__c
                                    LIMIT 1];

        String accountSOQL = 'SELECT Id, BillingStreet, BillingCity, BillingState, BillingPostalCode, BillingCountry';
        if (isStateCountryEnabled) {
            accountSOQL += ', BillingStateCode, BillingCountryCode';
        }
        accountSOQL += ' FROM Account WHERE Id = \'' + testContact.AccountId +'\'';
        Account acct = Database.query(accountSOQL);

        System.assertEquals(testContact.MailingStreet, TEST_STREET);
        System.assertEquals(testContact.MailingCity, TEST_CITY);
        System.assertEquals(testContact.MailingPostalCode, TEST_POSTAL);
        System.assertEquals(testContact.MailingState, TEST_STATE, 'The MailingState field should have a value');
        System.assertEquals(testContact.MailingCountry, TEST_COUNTRY, 'The MailingCountry field should have a value');
        if (isStateCountryEnabled) {
            System.assertEquals(testContact.get('MailingStateCode'), TEST_STATE_CODE, 'The MailingStateCode field should have a value');
            System.assertEquals(testContact.get('MailingCountryCode'), TEST_COUNTRY_CODE, 'The MailingCountryCode field should have a value');
        }

        System.assertEquals(acct.BillingStreet, TEST_STREET);
        System.assertEquals(acct.BillingCity, TEST_CITY);
        System.assertEquals(acct.BillingPostalCode, TEST_POSTAL);
        System.assertEquals(acct.BillingState, TEST_STATE, 'The BillingState field should have a value');
        System.assertEquals(acct.BillingCountry, TEST_COUNTRY, 'The BillingCountry field should have a value');
        if (isStateCountryEnabled) {
            System.assertEquals(acct.get('BillingStateCode'), TEST_STATE_CODE, 'The BillingStateCode field should have a value');
            System.assertEquals(acct.get('BillingCountryCode'), TEST_COUNTRY_CODE, 'The BillingCountryCode field should have a value');
        }

        System.assertEquals(addr.MailingStreet__c, TEST_STREET);
        System.assertEquals(addr.MailingCity__c, TEST_CITY);
        System.assertEquals(addr.MailingPostalCode__c, TEST_POSTAL);
        System.assert(addr.MailingState__c != null, 'The MailingState field should have a value');
        System.assert(addr.MailingCountry__c != null, 'The MailingCountry field should have a value');
    }


    // ====================================================
    // Helper Methods

    private static List<Account> createTestAccountsWithBillingAddress(Integer numberOfAccountsToCreate) {
        List<Account> testAccounts = UTIL_UnitTestData_TEST.createMultipleTestAccounts(
                numberOfAccountsToCreate, CAO_Constants.HH_ACCOUNT_TYPE);

        for (Account account : testAccounts) {
            account.BillingStreet = '123 Household Street';
            account.BillingCity = 'Household City';
            account.BillingPostalCode = '98005';
            account.BillingState = 'Washington';
            account.BillingCountry = 'United States';
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