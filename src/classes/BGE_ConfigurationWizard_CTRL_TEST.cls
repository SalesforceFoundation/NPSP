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
* @group-content
* @description Unit Tests for the Lightning Component Apex Controller for the BGE Wizard UI.
**/

@isTest(IsParallel=true)
private class BGE_ConfigurationWizard_CTRL_TEST {

    // TODO: It looks like all of tests need to be re-written against batch config fields

    /*********************************************************************************************************
    * @description Tests sets up a new Batch Record
    */
    private static DataImportBatch__c initBatchConfigTest() {
        DataImportBatch__c batchConfig = new DataImportBatch__c();
        batchConfig.Name = 'Test Template 1';
        batchConfig.Batch_Description__c = 'Test Record';
        batchConfig.RequireTotalMatch__c = true;

        insert batchConfig;

        return batchConfig;
    }

    /*********************************************************************************************************
    * @description Tests getRecordDetails() for a new record
    */

    @isTest
    private static void testGetNewTemplateDetails() {

        Test.startTest();
        String jsonModel = BGE_ConfigurationWizard_CTRL.getRecordDetails(null);
        BGE_ConfigurationWizard_CTRL.BGEDetailsModel templateDetails = (BGE_ConfigurationWizard_CTRL.BGEDetailsModel) JSON.deserialize(jsonModel, BGE_ConfigurationWizard_CTRL.BGEDetailsModel.class);
        Test.stopTest();

        System.assertNotEquals(null, jsonModel, 'JSON string of entire model should be returned.');
        //for null, only these fields are populated
        System.assertNotEquals(null, templateDetails.templateFields, 'Available fields should not be null');
        System.assertNotEquals(null, templateDetails.labels, 'Batch config labels should not be null');

        System.assertEquals(null, templateDetails.name, 'Batch name should be null');
        System.assertEquals(null, templateDetails.description, 'Batch description should be null');
        System.assertEquals(false, templateDetails.requireTotalMatch, 'Require total match should be false');
        System.assertEquals(BGE_ConfigurationWizard_CTRL.getDefaultActiveFields(), templateDetails.activeFields, 'Active Fields should match default');
        System.assertEquals(null, templateDetails.id, 'Batch ID should be null');
    }

    /*********************************************************************************************************
    * @description Tests getTemplateDetails() for an existing record
    */

    @isTest
    private static void testGetExistingTemplateDetails() {
        DataImportBatch__c batchConfig = initBatchConfigTest();

        Test.startTest();
        String jsonModel = BGE_ConfigurationWizard_CTRL.getRecordDetails(batchConfig.Id);
        BGE_ConfigurationWizard_CTRL.BGEDetailsModel templateDetails = (BGE_ConfigurationWizard_CTRL.BGEDetailsModel) JSON.deserialize(jsonModel, BGE_ConfigurationWizard_CTRL.BGEDetailsModel.class);
        Test.stopTest();

        System.assertNotEquals(null, jsonModel, 'JSON string of entire model should be returned.');
        System.assertNotEquals(null, templateDetails.templateFields, 'Fields should not be null');
        System.assertNotEquals(null, templateDetails.labels, 'Labels should not be null');

        System.assertEquals(batchConfig.Name, templateDetails.name, 'Details name should match');
        System.assertEquals(batchConfig.Batch_Description__c, templateDetails.description, 'Details description should match');
        System.assertEquals(batchConfig.RequireTotalMatch__c, templateDetails.requireTotalMatch, 'Require total match should match');
        System.assertEquals(BGE_ConfigurationWizard_CTRL.getDefaultActiveFields(), templateDetails.activeFields, 'Active Fields should match default');
        System.assertEquals(batchConfig.Id, templateDetails.id, 'Batch ID should match');
    }

    /*********************************************************************************************************
    * @description Tests saveTemplateDetails() for a new record
    */

    @isTest
    private static void testSaveNewTemplateDetails() {

        String templateInfoJSON = '{' +
                '"name":"Test 4",' +
                '"id":null,' +
                '"description":"Test Record",' +
                '"requireTotalMatch":false,' +
                '"batchProcessSize":5,' +
                '"runOpportunityRollupsWhileProcessing":false,' +
                '"contactMatchingRule":"Firstname,Lastname,Email",' +
                '"donationMatchingBehavior":"'+ BDI_DataImport_API.RequireBestMatch + '",' +
                '"donationMatchingRule":["' + UTIL_Namespace.StrAllNSPrefix('Donation_Amount__c').toLowerCase() + '"],' +
                '"donationDateRange":1,' +
                '"processUsingScheduledJob":false,' +
                '"availableFields":null,' +
                '"labels":null' +
                '}';
        String activeFieldsJSON = BGE_ConfigurationWizard_CTRL.getDefaultActiveFields();
        Test.startTest();
        String jsonModel = BGE_ConfigurationWizard_CTRL.saveRecord(templateInfoJSON, activeFieldsJSON);
        BGE_ConfigurationWizard_CTRL.BGEDetailsModel templateDetails = (BGE_ConfigurationWizard_CTRL.BGEDetailsModel) JSON.deserialize(jsonModel, BGE_ConfigurationWizard_CTRL.BGEDetailsModel.class);
        Test.stopTest();

        System.assertNotEquals(null, jsonModel, 'JSON string of entire model should be returned.');
        System.assertEquals('Test 4', templateDetails.name, 'Template details name should be Test 4');
        System.assertEquals('Test Record', templateDetails.description, 'Template details description should be Test Record');
        System.assertEquals(false, templateDetails.requireTotalMatch, 'Require total match should be false');
        System.assertEquals(BGE_ConfigurationWizard_CTRL.getDefaultActiveFields(), templateDetails.activeFields, 'Active Fields should match default');
        System.assertNotEquals(null, templateDetails.id, 'Template details should not be null');

    }

    /*********************************************************************************************************
    * @description Tests saveTemplateDetails() for an existing record
    */

    @isTest
    private static void testSaveExistingTemplateDetails() {

        DataImportBatch__c batchConfig = initBatchConfigTest();
        String newName = 'New Name';
        System.assertNotEquals(newName, batchConfig.Name);

        String sObjectName = 'DataImportBatch__c';
        String templateInfoJSON = '{' +
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
                '"processUsingScheduledJob":false,' +
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
        String jsonModel = BGE_ConfigurationWizard_CTRL.saveRecord(templateInfoJSON, activeFieldsJSON);
        BGE_ConfigurationWizard_CTRL.BGEDetailsModel templateDetails = (BGE_ConfigurationWizard_CTRL.BGEDetailsModel) JSON.deserialize(jsonModel, BGE_ConfigurationWizard_CTRL.BGEDetailsModel.class);
        Test.stopTest();

        System.assertNotEquals(null, jsonModel, 'JSON string of entire model should be returned.');
        System.assertEquals(newName, templateDetails.name, 'Batch name does not match.');
        System.assertEquals(batchConfig.Id, templateDetails.id, 'Wrong Batch record was updated.');
    }

}