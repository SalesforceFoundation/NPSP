/*
    Copyright (c) 2019 Salesforce.org
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
* @date 2019
* @group Batch Data Import
* @group-content ../../ApexDocContent/BatchDataImport.htm
* @description tests specific to the Batch Data Importer Dry Run mode
*/

@isTest
public with sharing class BDI_DryRun_TEST {

    /*********************************************************************************************************
    * @description operation:
    *    process new contacts through Dry Run mode
    * verify:
    *    no objects created
    *    Statuses updated appropriately
    **********************************************************************************************************/
    static testMethod void manyDISameNewC1Contact() {

        List<DataImport__c> dataImports = new List<DataImport__c>();
        dataImports.add(BDI_DataImport_TEST.newDI('c1', 'C1'));
        dataImports.add(BDI_DataImport_TEST.newDI('c1', 'C1'));
        dataImports.add(BDI_DataImport_TEST.newDI('c1', 'C1'));
        insert dataImports;

        //run batch data import
        Test.StartTest();
        BDI_DataImport_BATCH bdi = new BDI_DataImport_BATCH(null, true);
        ID ApexJobId = Database.executeBatch(bdi, 10);
        Test.stopTest();

        // verify expected results
        List<Contact> contacts = [SELECT Id, Name FROM Contact];
        System.assertEquals(0, contacts.size());

        dataImports = getUpdatedDataImports();
        System.assertEquals(3, dataImports.size());
        for (DataImport__c dataImport : dataImports) {
            System.assertEquals(BDI_DataImport_API.bdiDryRunValidated, dataImport.Status__c);
            System.assertEquals(null, dataImport.Contact1Imported__c);
            System.assertEquals(null, dataImport.HouseholdAccountImported__c);
            System.assertEquals(Label.bdiDryRunNoMatch, dataImport.Contact1ImportStatus__c);
        }
    }

    /*********************************************************************************************************
    * @description operation:
    *    process new contacts with C1 and C2 specified, through Dry Run mode
    * verify:
    *    no objects created
    *    Statuses updated appropriately
    **********************************************************************************************************/
    static testMethod void manyDINewC1andC2Contacts() {

        List<DataImport__c> dataImports = new List<DataImport__c>();
        dataImports.add(BDI_DataImport_TEST.newDI('c1', 'C1', 'c1Spouse', null));
        dataImports.add(BDI_DataImport_TEST.newDI('c2', 'C2', 'c2Spouse', null));
        dataImports.add(BDI_DataImport_TEST.newDI('c3', 'C3', 'c3Spouse', null));
        insert dataImports;

        //run batch data import
        Test.StartTest();
        BDI_DataImport_BATCH bdi = new BDI_DataImport_BATCH(null, true);
        ID ApexJobId = Database.executeBatch(bdi, 10);
        Test.stopTest();

        // verify expected results
        List<Contact> contacts = [SELECT Id, Name FROM Contact];
        System.assertEquals(0, contacts.size());

        dataImports = getUpdatedDataImports();
        System.assertEquals(3, dataImports.size());
        for (DataImport__c dataImport : dataImports) {
            System.assertEquals(BDI_DataImport_API.bdiDryRunValidated, dataImport.Status__c);
            System.assertEquals(null, dataImport.Contact1Imported__c);
            System.assertEquals(null, dataImport.HouseholdAccountImported__c);
            System.assertEquals(Label.bdiDryRunNoMatch, dataImport.Contact1ImportStatus__c);
            System.assertEquals(null, dataImport.Contact2Imported__c);
            System.assertEquals(Label.bdiDryRunNoMatch, dataImport.Contact2ImportStatus__c);
        }
    }

    /*********************************************************************************************************
    * @description operation:
    *    process new contacts through Dry Run mode
    * verify:
    *    no objects created
    *    Statuses updated appropriately
    **********************************************************************************************************/
    static testMethod void manyDISameNewC1andC2Contacts() {

        List<DataImport__c> dataImports = new List<DataImport__c>();
        dataImports.add(BDI_DataImport_TEST.newDI('c1', 'C1', 'c1Spouse', null));
        dataImports.add(BDI_DataImport_TEST.newDI('c1', 'C1', 'c1Spouse', null));
        dataImports.add(BDI_DataImport_TEST.newDI('c1', 'C1', 'c1Spouse', null));
        insert dataImports;

        //run batch data import
        Test.StartTest();
        BDI_DataImport_BATCH bdi = new BDI_DataImport_BATCH(null, true);
        ID ApexJobId = Database.executeBatch(bdi, 10);
        Test.stopTest();

        // verify expected results
        List<Contact> contacts = [SELECT Id, Name FROM Contact];
        System.assertEquals(0, contacts.size());

        dataImports = getUpdatedDataImports();
        System.assertEquals(3, dataImports.size());
        for (DataImport__c dataImport : dataImports) {
            System.assertEquals(BDI_DataImport_API.bdiDryRunValidated, dataImport.Status__c);
            System.assertEquals(null, dataImport.Contact1Imported__c);
            System.assertEquals(null, dataImport.HouseholdAccountImported__c);
            System.assertEquals(Label.bdiDryRunNoMatch, dataImport.Contact1ImportStatus__c);
            System.assertEquals(Label.bdiDryRunNoMatch, dataImport.Contact2ImportStatus__c);
            System.assertEquals(null, dataImport.Contact2Imported__c);
        }
    }

    /*********************************************************************************************************
    * @description operation:
    *    process existing contacts through Dry Run mode
    * verify:
    *    no objects created
    *    Statuses updated appropriately
    **********************************************************************************************************/
    static testMethod void manyDIExistingC1andC2Contacts() {

        // existing contacts
        List<Contact> existingContacts = new List<Contact>();
        existingContacts.add(new Contact(Firstname='c1', Lastname='C1', Email='c1@C1.com'));
        existingContacts.add(new Contact(Firstname='c2', Lastname='C2', Email='c2@C2.com'));
        existingContacts.add(new Contact(Firstname='c3', Lastname='C3', Email='c3@C3.com'));
        existingContacts.add(new Contact(Firstname='c4', Lastname='C4', Email='c4@C4.com'));
        insert existingContacts;

        UTIL_UnitTestData_TEST.setFixedSearchResults(existingContacts);

        List<DataImport__c> dataImports = new List<DataImport__c>();
        dataImports.add(BDI_DataImport_TEST.newDI('c1', 'C1', 'c2', 'C2'));
        dataImports.add(BDI_DataImport_TEST.newDI('c3', 'C3', 'c4', 'C4'));
        insert dataImports;

        //run batch data import
        Test.StartTest();
        BDI_DataImport_BATCH bdi = new BDI_DataImport_BATCH(null, true);
        ID ApexJobId = Database.executeBatch(bdi, 10);
        Test.stopTest();

        // verify expected results
        List<Contact> contacts = [SELECT Id, Name FROM Contact];
        System.assertEquals(4, contacts.size());

        dataImports = getUpdatedDataImports();
        System.assertEquals(2, dataImports.size());
        for (DataImport__c dataImport : dataImports) {
            System.assertEquals(BDI_DataImport_API.bdiDryRunValidated, dataImport.Status__c);
            System.assertNotEquals(null, dataImport.Contact1Imported__c);
            System.assertNotEquals(null, dataImport.HouseholdAccountImported__c);
            System.assertEquals(Label.bdiDryRunMatched, dataImport.Contact1ImportStatus__c);
            System.assertNotEquals(null, dataImport.Contact2Imported__c);
            System.assertEquals(Label.bdiDryRunMatched, dataImport.Contact2ImportStatus__c);
        }
    }

    /*********************************************************************************************************
    * @description operation:
    *    process new Accounts through Dry Run mode
    * verify:
    *    no objects created
    *    Statuses updated appropriately
    **********************************************************************************************************/
    static testMethod void manyDISameNewA1A2Accounts() {

        List<DataImport__c> dataImports = new List<DataImport__c>();
        dataImports.add(new DataImport__c(Account1_Name__c='A1', Account2_Name__c='A2'));
        dataImports.add(new DataImport__c(Account1_Name__c='A1', Account2_Name__c='A2'));
        dataImports.add(new DataImport__c(Account1_Name__c='A1', Account2_Name__c='A2'));
        insert dataImports;

        //run batch data import
        Test.StartTest();
        BDI_DataImport_BATCH bdi = new BDI_DataImport_BATCH(null, true);
        ID ApexJobId = Database.executeBatch(bdi, 10);
        Test.stopTest();

        // verify expected results
        List<Account> accounts = [SELECT Id, Name FROM Account];
        System.assertEquals(0, accounts.size());

        dataImports = getUpdatedDataImports();
        System.assertEquals(3, dataImports.size());
        for (DataImport__c dataImport : dataImports) {
            System.assertEquals(BDI_DataImport_API.bdiDryRunValidated, dataImport.Status__c);
            System.assertEquals(null, dataImport.Account1Imported__c);
            System.assertEquals(null, dataImport.Account2Imported__c);
            System.assertEquals(Label.bdiDryRunNoMatch, dataImport.Account1ImportStatus__c);
            System.assertEquals(Label.bdiDryRunNoMatch, dataImport.Account2ImportStatus__c);
        }
    }

    /*********************************************************************************************************
    * @description operation:
    *    process new Accounts through Dry Run mode
    * verify:
    *    no objects created
    *    Statuses updated appropriately
    **********************************************************************************************************/
    static testMethod void manyDIExistingA1A2Accounts() {

        // existing Accounts
        List<Account> existingAccounts = new List<Account>();
        existingAccounts.add(new Account(Name='A1'));
        existingAccounts.add(new Account(Name='A2'));
        existingAccounts.add(new Account(Name='A3'));
        existingAccounts.add(new Account(Name='A4'));
        insert existingAccounts;

        UTIL_UnitTestData_TEST.setFixedSearchResults(existingAccounts);

        List<DataImport__c> dataImports = new List<DataImport__c>();
        dataImports.add(new DataImport__c(Account1_Name__c='A1', Account2_Name__c='A2'));
        dataImports.add(new DataImport__c(Account1_Name__c='A3', Account2_Name__c='A4'));
        insert dataImports;

        //run batch data import
        Test.StartTest();
        BDI_DataImport_BATCH bdi = new BDI_DataImport_BATCH(null, true);
        ID ApexJobId = Database.executeBatch(bdi, 10);
        Test.stopTest();

        // verify expected results
        List<Account> accounts = [SELECT Id, Name FROM Account];
        System.assertEquals(4, accounts.size());

        dataImports = getUpdatedDataImports();
        System.assertEquals(2, dataImports.size());
        for (DataImport__c dataImport : dataImports) {
            System.assertEquals(BDI_DataImport_API.bdiDryRunValidated, dataImport.Status__c);
            System.assertNotEquals(null, dataImport.Account1Imported__c);
            System.assertNotEquals(null, dataImport.Account2Imported__c);
            System.assertEquals(Label.bdiDryRunMatched, dataImport.Account1ImportStatus__c);
            System.assertEquals(Label.bdiDryRunMatched, dataImport.Account2ImportStatus__c);
        }
    }

    /*********************************************************************************************************
    * @description operation
    *        process existing contacts with existing home addresses
    * verify:
    *    no objects created
    *    Statuses updated appropriately
    **********************************************************************************************************/
    static testMethod void manyDIExistingHomeAddresses() {
        //skip the test if Advancement is installed
        if(ADV_PackageInfo_SVC.useAdv()) return;

        Address__c address = new Address__c(MailingCity__c='Seattle', MailingState__c='Washington', MailingCountry__c='United States');

        // existing contacts
        List<Contact> existingContacts = new List<Contact>();
        existingContacts.add(new Contact(Firstname='c1', Lastname='C1', Email='c1@C1.com',
                MailingCity=address.MailingCity__c, MailingState=address.MailingState__c, MailingCountry=address.MailingCountry__c));
        existingContacts.add(new Contact(Firstname='c3', Lastname='C3', Email='c3@C3.com',
                MailingCity=address.MailingCity__c, MailingState=address.MailingState__c, MailingCountry=address.MailingCountry__c));
        insert existingContacts;

        UTIL_UnitTestData_TEST.setFixedSearchResults(existingContacts);

        List<DataImport__c> dataImports = new List<DataImport__c>();
        dataImports.add(BDI_DataImport_TEST.newDI('c1', 'C1', 'c2', 'C2', address));
        dataImports.add(BDI_DataImport_TEST.newDI('c3', 'C3', 'c4', 'C4', address));
        insert dataImports;

        //run batch data import
        Test.StartTest();
        BDI_DataImport_BATCH bdi = new BDI_DataImport_BATCH(null, true);
        ID ApexJobId = Database.executeBatch(bdi, 10);
        Test.stopTest();

        // verify expected results
        List<Contact> contacts = [SELECT Id, Name, AccountId, MailingCity FROM Contact];
        System.assertEquals(2, contacts.size());

        List<Address__c> addresses = [SELECT Id, Household_Account__c, MailingCity__c FROM Address__c];
        System.assertEquals(2, addresses.size());

        dataImports = getUpdatedDataImports();
        System.assertEquals(2, dataImports.size());
        for (DataImport__c dataImport : dataImports) {
            System.assertEquals(BDI_DataImport_API.bdiDryRunValidated, dataImport.Status__c);
            System.assertNotEquals(null, dataImport.HomeAddressImported__c);
            System.assertEquals(Label.bdiDryRunMatched, dataImport.HomeAddressImportStatus__c);
        }
    }

    /*********************************************************************************************************
    * @description operation
    *        process existing contacts with updated home addresses
    * verify:
    *    no objects created
    *    Statuses updated appropriately
    **********************************************************************************************************/
    static testMethod void manyDIUpdatedHomeAddresses() {
        //skip the test if Advancement is installed
        if(ADV_PackageInfo_SVC.useAdv()) return;

        Address__c address1 = new Address__c(MailingCity__c='Seattle', MailingState__c='Washington', MailingCountry__c='United States');
        Address__c address2 = new Address__c(MailingCity__c='Portland', MailingState__c='Oregon');

        // existing contacts
        List<Contact> existingContacts = new List<Contact>();
        existingContacts.add(new Contact(Firstname='c1', Lastname='C1', Email='c1@C1.com',
                MailingCity=address1.MailingCity__c, MailingState=address1.MailingState__c, MailingCountry=address1.MailingCountry__c));
        existingContacts.add(new Contact(Firstname='c3', Lastname='C3', Email='c3@C3.com',
                MailingCity=address1.MailingCity__c, MailingState=address1.MailingState__c, MailingCountry=address1.MailingCountry__c));
        insert existingContacts;

        UTIL_UnitTestData_TEST.setFixedSearchResults(existingContacts);

        List<DataImport__c> dataImports = new List<DataImport__c>();
        dataImports.add(BDI_DataImport_TEST.newDI('c1', 'C1', 'c2', 'C2', address2));
        dataImports.add(BDI_DataImport_TEST.newDI('c3', 'C3', 'c4', 'C4', address2));
        dataImports.add(BDI_DataImport_TEST.newDI('c3', 'C3', 'c5', 'C5', address2));
        insert dataImports;

        //run batch data import
        Test.StartTest();
        BDI_DataImport_BATCH bdi = new BDI_DataImport_BATCH(null, true);
        ID ApexJobId = Database.executeBatch(bdi, 10);
        Test.stopTest();

        // verify expected results
        List<Contact> contacts = [SELECT Id, Name, AccountId, MailingCity FROM Contact];
        System.assertEquals(2, contacts.size());

        List<Address__c> addresses = [SELECT Id, Household_Account__c, MailingCity__c FROM Address__c];
        System.assertEquals(2, addresses.size());

        dataImports = getUpdatedDataImports();
        System.assertEquals(3, dataImports.size());
        for (DataImport__c dataImport : dataImports) {
            System.assertEquals(BDI_DataImport_API.bdiDryRunValidated, dataImport.Status__c);
            System.assertEquals(null, dataImport.HomeAddressImported__c);
            System.assertEquals(Label.bdiDryRunNoMatch, dataImport.HomeAddressImportStatus__c);
        }
    }

    /*********************************************************************************************************
    * @description operation:
    *    process records with errors through Dry Run mode
    * verify:
    *    no objects created
    *    Statuses updated appropriately
    **********************************************************************************************************/
    static testMethod void manyDIContainingErrors() {

        List<DataImport__c> dataImports = new List<DataImport__c>();
        dataImports.add(new DataImport__c(Contact1_Firstname__c='fail'));
        dataImports.add(new DataImport__c(Contact1_Firstname__c='fail'));
        dataImports.add(new DataImport__c(Contact1_Firstname__c='c3', Contact1_Lastname__c='C3'));
        insert dataImports;

        //run batch data import
        Test.StartTest();
        BDI_DataImport_BATCH bdi = new BDI_DataImport_BATCH(null, true);
        ID ApexJobId = Database.executeBatch(bdi, 10);
        Test.stopTest();

        // verify expected results
        List<Contact> contacts = [SELECT Id, Name FROM Contact];
        System.assertEquals(0, contacts.size());

        dataImports = getUpdatedDataImports();
        System.assertEquals(3, dataImports.size());
        for (DataImport__c dataImport : dataImports) {
            if (dataImport.Contact1_Firstname__c == 'fail') {
                System.assertEquals(BDI_DataImport_API.bdiDryRunError, dataImport.Status__c);
                System.assertEquals(null, dataImport.Contact1Imported__c);
                System.assertEquals(null, dataImport.HouseholdAccountImported__c);
                System.assertNotEquals(null, dataImport.Contact1ImportStatus__c);
            } else {
                System.assertEquals(BDI_DataImport_API.bdiDryRunValidated, dataImport.Status__c);
                System.assertEquals(null, dataImport.Contact1Imported__c);
                System.assertEquals(null, dataImport.HouseholdAccountImported__c);
                System.assertEquals(Label.bdiDryRunNoMatch, dataImport.Contact1ImportStatus__c);
            }
        }
    }

    /*********************************************************************************************************
    * @description operation:
    *    process new contacts with new Donations through Dry Run mode
    * verify:
    *    no objects created
    *    Statuses updated appropriately
    **********************************************************************************************************/
    static testMethod void manyDINewC1ContactNewDonations() {

        List<DataImport__c> dataImports = new List<DataImport__c>();
        dataImports.add(BDI_DataImport_TEST.newDI('c1', 'C1', 100));

        dataImports.add(BDI_DataImport_TEST.newDI('c2', 'C2', 100));
        insert dataImports;

        //run batch data import
        Test.StartTest();
        BDI_DataImport_BATCH bdi = new BDI_DataImport_BATCH(null, true);
        ID ApexJobId = Database.executeBatch(bdi, 10);
        Test.stopTest();

        // verify expected results
        List<Contact> contacts = [SELECT Id, Name FROM Contact];
        System.assertEquals(0, contacts.size());
        List<Opportunity> opps = [SELECT Id, Name FROM Opportunity];
        System.assertEquals(0, opps.size());

        dataImports = getUpdatedDataImports();
        System.assertEquals(2, dataImports.size());
        for (DataImport__c dataImport : dataImports) {
            System.assertEquals(BDI_DataImport_API.bdiDryRunValidated, dataImport.Status__c);
            System.assertEquals(null, dataImport.Contact1Imported__c);
            System.assertEquals(null, dataImport.HouseholdAccountImported__c);
            System.assertEquals(Label.bdiDryRunNoMatch, dataImport.Contact1ImportStatus__c);

            System.assertEquals(null, dataImport.DonationImported__c);
            System.assertEquals(null, dataImport.Donation_Possible_Matches__c);
            System.assertEquals(null, dataImport.DonationImportStatus__c);

            System.assertEquals(null, dataImport.PaymentImported__c);
            System.assertEquals(null, dataImport.Payment_Possible_Matches__c);
            System.assertEquals(null, dataImport.PaymentImportStatus__c);
        }
    }

    /*********************************************************************************************************
    * @description operation:
    *    process existing contacts with new Donations through Dry Run mode
    * verify:
    *    no objects created
    *    Statuses updated appropriately
    **********************************************************************************************************/
    static testMethod void manyDIExistingC1ContactNewDonations() {

        // existing contacts
        List<Contact> existingContacts = new List<Contact>();
        existingContacts.add(new Contact(Firstname='c1', Lastname='C1', Email='c1@C1.com'));
        existingContacts.add(new Contact(Firstname='c2', Lastname='C2', Email='c2@C2.com'));
        insert existingContacts;

        UTIL_UnitTestData_TEST.setFixedSearchResults(existingContacts);

        List<DataImport__c> dataImports = new List<DataImport__c>();
        dataImports.add(BDI_DataImport_TEST.newDI('c1', 'C1', 100));

        dataImports.add(BDI_DataImport_TEST.newDI('c2', 'C2', 200));
        insert dataImports;

        // set the specified settings
        Data_Import_Settings__c diSettings = UTIL_CustomSettingsFacade.getDataImportSettings();
        diSettings.Donation_Matching_Rule__c = UTIL_Namespace.StrTokenNSPrefix('Donation_Amount__c') + ';' +
            UTIL_Namespace.StrTokenNSPrefix('Donation_Date__c');
        diSettings.Donation_Matching_Behavior__c = BDI_DataImport_API.BestMatchOrCreate;

        //run batch data import
        Test.StartTest();
        BDI_DataImport_BATCH bdi = new BDI_DataImport_BATCH(null, true);
        ID ApexJobId = Database.executeBatch(bdi, 10);
        Test.stopTest();

        // verify expected results
        List<Contact> contacts = [SELECT Id, Name FROM Contact];
        System.assertEquals(2, contacts.size());
        List<Opportunity> opps = [SELECT Id, Name FROM Opportunity];
        System.assertEquals(0, opps.size());

        dataImports = getUpdatedDataImports();
        System.assertEquals(2, dataImports.size());
        for (DataImport__c dataImport : dataImports) {
            System.assertEquals(BDI_DataImport_API.bdiDryRunValidated, dataImport.Status__c);
            System.assertNotEquals(null, dataImport.Contact1Imported__c);
            System.assertNotEquals(null, dataImport.HouseholdAccountImported__c);
            System.assertEquals(Label.bdiDryRunMatched, dataImport.Contact1ImportStatus__c);

            System.assertEquals(null, dataImport.DonationImported__c);
            System.assertEquals(null, dataImport.Donation_Possible_Matches__c);
            System.assertEquals(Label.bdiDryRunNoMatch, dataImport.DonationImportStatus__c);

            System.assertEquals(null, dataImport.PaymentImported__c);
            System.assertEquals(null, dataImport.Payment_Possible_Matches__c);
            System.assertEquals(null, dataImport.PaymentImportStatus__c);
        }
    }

    /*********************************************************************************************************
    * @description operation:
    *    process existing contacts with existing matched Donations through Dry Run mode
    * verify:
    *    no objects created
    *    Statuses updated appropriately
    **********************************************************************************************************/
    static testMethod void manyDIExistingC1ContactExistingMatchedDonations() {

        // existing contacts
        List<Contact> existingContacts = new List<Contact>();
        existingContacts.add(new Contact(Firstname='c1', Lastname='C1', Email='c1@C1.com'));
        existingContacts.add(new Contact(Firstname='c2', Lastname='C2', Email='c2@C2.com'));
        insert existingContacts;

        UTIL_UnitTestData_TEST.setFixedSearchResults(existingContacts);
        
        // existing opps
        List<Opportunity> existingOpps = UTIL_UnitTestData_TEST.OppsForContactList(existingContacts, null,
            UTIL_unitTestData_TEST.getOpenStage(), System.today(), 100, null, null);
        insert existingOpps;

        List<DataImport__c> dataImports = new List<DataImport__c>();
        dataImports.add(BDI_DataImport_TEST.newDI('c1', 'C1', 100));
        //should stay in old format for Contact1_Work_Email__c only
        dataImports.add(new DataImport__c(Contact1_Firstname__c='c2', Contact1_Lastname__c='C2', Contact1_Work_Email__c='c2@C2.com',
                Donation_Amount__c=100, Donation_Date__c=System.today()));
        insert dataImports;

        // set the specified settings
        Data_Import_Settings__c diSettings = UTIL_CustomSettingsFacade.getDataImportSettings();
        diSettings.Donation_Matching_Rule__c = UTIL_Namespace.StrTokenNSPrefix('Donation_Amount__c') + ';' +
            UTIL_Namespace.StrTokenNSPrefix('Donation_Date__c');
        diSettings.Donation_Matching_Behavior__c = BDI_DataImport_API.BestMatchOrCreate;

        //run batch data import
        Test.StartTest();
        BDI_DataImport_BATCH bdi = new BDI_DataImport_BATCH(null, true);
        ID ApexJobId = Database.executeBatch(bdi, 10);
        Test.stopTest();

        // verify expected results
        List<Contact> contacts = [SELECT Id, Name FROM Contact];
        System.assertEquals(2, contacts.size());
        List<Opportunity> opps = [SELECT Id, Name FROM Opportunity];
        System.assertEquals(2, opps.size());

        dataImports = getUpdatedDataImports();
        System.assertEquals(2, dataImports.size());
        for (DataImport__c dataImport : dataImports) {
            System.assertEquals(BDI_DataImport_API.bdiDryRunValidated, dataImport.Status__c);
            System.assertNotEquals(null, dataImport.Contact1Imported__c);
            System.assertNotEquals(null, dataImport.HouseholdAccountImported__c);
            System.assertEquals(Label.bdiDryRunMatched, dataImport.Contact1ImportStatus__c);

            System.assertNotEquals(null, dataImport.DonationImported__c);
            System.assertEquals(null, dataImport.Donation_Possible_Matches__c);
            System.assertEquals(Label.bdiDryRunMatched, dataImport.DonationImportStatus__c);

            System.assertNotEquals(null, dataImport.PaymentImported__c);
            System.assertEquals(null, dataImport.Payment_Possible_Matches__c);
            System.assertEquals(Label.bdiDryRunMatched, dataImport.PaymentImportStatus__c);
        }
    }

    /*********************************************************************************************************
    * @description operation:
    *    process existing contacts with existing matched by Id Donations through Dry Run mode
    * verify:
    *    no objects created
    *    Statuses updated appropriately
    **********************************************************************************************************/
    static testMethod void manyDIExistingC1ContactExistingMatchedByIdDonations() {

        // existing contacts
        List<Contact> existingContacts = new List<Contact>();
        existingContacts.add(new Contact(Firstname='c1', Lastname='C1', Email='c1@C1.com'));
        existingContacts.add(new Contact(Firstname='c2', Lastname='C2', Email='c2@C2.com'));
        insert existingContacts;

        UTIL_UnitTestData_TEST.setFixedSearchResults(existingContacts);

        // existing opps
        List<Opportunity> existingOpps = UTIL_UnitTestData_TEST.OppsForContactList(existingContacts, null,
            UTIL_unitTestData_TEST.getOpenStage(), System.today(), 100, null, null);
        insert existingOpps;


        List<DataImport__c> dataImports = new List<DataImport__c>();
        dataImports.add(BDI_DataImport_TEST.newDI('c1', 'C1', 100));
        dataImports[0].DonationImported__c = existingOpps[0].Id;

        dataImports.add(BDI_DataImport_TEST.newDI('c2', 'C2', 200));
        dataImports[1].DonationImported__c = existingOpps[1].Id;
        insert dataImports;

        // set the specified settings
        Data_Import_Settings__c diSettings = UTIL_CustomSettingsFacade.getDataImportSettings();
        diSettings.Donation_Matching_Rule__c = UTIL_Namespace.StrTokenNSPrefix('Donation_Amount__c') + ';' +
            UTIL_Namespace.StrTokenNSPrefix('Donation_Date__c');
        diSettings.Donation_Matching_Behavior__c = BDI_DataImport_API.BestMatchOrCreate;

        //run batch data import
        Test.StartTest();
        BDI_DataImport_BATCH bdi = new BDI_DataImport_BATCH(null, true);
        ID ApexJobId = Database.executeBatch(bdi, 10);
        Test.stopTest();

        // verify expected results
        List<Contact> contacts = [SELECT Id, Name FROM Contact];
        System.assertEquals(2, contacts.size());
        List<Opportunity> opps = [SELECT Id, Name FROM Opportunity];
        System.assertEquals(2, opps.size());

        dataImports = getUpdatedDataImports();
        System.assertEquals(2, dataImports.size());
        for (DataImport__c dataImport : dataImports) {
            System.assertEquals(BDI_DataImport_API.bdiDryRunValidated, dataImport.Status__c);
            System.assertNotEquals(null, dataImport.Contact1Imported__c);
            System.assertNotEquals(null, dataImport.HouseholdAccountImported__c);
            System.assertEquals(Label.bdiDryRunMatched, dataImport.Contact1ImportStatus__c);

            System.assertNotEquals(null, dataImport.DonationImported__c);
            System.assertEquals(null, dataImport.Donation_Possible_Matches__c);
            System.assertEquals(Label.bdiDryRunMatchedId, dataImport.DonationImportStatus__c);

            System.assertNotEquals(null, dataImport.PaymentImported__c);
            System.assertEquals(null, dataImport.Payment_Possible_Matches__c);
            System.assertEquals(Label.bdiDryRunMatched, dataImport.PaymentImportStatus__c);
        }
    }

    /*********************************************************************************************************
    * @description operation:
    *    process existing contacts with existing matched by Id Payment through Dry Run mode
    * verify:
    *    no objects created
    *    Statuses updated appropriately
    **********************************************************************************************************/
    static testMethod void manyDIExistingC1ContactExistingMatchedByIdPayments() {

        // existing contacts
        List<Contact> existingContacts = new List<Contact>();
        existingContacts.add(new Contact(Firstname='c1', Lastname='C1', Email='c1@C1.com'));
        existingContacts.add(new Contact(Firstname='c2', Lastname='C2', Email='c2@C2.com'));
        insert existingContacts;

        UTIL_UnitTestData_TEST.setFixedSearchResults(existingContacts);

        // existing opps
        List<Opportunity> listOppExisting = UTIL_UnitTestData_TEST.OppsForContactList(existingContacts, null,
            UTIL_unitTestData_TEST.getOpenStage(), System.today(), 100, null, null);
        insert listOppExisting;

        // find auto-created payments
        List<npe01__OppPayment__c> listPaymentExisting = [SELECT Id FROM npe01__OppPayment__c ORDER BY npe01__Opportunity__c];
        System.assertEquals(2, listPaymentExisting.size());

        List<DataImport__c> dataImports = new List<DataImport__c>();
        dataImports.add(BDI_DataImport_TEST.newDI('c1', 'C1', 100));
        dataImports[0].PaymentImported__c=listPaymentExisting[0].Id;
        //use old format for work email only
        dataImports.add(new DataImport__c(Contact1_Firstname__c='c2', Contact1_Lastname__c='C2', Contact1_Work_Email__c='c2@C2.com',
            Donation_Amount__c=100, Donation_Date__c=System.today(), PaymentImported__c=listPaymentExisting[1].Id));
        insert dataImports;

        // set the specified settings
        Data_Import_Settings__c diSettings = UTIL_CustomSettingsFacade.getDataImportSettings();
        diSettings.Donation_Matching_Rule__c = UTIL_Namespace.StrTokenNSPrefix('Donation_Amount__c') + ';' +
            UTIL_Namespace.StrTokenNSPrefix('Donation_Date__c');
        diSettings.Donation_Matching_Behavior__c = BDI_DataImport_API.BestMatchOrCreate;

        //run batch data import
        Test.StartTest();
        BDI_DataImport_BATCH bdi = new BDI_DataImport_BATCH(null, true);
        ID ApexJobId = Database.executeBatch(bdi, 10);
        Test.stopTest();

        // verify expected results
        List<Contact> contacts = [SELECT Id, Name FROM Contact];
        System.assertEquals(2, contacts.size());
        List<Opportunity> opps = [SELECT Id, Name FROM Opportunity];
        System.assertEquals(2, opps.size());

        dataImports = getUpdatedDataImports();
        System.assertEquals(2, dataImports.size());
        for (DataImport__c dataImport : dataImports) {
            System.assertEquals(BDI_DataImport_API.bdiDryRunValidated, dataImport.Status__c);
            System.assertNotEquals(null, dataImport.Contact1Imported__c);
            System.assertNotEquals(null, dataImport.HouseholdAccountImported__c);
            System.assertEquals(Label.bdiDryRunMatched, dataImport.Contact1ImportStatus__c);

            System.assertNotEquals(null, dataImport.DonationImported__c);
            System.assertEquals(null, dataImport.Donation_Possible_Matches__c);
            System.assertEquals(Label.bdiDryRunMatchedId, dataImport.DonationImportStatus__c);

            System.assertNotEquals(null, dataImport.PaymentImported__c);
            System.assertEquals(null, dataImport.Payment_Possible_Matches__c);
            System.assertEquals(Label.bdiDryRunMatchedId, dataImport.PaymentImportStatus__c);
        }
    }

    /*********************************************************************************************************
    * @description operation:
    *    process existing contacts with existing best matched Donations through Dry Run mode
    * verify:
    *    no objects created
    *    Statuses updated appropriately
    **********************************************************************************************************/
    static testMethod void manyDIExistingC1ContactExistingBestMatchedDonations() {

        // existing contacts
        List<Contact> existingContacts = new List<Contact>();
        existingContacts.add(new Contact(Firstname='c1', Lastname='C1', Email='c1@C1.com'));
        existingContacts.add(new Contact(Firstname='c2', Lastname='C2', Email='c2@C2.com'));
        insert existingContacts;

        UTIL_UnitTestData_TEST.setFixedSearchResults(existingContacts);

        // existing opps
        List<Opportunity> existingOpportunities = UTIL_UnitTestData_TEST.OppsForContactList(existingContacts, null,
            UTIL_unitTestData_TEST.getOpenStage(), System.today().addDays(-1), 100, null, null);
        existingOpportunities.addAll(UTIL_UnitTestData_TEST.OppsForContactList(existingContacts, null,
            UTIL_unitTestData_TEST.getOpenStage(), System.today(), 100, null, null));
        insert existingOpportunities;


        List<DataImport__c> dataImports = new List<DataImport__c>();
        dataImports.add(BDI_DataImport_TEST.newDI('c1', 'C1', 100));
        //use old format for work email only
        dataImports.add(new DataImport__c(Contact1_Firstname__c='c2', Contact1_Lastname__c='C2', Contact1_Work_Email__c='c2@C2.com',
            Donation_Amount__c=100, Donation_Date__c=System.today()));
        insert dataImports;

        // set the specified settings
        Data_Import_Settings__c diSettings = UTIL_CustomSettingsFacade.getDataImportSettings();
        diSettings.Donation_Matching_Rule__c = UTIL_Namespace.StrTokenNSPrefix('Donation_Amount__c') + ';' +
            UTIL_Namespace.StrTokenNSPrefix('Donation_Date__c');
        diSettings.Donation_Matching_Behavior__c = BDI_DataImport_API.BestMatchOrCreate;
        diSettings.Donation_Date_Range__c = 5;

        //run batch data import
        Test.StartTest();
        BDI_DataImport_BATCH bdi = new BDI_DataImport_BATCH(null, true);
        ID ApexJobId = Database.executeBatch(bdi, 10);
        Test.stopTest();

        // verify expected results
        List<Contact> listCon = [SELECT Id, Name FROM Contact];
        System.assertEquals(2, listCon.size());
        List<Opportunity> listOpp = [SELECT Id, Name FROM Opportunity];
        System.assertEquals(4, listOpp.size());

        dataImports = getUpdatedDataImports();
        System.assertEquals(2, dataImports.size());
        for (DataImport__c dataImport : dataImports) {
            System.assertEquals(BDI_DataImport_API.bdiDryRunValidated, dataImport.Status__c);
            System.assertNotEquals(null, dataImport.Contact1Imported__c);
            System.assertNotEquals(null, dataImport.HouseholdAccountImported__c);
            System.assertEquals(Label.bdiDryRunMatched, dataImport.Contact1ImportStatus__c);

            System.assertNotEquals(null, dataImport.DonationImported__c);
            System.assertNotEquals(null, dataImport.Donation_Possible_Matches__c);
            System.assertEquals(Label.bdiDryRunMatchedBest, dataImport.DonationImportStatus__c);

            System.assertNotEquals(null, dataImport.PaymentImported__c);
            System.assertNotEquals(null, dataImport.Payment_Possible_Matches__c);
            System.assertEquals(Label.bdiDryRunMatchedBest, dataImport.PaymentImportStatus__c);
        }
    }

    /*********************************************************************************************************
    * @description operation:
    *    process existing contacts with new Donations with invalid recordtypes, through Dry Run mode
    * verify:
    *    no objects created
    *    Statuses updated appropriately
    **********************************************************************************************************/
    static testMethod void manyDIExistingC1ContactNewDonationsInvalidRecordtype() {

        // existing contacts
        List<Contact> existingContacts = new List<Contact>();
        existingContacts.add(new Contact(Firstname='c1', Lastname='C1', Email='c1@C1.com'));
        existingContacts.add(new Contact(Firstname='c2', Lastname='C2', Email='c2@C2.com'));
        insert existingContacts;

        UTIL_UnitTestData_TEST.setFixedSearchResults(existingContacts);

        List<DataImport__c> dataImports = new List<DataImport__c>();
        dataImports.add(BDI_DataImport_TEST.newDI('c1', 'C1', 100));
        dataImports[0].Donation_Record_Type_Name__c='bogus rt';
        dataImports.add(BDI_DataImport_TEST.newDI('c2', 'C2', 200));
        dataImports[1].Donation_Record_Type_Name__c='bogus rt';
        insert dataImports;

        // set the specified settings
        Data_Import_Settings__c diSettings = UTIL_CustomSettingsFacade.getDataImportSettings();
        diSettings.Donation_Matching_Rule__c = UTIL_Namespace.StrTokenNSPrefix('Donation_Amount__c') + ';' +
            UTIL_Namespace.StrTokenNSPrefix('Donation_Date__c');
        diSettings.Donation_Matching_Behavior__c = BDI_DataImport_API.BestMatchOrCreate;

        //run batch data import
        Test.StartTest();
        BDI_DataImport_BATCH bdi = new BDI_DataImport_BATCH(null, true);
        ID ApexJobId = Database.executeBatch(bdi, 10);
        Test.stopTest();

        // verify expected results
        List<Contact> contacts = [SELECT Id, Name FROM Contact];
        System.assertEquals(2, contacts.size());
        List<Opportunity> opps = [SELECT Id, Name FROM Opportunity];
        System.assertEquals(0, opps.size());

        dataImports = getUpdatedDataImports();
        System.assertEquals(2, dataImports.size());
        for (DataImport__c dataImport : dataImports) {
            System.assertEquals(BDI_DataImport_API.bdiDryRunError, dataImport.Status__c);
            System.assertNotEquals(null, dataImport.Contact1Imported__c);
            System.assertNotEquals(null, dataImport.HouseholdAccountImported__c);
            System.assertEquals(Label.bdiDryRunMatched, dataImport.Contact1ImportStatus__c);

            System.assertEquals(null, dataImport.DonationImported__c);
            System.assertEquals(null, dataImport.Donation_Possible_Matches__c);
            System.assertEquals(Label.bdiErrorInvalidOppRTName, dataImport.DonationImportStatus__c);

            System.assertEquals(null, dataImport.PaymentImported__c);
            System.assertEquals(null, dataImport.Payment_Possible_Matches__c);
            System.assertEquals(null, dataImport.PaymentImportStatus__c);
        }
    }

    /*********************************************************************************************************
    * @description operation:
    *    process new contacts through Dry Run mode using a Batch
    * verify:
    *    no objects created
    *    Statuses updated appropriately
    *    Batch statistics are not updated
    **********************************************************************************************************/
    static testMethod void manyDISameBatch() {

        DataImportBatch__c batch = BDI_DataImportAPI_TEST.newBatch('mybatch', false);
        List<DataImport__c> dataImports = new List<DataImport__c>();
        dataImports.add(BDI_DataImportAPI_TEST.newDI(batch.Id, 'c1', 'C1'));
        dataImports.add(BDI_DataImportAPI_TEST.newDI(batch.Id, 'c1', 'C1'));
        dataImports.add(BDI_DataImportAPI_TEST.newDI(batch.Id, 'c1', 'C1'));
        insert dataImports;

        //run batch data import
        Test.StartTest();
        BDI_DataImport_BATCH bdi = new BDI_DataImport_BATCH(batch.Id, true);
        ID ApexJobId = Database.executeBatch(bdi, 10);
        Test.stopTest();

        // verify expected results
        List<Contact> contacts = [SELECT Id, Name FROM Contact];
        System.assertEquals(0, contacts.size());

        dataImports = getUpdatedDataImports();
        System.assertEquals(3, dataImports.size());
        for (DataImport__c dataImport : dataImports) {
            System.assertEquals(BDI_DataImport_API.bdiDryRunValidated, dataImport.Status__c);
            System.assertEquals(null, dataImport.Contact1Imported__c);
            System.assertEquals(null, dataImport.HouseholdAccountImported__c);
            System.assertEquals(Label.bdiDryRunNoMatch, dataImport.Contact1ImportStatus__c);
        }

        batch = [SELECT Id, Records_Failed__c, Records_Successfully_Processed__c, Last_Processed_On__c FROM DataImportBatch__c];
        System.assertEquals(null, batch.Records_Failed__c);
        System.assertEquals(null, batch.Records_Successfully_Processed__c);
        System.assertEquals(null, batch.Last_Processed_On__c);
    }

    /*********************************************************************************************************
    * @description operation
    *        run dry run contacts with donation & campaign IDs and Names
    * verify:
    *    DonationCampaignImported__c is set on ID and name match
    *    Campaign Status is still matched instead of Matched by ID
    **********************************************************************************************************/
    static testMethod void TwoDIWithDonationsAndCampaignIdsInDryRun() {
        //skip the test if Advancement is installed
        if (ADV_PackageInfo_SVC.useAdv()) return;

        List<Campaign> campaigns = new List<Campaign>();
        campaigns.add(new Campaign(Name = 'CmpExisting'));
        campaigns.add(new Campaign(Name = 'AnotherCmpExisting'));
        insert campaigns;

        Id campaignId = campaigns[0].Id;

        List<DataImport__c> dataImports = new List<DataImport__c>();

        dataImports.add(BDI_DataImport_TEST.newDI('c1', 'C1', 100));
        dataImports[0].DonationCampaignImported__c = campaignId;

        dataImports.add(BDI_DataImport_TEST.newDI('c2', 'C2', 200));
        dataImports[1].DonationCampaignImported__c = null;
        dataImports[1].Donation_Campaign_Name__c = 'AnotherCmpExisting';

        insert dataImports;

        //run batch data import
        Test.StartTest();
        BDI_DataImport_BATCH bdi = new BDI_DataImport_BATCH(null, true);
        ID ApexJobId = Database.executeBatch(bdi, 10);
        Test.stopTest();

        //verify dry run statuses and import fields
        dataImports = getUpdatedDataImports();
        System.assertEquals(System.Label.bdiDryRunMatchedId, dataImports[0].DonationCampaignImportStatus__c, 'DonationCampaignImportStatus__c should have a match by ID');
        System.assertEquals(campaigns[0].Id, dataImports[0].DonationCampaignImported__c, 'DonationCampaignImported__c does not have the correct campaign ID');
        System.assertEquals(System.Label.bdiDryRunMatched, dataImports[1].DonationCampaignImportStatus__c, 'DonationCampaignImportStatus__c should have a match');
        System.assertEquals(campaigns[1].Id, dataImports[1].DonationCampaignImported__c, 'DonationCampaignImported__c does not have the correct campaign ID');
    }

    /*********************************************************************************************************
    * @description operation
    *        import contacts with donation & campaign names -- Only Dry Run
    * verify:
    *    no opportunity objects created during dry run
    *    no campaign objects created during dry run
    *    correct campaign status for dry run matching
    **********************************************************************************************************/
    static testMethod void TwoDIWithDonationsAndDuplicateCampaignNameInDryRun() {
        //skip the test if Advancement is installed
        if (ADV_PackageInfo_SVC.useAdv()) return;

        List<DataImport__c> dataImports = new List<DataImport__c>();
        String duplicateCampaignName = 'Matching Campaign Name';

        dataImports.add(BDI_DataImport_TEST.newDI('c1', 'C1', 100));
        dataImports[0].Donation_Campaign_Name__c = duplicateCampaignName;

        dataImports.add(BDI_DataImport_TEST.newDI('c2', 'C2', 200));
        dataImports[1].Donation_Campaign_Name__c = duplicateCampaignName;

        insert dataImports;

        //run batch data import
        Test.StartTest();
        BDI_DataImport_BATCH bdi = new BDI_DataImport_BATCH(null, true);
        ID ApexJobId = Database.executeBatch(bdi, 10);
        Test.stopTest();

        // verify expected results
        List<Opportunity> opps = [SELECT Id, Name FROM Opportunity];
        System.assertEquals(0, opps.size());

        List<Campaign> campaigns = [SELECT Id, Name FROM Campaign ORDER BY Id];
        System.assertEquals(0, campaigns.size());

        dataImports = getUpdatedDataImports();
        System.assertEquals(2, dataImports.size());

        System.assertEquals(null, dataImports[0].DonationCampaignImported__c, 'DonationCampaignImported__c should not be populated.');
        System.assertEquals(System.Label.bdiDryRunNoMatch, dataImports[0].DonationCampaignImportStatus__c, 'DonationCampaignImportStatus__c should show no match');
        System.assertEquals(null, dataImports[1].DonationCampaignImported__c, 'DonationCampaignImported__c should not be populated.');
        System.assertEquals(System.Label.bdiDryRunNoMatch, dataImports[1].DonationCampaignImportStatus__c, 'DonationCampaignImportStatus__c should show no match');
    }

    /*********************************************************************************************************
    * @description operation:
    *    Retrieves data import records in the order they were created during the test.
    * @return List<DataImport__c> All data import records in creation order
    **********************************************************************************************************/
    private static List<DataImport__c> getUpdatedDataImports() {
        return [
                SELECT Account1Imported__c, Account1ImportStatus__c, Account2Imported__c, Account2ImportStatus__c,
                        Contact1_Firstname__c, Contact1Imported__c, Contact1ImportStatus__c, Contact2Imported__c,
                        Contact2ImportStatus__c, DonationImported__c, DonationImportStatus__c, Donation_Possible_Matches__c,
                        DonationCampaignImported__c, DonationCampaignImportStatus__c, HomeAddressImported__c,
                        HomeAddressImportStatus__c, HouseholdAccountImported__c, PaymentImported__c, PaymentImportStatus__c,
                        Payment_Possible_Matches__c, Status__c
                FROM DataImport__c
                ORDER BY Id
        ];
    }

}