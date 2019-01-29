/*
    Copyright (c) 2019, Salesforce.org
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
* @group BGE
* @group-content ../../ApexDocContent/BatchDataImport.htm
* @description Unit Tests for the Data Import Batch Entry component.
*/

@isTest(IsParallel=true)
private class BGE_DataImportBatchEntry_CTRL_TEST {

    private class OpenDonations {
        private List<Opportunity> openOpportunities;
        private List<npe01__OppPayment__c> unpaidPayments;
    }

    /*********************************************************************************************************
    * @description Sets up a new NPSP_Data_Import_Batch__c Record
    * @return Id of the new NPSP_Data_Import_Batch__c
    */
    private static Id createDataImportBatch() {
        DataImportBatch__c dataImportBatch = new DataImportBatch__c();
        dataImportBatch.Name = 'Batch 1';

        insert dataImportBatch;
        return (Id)dataImportBatch.Id;
    }

    /*********************************************************************************************************
    * @description Sets up a list of DataImport__c Records
    * @param numOfImports number of imports to create
    * @param batchId ID of the related NPSP_Data_Import_Batch__c
    * @return list of new DataImport__c records
    */
    private static List<DataImport__c> createDataImports(Integer numOfImports, Id batchId) {
        List<DataImport__c> dataImports = new List<DataImport__c>();

        for (Integer i=0; i < numOfImports; i++) {
            DataImport__c dataImport = new DataImport__c();
            dataImport.Account1_Name__c = 'Test Record ' + i;
            dataImport.NPSP_Data_Import_Batch__c = batchId;
            dataImports.add(dataImport);
        }

        insert dataImports;
        return dataImports;
    }

    /*********************************************************************************************************
    * @description Tests that updateDataImports() updates records and returns updated totals
    */

    @isTest
    static void testUpdateDataImports() {
        Id batchId = createDataImportBatch();
        String newName = 'New Name';
        Integer totalRecords = 2;
        Decimal totalAmount = 5.0;
        List<DataImport__c> dataImports = createDataImports(totalRecords, batchId);

        dataImports[0].Account1_Name__c = newName;
        dataImports[0].Donation_Amount__c = totalAmount;

        Test.startTest();
        String jsonModel = BGE_DataImportBatchEntry_CTRL.updateDataImports(dataImports, batchId);
        DataImport__c updatedDataImport = [SELECT Id, Account1_Name__c FROM DataImport__c WHERE Id =: dataImports[0].Id];
        Test.stopTest();

        BGE_DataImportBatchEntry_CTRL.DataImportModel model = (BGE_DataImportBatchEntry_CTRL.DataImportModel)JSON.deserialize(jsonModel,
                BGE_DataImportBatchEntry_CTRL.DataImportModel.class);
        System.assertEquals(newName, updatedDataImport.Account1_Name__c);
        System.assertEquals(model.totalCountOfRows, totalRecords);
        System.assertEquals(model.totalRowAmount, totalAmount);
    }

    /*********************************************************************************************************
    * @description Tests getDataImportModel() for a new record
    */

    @isTest
    static void testGetNewDataImport() {

        Boolean errorIsThrownForNullId = false;

        try {
            String jsonModel = BGE_DataImportBatchEntry_CTRL.getDataImportModel(null);
        } catch (AuraHandledException e) {
            errorIsThrownForNullId = true;
        }

        System.assert(true, errorIsThrownForNullId);
    }

    /*********************************************************************************************************
    * @description Tests getDataImportModel() for a new record
    */

    @isTest
    static void testGetExistingDataImport() {

        Id batchId = createDataImportBatch();
        List<DataImport__c> dataImports = createDataImports(1, batchId);

        Test.startTest();
        String jsonModel = BGE_DataImportBatchEntry_CTRL.getDataImportModel(batchId);
        BGE_DataImportBatchEntry_CTRL.DataImportModel dataImportModel = (BGE_DataImportBatchEntry_CTRL.DataImportModel) JSON.deserialize(jsonModel, BGE_DataImportBatchEntry_CTRL.DataImportModel.class);
        Test.stopTest();

        System.assertNotEquals(null, jsonModel, 'JSON string of entire model should be returned.');
        System.assertNotEquals(null, dataImportModel.columns, 'Data Import Model Columns should not be null');
        System.assertNotEquals(null, dataImportModel.labels, 'Data Import Model Labels should not be null');
        System.assertNotEquals(null, dataImportModel.dataImportRows, 'Data Import Model Rows should not be null');
        System.assertNotEquals(null, dataImportModel.id, 'Data Import ID should not be null');
    }

