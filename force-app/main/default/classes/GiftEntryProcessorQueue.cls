/*
    Copyright (c) 2022 Salesforce.org
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
* @date 2022
* @description Processor Queue for all gifts entered and processed through the Gift Entry App.
*/

public with sharing class GiftEntryProcessorQueue implements Queueable, Database.AllowsCallouts{

    private GiftBatchId giftBatchId;
    private String jobId;
    @TestVisible private GiftBatchService giftBatchService = new GiftBatchService();

    public GiftEntryProcessorQueue (GiftBatchId giftBatchId){
        this.giftBatchId = giftBatchId;
    }

    public void execute(QueueableContext queueableContext) {
        if (Test.isRunningTest()){
            jobId = UTIL_UnitTestData_TEST.mockId(AsyncApexJob.getSObjectType());
        } else {
            System.attachFinalizer(new GiftEntryProcessorQueueFinalizer(this.giftBatchId));
            BDI_DataImport_BATCH batch = new BDI_DataImport_BATCH(giftBatchId.value(), false);
            jobId = Database.executeBatch(batch, Integer.valueOf(batch.diSettings.Batch_Size__c));
        }
        updateGiftBatchWith(new AsyncApexJobId(jobId));
    }

    private void updateGiftBatchWith(AsyncApexJobId asyncApexJobId) {
        giftBatchService.updateGiftBatchWith(giftBatchId, asyncApexJobId);
    }
}