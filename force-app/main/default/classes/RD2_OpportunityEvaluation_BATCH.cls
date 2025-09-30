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
    implements Database.Batchable<SObject>, Database.AllowsCallouts, Database.Stateful, Schedulable {

    /**
    * @description Batch size for Apex Job. Uses default if the Custom Setting batch size is not provided.
    */
    public Integer batchSize {
        get {
            if (batchSize == null) {
               batchSize = getBatchSize();
            }
            return batchSize;
        }
        private set;
    }

    /**
    * @description Returns true if the "Exclude Closed Recurring Donations" setting is enabled
    * Can be manually overwritten for use in Bulk Data Processes
    */
    public Boolean closedFilterEnabled {
        get {
            if (closedFilterEnabled == null) {
                closedFilterEnabled = UTIL_CustomSettingsFacade.getRecurringDonationsSettings().ExcludeClosedRecurringDonations__c;
            }
            return closedFilterEnabled != null ? closedFilterEnabled : false;
        }
        set;
    }

    /***
    * @description Contains batch Apex class name
    */
    private String batchClassName {
        get {
            if (batchClassName == null) {
                batchClassName = RD2_OpportunityEvaluation_BATCH.class.getName();
            }
            return batchClassName;
        }
        set;
    }

    /***
    * @description Checks if another concurrent batch job is in progress
    */
    @TestVisible
    private Boolean isConcurrentBatch {
        get {
            if (isConcurrentBatch == null) {
                isConcurrentBatch = new UTIL_BatchJobService().isConcurrentBatch(batchClassName);
            }
            return isConcurrentBatch;
        }
        set;
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

    @TestVisible
    private static RD2_Settings rd2Settings {
        get {
            if (rd2Settings == null) {
                rd2Settings = RD2_Settings.getInstance();
            }
            return rd2Settings;
        }
        set;
    }

    private static Customizable_Rollup_Settings__c customizableRollupSettings {
        get {
            if (customizableRollupSettings == null) {
                customizableRollupSettings = UTIL_CustomSettingsFacade.getCustomizableRollupSettings();
            }
            return customizableRollupSettings;
        }
        set;
    }

    /**
     * @description API name of the date field to use as in the inner join query
     */
    private String lastModifiedDateField {
        get {
            if (lastModifiedDateField == null) {
                if (String.isNotBlank(customizableRollupSettings.Rollups_IncrementalLastNDays_FldOverride__c)) {
                    lastModifiedDateField = customizableRollupSettings.Rollups_IncrementalLastNDays_FldOverride__c;
                } else {
                    lastModifiedDateField = 'SystemModstamp';
                }
            }
            return lastModifiedDateField;
        }
        set;
    }

    private Set<String> closedStatusValues {
        get {
            if (closedStatusValues == null) {
                closedStatusValues = RD2_StatusMapper.getInstance().getClosedStatusValues();
            }
            return closedStatusValues;
        }
        set;
    }

    /**
    * @description Count of RD's processed by the batch
    */
    @TestVisible
    private Integer recordsProcessed = 0;

    /***
    * @description Count of RD's that hit errors while processing
    */
    @TestVisible
    private Integer recordsFailed = 0;

    /***
    * @description Count of new installment Opportunities created
    */
    @TestVisible
    private Integer recordsCreated = 0;

    /**
     * @description Contains current date value so the batch can be executed for a 
     * date referenced in past, today or a future date. Regardless of the value, the current date
     * is considered "today" for the Opp evaluation, Opp and RD Schedule services.
     * The current date is used as a cut off date to filter out Opportunities in Opp services
     * and to determine if the next Opp should be created for a Recurring Donation.
     * It is also used as a point of reference to view projected RD Schedule installments as of the current date.
     * The current date defaults to the actual today when executed from a scheduler.
     */
    private Date currentDate {
        get {
            if (currentDate == null) {
                currentDate = Date.today();
            }
            return currentDate;
        }
        set;
    }

    /**
     * @description Default constructor
     */
    public RD2_OpportunityEvaluation_BATCH() {
        //Do not set the current date in constructor, Date.today() will be used by default.
    }

    /**
     * @description Constructor setting the current date to the specified date.
     * The constructor is mainly used for testing.
     * @param currentDate Date considered as today
     */
    public RD2_OpportunityEvaluation_BATCH(Date currentDate) {
        this.currentDate = currentDate;
    }

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
        if (!RD2_EnablementService.isRecurringDonations2Enabled) {
            throw new BatchException(System.Label.RD2_ErrorEnhancedRDBatchJobCannotBeRun);
        }

        validateStatusField();

        return Database.getQueryLocator(getRDBatchQuery());
    }

    /**
    * @description Batch Execute Method
    */
    public void execute(Database.BatchableContext context, List<npe03__Recurring_Donation__c> rds) {
        recordsProcessed += rds.size();

        if (disableRollups) {
            TDTM_Config_API.disableAllRollupTriggers();
        }

        // Instantiate new database service instance for each batch and pass it to the evaluation service
        // so that the records created/failed counts are not reset to 0 by other processes running in the same transaction
        // It needs to return those counts to this batch class to capturing in the CustomSettings object as well as the instrumentation service
        RD2_DatabaseService dbService = new RD2_DatabaseService();

        RD2_OpportunityEvaluationService evalService = new RD2_OpportunityEvaluationService()
            .withBatchContext()
            .withRds(UTIL_SObject.extractIds(rds))
            .withCurrentDate(currentDate)
            .withDatabaseService(dbService)
            .evaluateOpportunities();
        
        recordsFailed += dbService.getRecordsFailed();
        recordsCreated += dbService.getRecordsCreated();
    }

    /**
    * @description Build the query of all standard RD fields to use for the batch query
    * @return SOQL
    */
    @TestVisible
    private String getRDBatchQuery() {
        UTIL_Query query = new UTIL_Query()
            .withFrom(npe03__Recurring_Donation__c.SObjectType)
            .withSelectFields(
                new Set<String>{ 'Id' }
            );

        if (closedFilterEnabled) {
            query.withWhere('Status__c NOT IN :closedStatusValues');
        }

        if (isConcurrentBatch) {
            new UTIL_BatchJobService().logConcurrentBatchError(batchClassName, ERR_Handler_API.Context.RD);
            query.withLimit(0);
        }

        return query.build();
    }

    /**
    * @description Batch Finish Method
    */
    public void finish(Database.BatchableContext context) {
        RD2_Settings.getInstance()
            .saveLatestBatchResults(context.getJobId(), recordsProcessed, recordsFailed);

        if (recordsCreated > 0 || recordsFailed > 0 || recordsProcessed > 0) {
            SfdoInstrumentationService.getInstance().log(
                SfdoInstrumentationEnum.Feature.EnhancedRecurringDonations,
                SfdoInstrumentationEnum.Component.Batch,
                SfdoInstrumentationEnum.Action.ProcessedCount,
                new Map<String, Object>{ 
                    'RD Records Processed' => recordsProcessed, 
                    'RD Records Failed' => recordsFailed, 
                    'Opportunity Records Created ' => recordsCreated,
                    'SourceClass' => 'RD2_OpportunityEvaluation_BATCH'
                },
                recordsCreated
            );
        }
    }

    /**
    * @description validate system requirements related to Recurring Donation Evaluation Batch
    * If Paused Status is not Active, an error record will be generated.
    */
    private void validateStatusField() {
       if (!RD2_ValidationService.isStatusPausedActive()) {
            BatchException ex = new BatchException(System.Label.RD2_PauseStatusMustExist);
            ex.setMessage(System.Label.RD2_PauseStatusMustExist);
            ERR_Handler.processError(ex, ERR_Handler_API.Context.RD);
        }
    }

    private Integer getBatchSize() {
        Decimal configValue = UTIL_CustomSettingsFacade.getRecurringDonationsSettings().Recurring_Donation_Batch_Size__c;

        if (configValue == null) {
            configValue = 50;
        }

        if (RD2_ElevateIntegrationService.isIntegrationEnabled() &&
            (rd2Settings.isStatusAutomationForClosedEnabled() || rd2Settings.isStatusAutomationForLapsedEnabled())
        ) {
            Decimal maxSize = RD2_UpdateCommitmentBulkService.MAXIMUM_API_CALL_PER_TRANSACTION
                * RD2_UpdateCommitmentBulkService.REQUEST_SIZE;
            configValue = (configValue > maxSize ) ? maxSize : configValue;
        }

        return configValue.intValue();
    }

    /**
    * @description Custom batch exception
    */
    private class BatchException extends Exception { }
}