    /*********************************************************************************************************
    * @description Tests deleteDataImportRow() by creating 2 related DataImport__c records and deleting 1
    */

    @isTest
    static void testDeleteDataImportRow() {

        Id batchId = createDataImportBatch();
        List<DataImport__c> dataImports = createDataImports(2, batchId);

        Test.startTest();
        String jsonModel = BGE_DataImportBatchEntry_CTRL.deleteDataImportRow(batchId, dataImports[0].id);
        List<DataImport__c> updatedDataImports = [SELECT Name, Id FROM DataImport__c WHERE NPSP_Data_Import_Batch__c = :batchId];
        Test.stopTest();

        System.assertEquals(2, dataImports.size(), 'Data Imports should return 2 rows');
        System.assertEquals(1, updatedDataImports.size(), 'Updated Data Imports should return only 1 row');
    }

    /*********************************************************************************************************
    * @description Tests getOpenDonations() for donor with no donation
    */

    @isTest
    static void testGetEmptyOpenDonations() {

        Account donorAccount = new Account(Name='Test Acc');
        insert donorAccount;

        Test.startTest();
        String jsonModel = BGE_DataImportBatchEntry_CTRL.getOpenDonations(donorAccount.Id, 'Account1');
        Test.stopTest();

        OpenDonations openDonations = (OpenDonations)JSON.deserialize(jsonModel, openDonations.class);

        System.assertNotEquals(jsonModel, null);
        System.assertEquals(0, openDonations.openOpportunities.size(), 'Donor should have no open opportunities.');
        System.assertEquals(0, openDonations.unpaidPayments.size(), 'Donor should have no unpaid payments.');
    }

    /*********************************************************************************************************
    * @description Tests getOpenDonations() for donor with only unpaid payments and no opps without unpaid payments
    */

    @isTest
    static void testGetOpenDonationsWithNoOpps() {

        List<Contact> donorContacts = UTIL_UnitTestData_TEST.CreateMultipleTestContacts(1);
        insert donorContacts;

        Opportunity opp = new Opportunity(name='MyOpenOpp',
                Primary_Contact__c=donorContacts[0].Id,
                Amount=100,
                CloseDate=System.today(),
                StageName=UTIL_UnitTestData_TEST.getOpenStage(),
                npe01__Do_Not_Automatically_Create_Payment__c=false
        );
        insert opp;

        Test.startTest();
        String jsonModel = BGE_DataImportBatchEntry_CTRL.getOpenDonations(donorContacts[0].Id, 'Contact1');
        Test.stopTest();

        npe01__OppPayment__c pmt = [
                SELECT Id, npe01__Opportunity__c, npe01__Paid__c
                FROM npe01__OppPayment__c
                WHERE npe01__Opportunity__c = :opp.Id
        ];
        OpenDonations openDonations = (OpenDonations)JSON.deserialize(jsonModel, openDonations.class);

        System.assertEquals(false, pmt.npe01__Paid__c);
        System.assertEquals(0, openDonations.openOpportunities.size(), 'Donor should have no open opportunities without payments.');
        System.assertNotEquals(0, openDonations.unpaidPayments.size(), 'Donor should have unpaid payments.');
    }

    /*********************************************************************************************************
    * @description Tests getOpenDonations() for donor with only open opportunities and no unpaid payments
    */

