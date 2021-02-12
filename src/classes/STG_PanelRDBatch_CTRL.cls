/*
    Copyright (c) 2014, Salesforce.org
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
* @date 2014
* @group Settings
* @description The controller for the Recurring Donations Batch panel
*/
public with sharing class STG_PanelRDBatch_CTRL extends STG_Panel {


    /***
    * @description The panel's constructor
    */
    public STG_PanelRDBatch_CTRL() {
        isRunningBatch = false;
    }

    /***
    * @description Batch job service
    */
    private UTIL_BatchJobService batchService {
        get {
            if (batchService == null) {
                batchService = new UTIL_BatchJobService();
            }
            return batchService;
        }
        set;
    }

    /***
    * @description Returns the string Id of the RD Batch panel.
    */
    public override String idPanel() {
        return 'idPanelRDBatch';
    }

    /***
    * @description Batch class name
    */
    private String batchClassName {
        get {
            if (batchClassName == null) {
                batchClassName = isRD2Enabled 
                    ? RD2_OpportunityEvaluation_BATCH.class.getName() 
                    : RD_RecurringDonations_BATCH.class.getName();
            }
            return batchClassName;
        }
        set;
    }

    /***
    * @description Whether the batch process is currently running
    */
    public Boolean isRunningBatch { get; set; }

    /***
    * @description Whether any batch job with the same class name is currently running
    */
    public Boolean isConcurrentBatch {
        get {
            return new UTIL_BatchJobService().isBatchInProgress(batchClassName);
        }
    }

    /***
    * Description The Recurring Donation Batch Introduction Text
    */
    public String getPageDescription() {
        return isRD2Enabled
            ? System.Label.stgHelpEnhancedRDBatch
            : System.Label.stgHelpRDBatch;
    }

    /***
    * @description Action Method to execute the RD Batch process
    * @return null
    */
    public PageReference runBatch() {
        if (isConcurrentBatch) {
            ApexPages.addMessage(new ApexPages.Message(
                ApexPages.Severity.ERROR, 
                batchService.getConcurrentBatchMessage(batchClassName)
            ));
            return null;
        }

        Savepoint sp = Database.setSavepoint();
        try {
            isRunningBatch = true;
            // Call the batch job, using the Recurring Donations Batch Size field in Custom Settings
            if (isRD2Enabled) {
                RD2_OpportunityEvaluation_BATCH rdBatchJob = new RD2_OpportunityEvaluation_BATCH();
                Integer batchSize = rdBatchJob.batchSize;
                Database.executeBatch(rdBatchJob, batchSize);
            } else {
                RD_RecurringDonations_BATCH rdBatchJob = new RD_RecurringDonations_BATCH();
                Integer batchSize = RD_RecurringDonations_BATCH.batchSize;
                Database.executeBatch(rdBatchJob, batchSize);
            }

        }
        catch(Exception e) {
            Database.rollback(sp);
            ERR_Handler.processError(e, ERR_Handler_API.Context.RD);
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage()));
        }
        return null;
    }

    /**
    * @description Check if the running user has update access to the Opportunity sObject and Recurring Donation sObject
    * Contact sObject
    * @return Boolean
    */
    public Boolean getHasAccess() {
        String oppObject = Schema.SObjectType.Opportunity.getName();
        String rdObject = Schema.SObjectType.npe03__Recurring_Donation__c.getName();

        return UTIL_Permissions.canUpdate(oppObject, false) &&
            UTIL_Permissions.canUpdate(rdObject, false);
    }

}