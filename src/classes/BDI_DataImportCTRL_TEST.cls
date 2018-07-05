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