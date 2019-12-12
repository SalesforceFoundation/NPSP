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
* @description Data Migration batch job used to convert Recurring Donation Records from
* Legacy to Enhanced Recurring Donation format
*
*/
public class RD2_DataMigration_BATCH implements Database.Batchable<SObject>, Schedulable, Database.Stateful {

    public static final String LOG_CONTEXT_PREFIX = 'RDDataMigration:';
    public static final String LOG_EXCEPTION_ERROR_TYPE = 'Data Migration Exception';

    /**
    * @description The default batch size for the migration job if it's not specified
    * in custom settings
    */
    private static final Integer DEFAULT_MIGRATION_JOB_BATCH_SIZE = 25;

    /**
    * @description Indicates if Recurring Donations will be attempted to be converted but not committed to database
    */
    private Boolean isDryRunMode = false;

    /**
    * @description Batch size for Apex Job. Uses default if the Custom Setting batch size is not provided.
    */
    public Integer batchSize {
        get {
            if (batchSize == null) {
                Decimal configValue = UTIL_CustomSettingsFacade.getRecurringDonationsSettings().DataMigrationBatchSize__c;

                if (configValue == null) {
                    configValue = DEFAULT_MIGRATION_JOB_BATCH_SIZE;
                }

                batchSize = configValue.intValue();
            }
            return batchSize;
        }
        private set;
    }

    /**
    * @description Contains batch job Id
    */
    private Id batchJobId;

    /**
    * @description Constructs context used to log errors
    */
    private String logContext {
        get {
            if (logContext == null) {
                logContext = constructLogContext();
            }
            return logContext;
        }
        set;
    }

    /***
    * @description Schedulable executes the batch job
    */
    public void execute(SchedulableContext context) {
        Database.executeBatch(new RD2_DataMigration_BATCH(), batchSize);
    }

    /**
    * @description Enables Dry Run Mode for the migration job
    */
    public RD2_DataMigration_BATCH enableDryRunMode() {
        isDryRunMode = true;
        return this;
    }

    /**
    * @description Batch Start Method
    */
    public Database.QueryLocator start(Database.BatchableContext context) {
        setBatchJobId(context);

        if (RD2_EnablementService.isRecurringDonations2Enabled) {
            return Database.getQueryLocator(getRDMigrationQuery());
        } else {
            throw new MigrationException(System.Label.RD2_ErrorDataMigrationJobCannotBeRun);
        }
    }

    /**
    * @description Converts legacy Recurring Donation into enhanced Recurring Donation format
    * @param context Batchable context
    * @param rds Recurring Donations
    * @return void
    */
    public void execute(Database.BatchableContext context, List<npe03__Recurring_Donation__c> rds) {
        setBatchJobId(context);

        ERR_Handler.Errors errorResult = new ERR_Handler.Errors();
        Map<Id, List<Opportunity>> oppsByRdId = getRelatedOpportunities(rds);
        List<npe03__Recurring_Donation__c> convertedRDs = new List<npe03__Recurring_Donation__c>();

        for (npe03__Recurring_Donation__c rd : rds) {
            RD2_DataMigrationMapper mapper = new RD2_DataMigrationMapper(rd)
                .withRelatedOpportunities(oppsByRdId.get(rd.Id));

            if (mapper.isConverted()) {
                continue;
            }

            try {
                convertedRDs.add(mapper.convertToEnhancedRD());

            } catch (Exception e) {
                addError(e, rd.Id, errorResult);
            }
        }

        handleSaveAndLogging(convertedRDs, errorResult);
    }

    /**
    * @description Batch Finish Method
    */
    public void finish(Database.BatchableContext context) {
    }


    /**
    * @description Sets batch job Id
    * @param context Batchable context
    * @return void
    */
    private void setBatchJobId(Database.BatchableContext context) {
        if (context == null || batchJobId != null) {
            return;
        }

        batchJobId = context.getJobId();
    }

    /**
    * @description Constructs log context
    * @return String Log context containing batch job Created Date
    */
    private String constructLogContext() {
        UTIL_BatchJobService.BatchJob batchJob = new UTIL_BatchJobService().getBatchJob(batchJobId);

        String formattedDateSuffix = batchJob == null
            ? ''
            : ' ' + String.valueOf(batchJob.CreatedDate);

        return LOG_CONTEXT_PREFIX + formattedDateSuffix;
    }

