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
* @description Unit Tests for the Lightning Component Apex Controller for the BGE Batch Template UI.
**/

@isTest(IsParallel=true)
public class BGE_Template_CTRL_TEST {

    /*********************************************************************************************************
    * @description Tests sets up a new Batch Template Record
    */
    private static Batch_Template__c initBatchTemplateTest() {
        Batch_Template__c batchTemplate = new Batch_Template__c();
        batchTemplate.Name = 'Test Template 1';
        batchTemplate.Description__c = 'Test Record';
        batchTemplate.Enable_Total_Entry__c = true;
        batchTemplate.Require_Total_Match__c = true;

        insert batchTemplate;

        return batchTemplate;
    }

    /*********************************************************************************************************
    * @description Tests getTemplateDetails() for a new record
    */

    public static testMethod void testGetNewTemplateDetails() {

        Test.startTest();
        String jsonModel = BGE_Template_CTRL.getTemplateDetails(null);
        BGE_Template_CTRL.TemplateDetailsModel templateDetails = (BGE_Template_CTRL.TemplateDetailsModel) JSON.deserialize(jsonModel, BGE_Template_CTRL.TemplateDetailsModel.class);
        Test.stopTest();

        System.assertNotEquals(null, jsonModel, 'JSON string of entire model should be returned.');
        //for null, only these fields are populated
        System.assertNotEquals(null, templateDetails.templateFields);
        System.assertNotEquals(null, templateDetails.labels);

        System.assertEquals(null, templateDetails.name);
        System.assertEquals(null, templateDetails.description);
        System.assertEquals(false, templateDetails.enableTotalEntry);
        System.assertEquals(false, templateDetails.requireTotalMatch);
        System.assertEquals(null, templateDetails.activeFields);
        System.assertEquals(null, templateDetails.id);
    }

    /*********************************************************************************************************
    * @description Tests getTemplateDetails() for an existing record
    */

    public static testMethod void testGetExistingTemplateDetails() {
        Batch_Template__c batchTemplate = initBatchTemplateTest();

        Test.startTest();
        String jsonModel = BGE_Template_CTRL.getTemplateDetails(batchTemplate.Id);
        BGE_Template_CTRL.TemplateDetailsModel templateDetails = (BGE_Template_CTRL.TemplateDetailsModel) JSON.deserialize(jsonModel, BGE_Template_CTRL.TemplateDetailsModel.class);
        Test.stopTest();

        System.assertNotEquals(null, jsonModel, 'JSON string of entire model should be returned.');
        System.assertNotEquals(null, templateDetails.templateFields);
        System.assertNotEquals(null, templateDetails.labels);

        System.assertEquals(batchTemplate.Name, templateDetails.name);
        System.assertEquals(batchTemplate.Description__c, templateDetails.description);
        System.assertEquals(batchTemplate.Enable_Total_Entry__c, templateDetails.enableTotalEntry);
        System.assertEquals(batchTemplate.Require_Total_Match__c, templateDetails.requireTotalMatch);
        System.assertEquals(null, templateDetails.activeFields);
        System.assertEquals(batchTemplate.Id, templateDetails.id);
    }

    /*********************************************************************************************************
    * @description Tests saveTemplateDetails() for a new record
    */

    public static testMethod void testSaveNewTemplateDetails() {

        String templateInfoJSON = '{"name":"Test 4","id":null,"description":"Test Record","enableTotalEntry":true,"requireTotalMatch":false}';
        String activeFieldsJSON = '[{"label":"Name","name":"npsp__Account1_Name__c","sObjectName":"Account1","defaultValue":null,"required":false,"hide":false,"sortOrder":0}]';

        Test.startTest();
        String jsonModel = BGE_Template_CTRL.saveTemplate(templateInfoJSON, activeFieldsJSON);
        BGE_Template_CTRL.TemplateDetailsModel templateDetails = (BGE_Template_CTRL.TemplateDetailsModel) JSON.deserialize(jsonModel, BGE_Template_CTRL.TemplateDetailsModel.class);
        Test.stopTest();

        System.assertNotEquals(null, jsonModel, 'JSON string of entire model should be returned.');
        System.assertEquals('Test 4', templateDetails.name);
        System.assertEquals('Test Record', templateDetails.description);
        System.assertEquals(true, templateDetails.enableTotalEntry);
        System.assertEquals(false, templateDetails.requireTotalMatch);
        System.assertEquals(null, templateDetails.activeFields);
        System.assertNotEquals(null, templateDetails.id);

    }

    /*********************************************************************************************************
    * @description Tests saveTemplateDetails() for an existing record
    */

    public static testMethod void testSaveExistingTemplateDetails() {

        Batch_Template__c batchTemplate = initBatchTemplateTest();
        String newName = 'New Name';
        System.assertNotEquals(newName, batchTemplate.Name);

        String templateInfoJSON = '{"name":"' + newName +'","id":"' + batchTemplate.id + '","description":"Test Record","enableTotalEntry":true,"requireTotalMatch":false}';
        String activeFieldsJSON = '[{"label":"Name","name":"npsp__Account1_Name__c","sObjectName":"Account1","defaultValue":null,"required":false,"hide":false,"sortOrder":0}]';

        Test.startTest();
        String jsonModel = BGE_Template_CTRL.saveTemplate(templateInfoJSON, activeFieldsJSON);
        BGE_Template_CTRL.TemplateDetailsModel templateDetails = (BGE_Template_CTRL.TemplateDetailsModel) JSON.deserialize(jsonModel, BGE_Template_CTRL.TemplateDetailsModel.class);
        Test.stopTest();

        System.assertNotEquals(null, jsonModel, 'JSON string of entire model should be returned.');
        System.assertEquals(newName, templateDetails.name);
        System.assertEquals(batchTemplate.Id, templateDetails.id);
    }

}