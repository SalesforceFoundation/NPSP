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
* @description Unit Tests for the Batch Gift Entry Tab component.
*/

@isTest(IsParallel=true)
private class BGE_BatchGiftEntryTab_CTRL_TEST {

    /*********************************************************************************************************
    * @description Sets up new NPSP_Data_Import_Batch__c records
    * @return List of the new NPSP_Data_Import_Batch__c records
    */
    @testSetup
    private static void createDataImportBatches() {
        List<DataImportBatch__c> batches = new List<DataImportBatch__c>();
        for (Integer i=0; i<75; i++){
            DataImportBatch__c dataImportBatch = new DataImportBatch__c();
            dataImportBatch.Name = 'Batch ' + i;
            dataImportBatch.GiftBatch__c = true;
            batches.add(dataImportBatch);
        }

        insert batches;
    }

    /*********************************************************************************************************
    * @description Tests getTabModel() for a new record
    */
    @isTest
    static void testGetTabModel() {

        List<DataImportBatch__c> batches = [SELECT Id FROM DataImportBatch__c];
        Test.startTest();
        BGE_BatchGiftEntryTab_CTRL.TabModel model = (BGE_BatchGiftEntryTab_CTRL.TabModel) JSON.deserialize(BGE_BatchGiftEntryTab_CTRL.getTabModel(), BGE_BatchGiftEntryTab_CTRL.TabModel.class);
        Test.stopTest();
        System.assertEquals(75, model.totalNumberOfRows);
        System.assertEquals(50, model.batches.size());
        System.assertEquals(batches[0].Id, model.batches[0].Id);
        System.assert(model.columns.size()>0);
    }

}
