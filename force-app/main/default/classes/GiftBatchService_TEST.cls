/*
    Copyright (c) 2021 Salesforce.org
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
* @date 2021
* @description Integration tests for the GiftBatchService.
*/
@IsTest
private class GiftBatchService_TEST {

    @TestSetup
    static void testSetup() {
        DataImportBatch__c dataImportBatch = UTIL_UnitTestData_TEST.createGiftBatches(10,2,1)[0];
        Form_Template__c defaultTemplate = new Form_Template__c( Format_Version__c = '1.0' );

        GE_Template.Template template = UTIL_UnitTestData_TEST.createSampleTemplate();
        String templateJSON = JSON.serialize(template);
        defaultTemplate.Template_JSON__c = templateJSON;
        insert defaultTemplate;

        dataImportBatch.Form_Template__c = defaultTemplate.Id;
        insert dataImportBatch;

        List<DataImport__c> dataImports = new List<DataImport__c>();
        for (Integer i = 0; i < 10; i++) {
            DataImport__c dataImport = BDI_DataImport_TEST.newDI('John'+i,'Doe'+i, 200);
            dataImport.NPSP_Data_Import_Batch__c = dataImportBatch.Id;
            dataImports.add(dataImport);
        }
        insert dataImports;
    }

    @IsTest
    static void shouldBeAbleToEnqueueGiftBatch() {
        // Arrange
        Id dataImportBatchId = [SELECT Id FROM DataImportBatch__c][0].Id;
        GiftBatchId giftBatchId = new GiftBatchId(dataImportBatchId);
        GiftBatchService giftBatchService = new GiftBatchService();

        // Act
        Test.startTest();
        giftBatchService.processGiftsFor(giftBatchId);
        Test.stopTest();

        // Assert
        Integer jobsCount = [SELECT count() FROM AsyncApexJob];
        System.assertEquals(1, jobsCount, 'Should have enqueued a job');

        Integer opportunitiesCount = [SELECT count() FROM Opportunity];
        System.assertEquals(10, opportunitiesCount, 'Should have created 10 opportunities');
    }

    @IsTest
    private static void shouldReturnFalseWhenLatestApexJobFinishRunningOrNoLongerExist() {
        DataImportBatch__c dataImportBatch = [SELECT Id FROM DataImportBatch__c][0];
        dataImportBatch.Latest_Apex_Job_Id__c = UTIL_UnitTestData_TEST.mockId(AsyncApexJob.SObjectType);
        update dataImportBatch;

        GiftBatchService giftBatchService = new GiftBatchService();

        Test.startTest();
        Boolean hasActiveRunningJob = giftBatchService.hasActiveRunningJob(new GiftBatchId(dataImportBatch.Id));
        Test.stopTest();

        System.assertEquals(false, hasActiveRunningJob, 'Should not retrun true when the latest apex job is not in a running status');
    }
}
