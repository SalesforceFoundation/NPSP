/*
    Copyright (c) 2017 Salesforce.org
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
* @date 2017
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

        list<DataImport__c> listDI = new list<DataImport__c>();
        listDI.add(new DataImport__c(Contact1_Firstname__c='c1', Contact1_Lastname__c='C1', Contact1_Personal_Email__c='c1@foo.com'));
        listDI.add(new DataImport__c(Contact1_Firstname__c='c1', Contact1_Lastname__c='C1', Contact1_Work_Email__c='c1@foo.com'));
        listDI.add(new DataImport__c(Contact1_Firstname__c='c1', Contact1_Lastname__c='C1', Contact1_Alternate_Email__c='c1@foo.com'));
        insert listDI;

        //run batch data import
        Test.StartTest();
        BDI_DataImport_BATCH bdi = new BDI_DataImport_BATCH(null, true);
        ID ApexJobId = Database.executeBatch(bdi, 10);
        Test.stopTest();

        // verify expected results
        list<Contact> listCon = [select Id, Name from Contact];
        system.assertEquals(0, listCon.size());

        listDI = [select Status__c, Contact1Imported__c, Contact1ImportStatus__c, HouseholdAccountImported__c,
            Contact2Imported__c, Contact2ImportStatus__c from DataImport__c order by Id];
        system.assertEquals(3, listDI.size());
        for (DataImport__c di : listDI) {
            system.assertEquals(label.bdiDryRunValidated, di.Status__c);
            system.assertEquals(null, di.Contact1Imported__c);
            system.assertEquals(null, di.HouseholdAccountImported__c);
            system.assertEquals(label.bdiDryRunNoMatch, di.Contact1ImportStatus__c);
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

        list<DataImport__c> listDI = new list<DataImport__c>();
        listDI.add(new DataImport__c(Contact1_Firstname__c='c1', Contact1_Lastname__c='C1', Contact2_Firstname__c='c1Spouse'));
        listDI.add(new DataImport__c(Contact1_Firstname__c='c2', Contact1_Lastname__c='C2', Contact2_Firstname__c='c2Spouse'));
        listDI.add(new DataImport__c(Contact1_Firstname__c='c3', Contact1_Lastname__c='C3', Contact2_Firstname__c='c3Spouse'));
        insert listDI;

        //run batch data import
        Test.StartTest();
        BDI_DataImport_BATCH bdi = new BDI_DataImport_BATCH(null, true);
        ID ApexJobId = Database.executeBatch(bdi, 10);
        Test.stopTest();

        // verify expected results
        list<Contact> listCon = [select Id, Name from Contact];
        system.assertEquals(0, listCon.size());

        listDI = [select Status__c, Contact1Imported__c, Contact1ImportStatus__c, HouseholdAccountImported__c,
            Contact2Imported__c, Contact2ImportStatus__c from DataImport__c order by Id];
        system.assertEquals(3, listDI.size());
        for (DataImport__c di : listDI) {
            system.assertEquals(label.bdiDryRunValidated, di.Status__c);
            system.assertEquals(null, di.Contact1Imported__c);
            system.assertEquals(null, di.HouseholdAccountImported__c);
            system.assertEquals(label.bdiDryRunNoMatch, di.Contact1ImportStatus__c);
            system.assertEquals(null, di.Contact2Imported__c);
            system.assertEquals(label.bdiDryRunNoMatch, di.Contact2ImportStatus__c);
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

        list<DataImport__c> listDI = new list<DataImport__c>();
        listDI.add(new DataImport__c(Contact1_Firstname__c='c1', Contact1_Lastname__c='C1', Contact1_Personal_Email__c='c1@foo.com', Contact2_Firstname__c='c1Spouse'));
        listDI.add(new DataImport__c(Contact1_Firstname__c='c1', Contact1_Lastname__c='C1', Contact1_Work_Email__c='c1@foo.com', Contact2_Firstname__c='c1Spouse'));
        listDI.add(new DataImport__c(Contact1_Firstname__c='c1', Contact1_Lastname__c='C1', Contact1_Alternate_Email__c='c1@foo.com', Contact2_Firstname__c='c1Spouse'));
        insert listDI;

        //run batch data import
        Test.StartTest();
        BDI_DataImport_BATCH bdi = new BDI_DataImport_BATCH(null, true);
        ID ApexJobId = Database.executeBatch(bdi, 10);
        Test.stopTest();

        // verify expected results
        list<Contact> listCon = [select Id, Name from Contact];
        system.assertEquals(0, listCon.size());

        listDI = [select Status__c, Contact1Imported__c, Contact1ImportStatus__c, HouseholdAccountImported__c,
            Contact2Imported__c, Contact2ImportStatus__c from DataImport__c order by Id];
        system.assertEquals(3, listDI.size());
        for (DataImport__c di : listDI) {
            system.assertEquals(label.bdiDryRunValidated, di.Status__c);
            system.assertEquals(null, di.Contact1Imported__c);
            system.assertEquals(null, di.HouseholdAccountImported__c);
            system.assertEquals(label.bdiDryRunNoMatch, di.Contact1ImportStatus__c);
            system.assertEquals(label.bdiDryRunNoMatch, di.Contact2ImportStatus__c);
            system.assertEquals(null, di.Contact2Imported__c);
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
        list<Contact> listConExisting = new list<Contact>();
        listConExisting.add(new Contact(Firstname='c1', Lastname='C1', Email='c1@foo.com'));
        listConExisting.add(new Contact(Firstname='c2', Lastname='C2', Email='c2@foo.com'));
        listConExisting.add(new Contact(Firstname='c3', Lastname='C3', Email='c3@foo.com'));
        listConExisting.add(new Contact(Firstname='c4', Lastname='C4', Email='c4@foo.com'));
        insert listConExisting;

        list<DataImport__c> listDI = new list<DataImport__c>();
        listDI.add(new DataImport__c(
            Contact1_Firstname__c='c1', Contact1_Lastname__c='C1', Contact1_Personal_Email__c='c1@foo.com',
            Contact2_Firstname__c='c2', Contact2_Lastname__c='C2', Contact2_Personal_Email__c='c2@foo.com'));
        listDI.add(new DataImport__c(
            Contact1_Firstname__c='c3', Contact1_Lastname__c='C3', Contact1_Personal_Email__c='c3@foo.com',
            Contact2_Firstname__c='c4', Contact2_Lastname__c='C4', Contact2_Personal_Email__c='c4@foo.com'));
        insert listDI;

        //run batch data import
        Test.StartTest();
        BDI_DataImport_BATCH bdi = new BDI_DataImport_BATCH(null, true);
        ID ApexJobId = Database.executeBatch(bdi, 10);
        Test.stopTest();

        // verify expected results
        list<Contact> listCon = [select Id, Name from Contact];
        system.assertEquals(4, listCon.size());

        listDI = [select Status__c, Contact1Imported__c, Contact1ImportStatus__c, HouseholdAccountImported__c,
            Contact2Imported__c, Contact2ImportStatus__c from DataImport__c order by Id];
        system.assertEquals(2, listDI.size());
        for (DataImport__c di : listDI) {
            system.assertEquals(label.bdiDryRunValidated, di.Status__c);
            system.assertNotEquals(null, di.Contact1Imported__c);
            system.assertNotEquals(null, di.HouseholdAccountImported__c);
            system.assertEquals(label.bdiDryRunMatched, di.Contact1ImportStatus__c);
            system.assertNotEquals(null, di.Contact2Imported__c);
            system.assertEquals(label.bdiDryRunMatched, di.Contact2ImportStatus__c);
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

        list<DataImport__c> listDI = new list<DataImport__c>();
        listDI.add(new DataImport__c(Account1_Name__c='A1', Account2_Name__c='A2'));
        listDI.add(new DataImport__c(Account1_Name__c='A1', Account2_Name__c='A2'));
        listDI.add(new DataImport__c(Account1_Name__c='A1', Account2_Name__c='A2'));
        insert listDI;

        //run batch data import
        Test.StartTest();
        BDI_DataImport_BATCH bdi = new BDI_DataImport_BATCH(null, true);
        ID ApexJobId = Database.executeBatch(bdi, 10);
        Test.stopTest();

        // verify expected results
        list<Account> listAcc = [select Id, Name from Account];
        system.assertEquals(0, listAcc.size());

        listDI = [select Status__c, Account1Imported__c, Account1ImportStatus__c,
            Account2Imported__c, Account2ImportStatus__c from DataImport__c order by Id];
        system.assertEquals(3, listDI.size());
        for (DataImport__c di : listDI) {
            system.assertEquals(label.bdiDryRunValidated, di.Status__c);
            system.assertEquals(null, di.Account1Imported__c);
            system.assertEquals(null, di.Account2Imported__c);
            system.assertEquals(label.bdiDryRunNoMatch, di.Account1ImportStatus__c);
            system.assertEquals(label.bdiDryRunNoMatch, di.Account2ImportStatus__c);
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
        list<Account> listAccExisting = new list<Account>();
        listAccExisting.add(new Account(Name='A1'));
        listAccExisting.add(new Account(Name='A2'));
        listAccExisting.add(new Account(Name='A3'));
        listAccExisting.add(new Account(Name='A4'));
        insert listAccExisting;

        list<DataImport__c> listDI = new list<DataImport__c>();
        listDI.add(new DataImport__c(Account1_Name__c='A1', Account2_Name__c='A2'));
        listDI.add(new DataImport__c(Account1_Name__c='A3', Account2_Name__c='A4'));
        insert listDI;

        //run batch data import
        Test.StartTest();
        BDI_DataImport_BATCH bdi = new BDI_DataImport_BATCH(null, true);
        ID ApexJobId = Database.executeBatch(bdi, 10);
        Test.stopTest();

        // verify expected results
        list<Account> listAcc = [select Id, Name from Account];
        system.assertEquals(4, listAcc.size());

        listDI = [select Status__c, Account1Imported__c, Account1ImportStatus__c,
            Account2Imported__c, Account2ImportStatus__c from DataImport__c order by Id];
        system.assertEquals(2, listDI.size());
        for (DataImport__c di : listDI) {
            system.assertEquals(label.bdiDryRunValidated, di.Status__c);
            system.assertNotEquals(null, di.Account1Imported__c);
            system.assertNotEquals(null, di.Account2Imported__c);
            system.assertEquals(label.bdiDryRunMatched, di.Account1ImportStatus__c);
            system.assertEquals(label.bdiDryRunMatched, di.Account2ImportStatus__c);
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

        // existing contacts
        list<Contact> listConExisting = new list<Contact>();
        listConExisting.add(new Contact(Firstname='c1', Lastname='C1', Email='c1@foo.com', MailingCity='Seattle', MailingState='Washington'));
        listConExisting.add(new Contact(Firstname='c3', Lastname='C3', Email='c3@foo.com', MailingCity='Seattle', MailingState='Washington'));
        insert listConExisting;

        list<DataImport__c> listDI = new list<DataImport__c>();
        listDI.add(new DataImport__c(
            Contact1_Firstname__c='c1', Contact1_Lastname__c='C1', Contact1_Personal_Email__c='c1@foo.com',
            Contact2_Firstname__c='c2', Contact2_Lastname__c='C2', Contact2_Personal_Email__c='c2@foo.com',
            Home_City__c='Seattle', Home_State_Province__c='Washington'));
        listDI.add(new DataImport__c(
            Contact1_Firstname__c='c3', Contact1_Lastname__c='C3', Contact1_Personal_Email__c='c3@foo.com',
            Contact2_Firstname__c='c4', Contact2_Lastname__c='C4', Contact2_Personal_Email__c='c4@foo.com',
            Home_City__c='Seattle', Home_State_Province__c='Washington'));
        insert listDI;

        //run batch data import
        Test.StartTest();
        BDI_DataImport_BATCH bdi = new BDI_DataImport_BATCH(null, true);
        ID ApexJobId = Database.executeBatch(bdi, 10);
        Test.stopTest();

        // verify expected results
        list<Contact> listCon = [select Id, Name, AccountId, MailingCity from Contact order by Lastname];
        system.assertEquals(2, listCon.size());

        list<Address__c> listAddr = [select Id, Household_Account__c, MailingCity__c from Address__c order by MailingCity__c];
        system.assertEquals(2, listAddr.size());

        listDI = [select Status__c, HomeAddressImported__c, HomeAddressImportStatus__c, Home_City__c from DataImport__c order by Home_City__c];
        system.assertEquals(2, listDI.size());
        for (DataImport__c di : listDI) {
            system.assertEquals(label.bdiDryRunValidated, di.Status__c);
            system.assertNotEquals(null, di.HomeAddressImported__c);
            system.assertEquals(label.bdiDryRunMatched, di.HomeAddressImportStatus__c);
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

        // existing contacts
        list<Contact> listConExisting = new list<Contact>();
        listConExisting.add(new Contact(Firstname='c1', Lastname='C1', Email='c1@foo.com', MailingCity='Seattle', MailingState='Washington'));
        listConExisting.add(new Contact(Firstname='c3', Lastname='C3', Email='c3@foo.com', MailingCity='Seattle', MailingState='Washington'));
        insert listConExisting;

        list<DataImport__c> listDI = new list<DataImport__c>();
        listDI.add(new DataImport__c(
            Contact1_Firstname__c='c1', Contact1_Lastname__c='C1', Contact1_Personal_Email__c='c1@foo.com',
            Contact2_Firstname__c='c2', Contact2_Lastname__c='C2', Contact2_Personal_Email__c='c2@foo.com',
            Home_City__c='Portland', Home_State_Province__c='Oregon'));
        listDI.add(new DataImport__c(
            Contact1_Firstname__c='c3', Contact1_Lastname__c='C3', Contact1_Personal_Email__c='c3@foo.com',
            Contact2_Firstname__c='c4', Contact2_Lastname__c='C4', Contact2_Personal_Email__c='c4@foo.com',
            Home_City__c='Portland', Home_State_Province__c='Oregon'));
        listDI.add(new DataImport__c(
            Contact1_Firstname__c='c3', Contact1_Lastname__c='C3', Contact1_Personal_Email__c='c3@foo.com',
            Contact2_Firstname__c='c5', Contact2_Lastname__c='C5', Contact2_Personal_Email__c='c5@foo.com',
            Home_City__c='Portland', Home_State_Province__c='Oregon'));
        insert listDI;

        //run batch data import
        Test.StartTest();
        BDI_DataImport_BATCH bdi = new BDI_DataImport_BATCH(null, true);
        ID ApexJobId = Database.executeBatch(bdi, 10);
        Test.stopTest();

        // verify expected results
        list<Contact> listCon = [select Id, Name, AccountId, MailingCity from Contact order by Lastname];
        system.assertEquals(2, listCon.size());

        list<Address__c> listAddr = [select Id, Household_Account__c, MailingCity__c from Address__c order by MailingCity__c];
        system.assertEquals(2, listAddr.size());

        listDI = [select Status__c, HomeAddressImported__c, HomeAddressImportStatus__c, Home_City__c from DataImport__c order by Home_City__c];
        system.assertEquals(3, listDI.size());
        for (DataImport__c di : listDI) {
            system.assertEquals(label.bdiDryRunValidated, di.Status__c);
            system.assertEquals(null, di.HomeAddressImported__c);
            system.assertEquals(label.bdiDryRunNoMatch, di.HomeAddressImportStatus__c);

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

        list<DataImport__c> listDI = new list<DataImport__c>();
        listDI.add(new DataImport__c(Contact1_Firstname__c='fail'));
        listDI.add(new DataImport__c(Contact1_Firstname__c='fail'));
        listDI.add(new DataImport__c(Contact1_Firstname__c='c3', Contact1_Lastname__c='C3'));
        insert listDI;

        //run batch data import
        Test.StartTest();
        BDI_DataImport_BATCH bdi = new BDI_DataImport_BATCH(null, true);
        ID ApexJobId = Database.executeBatch(bdi, 10);
        Test.stopTest();

        // verify expected results
        list<Contact> listCon = [select Id, Name from Contact];
        system.assertEquals(0, listCon.size());

        listDI = [select Status__c, Contact1_Firstname__c, Contact1Imported__c, Contact1ImportStatus__c, HouseholdAccountImported__c,
            Contact2Imported__c, Contact2ImportStatus__c from DataImport__c order by Id];
        system.assertEquals(3, listDI.size());
        for (DataImport__c di : listDI) {
            if (di.Contact1_Firstname__c == 'fail') {
                system.assertEquals(label.bdiDryRunError, di.Status__c);
                system.assertEquals(null, di.Contact1Imported__c);
                system.assertEquals(null, di.HouseholdAccountImported__c);
                system.assertNotEquals(null, di.Contact1ImportStatus__c);
            } else {
                system.assertEquals(label.bdiDryRunValidated, di.Status__c);
                system.assertEquals(null, di.Contact1Imported__c);
                system.assertEquals(null, di.HouseholdAccountImported__c);
                system.assertEquals(label.bdiDryRunNoMatch, di.Contact1ImportStatus__c);
            }
        }
    }

}