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
/**
* @author Salesforce.org
* @date 2013
* @group Address Management
* @description Tests specific to Address Management. 
*/

@IsTest
public with sharing class ADDR_Addresses_TEST {

    /*********************************************************************************************************
    * @description Holds the number of Households to create in tests.
    */
    private static final Integer cHH = 2;

    /*********************************************************************************************************
    * @description Holds the number of Contacts per Household to create in tests.
    */
    static Integer cCon = 2;

    /*********************************************************************************************************
    * @description The list of created test Contacts.
    */
    public static List<Contact> listConT;

    /*********************************************************************************************************
    * @description The list of created test Accounts.
    */
    public static List<Account> listAccT;

    /*********************************************************************************************************
    * @description The list of created test Addresses.
    */
    public static List<Address__c> listAddrT;

    private static OrgConfig orgConfig = new OrgConfig();

    /*********************************************************************************************************
    @description
        create N new default Addresses for N Households (with M Contacts)
    verify:
        N addresses created
        N household billing address fields updated
        M contact Mailing address fields updated
    **********************************************************************************************************/
    @IsTest
    private static void newDefaultAddr() {

        // this creates a default Address for each HH
        createHHTestData(cHH, cCon);
        Test.startTest();
        Test.stopTest();

        // verify that the HH and Contacts share the same address
        Map<Id, Account> mapAccIdAcc = new Map<Id, Account>([SELECT Id, Name, BillingStreet, BillingCity, BillingState, BillingPostalCode, BillingCountry, BillingLatitude, BillingLongitude FROM Account]);
        List<Contact> listCon = [SELECT Id, Name, AccountId, is_Address_Override__c, Current_Address__c, MailingStreet, MailingCity, MailingState, MailingPostalCode, MailingCountry, MailingLatitude, MailingLongitude FROM Contact];

        for (Contact con : listCon) {
            Account acc = mapAccIdAcc.get(con.AccountId);
            System.assertEquals(true, isMatchAddressAccCon(acc, con));
            System.assertEquals(false, con.is_Address_Override__c);
            System.assertNotEquals(null, con.Current_Address__c);
        }
    }

    /*********************************************************************************************************
    @description
        insert contact w/ address
    verify:
        new default Address created
        contact address lookup updated to new address
        the contact gets the new Address
    **********************************************************************************************************/
    @IsTest
    private static void insertContactWithAddress() {
        //skip the test if Advancement is installed
        if (ADV_PackageInfo_SVC.useAdv()) {
            return;
        }

        npe01__Contacts_And_Orgs_Settings__c contactSettingsForTests = UTIL_CustomSettingsFacade.getContactsSettings();

        listConT = UTIL_UnitTestData_TEST.createMultipleTestContacts(cCon);
        for (Contact con : listConT) {
            con.MailingStreet = 'new street';
            con.MailingCity = 'new city';
            con.npe01__Primary_Address_Type__c = 'Other';
        }
        Test.startTest();
        insert listConT;
        Test.stopTest();

        // verify that the HH and Contacts share the same address
        Map<Id, Account> mapAccIdAcc = new Map<Id, Account>([SELECT Id, Name, BillingStreet, BillingCity, BillingState, BillingPostalCode, BillingCountry, BillingLatitude, BillingLongitude FROM Account]);
        List<Contact> listCon = [SELECT Id, Name, AccountId, is_Address_Override__c, Current_Address__c, npe01__Primary_Address_Type__c, MailingStreet, MailingCity, MailingState, MailingPostalCode, MailingCountry, MailingLatitude, MailingLongitude FROM Contact];

        for (Contact con : listCon) {
            Account acc = mapAccIdAcc.get(con.AccountId);
            System.assertEquals(true, isMatchAddressAccCon(acc, con));
            System.assertEquals(false, con.is_Address_Override__c);
            System.assertNotEquals(null, con.Current_Address__c);
            System.assertEquals('Other', con.npe01__Primary_Address_Type__c);
        }

        List<Address__c> listAddr = [
            SELECT Id, Default_Address__c, MailingStreet__c, Household_Account__c, Address_Type__c
            FROM Address__c
            WHERE Default_Address__c = TRUE
        ];
        System.assertEquals(cCon, listAddr.size());
        for (Address__c addr : listAddr) {
            System.assertEquals('Other', addr.Address_Type__c);
        }
    }

    /*********************************************************************************************************
    @description
        insert contact w/ address, and force recreate of hh account
    verify:
        new default Address created
        contact address lookup updated to new address
        the contact gets the new Address
        the household account gets the new Address
    **********************************************************************************************************/
    @IsTest
    private static void insertContactWithAddressRecreateAccount() {
        //skip the test if Advancement is installed
        if (ADV_PackageInfo_SVC.useAdv()) return;

        TDTM_DefaultConfig.startTestDataInit();
        npe01__Contacts_And_Orgs_Settings__c contactSettingsForTests = UTIL_CustomSettingsFacade.getContactsSettings();

        listConT = UTIL_UnitTestData_TEST.createMultipleTestContacts(cCon);
        for (Contact con : listConT) {
            con.MailingStreet = 'new street';
            con.MailingCity = 'new city';
        }
        insert listConT;
        TDTM_DefaultConfig.stopTestDataInit();

        // null out account, so a new account will be created.
        Test.startTest();
        for (Contact con : listConT) {
            con.AccountId = null;
        }
        update listConT;
        Test.stopTest();

        // verify that the HH and Contacts share the same address
        Map<Id, Account> mapAccIdAcc = new Map<Id, Account>([SELECT Id, Name, BillingStreet, BillingCity, BillingState, BillingPostalCode, BillingCountry, BillingLatitude, BillingLongitude FROM Account]);
        List<Contact> listCon = [SELECT Id, Name, AccountId, is_Address_Override__c, Current_Address__c, MailingStreet, MailingCity, MailingState, MailingPostalCode, MailingCountry, MailingLatitude, MailingLongitude FROM Contact];

        for (Contact con : listCon) {
            Account acc = mapAccIdAcc.get(con.AccountId);
            System.assertEquals(true, isMatchAddressAccCon(acc, con));
            System.assertEquals(false, con.is_Address_Override__c);
            System.assertNotEquals(null, con.Current_Address__c);
        }
    }

    /*********************************************************************************************************
    @description
        insert contact w/ new address override
    verify:
        new non-default Address created
        contact address lookup updated to new address
        the contact gets the new Address
    **********************************************************************************************************/
    @IsTest
    private static void insertContactWithAddressOverride() {
        //skip the test if Advancement is installed
        if (ADV_PackageInfo_SVC.useAdv()) return;

        npe01__Contacts_And_Orgs_Settings__c contactSettingsForTests = UTIL_CustomSettingsFacade.getContactsSettings();

        listConT = UTIL_UnitTestData_TEST.createMultipleTestContacts(cCon);
        Integer i = 1;
        for (Contact con : listConT) {
            con.MailingStreet = 'new street' + i;
            con.MailingCity = 'new city' + i;
            con.is_Address_Override__c = true;
            i++;
        }
        Test.startTest();
        insert listConT;
        Test.stopTest();

        // verify that the HH and Contacts share the same address
        Map<Id, Account> mapAccIdAcc = new Map<Id, Account>([SELECT Id, Name, BillingStreet, BillingCity, BillingState, BillingPostalCode, BillingCountry, BillingLatitude, BillingLongitude FROM Account]);
        List<Contact> listCon = [SELECT Id, Name, AccountId, is_Address_Override__c, Current_Address__c, MailingStreet, MailingCity, MailingState, MailingPostalCode, MailingCountry, MailingLatitude, MailingLongitude FROM Contact];

        for (Contact con : listCon) {
            Account acc = mapAccIdAcc.get(con.AccountId);
            System.assertEquals(false, isMatchAddressAccCon(acc, con));
            System.assertEquals(null, acc.BillingStreet);
            System.assertEquals(true, con.is_Address_Override__c);
            System.assertNotEquals(null, con.Current_Address__c);
        }
    }

    /*********************************************************************************************************
    @description
        update existing default Addresses
    verify:
        household billing address fields updated
        contact Mailing address fields updated
    **********************************************************************************************************/
    @IsTest
    private static void updateDefaultAddr() {

        // this creates a default Address for each HH
        createHHTestData(cHH, cCon);

        // now let's update the Addresses
        for (Integer i = 0; i < cHH; i++) {
            Address__c addr = listAddrT[i];
            addr.MailingStreet__c = 'New Street' + i;
            addr.MailingCity__c = 'New City' + i;
        }
        Test.startTest();
        update listAddrT;
        Test.stopTest();

        // verify that the HH and Contacts share the same address and it's new!
        Map<Id, Account> mapAccIdAcc = new Map<Id, Account>([SELECT Id, Name, BillingStreet, BillingCity, BillingState, BillingPostalCode, BillingCountry, BillingLatitude, BillingLongitude FROM Account]);
        List<Contact> listCon = [SELECT Id, Name, AccountId, is_Address_Override__c, Current_Address__c, MailingStreet, MailingCity, MailingState, MailingPostalCode, MailingCountry, MailingLatitude, MailingLongitude FROM Contact];
        System.assertEquals(cHH * cCon, listCon.size());

        for (Contact con : listCon) {
            Account acc = mapAccIdAcc.get(con.AccountId);
            System.assertEquals(true, isMatchAddressAccCon(acc, con));
            System.assert(con.MailingStreet.contains('New Street'));
            System.assert(con.MailingCity.contains('New City'));
            System.assertEquals(false, con.is_Address_Override__c);
            System.assertNotEquals(null, con.Current_Address__c);
        }
    }

    /*********************************************************************************************************
    @description
        delete existing default Addresses
    verify:
        household billing address fields cleared
        contact Mailing address fields cleared
    **********************************************************************************************************/
    @IsTest
    private static void deleteDefaultAddr() {

        // this creates a default Address for each HH
        createHHTestData(cHH, cCon);

        // now let's delete the Addresses
        Test.startTest();
        delete listAddrT;
        Test.stopTest();

        // verify that the HH and Contacts' address fields are cleared
        Map<Id, Account> mapAccIdAcc = new Map<Id, Account>([SELECT Id, Name, BillingStreet, BillingCity, BillingState, BillingPostalCode, BillingCountry, BillingLatitude, BillingLongitude FROM Account]);
        List<Contact> listCon = [SELECT Id, Name, AccountId, is_Address_Override__c, Current_Address__c, MailingStreet, MailingCity, MailingState, MailingPostalCode, MailingCountry, MailingLatitude, MailingLongitude FROM Contact];
        System.assertEquals(cHH * cCon, listCon.size());

        for (Contact con : listCon) {
            Account acc = mapAccIdAcc.get(con.AccountId);
            System.assertEquals(true, isMatchAddressAccCon(acc, con));
            System.assertEquals(null, con.MailingStreet);
            System.assertEquals(null, con.MailingCity);
            System.assertEquals(false, con.is_Address_Override__c);
            System.assertEquals(null, con.Current_Address__c);
            System.assertEquals(null, acc.BillingStreet);
            System.assertEquals(null, acc.BillingCity);
        }
    }

    /*********************************************************************************************************
    @description
        delete existing non-default override Addresses
    verify:
        household billing address fields not changed
        contact Mailing address fields reset to default
    **********************************************************************************************************/
    @IsTest
    private static void deleteNonDefaultOverrideAddr() {

        // this creates a default Address for each HH
        createHHTestData(cHH, cCon);

        // create additional addresses
        initTestAddr(cHH);
        for (Integer i = 0; i < cHH; i++) {
            listAddrT[i].Household_Account__c = listAccT[i].Id;
            listAddrT[i].Default_Address__c = false;
            listAddrT[i].MailingStreet__c = 'override' + i;
            listAddrT[i].MailingCity__c = 'override' + i;
        }
        insert listAddrT;

        // set the contacts' address overrides
        List<Contact> listCon = new List<Contact>();
        for (Integer i = 0; i < cHH; i++) {
            Contact con = listConT[i * cHH + i];
            con.Current_Address__c = listAddrT[i].Id;
            con.is_Address_Override__c = true;
            listCon.add(con);
        }
        update listCon;

        // now let's delete the override Addresses
        Test.startTest();
        delete listAddrT;
        Test.stopTest();

        // verify that the HH and Contacts' address fields the default
        Map<Id, Account> mapAccIdAcc = new Map<Id, Account>([SELECT Id, Name, BillingStreet, BillingCity, BillingState, BillingPostalCode, BillingCountry, BillingLatitude, BillingLongitude FROM Account]);
        listCon = [SELECT Id, Name, AccountId, is_Address_Override__c, Current_Address__c, MailingStreet, MailingCity, MailingState, MailingPostalCode, MailingCountry, MailingLatitude, MailingLongitude FROM Contact];
        System.assertEquals(cHH * cCon, listCon.size());

        for (Contact con : listCon) {
            Account acc = mapAccIdAcc.get(con.AccountId);
            System.assertEquals(true, isMatchAddressAccCon(acc, con));
            System.assertEquals(false, con.is_Address_Override__c);
            System.assertNotEquals(null, con.Current_Address__c);
            System.assert(con.MailingStreet.contains('Street'));
            System.assert(con.MailingCity.contains('City'));
        }
    }

    /*********************************************************************************************************
    @description
        update existing non-default Addresses
    verify:
        no change to HH and contact addresses
    **********************************************************************************************************/
    @IsTest
    private static void updateNonDefaultAddr() {
        // this creates a default Address for each HH
        createHHTestData(cHH, cCon);

        // now let's update the Addresses
        for (Integer i = 0; i < cHH; i++) {
            Address__c addr = listAddrT[i];
            addr.Default_Address__c = false;
            addr.MailingStreet__c = 'New Street' + i;
            addr.MailingCity__c = 'New City' + i;
        }
        Test.startTest();
        update listAddrT;
        Test.stopTest();

        // verify that the HH and Contacts share the same address and it's new!
        Map<Id, Account> mapAccIdAcc = new Map<Id, Account>([SELECT Id, Name, BillingStreet, BillingCity, BillingState, BillingPostalCode, BillingCountry, BillingLatitude, BillingLongitude FROM Account]);
        List<Contact> listCon = [SELECT Id, Name, AccountId, is_Address_Override__c, Current_Address__c, MailingStreet, MailingCity, MailingState, MailingPostalCode, MailingCountry, MailingLatitude, MailingLongitude FROM Contact];
        System.assertEquals(cHH * cCon, listCon.size());

        for (Contact con : listCon) {
            Account acc = mapAccIdAcc.get(con.AccountId);
            System.assertEquals(true, isMatchAddressAccCon(acc, con));
            System.assert(!con.MailingStreet.contains('New Street'));
            System.assert(!con.MailingCity.contains('New City'));
            System.assertEquals(false, con.is_Address_Override__c);
            System.assertNotEquals(null, con.Current_Address__c);
        }
    }

    /*********************************************************************************************************
    @description
        set contact address override
    verify:
        contact's address matches override
    **********************************************************************************************************/
    @IsTest
    private static void setConAddrOverride() {

        // this creates a default Address for each HH
        createHHTestData(cHH, cCon);

        // create a new non-default address
        Address__c addrNew = new Address__c();
        addrNew.MailingStreet__c = 'street override';
        addrNew.MailingCity__c = 'city override';
        addrNew.Default_Address__c = false;
        addrNew.Household_Account__c = listAccT[0].Id;
        insert addrNew;

        // set a contact's address override
        listConT[0].Current_Address__c = addrNew.Id;
        listConT[0].is_Address_Override__c = true;
        update listConT[0];

        // now let's update the default Addresses
        for (Integer i = 0; i < cHH; i++) {
            Address__c addr = listAddrT[i];
            addr.MailingStreet__c = 'New Street' + i;
            addr.MailingCity__c = 'New City' + i;
        }
        Test.startTest();
        update listAddrT;
        Test.stopTest();

        // verify that the HH and Contacts share the same address and it's new!
        Map<Id, Account> mapAccIdAcc = new Map<Id, Account>([SELECT Id, Name, BillingStreet, BillingCity, BillingState, BillingPostalCode, BillingCountry, BillingLatitude, BillingLongitude FROM Account]);
        List<Contact> listCon = [SELECT Id, Name, AccountId, is_Address_Override__c, Current_Address__c, MailingStreet, MailingCity, MailingState, MailingPostalCode, MailingCountry, MailingLatitude, MailingLongitude FROM Contact];
        System.assertEquals(cHH * cCon, listCon.size());

        for (Contact con : listCon) {
            Account acc = mapAccIdAcc.get(con.AccountId);
            if (con.is_Address_Override__c) {
                System.assertEquals(con.Current_Address__c, addrNew.Id);
                System.assertEquals(false, isMatchAddressAccCon(acc, con), 'The Household address should not have been updated from the Contact');
                System.assert(!con.MailingStreet.contains('New Street'));
                System.assert(!con.MailingCity.contains('New City'));
            } else {
                System.assertEquals(true, isMatchAddressAccCon(acc, con), 'The Household address should have been updated from the Contact');
                System.assert(con.MailingStreet.contains('New Street'));
                System.assert(con.MailingCity.contains('New City'));
                System.assertEquals(false, con.is_Address_Override__c);
                System.assertNotEquals(null, con.Current_Address__c);
            }
        }
    }

    /*********************************************************************************************************
    @description
        set contact current address, but not override
    verify:
        contact's address updated, but not overriden; the household accounts address remains unchanged
    **********************************************************************************************************/
    @IsTest
    private static void setConAddrNoOverride() {
        //skip the test if Advancement is installed
        if (ADV_PackageInfo_SVC.useAdv()) return;

        // this creates a default Address for each HH
        createHHTestData(cHH, cCon);

        // create additional addresses
        initTestAddr(cHH);
        for (Integer i = 0; i < cHH; i++) {
            listAddrT[i].Household_Account__c = listAccT[i].Id;
            listAddrT[i].Default_Address__c = false;
            listAddrT[i].MailingStreet__c = 'not override' + i;
            listAddrT[i].MailingCity__c = 'not override' + i;
        }
        insert listAddrT;

        // set the contacts' "Current Address" to the new 'not override' address, but don't check "Is Address Override"
        List<Contact> listCon = new List<Contact>();
        for (Integer i = 0; i < cHH; i++) {
            Contact con = listConT[i * cHH + i];
            con.Current_Address__c = listAddrT[i].Id;
            con.is_Address_Override__c = false;
            listCon.add(con);
        }
        Test.startTest();
        update listCon;
        Test.stopTest();

        Map<Id, Account> mapAccIdAcc = new Map<Id, Account>([SELECT Id, Name, BillingStreet, BillingCity, BillingState, BillingPostalCode, BillingCountry, BillingLatitude, BillingLongitude FROM Account]);
        listCon = [SELECT Id, Name, AccountId, is_Address_Override__c, Current_Address__c, Current_Address__r.Default_Address__c, MailingStreet, MailingCity, MailingState, MailingPostalCode, MailingCountry, MailingLatitude, MailingLongitude FROM Contact];

        Integer nonOverrideAddressCounter = 0;

        for (Address__c address : [SELECT MailingCity__c FROM Address__c WHERE Default_Address__c = FALSE]) {
            if (address.MailingCity__c.startsWith('not')) {
                nonOverrideAddressCounter++;
            }
        }
        
        System.assertEquals(cHH, nonOverrideAddressCounter,
            'There should be one "not override" address per Household not set as default address');

        Integer cNotOverride = 0;
        for (Contact con : listCon) {
            Account acc = mapAccIdAcc.get(con.AccountId);
            if (con.MailingStreet.contains('not override') == true) {
                cNotOverride++;
                System.assertEquals(false, con.Current_Address__r.Default_Address__c);
                System.assertEquals(false, isMatchAddressAccCon(acc, con), 'The Household address should not have been updated from the Contact');
                System.assert(con.MailingStreet.contains('not override'));
                System.assert(con.MailingCity.contains('not override'));
                System.assertEquals(false, con.is_Address_Override__c);
                System.assertNotEquals(null, con.Current_Address__c);
            } else {
                System.assertEquals(true, con.Current_Address__r.Default_Address__c);
                System.assertEquals(true, isMatchAddressAccCon(acc, con), 'The Household address should remain unchanged from before and match the Contact that was not updated');
                System.assert(con.MailingStreet.contains('Street'));
                System.assert(con.MailingCity.contains('City'));
                System.assertEquals(false, con.is_Address_Override__c);
                System.assertNotEquals(null, con.Current_Address__c);
            }
        }
        System.assertEquals(cHH, cNotOverride, 'There should be one Contact per Household with the "not override" address');
    }

    /*********************************************************************************************************
    @description
        insert new default addresses to HH w/ existing default addresses
    verify:
        contact's && hh address matches new default
        old default addresses no longer marked default
    **********************************************************************************************************/
    @IsTest
    private static void insertNewDefaultAddr() {

        // this creates a default Address for each HH
        createHHTestData(cHH, cCon);

        // create additional addresses
        initTestAddr(cHH);
        for (Integer i = 0; i < cHH; i++) {
            listAddrT[i].Household_Account__c = listAccT[i].Id;
            listAddrT[i].Default_Address__c = true;
            listAddrT[i].MailingStreet__c = 'New Default Street' + i;
            listAddrT[i].MailingCity__c = 'New Default City' + i;
        }
        Test.startTest();
        insert listAddrT;
        Test.stopTest();

        // verify that the HH and Contacts share the same address and it's new!
        Map<Id, Account> mapAccIdAcc = new Map<Id, Account>([SELECT Id, Name, BillingStreet, BillingCity, BillingState, BillingPostalCode, BillingCountry, BillingLatitude, BillingLongitude FROM Account]);
        List<Contact> listCon = [SELECT Id, Name, AccountId, is_Address_Override__c, Current_Address__c, MailingStreet, MailingCity, MailingState, MailingPostalCode, MailingCountry, MailingLatitude, MailingLongitude FROM Contact];
        System.assertEquals(cHH * cCon, listCon.size());

        for (Contact con : listCon) {
            Account acc = mapAccIdAcc.get(con.AccountId);
            System.assertEquals(true, isMatchAddressAccCon(acc, con));
            System.assert(con.MailingStreet.contains('New Default Street'));
            System.assert(con.MailingCity.contains('New Default City'));
            System.assertEquals(false, con.is_Address_Override__c);
            System.assertNotEquals(null, con.Current_Address__c);
        }

        // verify the previous addresses got Default cleared.
        // and verify latest start date and latest end date appropriately set.
        List<Address__c> listAddr = [SELECT Id, Default_Address__c, MailingStreet__c, Household_Account__c, Latest_Start_Date__c, Latest_End_Date__c FROM Address__c];
        System.assertEquals(cHH * 2, listAddr.size());
        for (Address__c addr : listAddr) {
            Boolean fNewDefault = (addr.MailingStreet__c.contains('New Default Street'));
            System.assertEquals(fNewDefault, addr.Default_Address__c);
            if (fNewDefault) {
                System.assertEquals(System.today(), addr.Latest_Start_Date__c);
                System.assertEquals(null, addr.Latest_End_Date__c);
            } else {
                System.assertEquals(System.today(), addr.Latest_End_Date__c);
            }
        }
    }

    /*********************************************************************************************************
    @description
        insert new default addresses to HH w/ existing default addresses, and then go back
    verify:
        contact's && hh address matches original default
        new default addresses no longer marked default
    **********************************************************************************************************/
    @IsTest
    private static void insertNewDefaultAddrAndReset() {

        // this creates a default Address for each HH
        createHHTestData(cHH, cCon);
        List<Address__c> listAddrOriginal = listAddrT;

        // create additional addresses
        initTestAddr(cHH);
        for (Integer i = 0; i < cHH; i++) {
            listAddrT[i].Household_Account__c = listAccT[i].Id;
            listAddrT[i].Default_Address__c = true;
            listAddrT[i].MailingStreet__c = 'New Default Street' + i;
            listAddrT[i].MailingCity__c = 'New Default City' + i;
        }
        insert listAddrT;

        // go back to original default addresses
        // added this extra set to test fix where we didn't use the correct default
        for (Integer i = 0; i < cHH; i++) {
            listAddrOriginal[i].Default_Address__c = true;
            listAddrOriginal[i].MailingStreet__c = 'Original Default Street' + i;
            listAddrOriginal[i].MailingCity__c = 'Original Default City' + i;
        }
        Test.startTest();
        update listAddrOriginal;
        Test.stopTest();

        // verify that the HH and Contacts share the same address and it's new!
        Map<Id, Account> mapAccIdAcc = new Map<Id, Account>([SELECT Id, Name, BillingStreet, BillingCity, BillingState, BillingPostalCode, BillingCountry, BillingLatitude, BillingLongitude FROM Account]);
        List<Contact> listCon = [SELECT Id, Name, AccountId, is_Address_Override__c, Current_Address__c, MailingStreet, MailingCity, MailingState, MailingPostalCode, MailingCountry, MailingLatitude, MailingLongitude FROM Contact];
        System.assertEquals(cHH * cCon, listCon.size());

        for (Contact con : listCon) {
            Account acc = mapAccIdAcc.get(con.AccountId);
            System.assertEquals(true, isMatchAddressAccCon(acc, con));
            System.assert(con.MailingStreet.contains('Original Default Street'));
            System.assert(con.MailingCity.contains('Original Default City'));
            System.assertEquals(false, con.is_Address_Override__c);
            System.assertNotEquals(null, con.Current_Address__c);
        }

        // verify the previous addresses got Default cleared.
        // and verify latest start date and latest end date appropriately set.
        List<Address__c> listAddr = [SELECT Id, Default_Address__c, MailingStreet__c, Household_Account__c, Latest_Start_Date__c, Latest_End_Date__c FROM Address__c];
        System.assertEquals(cHH * 2, listAddr.size());
        for (Address__c addr : listAddr) {
            Boolean fNewDefault = (addr.MailingStreet__c.contains('Original Default Street'));
            System.assertEquals(fNewDefault, addr.Default_Address__c);
            if (fNewDefault) {
                System.assertEquals(System.today(), addr.Latest_Start_Date__c);
                System.assertEquals(null, addr.Latest_End_Date__c);
            } else {
                System.assertEquals(System.today(), addr.Latest_End_Date__c);
            }
        }
    }

    /*********************************************************************************************************
    @description
        update contacts' Address Override
    verify:
        contacts' Mailing address fields updated to the Address Override's fields.
    **********************************************************************************************************/
    @IsTest
    private static void updateAddrOverride() {
        //skip the test if Advancement is installed
        if (ADV_PackageInfo_SVC.useAdv()) return;

        // this creates a default Address for each HH
        createHHTestData(cHH, cCon);

        // create additional addresses
        initTestAddr(cHH);
        for (Integer i = 0; i < cHH; i++) {
            listAddrT[i].Household_Account__c = listAccT[i].Id;
            listAddrT[i].Default_Address__c = false;
            listAddrT[i].MailingStreet__c = 'override' + i;
            listAddrT[i].MailingCity__c = 'override' + i;
        }
        insert listAddrT;

        // set the contacts' address overrides
        List<Contact> listCon = new List<Contact>();
        for (Integer i = 0; i < cHH; i++) {
            Contact con = listConT[i * cHH + i];
            con.Current_Address__c = listAddrT[i].Id;
            con.is_Address_Override__c = true;
            listCon.add(con);
        }
        Test.startTest();
        update listCon;
        Test.stopTest();

        // verify that the HH and Contacts share the same address
        Map<Id, Account> mapAccIdAcc = new Map<Id, Account>([SELECT Id, Name, BillingStreet, BillingCity, BillingState, BillingPostalCode, BillingCountry, BillingLatitude, BillingLongitude FROM Account]);
        listCon = [SELECT Id, Name, AccountId, is_Address_Override__c, Current_Address__c, MailingStreet, MailingCity, MailingState, MailingPostalCode, MailingCountry, MailingLatitude, MailingLongitude FROM Contact];

        for (Contact con : listCon) {
            Account acc = mapAccIdAcc.get(con.AccountId);
            if (con.is_Address_Override__c) {
                System.assertNotEquals(null, con.Current_Address__c);
                System.assertEquals(false, isMatchAddressAccCon(acc, con));
                System.assert(con.MailingStreet.contains('override'));
                System.assert(con.MailingCity.contains('override'));
            } else {
                System.assertEquals(true, isMatchAddressAccCon(acc, con));
                System.assert(con.MailingStreet.contains('Street'));
                System.assert(con.MailingCity.contains('City'));
                System.assertEquals(false, con.is_Address_Override__c);
                System.assertNotEquals(null, con.Current_Address__c);
            }
        }

        // verify address overrides have latest start date and latest end date appropriately set.
        List<Address__c> listAddr = [SELECT Id, Latest_Start_Date__c, Latest_End_Date__c FROM Address__c WHERE Id IN :listAddrT];
        System.assertEquals(cHH, listAddr.size());
        for (Address__c addr : listAddr) {
            System.assertEquals(System.today(), addr.Latest_Start_Date__c);
            System.assertEquals(null, addr.Latest_End_Date__c);
        }
    }

    /*********************************************************************************************************
    @description
        clear contacts' Address Override
    verify:
        contacts' Mailing address fields updated to the HH default address
    **********************************************************************************************************/
    @IsTest
    private static void clearAddrOverride() {
        //skip the test if Advancement is installed
        if (ADV_PackageInfo_SVC.useAdv()) return;

        // this creates a default Address for each HH
        createHHTestData(cHH, cCon);

        // create additional addresses
        initTestAddr(cHH);
        for (Integer i = 0; i < cHH; i++) {
            listAddrT[i].Household_Account__c = listAccT[i].Id;
            listAddrT[i].Default_Address__c = false;
            listAddrT[i].MailingStreet__c = 'override' + i;
            listAddrT[i].MailingCity__c = 'override' + i;
        }
        insert listAddrT;

        // set the contacts' address overrides
        List<Contact> listCon = new List<Contact>();
        for (Integer i = 0; i < cHH; i++) {
            Contact con = listConT[i * cHH + i];
            con.Current_Address__c = listAddrT[i].Id;
            con.is_Address_Override__c = true;
            listCon.add(con);
        }
        update listCon;

        // now clear out the contacts' address overrides
        for (Contact con : listCon) {
            con.is_Address_Override__c = false;
        }
        Test.startTest();
        update listCon;
        Test.stopTest();

        // verify that the HH and Contacts share the same address
        Map<Id, Account> mapAccIdAcc = new Map<Id, Account>([SELECT Id, Name, BillingStreet, BillingCity, BillingState, BillingPostalCode, BillingCountry, BillingLatitude, BillingLongitude FROM Account]);
        listCon = [SELECT Id, Name, AccountId, is_Address_Override__c, Current_Address__c, MailingStreet, MailingCity, MailingState, MailingPostalCode, MailingCountry, MailingLatitude, MailingLongitude FROM Contact];

        for (Contact con : listCon) {
            Account acc = mapAccIdAcc.get(con.AccountId);
            System.assertEquals(false, con.is_Address_Override__c);
            System.assertNotEquals(null, con.Current_Address__c);
            System.assertEquals(true, isMatchAddressAccCon(acc, con));
            System.assert(con.MailingStreet.contains('Street'));
            System.assert(con.MailingCity.contains('City'));
        }

        // verify address overrides have latest start date and latest end date appropriately set.
        List<Address__c> listAddr = [SELECT Id, Latest_Start_Date__c, Latest_End_Date__c FROM Address__c WHERE Id IN :listAddrT];
        System.assertEquals(cHH, listAddr.size());
        for (Address__c addr : listAddr) {
            System.assertEquals(System.today(), addr.Latest_Start_Date__c);
            System.assertEquals(System.today(), addr.Latest_End_Date__c);
        }
    }

    /*********************************************************************************************************
     @description
         clear contacts' Address Override and modify a new address
     verify:
         new default address created
     **********************************************************************************************************/
    @IsTest
    private static void clearAddrOverrideNewAddr() {
        //skip the test if Advancement is installed
        if (ADV_PackageInfo_SVC.useAdv()) return;

        // this creates a default Address for each HH
        createHHTestData(cHH, cCon);

        // create additional addresses
        initTestAddr(cHH);
        for (Integer i = 0; i < cHH; i++) {
            listAddrT[i].Household_Account__c = listAccT[i].Id;
            listAddrT[i].Default_Address__c = false;
            listAddrT[i].MailingStreet__c = 'override' + i;
            listAddrT[i].MailingCity__c = 'override' + i;
        }
        insert listAddrT;

        // set the contacts' address overrides
        List<Contact> listCon = new List<Contact>();
        for (Integer i = 0; i < cHH; i++) {
            Contact con = listConT[i * cHH + i];
            con.Current_Address__c = listAddrT[i].Id;
            con.is_Address_Override__c = true;
            listCon.add(con);
        }
        update listCon;

        // now clear out the contacts' address overrides,
        // but modify the address also!
        for (Contact con : listCon) {
            con.is_Address_Override__c = false;
            con.MailingStreet = 'New Street';
            con.MailingCity = 'New City';
        }
        Test.startTest();
        update listCon;
        Test.stopTest();

        // verify that the HH and Contacts share the same address
        Map<Id, Account> mapAccIdAcc = new Map<Id, Account>([SELECT Id, Name, BillingStreet, BillingCity, BillingState, BillingPostalCode, BillingCountry, BillingLatitude, BillingLongitude FROM Account]);
        listCon = [SELECT Id, Name, AccountId, is_Address_Override__c, Current_Address__c, MailingStreet, MailingCity, MailingState, MailingPostalCode, MailingCountry, MailingLatitude, MailingLongitude FROM Contact];

        for (Contact con : listCon) {
            Account acc = mapAccIdAcc.get(con.AccountId);
            System.assertEquals(false, con.is_Address_Override__c);
            System.assertNotEquals(null, con.Current_Address__c);
            System.assertEquals(true, isMatchAddressAccCon(acc, con));
            System.assert(con.MailingStreet.contains('Street'));
            System.assert(con.MailingCity.contains('City'));
        }

    }

    /*********************************************************************************************************
    @description
        update contacts' mailing address to cause creation of new default Address object
    verify:
        new Default Address created
        HH and Contacts get new Address
    **********************************************************************************************************/
    @IsTest
    private static void updateConAddrNew() {
        //skip the test if Advancement is installed
        if (ADV_PackageInfo_SVC.useAdv()) return;

        // this creates a default Address for each HH
        createHHTestData(cHH, cCon);

        // modify some of the contact addresses directly
        List<Contact> listCon = new List<Contact>();
        for (Integer i = 0; i < cHH; i++) {
            Contact con = listConT[i * cHH + i];
            con.MailingStreet = 'Direct Street Edit';
            con.MailingCity = 'Direct City Edit';
            listCon.add(con);
        }
        update listCon;

        for (Integer i = 0; i < cHH; i++) {
            Contact con = listConT[i * cHH + i];
            con.MailingStreet = 'another Street Edit';
            con.MailingCity = 'another City Edit';
        }
        update listCon;

        for (Integer i = 0; i < cHH; i++) {
            Contact con = listConT[i * cHH + i];
            con.MailingStreet = 'final Street Edit';
            con.MailingCity = 'final City Edit';
        }
        Test.startTest();
        update listCon;
        Test.stopTest();

        // verify that the HH and Contacts share the same address
        Map<Id, Account> mapAccIdAcc = new Map<Id, Account>([SELECT Id, Name, BillingStreet, BillingCity, BillingState, BillingPostalCode, BillingCountry, BillingLatitude, BillingLongitude FROM Account]);
        listCon = [SELECT Id, Name, AccountId, is_Address_Override__c, Current_Address__c, MailingStreet, MailingCity, MailingState, MailingPostalCode, MailingCountry, MailingLatitude, MailingLongitude FROM Contact];

        for (Contact con : listCon) {
            Account acc = mapAccIdAcc.get(con.AccountId);
            System.assertEquals(true, isMatchAddressAccCon(acc, con));
            System.assert(con.MailingStreet.contains('final Street Edit'));
            System.assert(con.MailingCity.contains('final City Edit'));
            System.assertEquals(false, con.is_Address_Override__c);
            System.assertNotEquals(null, con.Current_Address__c);
        }

        // verify the previous addresses got Default cleared.
        List<Address__c> listAddr = [SELECT Id, Default_Address__c, MailingStreet__c, Household_Account__c FROM Address__c];
        // each set of edits created a new address object
        System.assertEquals(cHH * 4, listAddr.size());
        for (Address__c addr : listAddr) {
            Boolean fNewDefault = (addr.MailingStreet__c.contains('final Street Edit'));
            System.assertEquals(fNewDefault, addr.Default_Address__c);
        }
    }

    /*********************************************************************************************************
    @description
        update contacts' mailing address and mark it as override, to cause creation of new non-default Address object
    verify:
        new Address created
        HH sticks with default Address
        contact gets new address
    **********************************************************************************************************/
    @IsTest
    private static void updateConAddrMarkOverride() {
        //skip the test if Advancement is installed
        if (ADV_PackageInfo_SVC.useAdv()) return;

        // this creates a default Address for each HH
        createHHTestData(cHH, cCon);

        // modify the contact addresses directly, and set override
        List<Contact> listCon = new List<Contact>();
        for (Integer i = 0; i < cHH * cCon; i++) {
            Contact con = listConT[i];
            con.MailingStreet = 'Direct Street Edit';
            con.MailingCity = 'Direct City Edit';
            con.is_Address_Override__c = true;
            listCon.add(con);
        }
        Test.startTest();
        update listCon;
        Test.stopTest();

        // verify that the HH and Contacts do not share the same address
        Map<Id, Account> mapAccIdAcc = new Map<Id, Account>([SELECT Id, Name, BillingStreet, BillingCity, BillingState, BillingPostalCode, BillingCountry, BillingLatitude, BillingLongitude FROM Account]);
        listCon = [SELECT Id, Name, AccountId, is_Address_Override__c, Current_Address__c, MailingStreet, MailingCity, MailingState, MailingPostalCode, MailingCountry, MailingLatitude, MailingLongitude FROM Contact];

        for (Contact con : listCon) {
            Account acc = mapAccIdAcc.get(con.AccountId);
            System.assertEquals(false, isMatchAddressAccCon(acc, con));
            System.assertEquals(true, con.MailingStreet.contains('Direct Street Edit'));
            System.assertEquals(true, con.MailingCity.contains('Direct City Edit'));
            System.assertEquals(false, acc.BillingStreet.contains('Direct Street Edit'));
            System.assertEquals(false, acc.BillingCity.contains('Direct City Edit'));
            System.assertEquals(true, con.is_Address_Override__c);
            System.assertNotEquals(null, con.Current_Address__c);
        }

        // verify the previous addresses got Default cleared.
        List<Address__c> listAddr = [SELECT Id, Default_Address__c, MailingStreet__c, Household_Account__c FROM Address__c];
        System.assertEquals(cHH * cCon + cHH, listAddr.size());
        for (Address__c addr : listAddr) {
            Boolean isNewEdit = (addr.MailingStreet__c.contains('Direct Street Edit'));
            System.assertNotEquals(isNewEdit, addr.Default_Address__c);
        }
    }

    /*********************************************************************************************************
    @description
        Update Contact's mailing address and mark it as override, to cause creation of a new non-default Address
        record with the Mailing State value set as expected when State & Country Picklists are enabled.
    verify:
        Contact gets new Address
        HH sticks with default Address
        New Address created with State value set as expected
    **********************************************************************************************************/
    @IsTest
    private static void testAddressOverrideCreatesNewAddressWhenStateCodeIsChanged() {
        if (!orgConfig.isStateCountryPicklistsEnabled()) {

            return;
        }

        Integer hhSize = 1;
        Integer contactSize = 1;
        String state = 'California';
        String stateCode = 'CA';

        // This creates a default Address for each HH
        createHHTestData(hhSize, contactSize);
        System.assertEquals(1, getAddresses().size());

        // Modify the Contact addresses directly, and set override
        Contact con = listConT[0];
        con.put('MailingStateCode', stateCode);
        con.is_Address_Override__c = true;

        Test.startTest();
        update con;
        Test.stopTest();

        // Verify a new Address record was created
        List<Address__c> retrievedAddresses = getAddresses();
        System.assertEquals(2, retrievedAddresses.size());

        // Find the default Address
        Address__c defaultAddress = null;
        Address__c newAddress = null;
        for (Address__c eachAddress : retrievedAddresses) {
            if (eachAddress.Default_Address__c) {
                defaultAddress = eachAddress;
            } else {
                newAddress = eachAddress;
            }
        }

        // Verify the Account's Billing Address info matches the Default Address record
        assertEquals(listAddrT[0], defaultAddress);

        // Verify the Contact's Address was updated as expected and that the Household and Contact Addresses are different.
        List<Account> retrievedAccounts = Database.query(buildAccountSoql());
        Map<Id, Account> accountIdToAccount = new Map<Id, Account>(retrievedAccounts);
        List<Contact> listCon = Database.query(buildContactSoql());

        System.assertEquals(state, listCon[0].MailingState);
        System.assertEquals(true, listCon[0].is_Address_Override__c);
        System.assertNotEquals(null, listCon[0].Current_Address__c);

        Account eachContactAccount = accountIdToAccount.get(listCon[0].AccountId);
        System.assertEquals(false, isMatchAddressAccCon(eachContactAccount, listCon[0]));

        // Verify the new Address Mailing State matches Contact's MailingStateCode and not set as the Default
        System.assertEquals(stateCode, newAddress.MailingState__c);
        System.assertEquals(false, newAddress.Default_Address__c);
    }


    /*********************************************************************************************************
    @description
        Update Address' Mailing Country when it is empty and State & Country Picklists are enabled.
    verify:
        Does not populate the Address' Mailing Country if the source sObject's CountryCode is empty
        Populates the Address' Mailing Country with the source sObject's CountryCode value if the Mailing Country is empty
    **********************************************************************************************************/
    @IsTest
    private static void testEmptyAddressCountryIsPopulatedFromCountryCode() {
        if (!orgConfig.isStateCountryPicklistsEnabled()) {

            return;
        }

        Contact con = new Contact();
        con.put('MailingCountryCode', null);
        Address__c addressEmptyCountry = new Address__c(MailingCountry__c = null);

        Test.startTest();

        String countryCode = 'US';
        String country = 'United States';

        NPSP_Address npspAddressEmptyCountry = new NPSP_Address(addressEmptyCountry);
        npspAddressEmptyCountry.populateAddressCountryFromCountryCode(con, 'Mailing');
        System.assertEquals(null, npspAddressEmptyCountry.country());

        con.put('MailingCountryCode', countryCode);
        npspAddressEmptyCountry.populateAddressCountryFromCountryCode(con, 'Mailing');
        System.assertEquals(country, npspAddressEmptyCountry.country());

        Test.stopTest();
    }


    /*********************************************************************************************************
    @description
        Update the Address' Mailing State when it is empty or does not match the source sObject's StateCode
        and State & Country Picklists are enabled.
    verify:
        Does not populate the Address' Mailing State if the source sObject's StateCode is empty
        Populate the Address' Mailing State with the source sObject's StateCode value if the Mailing State is empty
        Populate the Address' Mailing State with the source sObject's StateCode value if the Mailing State does not match the StateCode
    **********************************************************************************************************/
    @IsTest
    private static void testEmptyAddressStateIsPopulatedFromStateCode() {
        if (!orgConfig.isStateCountryPicklistsEnabled()) {

            return;
        }

        Contact con = new Contact();
        con.put('MailingStateCode', null);
        Address__c addressEmptyState = new Address__c(MailingState__c = null);

        Test.startTest();

        String stateCode = 'CA';

        NPSP_Address npspAddressEmptyState = new NPSP_Address(addressEmptyState);
        npspAddressEmptyState.populateAddressStateFromStateCode(con, 'Mailing');
        System.assertEquals(null, npspAddressEmptyState.state());

        con.put('MailingStateCode', stateCode);
        npspAddressEmptyState.populateAddressStateFromStateCode(con, 'Mailing');
        System.assertEquals(stateCode, npspAddressEmptyState.state());

        npspAddressEmptyState.state('NY');
        npspAddressEmptyState.populateAddressStateFromStateCode(con, 'Mailing');
        System.assertEquals(stateCode, npspAddressEmptyState.state());

        Test.stopTest();
    }


    /*********************************************************************************************************
    @description
        Checks if the Mailing State matches the source sObject's StateCode.
    verify:
        Returns false if the Address Mailing State is empty
        Returns false if the Address Mailing State does not match the StateCode
        Returns true if the Address Mailing State matches the StateCode
    **********************************************************************************************************/
    @IsTest
    private static void testIsMatchingStateCode() {
        if (!orgConfig.isStateCountryPicklistsEnabled()) {

            return;
        }

        Address__c addressMatch = new Address__c();

        Test.startTest();

        String stateCode = 'CA';

        NPSP_Address npspAddressMatch = new NPSP_Address(addressMatch);
        npspAddressMatch.state(null);
        System.assertEquals(false, npspAddressMatch.isMatchingStateCode(stateCode));

        npspAddressMatch.state('Hawaii');
        System.assertEquals(false, npspAddressMatch.isMatchingStateCode(stateCode));

        npspAddressMatch.state('California');
        System.assertEquals(true, npspAddressMatch.isMatchingStateCode(stateCode));

        Test.stopTest();
    }


    /*********************************************************************************************************
    @description
        update contacts' mailing address to cause an update to default Address object
    verify:
        existing Default Address updated
        HH and Contacts get updated Address
    **********************************************************************************************************/
    @IsTest
    private static void updateConAddrExisting() {
        //skip the test if Advancement is installed
        if (ADV_PackageInfo_SVC.useAdv()) return;

        npe01__Contacts_And_Orgs_Settings__c contactSettingsForTests = UTIL_CustomSettingsFacade.getContactsSettingsForTests(
            new npe01__Contacts_And_Orgs_Settings__c(
                npe01__Account_Processor__c = CAO_Constants.HH_ACCOUNT_PROCESSOR,
                Simple_Address_Change_Treated_as_Update__c = true
            ));

        // this creates a default Address for each HH
        createHHTestData(cHH, cCon);

        // modify some of the contact addresses directly
        // NOTE: we only modify 1 field, so it will be treated as an update to an existing address!
        List<Contact> listCon = new List<Contact>();
        for (Integer i = 0; i < cHH; i++) {
            Contact con = listConT[i * cHH + i];
            con.MailingStreet = 'Direct Street Edit';
            listCon.add(con);
        }
        update listCon;

        for (Integer i = 0; i < cHH; i++) {
            Contact con = listConT[i * cHH + i];
            con.MailingState = 'Washington';
        }
        update listCon;

        for (Integer i = 0; i < cHH; i++) {
            Contact con = listConT[i * cHH + i];
            con.MailingStreet = ' direct street  edit ';  // whitespace and casing should not count as a real edit.
            con.MailingState = 'Oregon';
        }
        Test.startTest();
        update listCon;

        Test.stopTest();

        // verify that the HH and Contacts share the same address
        Map<Id, Account> mapAccIdAcc = new Map<Id, Account>([SELECT Id, Name, BillingStreet, BillingCity, BillingState, BillingPostalCode, BillingCountry, BillingLatitude, BillingLongitude FROM Account]);
        listCon = [SELECT Id, Name, AccountId, is_Address_Override__c, Current_Address__c, MailingStreet, MailingCity, MailingState, MailingPostalCode, MailingCountry, MailingLatitude, MailingLongitude FROM Contact];

        for (Contact con : listCon) {
            Account acc = mapAccIdAcc.get(con.AccountId);
            System.assertEquals(true, isMatchAddressAccCon(acc, con));
            System.assert(con.MailingStreet.contains('direct street  edit'));
            System.assertEquals(false, con.is_Address_Override__c);
            System.assertNotEquals(null, con.Current_Address__c);
        }

        List<Address__c> listAddr = [
                SELECT Id,
                        Default_Address__c,
                        MailingStreet__c,
                        Household_Account__c
                FROM Address__c
        ];
        System.assertEquals(cHH, listAddr.size(),
                'Whitespace and casing should not count as a real edit, so this test should' +
                        ' verify that no new address was created');
        for (Address__c addr : listAddr) {
            System.assertEquals('direct street  edit', addr.MailingStreet__c);
        }
    }

    /*********************************************************************************************************
    @description
        update contacts' address type to cause an update to default Address object
    verify:
        existing Default Address updated
        HH and Contacts get updated Address
    **********************************************************************************************************/
    @IsTest
    private static void updateConAddrExistingAddrType() {
        //skip the test if Advancement is installed
        if (ADV_PackageInfo_SVC.useAdv()) return;

        npe01__Contacts_And_Orgs_Settings__c contactSettingsForTests = UTIL_CustomSettingsFacade.getContactsSettingsForTests(
            new npe01__Contacts_And_Orgs_Settings__c(
                npe01__Account_Processor__c = CAO_Constants.HH_ACCOUNT_PROCESSOR,
                Simple_Address_Change_Treated_as_Update__c = true
            ));

        // this creates a default Address for each HH
        createHHTestData(cHH, cCon);

        // modify some of the contact addresses directly
        // NOTE: we only modify 1 field, so it will be treated as an update to an existing address!
        List<Contact> listCon = new List<Contact>();
        for (Integer i = 0; i < cHH; i++) {
            Contact con = listConT[i * cHH + i];
            con.npe01__Primary_Address_Type__c = 'Other';
            listCon.add(con);
        }
        update listCon;

        for (Integer i = 0; i < cHH; i++) {
            Contact con = listConT[i * cHH + i];
            con.MailingStreet = ' direct street edit ';
        }
        update listCon;

        for (Integer i = 0; i < cHH; i++) {
            Contact con = listConT[i * cHH + i];
            con.MailingState = 'Washington';
        }
        update listCon;

        for (Integer i = 0; i < cHH; i++) {
            Contact con = listConT[i * cHH + i];
            con.MailingStreet = ' direct street  edit ';  // whitespace and casing should not count as a real edit.
            con.MailingState = 'Oregon';
        }
        Test.startTest();
        update listCon;

        Test.stopTest();

        // verify that the HH and Contacts share the same address
        Map<Id, Account> mapAccIdAcc = new Map<Id, Account>([SELECT Id, Name, BillingStreet, BillingCity, BillingState, BillingPostalCode, BillingCountry, BillingLatitude, BillingLongitude FROM Account]);
        listCon = [SELECT Id, Name, AccountId, is_Address_Override__c, Current_Address__c, npe01__Primary_Address_Type__c, MailingStreet, MailingCity, MailingState, MailingPostalCode, MailingCountry, MailingLatitude, MailingLongitude FROM Contact];

        for (Contact con : listCon) {
            Account acc = mapAccIdAcc.get(con.AccountId);
            System.assertEquals(true, isMatchAddressAccCon(acc, con));
            System.assert(con.MailingStreet.contains('direct street  edit'));
            System.assertEquals(false, con.is_Address_Override__c);
            System.assertNotEquals(null, con.Current_Address__c);
            System.assertEquals('Other', con.npe01__Primary_Address_Type__c);
        }

        // verify that no new address was created
        List<Address__c> listAddr = [SELECT Id, Default_Address__c, MailingStreet__c, Household_Account__c, Address_Type__c FROM Address__c];
        System.assertEquals(cHH, listAddr.size());
        for (Address__c addr : listAddr) {
            System.assertEquals('direct street  edit', addr.MailingStreet__c);
            System.assertEquals('Other', addr.Address_Type__c);
        }
    }

    /*********************************************************************************************************
    @description
        Add an existing Contact to a Household.
        Pre-populate the Contact's address with the Household Address
        in the same way Manage Household pre-populates Contact's Mailing Address with Account's Billing Address.
    verify:
        The Contact's current Address is equal to the new Household Address.
        Contact's "Primary Address Type" is the same as the Address' "Address Type".
    **********************************************************************************************************/
    @IsTest
    private static void addExistingContactToNewHouseholdShouldSyncPrimaryAddressTypeWithAddressType() {
        //skip the test if Advancement is installed
        if (ADV_PackageInfo_SVC.useAdv()) return;

        UTIL_CustomSettingsFacade.getContactsSettingsForTests(
            new npe01__Contacts_And_Orgs_Settings__c (
                npe01__Account_Processor__c = CAO_Constants.HH_ACCOUNT_PROCESSOR,
                Simple_Address_Change_Treated_as_Update__c = true
            )
        );

        Integer hhSize = 1;
        Integer contactSize = 1;
        createHHTestData(hhSize, contactSize);

        Account account = new Account(Name = 'AccountWithoutAddress');
        insert account;
        Contact contact = new Contact(LastName = 'TestPrimaryAddressTypeExistingContact', AccountId = account.Id);
        insert contact;

        Test.startTest();

        contact.AccountId = listAccT[0].Id;
        populateContactAddress(contact, listAddrT[0]);
        update contact;

        Test.stopTest();

        Map<Id, Address__c[]> addressesByHh = getAddressesByHousehold();
        System.assertEquals(hhSize, addressesByHh.size());

        for (Address__c addr : listAddrT) {
            Address__c[] addresses = addressesByHh.get(addr.Household_Account__c);
            System.assert(addresses != null && addresses.size() == 1, addresses);

            assertEquals(addr, addresses[0]);
        }

        Contact[] contacts = getContacts();
        System.assertEquals(listConT.size() + 1, contacts.size());

        for (Contact c : contacts) {
            System.assertEquals(listAccT[0].Id, c.AccountId);

            Address__c[] addresses = addressesByHh.get(c.AccountId);
            System.assert(addresses != null && addresses.size() == 1, addresses);

            System.assertNotEquals(null, c.npe01__Primary_Address_Type__c);
            assertEqualAddresses(addresses[0], c);
        }
    }

    /*********************************************************************************************************
    @description
        Add a new Contact to a Household.
        Pre-populate the Contact's address with the Household Address
        in the same way standard Salesforce pre-populates Contact's Mailing Address with Account's Billing Address.
    verify:
        The Contact's current Address is equal to the new Household Address.
        Contact's "Primary Address Type" is the same as the Address' "Address Type".
    **********************************************************************************************************/
    @IsTest
    private static void addNewContactToHouseholdShouldSyncPrimaryAddressTypeWithAddressType() {
        //skip the test if Advancement is installed
        if (ADV_PackageInfo_SVC.useAdv()) return;

        UTIL_CustomSettingsFacade.getContactsSettingsForTests(
            new npe01__Contacts_And_Orgs_Settings__c (
                npe01__Account_Processor__c = CAO_Constants.HH_ACCOUNT_PROCESSOR,
                Simple_Address_Change_Treated_as_Update__c = true
            )
        );

        Integer hhSize = 1;
        Integer contactSize = 1;
        createHHTestData(hhSize, contactSize);

        Test.startTest();

        Contact contact = new Contact(LastName = 'TestPrimaryAddressTypeNewContact', AccountId = listAccT[0].Id);
        populateContactAddress(contact, listAddrT[0]);
        insert contact;

        Test.stopTest();

        Map<Id, Address__c[]> addressesByHh = getAddressesByHousehold();
        System.assertEquals(hhSize, addressesByHh.size());

        for (Address__c addr : listAddrT) {
            Address__c[] addresses = addressesByHh.get(addr.Household_Account__c);
            System.assert(addresses != null && addresses.size() == 1, addresses);

            assertEquals(addr, addresses[0]);
        }

        Contact[] contacts = getContacts();
        System.assertEquals(listConT.size() + 1, contacts.size());

        for (Contact c : contacts) {
            Address__c[] addresses = addressesByHh.get(c.AccountId);
            System.assert(addresses != null && addresses.size() == 1, addresses);

            System.assertNotEquals(null, c.npe01__Primary_Address_Type__c);
            assertEqualAddresses(addresses[0], c);
        }
    }

    /*********************************************************************************************************
    @description
        update contacts' mailing address with just a case change, to cause an update to default Address object
    verify:
        existing Default Address updated
        HH and Contacts get updated Address
    **********************************************************************************************************/
    @IsTest
    private static void updateConAddrExistingCaseOnly() {
        //skip the test if Advancement is installed
        if (ADV_PackageInfo_SVC.useAdv()) return;

        npe01__Contacts_And_Orgs_Settings__c contactSettingsForTests = UTIL_CustomSettingsFacade.getContactsSettingsForTests(
            new npe01__Contacts_And_Orgs_Settings__c(
                npe01__Account_Processor__c = CAO_Constants.HH_ACCOUNT_PROCESSOR,
                Simple_Address_Change_Treated_as_Update__c = true
            ));

        // this creates a default Address for each HH
        createHHTestData(cHH, cCon);

        // modify some of the contact addresses directly
        // NOTE: we only modify 1 field, so it will be treated as an update to an existing address!
        List<Contact> listCon = new List<Contact>();
        for (Integer i = 0; i < cHH; i++) {
            Contact con = listConT[i * cHH + i];
            con.MailingStreet = 'Direct Street Edit';
            listCon.add(con);
        }
        update listCon;

        for (Integer i = 0; i < cHH; i++) {
            Contact con = listConT[i * cHH + i];
            con.MailingState = 'Washington';
        }
        update listCon;

        for (Integer i = 0; i < cHH; i++) {
            Contact con = listConT[i * cHH + i];
            con.MailingStreet = ' direct street  edit ';  // whitespace and casing should not count as a real edit.
            con.MailingState = 'Oregon';
        }
        update listCon;

        for (Integer i = 0; i < cHH; i++) {
            Contact con = listConT[i * cHH + i];
            con.MailingStreet = ' DIRECT STREET  EDIT ';  // only change casing.
        }
        update listCon;

        // verify that the HH and Contacts share the same address
        Map<Id, Account> mapAccIdAcc = new Map<Id, Account>([SELECT Id, Name, BillingStreet, BillingCity, BillingState, BillingPostalCode, BillingCountry, BillingLatitude, BillingLongitude FROM Account]);
        listCon = [SELECT Id, Name, AccountId, is_Address_Override__c, Current_Address__c, MailingStreet, MailingCity, MailingState, MailingPostalCode, MailingCountry, MailingLatitude, MailingLongitude FROM Contact];

        for (Contact con : listCon) {
            Account acc = mapAccIdAcc.get(con.AccountId);
            System.assertEquals(true, isMatchAddressAccCon(acc, con));
            System.assert(con.MailingStreet.equals('DIRECT STREET  EDIT'));
            System.assertEquals(false, con.is_Address_Override__c);
            System.assertNotEquals(null, con.Current_Address__c);
        }

        // verify that no new address was created
        List<Address__c> listAddr = [SELECT Id, Default_Address__c, MailingStreet__c, Household_Account__c FROM Address__c];
        System.assertEquals(cHH, listAddr.size());
        for (Address__c addr : listAddr) {
            System.assert(addr.MailingStreet__c.equals('DIRECT STREET  EDIT'));
        }

        // now test that changing the case from the account updates all addresses
        for (Integer i = 0; i < cHH; i++) {
            Account acc = listAccT[i];
            acc.BillingStreet = 'direct street  edit';
        }
        Test.startTest();
        update listAccT;
        Test.stopTest();

        // verify that the HH and Contacts share the same address
        mapAccIdAcc = new Map<Id, Account>([SELECT Id, Name, BillingStreet, BillingCity, BillingState, BillingPostalCode, BillingCountry, BillingLatitude, BillingLongitude FROM Account]);
        listCon = [SELECT Id, Name, AccountId, is_Address_Override__c, Current_Address__c, MailingStreet, MailingCity, MailingState, MailingPostalCode, MailingCountry, MailingLatitude, MailingLongitude FROM Contact];

        for (Contact con : listCon) {
            Account acc = mapAccIdAcc.get(con.AccountId);
            System.assertEquals(true, isMatchAddressAccCon(acc, con));
            System.assert(con.MailingStreet.equals('direct street  edit'));
            System.assertEquals(false, con.is_Address_Override__c);
            System.assertNotEquals(null, con.Current_Address__c);
        }

        // verify that no new address was created
        listAddr = [SELECT Id, Default_Address__c, MailingStreet__c, Household_Account__c FROM Address__c];
        System.assertEquals(cHH, listAddr.size());
        for (Address__c addr : listAddr) {
            System.assert(addr.MailingStreet__c.equals('direct street  edit'));
        }


    }

    /*********************************************************************************************************
    @description
        update accounts' billing address to cause creation of new default Address object
    verify:
        new Default Address created
        HH and Contacts get new Address
    **********************************************************************************************************/
    @IsTest
    private static void updateAccAddrNew() {
        //skip the test if Advancement is installed
        if (ADV_PackageInfo_SVC.useAdv()) return;

        // this creates a default Address for each HH
        createHHTestData(cHH, cCon);

        // modify some of the account addresses directly
        for (Integer i = 0; i < cHH; i++) {
            Account acc = listAccT[i];
            acc.BillingStreet = 'Direct Street Edit';
            acc.BillingCity = 'Direct City Edit';
        }
        update listAccT;

        for (Integer i = 0; i < cHH; i++) {
            Account acc = listAccT[i];
            acc.BillingStreet = 'another Street Edit';
            acc.BillingCity = 'another City Edit';
        }
        update listAccT;

        for (Integer i = 0; i < cHH; i++) {
            Account acc = listAccT[i];
            acc.BillingStreet = 'final Street Edit';
            acc.BillingCity = 'final City Edit';
        }
        Test.startTest();
        update listAccT;
        Test.stopTest();

        // verify that the HH and Contacts share the same address
        Map<Id, Account> mapAccIdAcc = new Map<Id, Account>([SELECT Id, Name, BillingStreet, BillingCity, BillingState, BillingPostalCode, BillingCountry, BillingLatitude, BillingLongitude FROM Account]);
        List<Contact> listCon = [SELECT Id, Name, AccountId, is_Address_Override__c, Current_Address__c, MailingStreet, MailingCity, MailingState, MailingPostalCode, MailingCountry, MailingLatitude, MailingLongitude FROM Contact];

        for (Contact con : listCon) {
            Account acc = mapAccIdAcc.get(con.AccountId);
            System.assertEquals(true, isMatchAddressAccCon(acc, con));
            System.assert(acc.BillingStreet.contains('final Street Edit'));
            System.assert(con.MailingStreet.contains('final Street Edit'));
            System.assertEquals(false, con.is_Address_Override__c);
            System.assertNotEquals(null, con.Current_Address__c);
        }

        // verify the previous addresses got Default cleared.
        List<Address__c> listAddr = [SELECT Id, Default_Address__c, MailingStreet__c, Household_Account__c FROM Address__c];
        // each set of edits created a new address object
        System.assertEquals(cHH * 4, listAddr.size());
        for (Address__c addr : listAddr) {
            Boolean fNewDefault = (addr.MailingStreet__c.contains('final Street Edit'));
            System.assertEquals(fNewDefault, addr.Default_Address__c);
        }
    }

    /*********************************************************************************************************
    @description
        update accounts' billing address to cause an update of the default Address object
    verify:
        existing Default Address updated
        HH and Contacts get updated Address
    **********************************************************************************************************/
    @IsTest
    private static void updateAccAddrExisting() {
        //skip the test if Advancement is installed
        if (ADV_PackageInfo_SVC.useAdv()) return;

        npe01__Contacts_And_Orgs_Settings__c contactSettingsForTests = UTIL_CustomSettingsFacade.getContactsSettingsForTests(
            new npe01__Contacts_And_Orgs_Settings__c(
                npe01__Account_Processor__c = CAO_Constants.HH_ACCOUNT_PROCESSOR,
                Simple_Address_Change_Treated_as_Update__c = true
            ));

        // this creates a default Address for each HH
        createHHTestData(cHH, cCon);

        // modify some of the account addresses directly
        // NOTE: we only modify 1 field, so it will be treated as an update to an existing address!
        for (Integer i = 0; i < cHH; i++) {
            Account acc = listAccT[i];
            acc.BillingStreet = 'Direct Street Edit';
        }
        update listAccT;

        for (Integer i = 0; i < cHH; i++) {
            Account acc = listAccT[i];
            acc.BillingState = 'Washington';
        }
        update listAccT;

        for (Integer i = 0; i < cHH; i++) {
            Account acc = listAccT[i];
            acc.BillingStreet = ' direct street  edit ';    // whitespace and casing should not count as real edit.
            acc.BillingState = 'Oregon';
        }
        Test.startTest();
        update listAccT;
        Test.stopTest();

        // verify that the HH and Contacts share the same address
        Map<Id, Account> mapAccIdAcc = new Map<Id, Account>([SELECT Id, Name, BillingStreet, BillingCity, BillingState, BillingPostalCode, BillingCountry, BillingLatitude, BillingLongitude FROM Account]);
        List<Contact> listCon = [SELECT Id, Name, AccountId, is_Address_Override__c, Current_Address__c, MailingStreet, MailingCity, MailingState, MailingPostalCode, MailingCountry, MailingLatitude, MailingLongitude FROM Contact];

        for (Contact con : listCon) {
            Account acc = mapAccIdAcc.get(con.AccountId);
            System.assertEquals(true, isMatchAddressAccCon(acc, con));
            System.assert(acc.BillingStreet.contains('direct street  edit'));
            System.assert(con.MailingStreet.contains('direct street  edit'));
            System.assertEquals(false, con.is_Address_Override__c);
            System.assertNotEquals(null, con.Current_Address__c);
        }

        // verify that no new address was created
        List<Address__c> listAddr = [SELECT Id, Default_Address__c, MailingStreet__c, Household_Account__c FROM Address__c];
        System.assertEquals(cHH, listAddr.size());
        for (Address__c addr : listAddr) {
            System.assertEquals('direct street  edit', addr.MailingStreet__c);
        }
    }

    /*********************************************************************************************************
    @description
        create an Address with no Account
    verify:
        runtime error
    **********************************************************************************************************/
    @IsTest
    private static void newAddrNoAccount() {
        initTestAddr(cHH);
        for (Integer i = 0; i < cHH; i++) {
            System.assertEquals(null, listAddrT[i].Household_Account__c);
        }

        try {
            insert listAddrT;
        } catch (Exception ex) {
            System.assert(ex.getMessage().contains(Label.addrHHAccountOnly));
            return;
        }
        System.assert(false); //we shouldn't get here!
    }


    /*********************************************************************************************************
    @description
        create an Address with a NON-Household Account
    verify:
        runtime error
    **********************************************************************************************************/
    @IsTest
    private static void newAddrNotHHAccount() {
        listAccT = UTIL_UnitTestData_TEST.createMultipleTestAccounts(cHH, CAO_Constants.ONE_TO_ONE_ORGANIZATION_TYPE);
        insert listAccT;

        initTestAddr(cHH);
        for (Integer i = 0; i < cHH; i++) {
            System.assertEquals(null, listAddrT[i].Household_Account__c);
            listAddrT[i].Household_Account__c = listAccT[i].Id;
        }

        try {
            Test.startTest();
            insert listAddrT;
            Test.stopTest();
        } catch (Exception ex) {
            System.assert(ex.getMessage().contains(Label.addrHHAccountOnly));
        }
        Integer insertedAddrCount = [SELECT COUNT() FROM Address__c];
        System.assertEquals(0, insertedAddrCount);

        /* We cannot verify error record was created because the usage of addError causes the whole transaction
        to be rolled back.
        List<Error__c> errors = [select Id, Full_Message__c, Stack_Trace__c, Email_Sent__c from Error__c];
        UTIL_Debug.debug('****Errors: ' + JSON.serializePretty(errors));
        System.assertEquals(1, errors.size());*/
    }

    /*********************************************************************************************************
    @description
        insert new seasonal addresses to HH w/ existing default addresses
    verify:
        contact's && hh address matches new seasonal
        old default addresses still marked default
    **********************************************************************************************************/
    @IsTest
    private static void insertNewSeasonalAddr() {
        // this creates a default Address for each HH
        createHHTestData(cHH, cCon);

        // create additional addresses
        initTestAddr(cHH);
        for (Integer i = 0; i < cHH; i++) {
            listAddrT[i].Household_Account__c = listAccT[i].Id;
            listAddrT[i].Default_Address__c = false;
            listAddrT[i].Seasonal_Start_Month__c = String.valueOf(System.today().addMonths(-1).month());
            listAddrT[i].Seasonal_Start_Day__c = '1';
            listAddrT[i].Seasonal_End_Month__c = String.valueOf(System.today().addMonths(1).month());
            listAddrT[i].Seasonal_End_Day__c = '28';
            listAddrT[i].MailingStreet__c = 'New Seasonal Street' + i;
            listAddrT[i].MailingCity__c = 'New Seasonal City' + i;
        }
        Test.startTest();
        insert listAddrT;
        Test.stopTest();

        // verify that the HH and Contacts share the same address and it's new!
        Map<Id, Account> mapAccIdAcc = new Map<Id, Account>([SELECT Id, Name, BillingStreet, BillingCity, BillingState, BillingPostalCode, BillingCountry, BillingLatitude, BillingLongitude FROM Account]);
        List<Contact> listCon = [SELECT Id, Name, AccountId, is_Address_Override__c, Current_Address__c, MailingStreet, MailingCity, MailingState, MailingPostalCode, MailingCountry, MailingLatitude, MailingLongitude FROM Contact];
        System.assertEquals(cHH * cCon, listCon.size());

        for (Contact con : listCon) {
            Account acc = mapAccIdAcc.get(con.AccountId);
            System.assertEquals(true, isMatchAddressAccCon(acc, con));
            System.assert(con.MailingStreet.contains('New Seasonal Street'));
            System.assert(con.MailingCity.contains('New Seasonal City'));
            System.assertEquals(false, con.is_Address_Override__c);
            System.assertNotEquals(null, con.Current_Address__c);
        }

        // verify the previous addresses still are Default
        List<Address__c> listAddr = [SELECT Id, Default_Address__c, MailingStreet__c, Household_Account__c, Latest_Start_Date__c, Latest_End_Date__c FROM Address__c];
        System.assertEquals(cHH * 2, listAddr.size());
        for (Address__c addr : listAddr) {
            Boolean fSeasonal = (addr.MailingStreet__c.contains('New Seasonal Street'));
            System.assertEquals(!fSeasonal, addr.Default_Address__c);
        }
    }

    /*********************************************************************************************************
    @description
        insert new seasonal addresses, not current, to HH w/ existing default addresses
    verify:
        contact's && hh address stay with default
        old default addresses still marked default
    **********************************************************************************************************/
    @IsTest
    private static void insertNewSeasonalAddrNotCurrent() {
        // this creates a default Address for each HH
        createHHTestData(cHH, cCon);

        // create additional addresses
        initTestAddr(cHH);
        for (Integer i = 0; i < cHH; i++) {
            listAddrT[i].Household_Account__c = listAccT[i].Id;
            listAddrT[i].Default_Address__c = false;
            listAddrT[i].Seasonal_Start_Month__c = String.valueOf(System.today().addMonths(1).month());
            listAddrT[i].Seasonal_Start_Day__c = '1';
            listAddrT[i].Seasonal_End_Month__c = String.valueOf(System.today().addMonths(2).month());
            listAddrT[i].Seasonal_End_Day__c = '28';
            listAddrT[i].MailingStreet__c = 'New Seasonal Street' + i;
            listAddrT[i].MailingCity__c = 'New Seasonal City' + i;
        }
        Test.startTest();
        insert listAddrT;
        Test.stopTest();

        // verify that the HH and Contacts share the same address and it's new!
        Map<Id, Account> mapAccIdAcc = new Map<Id, Account>([SELECT Id, Name, BillingStreet, BillingCity, BillingState, BillingPostalCode, BillingCountry, BillingLatitude, BillingLongitude FROM Account]);
        List<Contact> listCon = [SELECT Id, Name, AccountId, is_Address_Override__c, Current_Address__c, MailingStreet, MailingCity, MailingState, MailingPostalCode, MailingCountry, MailingLatitude, MailingLongitude FROM Contact];
        System.assertEquals(cHH * cCon, listCon.size());

        for (Contact con : listCon) {
            Account acc = mapAccIdAcc.get(con.AccountId);
            System.assertEquals(true, isMatchAddressAccCon(acc, con));
            System.assert(!con.MailingStreet.contains('New Seasonal Street'));
            System.assert(!con.MailingCity.contains('New Seasonal City'));
            System.assertEquals(false, con.is_Address_Override__c);
            System.assertNotEquals(null, con.Current_Address__c);
        }

        // verify the previous addresses still are Default
        List<Address__c> listAddr = [SELECT Id, Default_Address__c, MailingStreet__c, Household_Account__c, Latest_Start_Date__c, Latest_End_Date__c FROM Address__c];
        System.assertEquals(cHH * 2, listAddr.size());
        for (Address__c addr : listAddr) {
            Boolean fSeasonal = (addr.MailingStreet__c.contains('New Seasonal Street'));
            System.assertEquals(!fSeasonal, addr.Default_Address__c);
        }
    }

    /*********************************************************************************************************
    @description
        Execute ContactRepository.getContacts() for an Account not having any Contact
    verify:
        Method returns empty Contact list
    **********************************************************************************************************/
    @IsTest
    private static void ContactRepository_getContactsShouldReturnEmptyListWhenAccountHasNoContacts() {
        Account account = new Account(Name = 'AccountWithoutContacts');
        insert account;

        HouseholdAccounts householdAccounts = new HouseholdAccounts(new Set<Id>{
                account.Id
        });

        Contact[] contacts = householdAccounts.membersOf(account.Id);
        System.assertEquals(0, contacts.size());
    }

    /*********************************************************************************************************
    @description
        Execute ContactRepository.getContacts() for Acconts having Contacts
    verify:
        Method returns expected Contact list for each Account
    **********************************************************************************************************/
    @IsTest
    private static void ContactRepository_getContactsShouldReturnContactsWhenAccountHasContacts() {
        Integer hhSize = 2;
        Integer contactSize = 2;
        createHHTestData(hhSize, contactSize);

        HouseholdAccounts contactRepo = new HouseholdAccounts(
                UTIL_SObject.extractIds(listAccT)
        );

        testAndAssertContactRepositoryGetContacts(contactRepo, listAccT, listConT);
    }

    /*********************************************************************************************************
    @description
        Execute ContactRepository.getContacts() for an Account not passed to the ContactRepository constructor
    verify:
        Method returns expected Contact list for each Account
    **********************************************************************************************************/
    @IsTest
    private static void ContactRepository_getContactsShouldReturnContactsWhenAccountHasNotBeenPassedToConstructor() {
        Integer hhSize = 2;
        Integer contactSize = 2;
        createHHTestData(hhSize, contactSize);

        HouseholdAccounts contactRepo = new HouseholdAccounts(new Set<Id>());
        testAndAssertContactRepositoryGetContacts(contactRepo, listAccT, listConT);

        contactRepo = new HouseholdAccounts(new Set<Id>{
                listAccT[0].Id
        });
        testAndAssertContactRepositoryGetContacts(contactRepo, listAccT, listConT);
    }

    /*********************************************************************************************************
    @description
        Execute ContactRepository.getContacts() for each Account in the input argument Account list
    verify:
        Method returns expected Contact list for each Account
    **********************************************************************************************************/
    static void testAndAssertContactRepositoryGetContacts(HouseholdAccounts contactRepo, List<Account> accounts, List<Contact> contacts) {
        Map<Id, Contact[]> contactsByAccountId = new Map<Id, Contact[]>();
        for (Contact c : contacts) {
            if (!contactsByAccountId.containsKey(c.AccountId)) {
                contactsByAccountId.put(c.AccountId, new Contact[0]);
            }
            contactsByAccountId.get(c.AccountId).add(c);
        }

        for (Account account : accounts) {
            Contact[] expectedContacts = contactsByAccountId.get(account.Id);
            Contact[] actualContacts = contactRepo.membersOf(account.Id);

            System.assertEquals(UTIL_SObject.extractIds(expectedContacts), UTIL_SObject.extractIds(actualContacts));
        }
    }

    /*********************************************************************************************************
    @description
        Insert more than 200 addresses to require multiple trigger calls, and to ensure our static counters
        are handled appropriately.
    verify:
        Addresses are propagated to all contacts and accounts
    **********************************************************************************************************/
    @IsTest
    private static void addressShouldBePropagatedToAccountsAndContactsOnMultipleTriggerCalls() {
        Integer totalHH = 210;
        Integer totalContactPerHH = 1;

        UTIL_Debug.disableDebugLogging();
        UTIL_UnitTestData_TEST.disableAffiliationsTriggers();
        UTIL_UnitTestData_TEST.disableRelationshipTriggers();
        UTIL_UnitTestData_TEST.disableMergeTriggers();
        UTIL_UnitTestData_TEST.disableHHNamingTriggers();

        createHHTestData(totalHH, totalContactPerHH);

        // verify that the HH and Contacts share the same address
        Map<Id, Account> accountById = new Map<Id, Account>([
            SELECT Id, Name, BillingStreet, BillingCity,
                BillingState, BillingPostalCode, BillingCountry,
                BillingLatitude, BillingLongitude
            FROM Account]);
        List<Contact> contacts = getContacts();
        System.assertEquals(totalHH * totalContactPerHH, contacts.size());

        for (Contact con : contacts) {
            Account acc = accountById.get(con.AccountId);

            System.assertEquals(true, isMatchAddressAccCon(acc, con));
            System.assertEquals(false, con.is_Address_Override__c);
            System.assertNotEquals(null, con.Current_Address__c);
        }
    }

    // Helpers
    ////////////


    /*********************************************************************************************************
    * @description
    * utility to set up common test data for the Address tests.
    *    - this will create & insert N household Accounts, each with M contacts
    *    - also will create a Default Addresses for each HH Account
    *    - will also setup the default Account Processor to be HH Accounts
    * @param cHHT the number of Household Accounts to create
    * @param cConT the number of Contacts to create per Household
    **********************************************************************************************************/
    public static void createHHTestData(Integer cHHT, Integer cConT) {

        // we are creating a bunch of test data that relies on no async behavior.
        TDTM_DefaultConfig.startTestDataInit();

        npe01__Contacts_And_Orgs_Settings__c contactSettingsForTests = UTIL_CustomSettingsFacade.getContactsSettings();

        listAccT = UTIL_UnitTestData_TEST.createMultipleTestAccounts(cHHT, CAO_Constants.HH_ACCOUNT_TYPE);
        insert listAccT;

        listConT = UTIL_UnitTestData_TEST.createMultipleTestContacts(cHHT * cConT);
        for (Integer i = 0; i < cHHT; i++) {
            for (Integer j = 0; j < cConT; j++) {
                listConT[(i * cConT) + j].AccountId = listAccT[i].Id;
                listConT[(i * cConT) + j].LastName =  listConT[(i * cConT) + j].LastName + j;
                listConT[(i * cConT) + j].OtherCity = null;
            }
        }
        insert listConT;

        initTestAddr(cHHT);
        for (Integer i = 0; i < cHHT; i++) {
            listAddrT[i].Household_Account__c = listAccT[i].Id;
            listAddrT[i].Default_Address__c = true;
        }
        insert listAddrT;

        // restore async behavior as appropriate
        TDTM_DefaultConfig.stopTestDataInit();
    }

    /*********************************************************************************************************
    * @description Initializes (but not inserts) N new Address objects.
    * @param cAddr the number of Address objects to create
    **********************************************************************************************************/
    public static void initTestAddr(Integer cAddr) {
        listAddrT = new List<Address__c>();
        for (Integer i = 0; i < cAddr; i++) {
            Address__c addr = new Address__c();
            addr.Address_Type__c = 'Home';
            addr.MailingStreet__c = 'Street' + i;
            addr.MailingCity__c = 'City' + i;
            addr.MailingState__c = 'Washington';
            addr.MailingPostalCode__c = 'Zip' + i;
            addr.MailingCountry__c = 'United States';
            addr.Geolocation__Latitude__s = Math.min(47.6097 + i, 90);
            addr.Geolocation__Longitude__s = Math.min(-122.3331 + i, 90);
            listAddrT.add(addr);
        }
    }

    /*********************************************************************************************************
    * @description Populates Contact's Mailing Address from the Address
    * @param c Contact
    * @param sourceAddress Address
    **********************************************************************************************************/
    static void populateContactAddress(Contact c, Address__c sourceAddress) {
        c.MailingStreet = sourceAddress.MailingStreet__c;
        c.MailingCity = sourceAddress.MailingCity__c;
        c.MailingState = sourceAddress.MailingState__c;
        c.MailingPostalCode = sourceAddress.MailingPostalCode__c;
        c.MailingCountry = sourceAddress.MailingCountry__c;
    }

    /*********************************************************************************************************
    * @description Creates mapping of Addresses by a Household
    * @return Map<Id, Address__c[]> Map of Addresses by a Household
    **********************************************************************************************************/
    static Map<Id, Address__c[]> getAddressesByHousehold() {
        Map<Id, Address__c[]> addressesByHh = new Map<Id, Address__c[]>();

        for (Address__c addr : getAddresses()) {
            if (!addressesByHh.containsKey(addr.Household_Account__c)) {
                addressesByHh.put(addr.Household_Account__c, new Address__c[0]);
            }

            addressesByHh.get(addr.Household_Account__c).add(addr);
        }

        return addressesByHh;
    }

    /*********************************************************************************************************
    * @description Retrieves all Addresses from database
    * @return Address__c[] List of all Addresses
    **********************************************************************************************************/
    static Address__c[] getAddresses() {
        return [
            SELECT Id, Default_Address__c, Household_Account__c, Address_Type__c,
                MailingStreet__c, MailingCity__c, MailingState__c,
                MailingPostalCode__c, MailingCountry__c
            FROM Address__c
        ];
    }

    /*********************************************************************************************************
    * @description Retrieves all Contacts from database
    * @return Contact[] List of all Contacts
    **********************************************************************************************************/
    static Contact[] getContacts() {
        return [
            SELECT Id, Name, AccountId, is_Address_Override__c,
                Current_Address__c, npe01__Primary_Address_Type__c,
                MailingStreet, MailingCity, MailingState, MailingPostalCode,
                MailingCountry, MailingLatitude, MailingLongitude
            FROM Contact
        ];
    }

    /*********************************************************************************************************
    * @description Asserts that an actual Address has the same values as the expected Address
    * @param expected An Address with expected values
    * @param actual An Address that needs to be verified
    **********************************************************************************************************/
    static void assertEquals(Address__c expected, Address__c actual) {
        System.assertEquals(expected.Address_Type__c, actual.Address_Type__c);
        System.assertEquals(expected.MailingStreet__c, actual.MailingStreet__c);
        System.assertEquals(expected.MailingCity__c, actual.MailingCity__c);
        System.assertEquals(expected.MailingState__c, actual.MailingState__c);
        System.assertEquals(expected.MailingPostalCode__c, actual.MailingPostalCode__c);
        System.assertEquals(expected.MailingCountry__c, actual.MailingCountry__c);
    }

    /*********************************************************************************************************
    * @description Asserts that a Contact's Address is the same as the expected Address
    * @param expected An Address with expected values
    * @param c Contact for which Mailing Address needs to be verified
    **********************************************************************************************************/
    static void assertEqualAddresses(Address__c expected, Contact c) {
        System.assertEquals(expected.Id, c.Current_Address__c);
        System.assertEquals(expected.Address_Type__c, c.npe01__Primary_Address_Type__c);
        System.assertEquals(expected.MailingStreet__c, c.MailingStreet);
        System.assertEquals(expected.MailingCity__c, c.MailingCity);
        System.assertEquals(expected.MailingState__c, c.MailingState);
        System.assertEquals(expected.MailingPostalCode__c, c.MailingPostalCode);
        System.assertEquals(expected.MailingCountry__c, c.MailingCountry);
    }

    /*********************************************************************************************************
    * @description Returns whether an Account Billing address matches a Contact Mailing address
    * @return  boolean 
    **********************************************************************************************************/
    public static Boolean isMatchAddressAccCon(Account acc, Contact con) {
        return (acc.BillingStreet == con.MailingStreet &&
            acc.BillingCity == con.MailingCity &&
            acc.BillingState == con.MailingState &&
            acc.BillingPostalCode == con.MailingPostalCode &&
            acc.BillingCountry == con.MailingCountry &&
            acc.BillingLatitude == con.MailingLatitude &&
            acc.BillingLongitude == con.MailingLongitude
        );
    }

    /*******************************************************************************************************
    * @description Builds SOQL for Contact sObject. Fields include standard Mailing fields as well as the one for State and Country Picklist enabled.
    * @return String SOQL
    */
    private static String buildContactSoql() {
        List<String> selectFields = new List<String>{
            'Id', 'AccountId', 'is_Address_Override__c', 'Current_Address__c',
            'MailingStreet', 'MailingCity', 'MailingState', 'MailingCountry', 'MailingPostalCode',
            'MailingLatitude', 'MailingLongitude', 'npe01__Primary_Address_Type__c'};

        if (orgConfig.isStateCountryPicklistsEnabled()) {

            selectFields.add('MailingCountryCode');
            selectFields.add('MailingStateCode');
            selectFields.add('OtherCountryCode');
            selectFields.add('OtherStateCode');
        }

        return new UTIL_Query()
            .withSelectFields(selectFields)
            .withFrom('Contact')
            .build();
    }


    /*******************************************************************************************************
    * @description Builds SOQL for Account sObject. Fields include standard Billing fields as well as the one for State and Country Picklist enabled.
    * @return String SOQL
    */
    private static String buildAccountSoql() {
        List<String> selectFields = new List<String>{
            'Id', 'BillingStreet', 'BillingCity', 'BillingState',  'BillingCountry',
            'BillingPostalCode', 'BillingLatitude', 'BillingLongitude'};

        if (orgConfig.isStateCountryPicklistsEnabled()) {

            selectFields.add('BillingCountryCode');
            selectFields.add('BillingStateCode');
        }

        return new UTIL_Query()
            .withSelectFields(selectFields)
            .withFrom('Account')
            .build();
    }


}
