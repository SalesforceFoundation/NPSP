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
* @description Service class for Gift Batches in NPSP.
*/
public with sharing class GiftBatchService {

    private GiftBatchServicePrivilegedHelper giftBatchServicePrivilegedHelper {
        get {
            if (giftBatchServicePrivilegedHelper == null) {
                giftBatchServicePrivilegedHelper = new GiftBatchServicePrivilegedHelper();
            }
            return giftBatchServicePrivilegedHelper;
        }
        set;
    }

    public static final List<String> PAYMENT_INTEGRATION_FIELDS = new List<String>{
        String.valueOf(DataImport__c.Donation_Amount__c), 
        String.valueOf(DataImport__c.Donation_Date__c), 
        String.valueOf(DataImport__c.Contact1Imported__c),
        String.valueOf(DataImport__c.Contact1_Firstname__c), 
        String.valueOf(DataImport__c.Contact1_Lastname__c), 
        String.valueOf(DataImport__c.Account1Imported__c),
        String.valueOf(DataImport__c.Account1_Name__c)
    };

    private static final Set<String> FINISH_JOB_STATUS_SET = New Set<String> {
        'Completed',
        'Failed',
        'Aborted'
    };

    // Used to determine whether or not the Gift Batch has recurring gifts and
    // the current user has the proper permissions to open the gift batch.
    public Boolean isGiftBatchAccessible(GiftBatchId giftBatchId) {
        return giftBatchServicePrivilegedHelper.isGiftBatchAccessible(giftBatchId);
    }

    public Map<String, Integer> getGiftBatchTotalsMapFor(Id batchId) {
        GiftBatches batches = new GiftBatches(new Set<Id> {batchId}, new GiftBatchSelector());
        GiftBatchGroupedTotals groupedTotals = batches.getGroupedTotals();
        return groupedTotals.totalsFor(batchId);
    }

    public void processGiftsFor(GiftBatchId giftBatchId) {
        GiftBatchForQueueable queueableGiftBatch = new GiftBatchForQueueable(giftBatchId, new GiftBatchSelector());
        queueableGiftBatch.chunkGiftsThatCanBeProcessed();
        GiftEntryProcessorQueue processorQueue = new GiftEntryProcessorQueue(queueableGiftBatch);

        Id jobId = System.enqueueJob(processorQueue);
        AsyncApexJobId asyncApexJobId = new AsyncApexJobId(jobId);

        updateGiftBatchWith(giftBatchId, asyncApexJobId);
    }

    public void disableRD2AsynchronousProcesses() {
        RD2_Settings rd2Settings = RD2_Settings.getInstance();
        rd2Settings.isGiftEntryMode = true;
    }


    public void enableRD2AsynchronousProcesses() {
        RD2_Settings rd2Settings = RD2_Settings.getInstance();
        rd2Settings.isGiftEntryMode = false;
    }


    public void chainNextQueueable(GiftBatchForQueueable queueableGiftBatch) {
        if (Test.isRunningTest()) {
            AsyncApexJobId queueableId = new AsyncApexJobId(UTIL_UnitTestData_TEST.mockId(AsyncApexJob.SObjectType));
            updateGiftBatchWith(queueableGiftBatch.id(), queueableId);
        } else {
            GiftEntryProcessorQueue giftEntryProcessorQueue = new GiftEntryProcessorQueue(queueableGiftBatch);
            Id jobId = System.enqueueJob(giftEntryProcessorQueue);
            AsyncApexJobId asyncApexJobId = new AsyncApexJobId(jobId);
            updateGiftBatchWith(queueableGiftBatch.id(), asyncApexJobId);
        }
    }

    public void giftsFailedCaptureFor(Id batchId, Map<String, String> failReasonByElevateBatchId) {
        GiftBatch giftBatch = new GiftBatch(new GiftBatchId(batchId));
        giftBatch.failGiftsWithReason(failReasonByElevateBatchId);
        giftBatch.updateRecords();
    }

    public void updateGiftBatchWith(GiftBatchId giftBatchId, AsyncApexJobId asyncApexJobId) {
        giftBatchServicePrivilegedHelper.updateGiftBatchWith(asyncApexJobId.value(), giftBatchId);
    }

    public GiftBatchView viewModelFrom(GiftBatchId giftBatchId) {
        GiftBatch giftBatch = new GiftBatch(giftBatchId);
        GiftBatchDTO giftBatchDTO = new GiftBatchDTO(giftBatch);
        return new GiftBatchView(giftBatchDTO);
    }

    public GiftBatchView viewModelWithLimitsAndOffsets(
        GiftBatchId giftBatchId, Integer giftsLimit, Integer giftsOffset) {
            GiftBatch giftBatch = new GiftBatch(giftBatchId, giftsLimit, giftsOffset);
            GiftBatchDTO giftBatchDTO = new GiftBatchDTO(giftBatch);
            return new GiftBatchView(giftBatchDTO);
    }

    public GiftBatchView store(InboundGiftBatchDTO giftBatchChanges) {
        GiftBatchId giftBatchId = new GiftBatchId(giftBatchChanges.giftBatchId);
        GiftBatch giftBatch = new GiftBatch(giftBatchId);
        giftBatch.updateWith(giftBatchChanges);
        return viewModelFrom(giftBatchId);
    }

    public GiftBatchView deleteMemberGiftBy(GiftBatchId giftBatchId, GiftId giftId) {
        GiftBatch giftBatch = new GiftBatch(giftBatchId);
        giftBatch.deleteGiftBy(giftId);
        return viewModelFrom(giftBatchId);
    }

    public void add(GiftBatchId giftBatchId, InboundGiftDTO inboundGift) {
        GiftBatch giftBatch = new GiftBatch(giftBatchId);
        giftBatch.add(inboundGift.asGift());
    }

    public void validateBatch(GiftBatchId giftBatchId) {
        GiftBatch giftBatch = new GiftBatch(giftBatchId);
        giftBatch.asyncApexJob(giftBatchServicePrivilegedHelper.getAsyncApexJob(giftBatchId));

        if (giftBatch.hasStandardGiftsToResolve()) {
            giftBatch.resolveStandardGiftsRemainingInProcessing();
            giftBatch.updateRecords();
        }

    }
    
    public Boolean hasActiveRunningJob(GiftBatchId giftBatchId) {
        Id jobId = giftBatchServicePrivilegedHelper.getLatestAsyncApexJobId(giftBatchId);
        if (jobId == null) {
            return false;
        }

        String jobStatus = getStatusFor(new AsyncApexJobId(jobId));
        return !(FINISH_JOB_STATUS_SET.contains(jobStatus) || jobStatus == null);
    }

    public String getStatusFor(AsyncApexJobId jobId) {
        return giftBatchServicePrivilegedHelper.getStatusFor(jobId);
    }

    public void clearLatestJobIdFrom(GiftBatchId giftBatchId) {
        giftBatchServicePrivilegedHelper.updateGiftBatchWith(null, giftBatchId);
    }

    public void failGiftsInProcessing(GiftBatchId giftBatchId) {
        GiftBatch giftBatch = new GiftBatch(giftBatchId);
        if (giftBatch.hasStandardGiftsToResolve()) {
            giftBatch.resolveStandardGiftsRemainingInProcessing();
            giftBatch.updateRecords();
        }
    }

    private inherited sharing class GiftBatchServicePrivilegedHelper {
        private DataImportBatch__c batch;
        private AsyncApexJob asyncApexJob;
        private final String JOB_TYPE_BATCH = 'BatchApex';

        @TestVisible
        private UnitOfWork unitOfWork {
            get {
                if (unitOfWork == null) {
                    unitOfWork = new UnitOfWork();
                }
                return unitOfWork;
            }
            set;
        }

        public GiftBatchServicePrivilegedHelper(){}

        private DataImportBatch__c selectGiftBatchBy(GiftBatchId giftBatchId){
            Id dataImportBatchId = giftBatchId.value();
            List<DataImportBatch__c> batches = [
                SELECT Id, Latest_Apex_Job_Id__c
                FROM DataImportBatch__c
                WHERE Id =: dataImportBatchId
            ];
            return batches.isEmpty() ? null : batches[0];
        }

        private Boolean hasRecurringGift(GiftBatchId giftBatchId){
            Id dataImportBatchId = giftBatchId.value();
            List<DataImport__c> gifts = [
                SELECT Id
                FROM DataImport__c
                WHERE NPSP_Data_Import_Batch__c =: dataImportBatchId
                AND Recurring_Donation_Recurring_Type__c != null
                LIMIT 1
            ];
            return gifts.isEmpty() ? false : true;
        }

        private AsyncApexJob selectAsyncApexJobBy(Id asyncApexJobId){
            List<AsyncApexJob> apexJobs = [
                SELECT
                    Status
                FROM AsyncApexJob
                WHERE Id =:asyncApexJobId
                AND JobType =: JOB_TYPE_BATCH
            ];
            return apexJobs.isEmpty() ? null : apexJobs[0];
        }

        public Boolean isGiftBatchAccessible(GiftBatchId giftBatchId) {
            if (hasRecurringGift(giftBatchId)) {
                GE_SettingsService service = new GE_SettingsService();
                return service.isRecurringGiftsEnabled();
            }
            return true;
        }

        public void updateGiftBatchWith(Id apexJobId, GiftBatchId giftBatchId) {
            DataImportBatch__c batch =
                new DataImportBatch__c(Id = giftBatchId.value(), Latest_Apex_Job_Id__c = apexJobId);
            unitOfWork.registerDirty(new List<SObject> { batch });
            unitOfWork.save();
        }

        public AsyncApexJob getAsyncApexJob(GiftBatchId giftBatchId){
            this.batch = selectGiftBatchBy(giftBatchId);
            this.asyncApexJob = selectAsyncApexJobBy(this.batch.Latest_Apex_Job_Id__c);
            return this.asyncApexJob;
        }

        public String getStatusFor(AsyncApexJobId jobId) {
            return selectAsyncApexJobBy(jobId.value())?.Status;
        }

        public Id getLatestAsyncApexJobId(GiftBatchId giftBatchId){
            this.batch = selectGiftBatchBy(giftBatchId);
            return this.batch.Latest_Apex_Job_Id__c;
        }
    }

}
