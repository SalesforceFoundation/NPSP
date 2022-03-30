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
* @description tests specific to the Batch Data Importer user interface
*/

@isTest
private with sharing class BDI_DataImportCTRL_TEST {

    /*********************************************************************************************************
    * @description operation:
    *    run data import through the visualforce page
    * verify:
    *    all code tested in controller
    **********************************************************************************************************/
    static testMethod void TestBDIVisualforcePage() {

        createTestData();

        Test.startTest();

        // create the page
        Test.setCurrentPage(Page.BDI_DataImport);

        // instantiate the controller
        BDI_DataImport_CTRL ctrl = new BDI_DataImport_CTRL();
        ctrl.preload();
        System.assertEquals(false, ctrl.isBatchJobCompleted);
        System.assertEquals(2, ctrl.crecToProcess);
        System.assertEquals(null, ctrl.crecProcessed);
        System.assertEquals(null, ctrl.crecImported);
        System.assertEquals(null, ctrl.crecFailed);

        ctrl.importData();
        Test.stopTest();
        System.assertEquals(true, ctrl.isBatchJobCompleted);
        System.assertEquals(100, ctrl.percentComplete);
        System.assertEquals(null, ctrl.strTimeSpent);
        System.assertNotEquals(null, ctrl.aaj);
        System.assertEquals(2, ctrl.crecProcessed);
        System.assertEquals(2, ctrl.crecImported);
        System.assertEquals(0, ctrl.crecFailed);
        System.assertEquals(0, ctrl.crecToProcess);
        System.assertNotEquals(null, ctrl.close());

        // verify expected results
        Map<Id, Contact> contactById = new Map<Id, Contact>(getContacts());
        System.assertEquals(4, contactById.size());

        List<Account> listAcc = getAccounts();
        System.assertEquals(3, listAcc.size());

        List<Opportunity> listOpp = getOpps();
        System.assertEquals(2, listOpp.size());
        System.assertEquals(100, listOpp[0].Amount);

        List<DataImport__c> listDI = getDIs();
        System.assertEquals(2, listDI.size());
        for (DataImport__c di : listDI) {
            System.assert(contactById.containsKey(di.Contact1Imported__c));
            System.assertEquals(di.Contact1_Firstname__c + ' ' + di.Contact1_Lastname__c, contactById.get(di.Contact1Imported__c).Name);
            System.assert(contactById.containsKey(di.Contact2Imported__c));
            System.assertEquals(di.Contact2_Firstname__c + ' ' + di.Contact2_Lastname__c, contactById.get(di.Contact2Imported__c).Name);
            System.assertNotEquals(null, di.HouseholdAccountImported__c);
            System.assertEquals(label.bdiCreated, di.Contact1ImportStatus__c);
            System.assertEquals(label.bdiCreated, di.Contact2ImportStatus__c);
        }
    }

    /*********************************************************************************************************
    * @description operation:
    *    run data import through Dry Run mode from the visualforce page
    * verify:
    *    all code tested in controller
    **********************************************************************************************************/
    static testMethod void testBDIDryRun() {

        createTestData();

        Test.startTest();

        // create the page
        Test.setCurrentPage(Page.BDI_DataImport);

        // instantiate the controller
        BDI_DataImport_CTRL ctrl = new BDI_DataImport_CTRL();
        ctrl.preload();

        System.assertEquals(false, ctrl.isBatchJobCompleted);
        System.assertEquals(2, ctrl.crecToProcess);
        System.assertEquals(null, ctrl.crecProcessed);
        System.assertEquals(null, ctrl.crecImported);
        System.assertEquals(null, ctrl.crecFailed);

        ctrl.startDryRun();
        Test.stopTest();

        System.assertEquals(true, ctrl.isBatchJobCompleted);
        System.assertEquals(100, ctrl.percentComplete);
        System.assertEquals(null, ctrl.strTimeSpent);
        System.assertNotEquals(null, ctrl.aaj);
        System.assertEquals(2, ctrl.crecProcessed);
        System.assertEquals(2, ctrl.crecImported);
        System.assertEquals(0, ctrl.crecFailed);
        System.assertEquals(2, ctrl.crecToProcess);  // since the 2 records still aren't imported.
        System.assertNotEquals(null, ctrl.close());

        // verify expected results
        list<Contact> listCon = getContacts();
        System.assertEquals(0, listCon.size());

        list<Account> listAcc = getAccounts();
        System.assertEquals(0, listAcc.size());

        list<Opportunity> listOpp = getOpps();
        System.assertEquals(0, listOpp.size());

        List<DataImport__c> listDI = getDIs();
        System.assertEquals(2, listDI.size());
        System.assertEquals(null, listDI[0].Contact1Imported__c);
        System.assertEquals(null, listDI[0].Contact2Imported__c);
        System.assertEquals(null, listDI[1].Contact1Imported__c);
        System.assertEquals(null, listDI[1].Contact2Imported__c);
        System.assertEquals(null, listDI[0].HouseholdAccountImported__c);
        System.assertEquals(null, listDI[1].HouseholdAccountImported__c);
        System.assertEquals(label.bdiDryRunNoMatch, listDI[0].Contact1ImportStatus__c);
        System.assertEquals(label.bdiDryRunNoMatch, listDI[0].Contact2ImportStatus__c);
        System.assertEquals(label.bdiDryRunNoMatch, listDI[1].Contact1ImportStatus__c);
        System.assertEquals(label.bdiDryRunNoMatch, listDI[1].Contact2ImportStatus__c);
    }

    /*********************************************************************************************************
    * @description Tests that controller will properly run dry run for only the selected DI records
    */
    static testMethod void testSelectedDIDryRun() {

        // Set the contact matching rule so that matching during dry run should happen
        Data_Import_Settings__c dis = UTIL_CustomSettingsFacade.getDataImportSettings();
        dis.Contact_Matching_Rule__c = 'Firstname,Lastname,Email';
        UTIL_CustomSettingsFacade.setDataImportSettings(dis);

        // This contact will cause the Data Import record to match on it
        Contact testContA = new Contact(FirstName = 'Susie',
                                         LastName = 'TestGroupA01',
                                        npe01__HomeEmail__c = 'testgroupAcontact01Personal@fakedata.com',
                                        Email = 'testgroupAcontact01Personal@fakedata.com');
        insert testContA;

        // This DI will the be passed into the controller and processed
        DataImport__c testDataImportA = new DataImport__c(
                                        Contact1_Firstname__c = 'Susie',
                                        Contact1_Home_Phone__c = '555-321-0001',
                                        Contact1_Lastname__c = 'TestGroupA01',
                                        Contact1_Other_Phone__c = '555-456-0001',
                                        Contact1_Personal_Email__c = 'testgroupAcontact01Personal@fakedata.com',
                                        Contact1_Preferred_Email__c = 'testgroupAcontact01Preferred@fakedata.com',
                                        Contact1_Preferred_Phone__c = '555-567-0001',
                                        Donation_Donor__c = 'Contact1',
                                        Donation_Amount__c = 100,
                                        Donation_Date__c = System.Date.Today(),
                                        Home_City__c = 'Fakeville',
                                        Home_Country__c = 'United States',
                                        Home_State_Province__c = 'California',
                                        Home_Street__c = '100 Fake Blvd',
                                        Home_Zip_Postal_Code__c = '94105',
                                        Household_Phone__c = '555-789-0001',
                                        Payment_Check_Reference_Number__c = '453',
                                        Payment_Method__c = 'Check');

        // This Test DI will be inserted but should not be processed
        DataImport__c testDataImportB = new DataImport__c(
                                        Contact1_Firstname__c = 'Joe',
                                        Contact1_Home_Phone__c = '555-321-0001',
                                        Contact1_Lastname__c = 'TestGroupB01',
                                        Contact1_Other_Phone__c = '555-456-0001',
                                        Contact1_Personal_Email__c = 'testgroupBcontact01Personal@fakedata.com',
                                        Contact1_Preferred_Email__c = 'testgroupBcontact01Preferred@fakedata.com',
                                        Contact1_Preferred_Phone__c = '555-567-0001',
                                        Donation_Campaign_Name__c = 'Test Campaign 2',
                                        Donation_Amount__c = 150,
                                        Home_City__c = 'Fakeville',
                                        Home_Country__c = 'United States',
                                        Home_State_Province__c = 'California',
                                        Home_Street__c = '500 Fake Blvd',
                                        Home_Zip_Postal_Code__c = '94105',
                                        Household_Phone__c = '555-789-0001',
                                        Payment_Check_Reference_Number__c = '453',
                                        Payment_Method__c = 'Check');

        // This DI will the be passed into the controller and processed
        DataImport__c testDataImportC = new DataImport__c(
                                        Contact1_Firstname__c = 'Tom',
                                        Contact1_Home_Phone__c = '555-321-0003',
                                        Contact1_Lastname__c = 'TestGroupC01',
                                        Contact1_Other_Phone__c = '555-456-0003',
                                        Contact1_Personal_Email__c = 'testgroupCcontact01Personal@fakedata.com',
                                        Contact1_Preferred_Email__c = 'testgroupCcontact01Preferred@fakedata.com',
                                        Contact1_Preferred_Phone__c = '555-567-0003',
                                        Donation_Donor__c = 'Contact1',
                                        Donation_Amount__c = 100,
                                        Donation_Date__c = System.Date.Today(),
                                        Home_City__c = 'Fakeville',
                                        Home_Country__c = 'United States',
                                        Home_State_Province__c = 'California',
                                        Home_Street__c = '103 Fake Blvd',
                                        Home_Zip_Postal_Code__c = '94105',
                                        Household_Phone__c = '555-789-0001',
                                        Payment_Check_Reference_Number__c = '453',
                                        Payment_Method__c = 'Check');

        insert new DataImport__c[]{testDataImportA,testDataImportB, testDataImportC};

        PageReference pageRef = Page.BDI_DataImport;
        pageRef.getParameters().put('diIds', testDataImportA.Id + ',' + testDataImportC.Id);
        Test.setCurrentPage(pageRef);
        BDI_DataImport_CTRL ctrl = new BDI_DataImport_CTRL();

        Test.startTest();
        // Verify that the data import is loaded from parameters properly and doesn't contain
        // the excluded DI
        System.assertNotEquals(null, ctrl.dataImportIds);
        System.assertEquals(true, ctrl.dataImportIds.contains(testDataImportA.Id));
        System.assertEquals(false, ctrl.dataImportIds.contains(testDataImportB.Id));
        System.assertEquals(true, ctrl.dataImportIds.contains(testDataImportC.Id));

        // Run import data to validate that it is correctly created.
        ctrl.startDryRun();
        Test.stopTest();

        DataImport__c testDIResultA;
        DataImport__c testDIResultB;
        DataImport__c testDIResultC;


        for (DataImport__c di : [SELECT Id,
                                        Status__c,
                                        FailureInformation__c,
                                        Contact1_Lastname__c,
                                        Account1_Name__c,
                                        Account1ImportStatus__c,
                                        Account1Imported__c, 
                                        Account2ImportStatus__c,
                                        Account2Imported__c,
                                        Contact1ImportStatus__c,
                                        Contact1Imported__c,
                                        Contact2ImportStatus__c,
                                        Contact2Imported__c,
                                        DonationCampaignImportStatus__c,
                                        DonationCampaignImported__c,
                                        DonationImportStatus__c,
                                        DonationImported__c,
                                        Donation_Donor__c,
                                        HomeAddressImportStatus__c,
                                        HomeAddressImported__c,
                                        HouseholdAccountImported__c,
                                        PaymentImportStatus__c,
                                        PaymentImported__c
                                    FROM DataImport__c]) {
            if (di.Contact1_Lastname__c == 'TestGroupA01') {
                testDIResultA = di;
            } else if (di.Contact1_Lastname__c == 'TestGroupB01') {
                testDIResultB = di;
            } else if (di.Contact1_Lastname__c == 'TestGroupC01') {
                testDIResultC = di;
            }
        }

        // Data Import record A should have had dry run processing completed and the contact
        // should have matched
        System.assertEquals(null,testDIResultA.FailureInformation__c);
        System.assertEquals(BDI_DataImport_API.bdiDryRunValidated,testDIResultA.Status__c);
        System.assertNotEquals(null,testDIResultA.Contact1Imported__c);
        System.assertEquals(System.label.bdiDryRunMatched,testDIResultA.Contact1ImportStatus__c);
        System.assertEquals(null,testDIResultA.DonationImported__c);
        System.assertEquals(null,testDIResultA.DonationImportStatus__c);


        // Data Import record B should not have been processed since it wasn't passed into the controller
        System.assertEquals(null,testDIResultB.FailureInformation__c);
        System.assertEquals(null,testDIResultB.Status__c);
        System.assertEquals(null,testDIResultB.Contact1Imported__c);
        System.assertEquals(null,testDIResultB.DonationImported__c);
        System.assertEquals(null,testDIResultB.HouseholdAccountImported__c);
        System.assertEquals(null,testDIResultB.HomeAddressImported__c);
        System.assertEquals(null,testDIResultB.PaymentImported__c);


        // Data Import record C should have had dry run processing completed but should not have matched
        System.assertEquals(null,testDIResultC.FailureInformation__c);
        System.assertEquals(BDI_DataImport_API.bdiDryRunValidated,testDIResultC.Status__c);
        System.assertEquals(null,testDIResultC.Contact1Imported__c);
        System.assertEquals(System.label.bdiDryRunNoMatch,testDIResultC.Contact1ImportStatus__c);
        System.assertEquals(null,testDIResultC.DonationImported__c);
        System.assertEquals(null,testDIResultC.DonationImportStatus__c);
    }
    

    /*********************************************************************************************************
    * @description operation:
    *    test validation rules for settings on visualforce page
    * verify:
    *    all code tested in controller
    **********************************************************************************************************/
    static testMethod void TestBDIVisualforcePageValidation() {

        list<DataImport__c> listDI = new list<DataImport__c>();
        listDI.add(BDI_DataImport_TEST.newDI('c1', 'C1', 'c2', 'C2'));
        insert listDI;

        Test.startTest();

        // create the page
        Test.setCurrentPage(Page.BDI_DataImport);

        // instantiate the controller
        BDI_DataImport_CTRL ctrl = new BDI_DataImport_CTRL();
        ctrl.preload();

        ctrl.diSettings.Contact_Custom_Unique_ID__c = 'bad field';
        ctrl.importData();
        System.assertEquals(false, ctrl.batchRunning);

        ctrl.diSettings.Account_Custom_Unique_ID__c = 'another bad field';
        ctrl.importData();
        System.assertEquals(false, ctrl.batchRunning);

        ctrl.diSettings.Donation_Matching_Rule__c = BDI_DataImport_API.RequireExactMatch;
        ctrl.diSettings.Donation_Matching_Behavior__c = null;
        ctrl.importData();
        System.assertEquals(false, ctrl.batchRunning);

        Test.stopTest();
    }

    /*********************************************************************************************************
    * @description operation:
    *    test controller handles the batchId parameter (which is what the Start Import button on Batches
    *    will use.
    */
    static testMethod void testBatchStartImportButton() {

        DataImportBatch__c diBatch = BDI_BatchOverride_TEST.newDIBatch();
        insert diBatch;

        PageReference pageRef = Page.BDI_DataImport;
        pageRef.getParameters().put('batchId', diBatch.Id);
        Test.setCurrentPage(pageRef);
        BDI_DataImport_CTRL ctrl = new BDI_DataImport_CTRL();

        Test.startTest();
        System.assertNotEquals(null, ctrl.diBatch);
        System.assertEquals(diBatch.Id, ctrl.diBatch.Id);
        System.assertEquals(diBatch.Name, ctrl.diBatch.Name);
        Test.stopTest();
    }

    /*********************************************************************************************************
    * @description Tests that controller will properly load and process selected DI records.
    */    
    static testMethod void testSelectedDIButton() {

        // This DI will the be passed into the controller and processed
        DataImport__c testDataImportA = new DataImport__c(
                                        Contact1_Firstname__c = 'Susie',
                                        Contact1_Home_Phone__c = '555-321-0001',
                                        Contact1_Lastname__c = 'TestGroupA01',
                                        Contact1_Other_Phone__c = '555-456-0001',
                                        Contact1_Personal_Email__c = 'testgroupAcontact01Personal@fakedata.com',
                                        Contact1_Preferred_Email__c = 'testgroupAcontact01Preferred@fakedata.com',
                                        Contact1_Preferred_Phone__c = '555-567-0001',
                                        Donation_Donor__c = 'Contact1',
                                        Donation_Amount__c = 100,
                                        Donation_Date__c = System.Date.Today(),
                                        Home_City__c = 'Fakeville',
                                        Home_Country__c = 'United States',
                                        Home_State_Province__c = 'California',
                                        Home_Street__c = '100 Fake Blvd',
                                        Home_Zip_Postal_Code__c = '94105',
                                        Household_Phone__c = '555-789-0001',
                                        Payment_Check_Reference_Number__c = '453',
                                        Payment_Method__c = 'Check');

        // This Test DI will be inserted but should not be processed
        DataImport__c testDataImportB = new DataImport__c(
                                        Contact1_Firstname__c = 'Joe',
                                        Contact1_Home_Phone__c = '555-321-0001',
                                        Contact1_Lastname__c = 'TestGroupB01',
                                        Contact1_Other_Phone__c = '555-456-0001',
                                        Contact1_Personal_Email__c = 'testgroupBcontact01Personal@fakedata.com',
                                        Contact1_Preferred_Email__c = 'testgroupBcontact01Preferred@fakedata.com',
                                        Contact1_Preferred_Phone__c = '555-567-0001',
                                        Donation_Campaign_Name__c = 'Test Campaign 2',
                                        Donation_Donor__c = null, //leaving this null to test defaulting of contact1
                                        Donation_Amount__c = 150,
                                        Home_City__c = 'Fakeville',
                                        Home_Country__c = 'United States',
                                        Home_State_Province__c = 'California',
                                        Home_Street__c = '500 Fake Blvd',
                                        Home_Zip_Postal_Code__c = '94105',
                                        Household_Phone__c = '555-789-0001',
                                        Payment_Check_Reference_Number__c = '453',
                                        Payment_Method__c = 'Check');

        // This DI will the be passed into the controller and processed
        DataImport__c testDataImportC = new DataImport__c(
                                        Contact1_Firstname__c = 'Tom',
                                        Contact1_Home_Phone__c = '555-321-0003',
                                        Contact1_Lastname__c = 'TestGroupC01',
                                        Contact1_Other_Phone__c = '555-456-0003',
                                        Contact1_Personal_Email__c = 'testgroupCcontact01Personal@fakedata.com',
                                        Contact1_Preferred_Email__c = 'testgroupCcontact01Preferred@fakedata.com',
                                        Contact1_Preferred_Phone__c = '555-567-0003',
                                        Donation_Donor__c = 'Contact1',
                                        Donation_Amount__c = 100,
                                        Donation_Date__c = System.Date.Today(),
                                        Home_City__c = 'Fakeville',
                                        Home_Country__c = 'United States',
                                        Home_State_Province__c = 'California',
                                        Home_Street__c = '103 Fake Blvd',
                                        Home_Zip_Postal_Code__c = '94105',
                                        Household_Phone__c = '555-789-0001',
                                        Payment_Check_Reference_Number__c = '453',
                                        Payment_Method__c = 'Check');

        insert new DataImport__c[]{testDataImportA,testDataImportB, testDataImportC};

        PageReference pageRef = Page.BDI_DataImport;
        pageRef.getParameters().put('diIds', testDataImportA.Id + ',' + testDataImportC.Id);
        Test.setCurrentPage(pageRef);
        BDI_DataImport_CTRL ctrl = new BDI_DataImport_CTRL();

        Test.startTest();
        // Verify that the data import is loaded from parameters properly
        System.assertNotEquals(null, ctrl.dataImportIds);
        List<Id> diIds = new List<Id>(ctrl.dataImportIds);
        System.assertEquals(testDataImportA.Id, diIds[0]);

        // Run import data to validate that it is correctly created.
        ctrl.importData();
        Test.stopTest();

        DataImport__c testDIResultA;
        DataImport__c testDIResultB;
        DataImport__c testDIResultC;

        for (DataImport__c di : [SELECT Id,
                                        Status__c,
                                        FailureInformation__c,
                                        Contact1_Lastname__c,
                                        Account1_Name__c,
                                        Account1ImportStatus__c,
                                        Account1Imported__c, 
                                        Account2ImportStatus__c,
                                        Account2Imported__c,
                                        Contact1ImportStatus__c,
                                        Contact1Imported__c,
                                        Contact2ImportStatus__c,
                                        Contact2Imported__c,
                                        DonationCampaignImportStatus__c,
                                        DonationCampaignImported__c,
                                        DonationImportStatus__c,
                                        DonationImported__c,
                                        Donation_Donor__c,
                                        HomeAddressImportStatus__c,
                                        HomeAddressImported__c,
                                        HouseholdAccountImported__c,
                                        PaymentImportStatus__c,
                                        PaymentImported__c
                                    FROM DataImport__c]) {
            if (di.Contact1_Lastname__c == 'TestGroupA01') {
                testDIResultA = di;
            } else if (di.Contact1_Lastname__c == 'TestGroupB01') {
                testDIResultB = di;
            } else if (di.Contact1_Lastname__c == 'TestGroupC01') {
                testDIResultC = di;
            }
        }

        // Data Import record A should have been processed successfully
        System.assertEquals(null,testDIResultA.FailureInformation__c);
        System.assertEquals(BDI_DataImport_API.bdiImported,testDIResultA.Status__c);
        System.assertNotEquals(null,testDIResultA.Contact1Imported__c);
        System.assertEquals(System.label.bdiCreated,testDIResultA.Contact1ImportStatus__c);
        System.assertNotEquals(null,testDIResultA.DonationImported__c);
        System.assertEquals(System.label.bdiCreated,testDIResultA.DonationImportStatus__c);
        System.assertNotEquals(null,testDIResultA.HouseholdAccountImported__c);
        System.assertNotEquals(null,testDIResultA.HomeAddressImported__c);
        System.assertNotEquals(null,testDIResultA.PaymentImported__c);


        // Data Import record B should not have been processed since it wasn't passed into the controller
        System.assertEquals(null,testDIResultB.FailureInformation__c);
        System.assertEquals(null,testDIResultB.Status__c);
        System.assertEquals(null,testDIResultB.Contact1Imported__c);
        System.assertEquals(null,testDIResultB.DonationImported__c);
        System.assertEquals(null,testDIResultB.HouseholdAccountImported__c);
        System.assertEquals(null,testDIResultB.HomeAddressImported__c);
        System.assertEquals(null,testDIResultB.PaymentImported__c);

        // Data Import record C should have been processed successfully
        System.assertEquals(null,testDIResultC.FailureInformation__c);
        System.assertEquals(BDI_DataImport_API.bdiImported,testDIResultC.Status__c);
        System.assertNotEquals(null,testDIResultC.Contact1Imported__c);
        System.assertEquals(System.label.bdiCreated,testDIResultC.Contact1ImportStatus__c);
        System.assertNotEquals(null,testDIResultC.DonationImported__c);
        System.assertEquals(System.label.bdiCreated,testDIResultC.DonationImportStatus__c);
        System.assertNotEquals(null,testDIResultC.HouseholdAccountImported__c);
        System.assertNotEquals(null,testDIResultC.HomeAddressImported__c);
        System.assertNotEquals(null,testDIResultC.PaymentImported__c);
    }

    /*********************************************************************************************************
    * @description operation:
    *    Open the Data Import Run/Settings page, with GiftBatch__c = false
    * verify:
    *    The UserCanEditSettings flag is correct.
    **********************************************************************************************************/
    static testMethod void testUserCanEditSettings() {

        DataImportBatch__c diBatch = BDI_BatchOverride_TEST.newDIBatch();
        diBatch.GiftBatch__c = false;
        insert diBatch;

        // Create an admin User
        User adminUser = UTIL_UnitTestData_TEST.createUserWithoutInsert(UTIL_Profile.SYSTEM_ADMINISTRATOR);
        adminUser.IsActive = true;
        insert adminUser;

        Test.startTest();
        System.runAs(adminUser) {
            PageReference pageRef = Page.BDI_DataImport;
            pageRef.getParameters().put('batchId', diBatch.Id);
            Test.setCurrentPage(pageRef);
            BDI_DataImport_CTRL ctrl = new BDI_DataImport_CTRL();

            System.assertEquals(true, ctrl.UserCanEditSettings, 'User should be able to edit settings');
            System.assertEquals(false, ctrl.isGiftBatch, 'Record should not be flagged for Batch Gift Entry.');
        }
        Test.stopTest();
    }

    /*********************************************************************************************************
    * @description operation:
    *    Open the Data Import Run/Settings page, with GiftBatch__c = true
    * verify:
    *    The UserCanEditSettings flag is correct.
    **********************************************************************************************************/
    static testMethod void testUserCannotEditSettings() {

        DataImportBatch__c diBatch = BDI_BatchOverride_TEST.newDIBatch();
        diBatch.GiftBatch__c = true;
        insert diBatch;

        // Create an admin User
        User adminUser = UTIL_UnitTestData_TEST.createUserWithoutInsert(UTIL_Profile.SYSTEM_ADMINISTRATOR);
        adminUser.IsActive = true;
        insert adminUser;

        Test.startTest();
        System.runAs(adminUser) {
            PageReference pageRef = Page.BDI_DataImport;
            pageRef.getParameters().put('batchId', diBatch.Id);
            Test.setCurrentPage(pageRef);
            BDI_DataImport_CTRL ctrl = new BDI_DataImport_CTRL();

            System.assertEquals(false, ctrl.UserCanEditSettings, 'User should not be able to edit settings');
            System.assertEquals(true, ctrl.isGiftBatch, 'Record should be flagged for Batch Gift Entry.');
        }
        Test.stopTest();
    }

    /*********************************************************************************************************
    * @description operation:
    *    Creates data import records
    **********************************************************************************************************/
    private static void createTestData() {
        List<DataImport__c> listDI = new List<DataImport__c>();
        listDI.add(BDI_DataImport_TEST.newDI('c1', 'C1', 'c2', 'C2'));
        listDI.add(BDI_DataImport_TEST.newDI('c3', 'C3', 'c4', 'C4'));
        listDI[0].Account1_Name__c = 'A1';
        listDI[0].Donation_Amount__c = 100;
        listDI[1].Donation_Amount__c = 200;
        insert listDI;
    }

    /*********************************************************************************************************
    * @description operation:
    *    Retrieves data import records in the order they were created during the test. 
    * @return List<DataImport__c> All data import records in creation order
    **********************************************************************************************************/
    private static List<DataImport__c> getDIs() {
        return [
            SELECT Contact1Imported__c, Contact1ImportStatus__c, Contact1_Firstname__c, Contact1_Lastname__c,
                Contact2Imported__c, Contact2ImportStatus__c, Contact2_Firstname__c, Contact2_LastName__c,
                HouseholdAccountImported__c
            FROM DataImport__c
        ];
    }

    /*********************************************************************************************************
    * @description operation:
    *    Retrieves contact records in the order they were created during the test. 
    * @return List<Contact> All contacts records in creation order
    **********************************************************************************************************/
    private static List<Contact> getContacts() {
        return [SELECT Id, Name FROM Contact ORDER BY Id];
    }

    /*********************************************************************************************************
    * @description operation:
    *    Retrieves account records in the order they were created during the test. 
    * @return List<Account> All account records in creation order
    **********************************************************************************************************/
    private static List<Account> getAccounts() {
        return [SELECT Id, Name FROM Account ORDER BY Id];
    }

    /*********************************************************************************************************
    * @description operation:
    *    Retrieves opportunity records in the order they were created during the test. 
    * @return List<Opportunity> All opportunity records in creation order
    **********************************************************************************************************/
    private static List<Opportunity> getOpps() {
        return [SELECT Id, Name, Amount, AccountId FROM Opportunity ORDER BY Id];
    }

}