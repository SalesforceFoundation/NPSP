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
* @group-content
* @description Unit Tests for the Lightning Component Apex Controller for the BGE Wizard UI.
**/

@isTest(IsParallel=true)
private class BGE_ConfigurationWizard_CTRL_TEST {

    /*********************************************************************************************************
    * @description Tests sets up a new Batch Record
    */
    private static DataImportBatch__c initBatchConfigTest() {
        DataImportBatch__c batchConfig = new DataImportBatch__c();
        batchConfig.Name = 'Test Batch 1';
        batchConfig.Batch_Description__c = 'Test Record';
        batchConfig.RequireTotalMatch__c = true;

        insert batchConfig;

        return batchConfig;
    }

    /*********************************************************************************************************
    * @description Tests getRecordDetails() for a new record
    */

    @isTest
    private static void testGetNewBatchDetails() {

        Test.startTest();
        String jsonModel = BGE_ConfigurationWizard_CTRL.getRecordDetails(null);
        BGE_ConfigurationWizard_CTRL.BGEDetailsModel batchDetails = (BGE_ConfigurationWizard_CTRL.BGEDetailsModel) JSON.deserialize(jsonModel, BGE_ConfigurationWizard_CTRL.BGEDetailsModel.class);
        Test.stopTest();

        System.assertNotEquals(null, jsonModel, 'JSON string of entire model should be returned.');
        //for null, only these fields are populated
        System.assertNotEquals(null, batchDetails.availableFields, 'Available fields should not be null');
        System.assertNotEquals(null, batchDetails.labels, 'Batch config labels should not be null');

        System.assertEquals(null, batchDetails.name, 'Batch name should be null');
        System.assertEquals(null, batchDetails.description, 'Batch description should be null');
        System.assertEquals(false, batchDetails.requireTotalMatch, 'Require total match should be false');
        System.assertEquals(BGE_ConfigurationWizard_CTRL.getDefaultActiveFields(), batchDetails.activeFields, 'Active Fields should match default');
        System.assertEquals(null, batchDetails.id, 'Batch ID should be null');
    }

    /*********************************************************************************************************
    * @description Tests getRecordDetails() for an existing record
    */

    @isTest
    private static void testGetExistingRecordDetails() {
        DataImportBatch__c batchConfig = initBatchConfigTest();

        Test.startTest();
        String jsonModel = BGE_ConfigurationWizard_CTRL.getRecordDetails(batchConfig.Id);
        BGE_ConfigurationWizard_CTRL.BGEDetailsModel batchDetails = (BGE_ConfigurationWizard_CTRL.BGEDetailsModel) JSON.deserialize(jsonModel, BGE_ConfigurationWizard_CTRL.BGEDetailsModel.class);
        Test.stopTest();

        System.assertNotEquals(null, jsonModel, 'JSON string of entire model should be returned.');
        System.assertNotEquals(null, batchDetails.availableFields, 'Fields should not be null');
        System.assertNotEquals(null, batchDetails.labels, 'Labels should not be null');

        System.assertEquals(batchConfig.Name, batchDetails.name, 'Details name should match');
        System.assertEquals(batchConfig.Batch_Description__c, batchDetails.description, 'Details description should match');
        System.assertEquals(batchConfig.RequireTotalMatch__c, batchDetails.requireTotalMatch, 'Require total match should match');
        System.assertEquals(BGE_ConfigurationWizard_CTRL.getDefaultActiveFields(), batchDetails.activeFields, 'Active Fields should match default');
        System.assertEquals(batchConfig.Id, batchDetails.id, 'Batch ID should match');
    }

    /*********************************************************************************************************
    * @description Tests saveBatchDetails() for a new record
    */

