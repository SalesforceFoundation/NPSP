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

        list<DataImport__c> listDI = new list<DataImport__c>();
        listDI.add(BDI_DataImport_TEST.newDI('c1', 'C1', 'c2', 'C2'));
        listDI.add(BDI_DataImport_TEST.newDI('c3', 'C3', 'c4', 'C4'));
        listDI[0].Account1_Name__c = 'A1';
        listDI[0].Donation_Amount__c = 100;
        listDI[1].Donation_Amount__c = 200;
        insert listDI;

        Test.startTest();

        // create the page
        Test.setCurrentPage(Page.BDI_DataImport);

        // instantiate the controller
        BDI_DataImport_CTRL ctrl = new BDI_DataImport_CTRL();
        ctrl.preload();

        system.assertEquals(2, ctrl.crecToProcess);
        system.assertEquals(false, ctrl.isBatchJobCompleted);
        system.assertEquals(null, ctrl.crecProcessed);
        system.assertEquals(null, ctrl.crecImported);
        system.assertEquals(null, ctrl.crecFailed);

        ctrl.importData();
        Test.stopTest();

        system.assertEquals(true, ctrl.isBatchJobCompleted);
        system.assertEquals(100, ctrl.percentComplete);
        system.assertEquals(null, ctrl.strTimeSpent);
        system.assertNotEquals(null, ctrl.aaj);
        system.assertEquals(2, ctrl.crecProcessed);
        system.assertEquals(2, ctrl.crecImported);
        system.assertEquals(0, ctrl.crecFailed);
        system.assertEquals(0, ctrl.crecToProcess);
        system.assertNotEquals(null, ctrl.close());

        // verify expected results
        list<Contact> listCon = [select Id, Name from Contact order by Name];
        system.assertEquals(4, listCon.size());
        system.assertEquals('c1 C1', listCon[0].Name);

        list<Account> listAcc = [select Id, Name from Account order by Name];
        system.assertEquals(3, listAcc.size());

        list<Opportunity> listOpp = [select Id, Name, Amount, AccountId from Opportunity order by Name];
        system.assertEquals(2, listOpp.size());
        system.assertEquals(100, listOpp[0].Amount);

        listDI = [
            select Contact1Imported__c, Contact1ImportStatus__c, HouseholdAccountImported__c,
                Contact2Imported__c, Contact2ImportStatus__c
            from DataImport__c
        ];
        system.assertEquals(2, listDI.size());
        system.assertEquals(listDI[0].Contact1Imported__c, listCon[0].Id);
        system.assertEquals(listDI[0].Contact2Imported__c, listCon[1].Id);
        system.assertEquals(listDI[1].Contact1Imported__c, listCon[2].Id);
        system.assertEquals(listDI[1].Contact2Imported__c, listCon[3].Id);
        system.assertNotEquals(null, listDI[0].HouseholdAccountImported__c);
        system.assertNotEquals(null, listDI[1].HouseholdAccountImported__c);
        system.assertEquals(label.bdiCreated, listDI[0].Contact1ImportStatus__c);
        system.assertEquals(label.bdiCreated, listDI[0].Contact2ImportStatus__c);
        system.assertEquals(label.bdiCreated, listDI[1].Contact1ImportStatus__c);
        system.assertEquals(label.bdiCreated, listDI[1].Contact2ImportStatus__c);
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
        system.assertEquals(false, ctrl.batchRunning);

        ctrl.diSettings.Account_Custom_Unique_ID__c = 'another bad field';
        ctrl.importData();
        system.assertEquals(false, ctrl.batchRunning);

        ctrl.diSettings.Donation_Matching_Rule__c = BDI_DataImport_API.RequireExactMatch;
        ctrl.diSettings.Donation_Matching_Behavior__c = null;
        ctrl.importData();
        system.assertEquals(false, ctrl.batchRunning);

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
        system.assertNotEquals(null, ctrl.diBatch);
        system.assertEquals(diBatch.Id, ctrl.diBatch.Id);
        system.assertEquals(diBatch.Name, ctrl.diBatch.Name);
        Test.stopTest();
    }

}