    /**
    * @description Constructs log record and adds it into the error log container
    * @param e Exception
    * @param rdId Recurring Donation Id
    * @param errorResult Exception/error log container
    * @return void
    */
    private void addError(Exception e, Id rdId, ERR_Handler.Errors errorResult) {
        Error__c logEntry = new Error__c(
            Context_Type__c = logContext,
            Datetime__c = System.now(),
            Related_Record_ID__c = rdId,
            Record_URL__c = ERR_Handler.getRecordURL(rdId),
            Error_Type__c = LOG_EXCEPTION_ERROR_TYPE,
            Full_Message__c = e.getMessage()
        );

        errorResult.errorRecords.add(logEntry);
    }

    /**
    * @description Save records and log all exceptions and errors generated during records' validation and save
    * @param convertedRDs Converted Recurring Donations
    * @param errorResult Exception/error log container
    * @return void
    */
    private void handleSaveAndLogging(List<npe03__Recurring_Donation__c> convertedRDs, ERR_Handler.Errors errorResult) {

        List<Database.SaveResult> saveResults = saveRecords(convertedRDs);

        errorResult.errorRecords.addAll(
            ERR_Handler.getErrors(saveResults, convertedRDs).errorRecords
        );

        errorResult.errorsExist = !errorResult.errorRecords.isEmpty();

        ERR_Handler.processErrorsOnly(errorResult, logContext);
    }

    /**
    * @description Save records
    * @param convertedRDs Converted Recurring Donations
    * @return List<Database.SaveResult>
    */
    private List<Database.SaveResult> saveRecords(List<npe03__Recurring_Donation__c> convertedRDs) {
        if (convertedRDs.isEmpty()) {
            return new List<Database.SaveResult>();
        }

        Savepoint sp = Database.setSavepoint();

        List<Database.SaveResult> saveResults = Database.update(convertedRDs, false);

        if (this.isDryRunMode) {
            Database.rollback(sp);
        }

        return saveResults;
    }

    /**
    * @description Build the query of all standard RD fields to use for the batch query
    * @return SOQL
    */
    @TestVisible
    private String getRDMigrationQuery() {
        Set<String> rdFields = new Set<String>{
            'Id',
            'Name',
            'npe03__Open_Ended_Status__c',
            'npe03__Next_Payment_Date__c',
            'npe03__Paid_Amount__c',
            'npe03__Organization__c',
            'npe03__Contact__c',
            'npe03__Installment_Amount__c',
            'npe03__Installments__c',
            'npe03__Amount__c',
            'npe03__Total__c',
            'npe03__Installment_Period__c',
            'npe03__Date_Established__c',
            'npe03__Schedule_Type__c',
            'npe03__Recurring_Donation_Campaign__c',
            'npe03__Total_Paid_Installments__c',
            'Ownerid',
            'Always_Use_Last_Day_of_Month__c',
            'Day_of_Month__c',
            'StartDate__c',
            'InstallmentFrequency__c',
            'PaymentMethod__c',
            'Status__c',
            'RecurringType__c'
        };
        if (UserInfo.isMultiCurrencyOrganization()) {
            rdFields.add('CurrencyIsoCode');
        }

        return new UTIL_Query()
            .withFrom(npe03__Recurring_Donation__c.SObjectType)
            .withSelectFields(rdFields)
            .withOrderBy('npe03__Last_Payment_Date__c')
            .build();
    }

    /**
    * @description Build a map of related Opportunities for each recurring donation
    * @param rds Collection of Recurring Donations to retrieve related Opps for
    * @return Map<Id, List<Opportunity>>
    */
    private Map<Id, List<Opportunity>> getRelatedOpportunities(List<npe03__Recurring_Donation__c> rds) {
        Map<Id, List<Opportunity>> oppsByRdId = new Map<Id, List<Opportunity>>();

        for (Opportunity opp : [
            SELECT Id,
                Name,
                Amount,
                CloseDate,
                CreatedDate,
                IsWon,
                IsClosed,
                npe03__Recurring_Donation__c
            FROM Opportunity
            WHERE npe03__Recurring_Donation__c IN :rds
            ORDER BY npe03__Recurring_Donation__c, CloseDate ASC
        ]) {

            if (!oppsByRdId.containsKey(opp.npe03__Recurring_Donation__c)) {
                oppsByRdId.put(opp.npe03__Recurring_Donation__c, new List<Opportunity>());
            }
            oppsByRdId.get(opp.npe03__Recurring_Donation__c).add(opp);
        }

        return oppsByRdId;
    }

    private class MigrationException extends Exception { }
}