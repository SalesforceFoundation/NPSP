/*
    Copyright (c) 2019 Salesforce.org
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
* @group Recurring Donations
* @description Recurring Donations Bulk Processing Batch Job to review EVERY Recurring Donation
* record to evaluate its attached Opportunities to take the necessary action.
*
*/
public without sharing class RD2_OpportunityEvaluation_BATCH
    implements Database.Batchable<SObject>, Database.Stateful, Schedulable {

    /**
    * @description Batch size for Apex Job. Uses default if the Custom Setting batch size is not provided.
    */
    @TestVisible
    public Integer batchSize {
        get {
            if (batchSize == null) {
                Decimal configValue = UTIL_CustomSettingsFacade.getRecurringDonationsSettings().Recurring_Donation_Batch_Size__c;

                if (configValue == null) {
                    configValue = 50;
                }

                batchSize = configValue.intValue();
            }
            return batchSize;
        }
        private set;
    }

    /**
    * @description Should Rollups be disabled before any new Installments Opps are inserted
    */
    private Boolean disableRollups {
        get {
            disableRollups = UTIL_CustomSettingsFacade.getRecurringDonationsSettings().DisableRollupsWhenCreatingInstallments__c;
            if (disableRollups == null) {
                disableRollups = false;
            }
            return disableRollups;
        } private set;
    }

    /*******************************************************************************************************
    * @description Count of RD's processed by the batch
    */
    private Integer numberRDsProcessed = 0;

    /*******************************************************************************************************
    * @description Count of RD's that hit errors while processing
    */
    private Integer numberOfFailures = 0;

    /**
     * @description Schedulable Execute Method to launch the Batch Job
     */
    public void execute(SchedulableContext context) {
        Database.executeBatch(new RD2_OpportunityEvaluation_BATCH(), batchSize);
    }


    /**
    * @description Batch Start Method
    */
    public Database.QueryLocator start(Database.BatchableContext context) {
        if (RD2_EnablementService.isRecurringDonations2Enabled) {
            return Database.getQueryLocator(getRDBatchQuery());
        } else {
            throw new BatchException(System.Label.RD2_ErrorEnhancedRDBatchJobCannotBeRun);
        }
    }

    /**
    * @description Batch Execute Method
    */
    public void execute(Database.BatchableContext context, List<npe03__Recurring_Donation__c> rds) {

        Set<Id> rdIds = (new Map<Id, npe03__Recurring_Donation__c>(rds)).keySet();

        RD2_OpportunityEvaluationService oppEvalService = new RD2_OpportunityEvaluationService()
            .withRds(rdIds);

        if (disableRollups) {
            TDTM_Config_API.disableAllRollupTriggers();
        }
        oppEvalService.evaluateOpportunities();

        numberRDsProcessed += rds.size();
    }

    /**
    * @description Build the query of all standard RD fields to use for the batch query
    * @return SOQL
    */
    @TestVisible
    private String getRDBatchQuery() {
        Set<String> rdFields = new Set<String>{
            'Id'
        };

        return new UTIL_Query()
            .withFrom(npe03__Recurring_Donation__c.SObjectType)
            .withSelectFields(rdFields)
            .build();
    }

    /**
    * @description Batch Finish Method
    */
    public void finish(Database.BatchableContext context) {
        AsyncApexJob job = new UTIL_BatchJobService().getAsyncApexJob(context.getJobId());

        npe03__Recurring_Donations_Settings__c rdSettings = UTIL_CustomSettingsFacade.getRecurringDonationsSettings();
        rdSettings.npe03__Last_Batch_Run__c = job.completedDate;
        rdSettings.npe03__Number_of_Successes__c = numberRDsProcessed - numberOfFailures;
        rdSettings.npe03__Number_of_Failures__c = numberOfFailures;

        if (!Test.isRunningTest()) {
            upsert rdSettings;
        }
    }

    private class BatchException extends Exception { }
}