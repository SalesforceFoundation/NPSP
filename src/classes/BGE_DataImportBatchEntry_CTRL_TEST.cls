/*
    Copyright (c) 2018, Salesforce.org
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
* @date 2018
* @group BGE
* @group-content //todo
* @description Unit Tests for the Data Import Batch Entry component.
*/

@isTest(IsParallel=true)
public with sharing class BGE_DataImportBatchEntry_CTRL_TEST {

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
    * @description Sets up a new DataImport__c Record
    * @param recordName desired test new
    * @param batchId ID of the related NPSP_Data_Import_Batch__c
    * @return new DataImport__c record
    */
    private static List<DataImport__c> createDataImports(Integer numOfImports, Id batchId) {
        List<DataImport__c> dataImports = new List<DataImport__c>();

        for (Integer i=0; i<numOfImports; i++) {
            DataImport__c dataImport = new DataImport__c();
            dataImport.Account1_Name__c = 'Test Record ' + i;
            dataImport.NPSP_Data_Import_Batch__c = batchId;
            dataImports.add(dataImport);
        }

        insert dataImports;
        return dataImports;
    }

    /*********************************************************************************************************
    * @description Tests getDataImportModel() for a new record
    */

    public static testMethod void testGetNewDataImport() {

        Test.startTest();
        String jsonModel = BGE_DataImportBatchEntry_CTRL.getDataImportModel(null);
        BGE_DataImportBatchEntry_CTRL.DataImportModel dataImportModel = (BGE_DataImportBatchEntry_CTRL.DataImportModel) JSON.deserialize(jsonModel, BGE_DataImportBatchEntry_CTRL.DataImportModel.class);
        Test.stopTest();

        System.assertNotEquals(null, jsonModel, 'JSON string of entire model should be returned.');
        //for null ID, only these fields are populated
        System.assertNotEquals(null, dataImportModel.columns);
        System.assertNotEquals(null, dataImportModel.labels);

        System.assertEquals(0, dataImportModel.dataImportRows.size());
        System.assertEquals(null, dataImportModel.id);
    }

    /*********************************************************************************************************
    * @description Tests getDataImportModel() for a new record
    */

    public static testMethod void testGetExistingDataImport() {

        Id batchId = createDataImportBatch();
        List<DataImport__c> dataImports = createDataImports(1, batchId);

        Test.startTest();
        String jsonModel = BGE_DataImportBatchEntry_CTRL.getDataImportModel(batchId);
        BGE_DataImportBatchEntry_CTRL.DataImportModel dataImportModel = (BGE_DataImportBatchEntry_CTRL.DataImportModel) JSON.deserialize(jsonModel, BGE_DataImportBatchEntry_CTRL.DataImportModel.class);
        Test.stopTest();

        System.assertNotEquals(null, jsonModel, 'JSON string of entire model should be returned.');
        System.assertNotEquals(null, dataImportModel.columns);
        System.assertNotEquals(null, dataImportModel.labels);
        System.assertNotEquals(null, dataImportModel.dataImportRows);
        System.assertNotEquals(null, dataImportModel.id);
    }

    /*********************************************************************************************************
    * @description Tests deleteDataImportRow() by creating 2 related DataImport__c records and deleting 1
    */

    public static testMethod void deleteDataImportRow() {

        Id batchId = createDataImportBatch();
        List<DataImport__c> dataImports = createDataImports(2, batchId);

        Test.startTest();
        String jsonModel = BGE_DataImportBatchEntry_CTRL.deleteDataImportRow(batchId, dataImports[0].id);
        List<DataImport__c> updatedDataImports = [SELECT Name, Id FROM DataImport__c WHERE NPSP_Data_Import_Batch__c = :batchId];
        Test.stopTest();

        System.assertEquals(dataImports.size(), 2);
        System.assertEquals(updatedDataImports.size(), 1);
    }

}