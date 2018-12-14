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

//    /*********************************************************************************************************
//    * @description Tests sets up a new Batch Template Record
//    */
//    private static Batch_Template__c initBatchTemplateTest() {
//        Batch_Template__c batchTemplate = new Batch_Template__c();
//        batchTemplate.Name = 'Test Template 1';
//        batchTemplate.Description__c = 'Test Record';
//        batchTemplate.RequireTotalMatch__c = true;
//
//        insert batchTemplate;
//
//        return batchTemplate;
//    }
//
//    /*********************************************************************************************************
//    * @description Tests getRecordDetails() for a new record
//    */
//
//    @isTest
//    public static void testGetNewTemplateDetails() {
//
//        Test.startTest();
//        String jsonModel = BGE_ConfigurationWizard_CTRL.getRecordDetails('Batch_Template__c', null);
//        BGE_ConfigurationWizard_CTRL.BGEDetailsModel templateDetails = (BGE_ConfigurationWizard_CTRL.BGEDetailsModel) JSON.deserialize(jsonModel, BGE_ConfigurationWizard_CTRL.BGEDetailsModel.class);
//        Test.stopTest();
//
//        System.assertNotEquals(null, jsonModel, 'JSON string of entire model should be returned.');
//        //for null, only these fields are populated
//        System.assertNotEquals(null, templateDetails.templateFields, 'Batch Template fields should not be null');
//        System.assertNotEquals(null, templateDetails.labels, 'Batch template labels should not be null');
//
//        System.assertEquals(null, templateDetails.name, 'Batch Template name should be null');
//        System.assertEquals(null, templateDetails.description, 'Batch Template description should be null');
//        System.assertEquals(false, templateDetails.requireTotalMatch, 'Require total match should be false');
//        System.assertEquals(BGE_ConfigurationWizard_CTRL.getDefaultActiveFields(), templateDetails.activeFields, 'Active Fields should match default');
//        System.assertEquals(null, templateDetails.id, 'Batch Template ID should be null');
//    }
//
//    /*********************************************************************************************************
//    * @description Tests getTemplateDetails() for an existing record
//    */
//
//    @isTest
//    public static void testGetExistingTemplateDetails() {
//        Batch_Template__c batchTemplate = initBatchTemplateTest();
//
//        Test.startTest();
//        String jsonModel = BGE_ConfigurationWizard_CTRL.getRecordDetails('Batch_Template__c', batchTemplate.Id);
//        BGE_ConfigurationWizard_CTRL.BGEDetailsModel templateDetails = (BGE_ConfigurationWizard_CTRL.BGEDetailsModel) JSON.deserialize(jsonModel, BGE_ConfigurationWizard_CTRL.BGEDetailsModel.class);
//        Test.stopTest();
//
//        System.assertNotEquals(null, jsonModel, 'JSON string of entire model should be returned.');
//        System.assertNotEquals(null, templateDetails.templateFields, 'Template Fields should not be null');
//        System.assertNotEquals(null, templateDetails.labels, 'Template Labels should not be null');
//
//        System.assertEquals(batchTemplate.Name, templateDetails.name, 'Template details name should match');
//        System.assertEquals(batchTemplate.Description__c, templateDetails.description, 'Template details description should match');
//        System.assertEquals(batchTemplate.RequireTotalMatch__c, templateDetails.requireTotalMatch, 'Require total match should match');
//        System.assertEquals(BGE_ConfigurationWizard_CTRL.getDefaultActiveFields(), templateDetails.activeFields, 'Active Fields should match default');
//        System.assertEquals(batchTemplate.Id, templateDetails.id, 'Batch template ID should match');
//    }
//
//    /*********************************************************************************************************
//    * @description Tests saveTemplateDetails() for a new record
//    */
//
//    @isTest
//    public static void testSaveNewTemplateDetails() {
//
//        String sObjectName = 'Batch_Template__c';
//        String templateInfoJSON = '{' +
//                '"name":"Test 4",' +
//                '"id":null,' +
//                '"description":"Test Record",' +
//                '"requireTotalMatch":false,' +
//                '"batchProcessSize":5,' +
//                '"runOpportunityRollupsWhileProcessing":false,' +
//                '"contactMatchingRule":"Firstname,Lastname,Email",' +
//                '"donationMatchingBehavior":"'+ BDI_DataImport_API.RequireBestMatch + '",' +
//                '"donationMatchingRule":["' + UTIL_Namespace.StrAllNSPrefix('Donation_Amount__c').toLowerCase() + '"],' +
//                '"donationDateRange":1,' +
//                '"processUsingScheduledJob":false,' +
//                '"templateFields":null,' +
//                '"labels":null' +
//                '}';
//        String activeFieldsJSON = BGE_ConfigurationWizard_CTRL.getDefaultActiveFields();
//        Test.startTest();
//        String jsonModel = BGE_ConfigurationWizard_CTRL.saveRecord(sObjectName, templateInfoJSON, activeFieldsJSON);
//        BGE_ConfigurationWizard_CTRL.BGEDetailsModel templateDetails = (BGE_ConfigurationWizard_CTRL.BGEDetailsModel) JSON.deserialize(jsonModel, BGE_ConfigurationWizard_CTRL.BGEDetailsModel.class);
//        Test.stopTest();
//
//        System.assertNotEquals(null, jsonModel, 'JSON string of entire model should be returned.');
//        System.assertEquals('Test 4', templateDetails.name, 'Template details name should be Test 4');
//        System.assertEquals('Test Record', templateDetails.description, 'Template details description should be Test Record');
//        System.assertEquals(false, templateDetails.requireTotalMatch, 'Require total match should be false');
//        System.assertEquals(BGE_ConfigurationWizard_CTRL.getDefaultActiveFields(), templateDetails.activeFields, 'Active Fields should match default');
//        System.assertNotEquals(null, templateDetails.id, 'Template details should not be null');
//
//    }
//
//    /*********************************************************************************************************
//    * @description Tests saveTemplateDetails() for an existing record
//    */
//
//    @isTest
//    public static void testSaveExistingTemplateDetails() {
//
//        Batch_Template__c batchTemplate = initBatchTemplateTest();
//        String newName = 'New Name';
//        System.assertNotEquals(newName, batchTemplate.Name);
//
//        String sObjectName = 'Batch_Template__c';
//        String templateInfoJSON = '{' +
//                '"name":"' + newName + '",' +
//                '"id":"' + batchTemplate.Id + '",' +
//                '"description":"Test Record",' +
//                '"requireTotalMatch":false,' +
//                '"batchProcessSize":5,' +
//                '"runOpportunityRollupsWhileProcessing":false,' +
//                '"contactMatchingRule":"Firstname,Lastname,Email",' +
//                '"donationMatchingBehavior":"'+ BDI_DataImport_API.RequireBestMatch + '",' +
//                '"donationMatchingRule":["' + UTIL_Namespace.StrAllNSPrefix('Donation_Amount__c').toLowerCase() + '"],' +
//                '"donationDateRange":1,' +
//                '"processUsingScheduledJob":false,' +
//                '"templateFields":null,' +
//                '"activeFields":null,' +
//                '"labels":null' +
//                '}';
//        String activeFieldsJSON = '[{' +
//                '"label":"Name",'+
//                '"name":"npsp__Account1_Name__c",'+
//                '"sObjectName":"Account1",'+
//                '"defaultValue":null,'+
//                '"required":false,'+
//                '"hide":false,'+
//                '"sortOrder":0'+
//                '}]';
//
//        Test.startTest();
//        System.debug(batchTemplate);
//        String jsonModel = BGE_ConfigurationWizard_CTRL.saveRecord(sObjectName, templateInfoJSON, activeFieldsJSON);
//        BGE_ConfigurationWizard_CTRL.BGEDetailsModel templateDetails = (BGE_ConfigurationWizard_CTRL.BGEDetailsModel) JSON.deserialize(jsonModel, BGE_ConfigurationWizard_CTRL.BGEDetailsModel.class);
//        Test.stopTest();
//
//        System.assertNotEquals(null, jsonModel, 'JSON string of entire model should be returned.');
//        System.assertEquals(newName, templateDetails.name, 'Batch Template name does not match.');
//        System.assertEquals(batchTemplate.Id, templateDetails.id, 'Wrong Batch Template record was updated.');
//    }

}