    @isTest
    private static void testSaveNewBatchWithDefaults() {

        BGE_ConfigurationWizard_CTRL.BGEDetailsModel defaultModel = BGE_ConfigurationWizard_CTRL.getDefaultBGEDetailsModel();
        defaultModel.name = 'testModel';
        String batchInfoJSON = JSON.serialize(defaultModel);
        String activeFieldsJSON = BGE_ConfigurationWizard_CTRL.getDefaultActiveFields();

        Test.startTest();
        String jsonModel = BGE_ConfigurationWizard_CTRL.saveRecord(batchInfoJSON, activeFieldsJSON);
        DataImportBatch__c batchRecord = [SELECT Id,
                                                Name,
                                                Batch_Description__c,
                                                RequireTotalMatch__c,
                                                Active_Fields__c,
                                                Expected_Total_Batch_Amount__c,
                                                Expected_Count_of_Gifts__c,
                                                Batch_Process_Size__c,
                                                Contact_Matching_Rule__c,
                                                Donation_Date_Range__c,
                                                Donation_Matching_Behavior__c,
                                                Donation_Matching_Implementing_Class__c,
                                                Post_Process_Implementing_Class__c,
                                                Run_Opportunity_Rollups_while_Processing__c,
                                                Donation_Matching_Rule__c,
                                                GiftBatch__c,
                                                Process_Using_Scheduled_Job__c
                                        FROM DataImportBatch__c
                                        LIMIT 1];
        BGE_ConfigurationWizard_CTRL.BGEDetailsModel batchDetails = (BGE_ConfigurationWizard_CTRL.BGEDetailsModel) JSON.deserialize(jsonModel, BGE_ConfigurationWizard_CTRL.BGEDetailsModel.class);
        Test.stopTest();

        System.assertNotEquals(null, batchDetails.id, 'Batch details id should not be null');
        System.assertNotEquals(null, jsonModel, 'JSON string of entire model should be returned.');
        System.assertEquals(activeFieldsJSON, batchRecord.Active_Fields__c, 'Active Fields should match default');
        System.assertEquals(defaultModel.name, batchRecord.Name, 'Batch record name should match default');
        System.assertEquals(defaultModel.description, batchRecord.Batch_Description__c, 'Batch Description should match default');
        System.assertEquals(defaultModel.requireTotalMatch, batchRecord.RequireTotalMatch__c, 'Require Total Match should match default');
        System.assertEquals(defaultModel.expectedCount, batchRecord.Expected_Count_of_Gifts__c, 'Expected Count of Gifts should match default');
        System.assertEquals(defaultModel.expectedTotal, batchRecord.Expected_Total_Batch_Amount__c, 'Expected Total Batch Amount should match default');
        System.assertEquals(defaultModel.batchProcessSize, batchRecord.Batch_Process_Size__c, 'Batch Process Size should match default');
        System.assertEquals(defaultModel.contactMatchingRule, batchRecord.Contact_Matching_Rule__c, 'Contact Matching Rule should match default');
        System.assertEquals(defaultModel.donationDateRange, batchRecord.Donation_Date_Range__c, 'Donation Date Range should match default');
        System.assertEquals(defaultModel.donationMatchingBehavior, batchRecord.Donation_Matching_Behavior__c, 'Donation Matching Behavior should match default');
        System.assertEquals(defaultModel.donationMatchingClass, batchRecord.Donation_Matching_Implementing_Class__c, 'Donation Matching Class should match default');
        System.assertEquals(defaultModel.postProcessClass, batchRecord.Post_Process_Implementing_Class__c, 'Post Processing Class should match default');
        System.assertEquals(defaultModel.runOpportunityRollupsWhileProcessing, batchRecord.Run_Opportunity_Rollups_while_Processing__c, 'Run Opportunity Rollups should match default');
        System.assertEquals(String.join(defaultModel.donationMatchingRule, ';'), batchRecord.Donation_Matching_Rule__c, 'Donation Matching Rule should match default');

        System.assertEquals(true, batchRecord.GiftBatch__c, 'Batch should be flagged as Gift Batch');
        System.assertEquals(false, batchRecord.Process_Using_Scheduled_Job__c, 'Process Using Scheduled Job flag should be false.');

    }

    /*********************************************************************************************************
    * @description Tests saveRecord() for an existing record
    */

    @isTest
    private static void testSaveExistingBatch() {

        DataImportBatch__c batchConfig = initBatchConfigTest();
        String newName = 'New Name';
        System.assertNotEquals(newName, batchConfig.Name);

        String batchInfoJSON = '{' +
            '"name":"' + newName + '",' +
            '"id":"' + batchConfig.Id + '",' +
            '"description":"Test Record",' +
            '"requireTotalMatch":false,' +
            '"batchProcessSize":5,' +
            '"runOpportunityRollupsWhileProcessing":false,' +
            '"contactMatchingRule":"Firstname,Lastname,Email",' +
            '"donationMatchingBehavior":"'+ BDI_DataImport_API.RequireBestMatch + '",' +
            '"donationMatchingRule":["' + UTIL_Namespace.StrAllNSPrefix('Donation_Amount__c').toLowerCase() + '"],' +
            '"donationDateRange":1,' +
            '"availableFields":null,' +
            '"activeFields":null,' +
            '"labels":null' +
        '}';
        String activeFieldsJSON = '[{' +
            '"label":"Name",'+
            '"name":"npsp__Account1_Name__c",'+
            '"sObjectName":"Account1",'+
            '"defaultValue":null,'+
            '"required":false,'+
            '"hide":false,'+
            '"sortOrder":0'+
        '}]';

        Test.startTest();
        System.debug(batchConfig);
        String jsonModel = BGE_ConfigurationWizard_CTRL.saveRecord(batchInfoJSON, activeFieldsJSON);
        BGE_ConfigurationWizard_CTRL.BGEDetailsModel batchDetails = (BGE_ConfigurationWizard_CTRL.BGEDetailsModel) JSON.deserialize(jsonModel, BGE_ConfigurationWizard_CTRL.BGEDetailsModel.class);
        Test.stopTest();

        System.assertNotEquals(null, jsonModel, 'JSON string of entire model should be returned.');
        System.assertEquals(newName, batchDetails.name, 'Batch name does not match.');
        System.assertEquals(batchConfig.Id, batchDetails.id, 'Wrong Batch record was updated.');
    }

}