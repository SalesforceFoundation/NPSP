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

@IsTest
private class NPSP_Batch_TEST {
    @isTest static void chargeCreditCardElevateBatchShouldReturnSuccessResponse() {
        PS_IntegrationService.setConfiguration(PS_IntegrationServiceConfig_TEST.testConfig);
        AuraHandledException auraException;
        List<DataImport__c> dataImports = new List<DataImport__c>{
                new DataImport__c(
                        Payment_Status__c = ElevateTransactionStatus.AUTHORIZED.name(),
                        Payment_Elevate_Batch_ID__c = 'test-valid-group-id')
        };
        insert dataImports;
        Test.startTest();
        try {
            NPSP_Batch batch = new NPSP_Batch(new Gifts(dataImports));
            String validResponse = '{"id": "test-valid-group-id","status": "Processing"}';
            UTIL_Http_TEST.mockChargeElevateBatch(validResponse);
            batch.processPayments();
        } catch (AuraHandledException ex) {
            auraException = ex;
        }
        Test.stopTest();
        List<DataImport__c> updatedDataImports = [
                SELECT Payment_Status__c FROM DataImport__c WHERE Id =: dataImports[0].Id
        ];
        System.assertEquals(ElevateTransactionStatus.PAYMENTPROCESSING.name(),updatedDataImports[0].Payment_Status__c);
    }
}