    @isTest
    static void testGetOpenDonationsWithNoPayments() {

        List<Contact> donorContacts = UTIL_UnitTestData_TEST.CreateMultipleTestContacts(1);
        insert donorContacts;

        Opportunity opp = new Opportunity(name='MyOpenOpp',
                Primary_Contact__c=donorContacts[0].Id,
                Amount=100,
                CloseDate=System.today(),
                StageName=UTIL_UnitTestData_TEST.getOpenStage(),
                npe01__Do_Not_Automatically_Create_Payment__c=true
        );
        insert opp;

        Test.startTest();
        String jsonModel = BGE_DataImportBatchEntry_CTRL.getOpenDonations(donorContacts[0].Id, 'Contact1');
        Test.stopTest();

        OpenDonations openDonations = (OpenDonations)JSON.deserialize(jsonModel, openDonations.class);

        System.assertNotEquals(0, openDonations.openOpportunities.size(), 'Donor should have open opportunities.');
        System.assertEquals(0, openDonations.unpaidPayments.size(), 'Donor should have no unpaid payments.');
        System.assertEquals(opp.Id, openDonations.openOpportunities[0].Id, 'Open opportunity ' + opp.Name + ' not retrieved');
    }

    /*********************************************************************************************************
    * @description Tests getOpenDonations() for donor with open opportunities and unpaid payments
    */
    @isTest
    static void testGetOpenDonationsWithOppsAndPayments() {

        List<Contact> donorContacts = UTIL_UnitTestData_TEST.CreateMultipleTestContacts(1);
        insert donorContacts;

        List<Opportunity> opps = new List<Opportunity>{
                new Opportunity(
                        name='MyOpenOpp1',
                        Primary_Contact__c=donorContacts[0].Id,
                        Amount=100,
                        CloseDate=System.today(),
                        StageName=UTIL_UnitTestData_TEST.getOpenStage(),
                        npe01__Do_Not_Automatically_Create_Payment__c=false
                ),
                new Opportunity(
                        name='MyOpenOpp2',
                        Primary_Contact__c=donorContacts[0].Id,
                        Amount=100,
                        CloseDate=System.today(),
                        StageName=UTIL_UnitTestData_TEST.getOpenStage(),
                        npe01__Do_Not_Automatically_Create_Payment__c=true
                )
        };

        insert opps;

        Test.startTest();
        String jsonModel = BGE_DataImportBatchEntry_CTRL.getOpenDonations(donorContacts[0].Id, 'Contact1');
        Test.stopTest();

        npe01__OppPayment__c pmt = [
                SELECT Id, npe01__Opportunity__c, npe01__Paid__c
                FROM npe01__OppPayment__c
                WHERE npe01__Opportunity__c = :opps[0].Id
        ];

        OpenDonations openDonations = (OpenDonations)JSON.deserialize(jsonModel, openDonations.class);

        System.assertEquals(false, pmt.npe01__Paid__c);
        System.assertEquals(1, openDonations.openOpportunities.size(), 'Donor should have only 1 open opportunity.');
        System.assertNotEquals(0, openDonations.unpaidPayments.size(), 'Donor should have unpaid payments.');
        System.assertEquals(opps[1].Id, openDonations.openOpportunities[0].Id, 'Open opportunity ' + opps[1].Name + ' not retrieved');
    }

    /*********************************************************************************************************
    * @description Tests getOpenDonations() for donor with only closed opportunities and paid payments
    */
    @isTest
    static void testGetOpenDonationsWithNoOppsOrPayments() {

        List<Contact> donorContacts = UTIL_UnitTestData_TEST.CreateMultipleTestContacts(1);
        insert donorContacts;

        Opportunity opp = new Opportunity(name='MyClosedOpp', Primary_Contact__c=donorContacts[0].Id, Amount=100, CloseDate=System.Today(),
                StageName=UTIL_unitTestData_TEST.getClosedWonStage(), npe01__Do_Not_Automatically_Create_Payment__c=false);
        insert opp;

        Test.startTest();
        String jsonModel = BGE_DataImportBatchEntry_CTRL.getOpenDonations(donorContacts[0].Id, 'Contact1');
        Test.stopTest();

        OpenDonations openDonations = (OpenDonations)JSON.deserialize(jsonModel, openDonations.class);
        npe01__OppPayment__c pmt = [
                SELECT Id, npe01__Opportunity__c, npe01__Paid__c
                FROM npe01__OppPayment__c
                WHERE npe01__Opportunity__c = :opp.Id
        ];

        System.assertEquals(true, pmt.npe01__Paid__c, 'Payment was not paid');
        System.assertEquals(0, openDonations.openOpportunities.size(), 'Donor should not have open opportunities.');
        System.assertEquals(0, openDonations.unpaidPayments.size(), 'Donor should not have unpaid payments.');
    }

}