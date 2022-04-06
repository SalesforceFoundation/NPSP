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
public abstract class RD2_DataMigrationBase_BATCH implements Database.Batchable<SObject>, Schedulable, Database.Stateful {

    public static final String LOG_CONTEXT_MIGRATION = 'RDDataMigration:';
    public static final String LOG_CONTEXT_DRY_RUN = 'RDValidateMigration:';
    public static final String LOG_EXCEPTION_ERROR_TYPE = 'Data Migration Exception';

    /**
     * @description A flag to mark Closed Lost Opps that are voided by the data migration.
     * The flag is used to exclude (ignore) such Opps by the Opp service
     * when determining if the next Opp with the same Close Date can be created.
     */
    public static final Integer MIGRATION_INSTALLMENT_NUMBER_FLAG = 0;

    /**
    * @description Contains Recurring Donation custom settings
    */
    private npe03__Recurring_Donations_Settings__c rdSettings = UTIL_CustomSettingsFacade.getRecurringDonationsSettings();

    /**
    * @description The default batch size for the migration job if it's not specified
    * in custom settings
    */
    private static final Integer DEFAULT_MIGRATION_JOB_BATCH_SIZE = 25;

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

    /**
    * @description Should Rollups be disabled or not before running data migration or validation
    */
    private Boolean disableRollups {
        get {
            disableRollups = (rdSettings.DisableRollupsWhenCreatingInstallments__c == true);
            return disableRollups;
        } private set;
    }

    /***
    * @description Count of Recurring Donations that are migrated
    */
    @TestVisible
    private Integer totalRecords = 0;

    /***
    * @description Count of Recurring Donations that failed to be migrated
    */
    @TestVisible
    private Integer totalRecordsFailed = 0;

    /**
    * @description Indicates if Recurring Donations will be attempted to be converted but not committed to database
    */
    public Boolean isDryRunMode = false;

    /**
    * @description Batch Start Method
    */
    public Database.QueryLocator start(Database.BatchableContext context) {
        setBatchJobId(context);

        if (!RD2_EnablementService.isRecurringDonations2Enabled && !isDryRunMode) {
            throw new MigrationException(System.Label.RD2_ErrorDataMigrationJobCannotBeRun);

        } else if (rdSettings.npe03__Open_Opportunity_Behavior__c == RD2_Constants.CloseActions.No_Action.name()) {
            throw new MigrationException(System.Label.RD2_DataMigrationInvalidCloseAction);

        } else {
            return Database.getQueryLocator(getRDMigrationQuery());
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

        //enable enhanced Recurring Donations during the batch transaction
        if (!RD2_EnablementService.isRecurringDonations2Enabled && isDryRunMode) {
            RD2_EnablementService.isRecurringDonations2EnabledOverride = true;
            RD2_EnablementService.isMetadataDeployed = true;
        }

        //ensure enhanced RD enablement flag is enabled
        if (!RD2_EnablementService.isRecurringDonations2Enabled) {
            throw new MigrationException(System.Label.RD2_ErrorDataMigrationJobCannotBeRun);
        }

       if (disableRollups) {
            TDTM_Config_API.disableAllRollupTriggers();
        }


        //do not evaluate Opportunities from the RD trigger during migration
        //migration batch itself will take care of outstanding Opps
        RD2_OpportunityEvaluationService.skipEvaluationService = true;

        Logger logger = new Logger(logContext);
        Map<Id, List<Opportunity>> oppsByRdId = getRelatedOpportunities(rds);
        Map<Id, List<Opportunity>> openOppsToVoidByRDId = new Map<Id, List<Opportunity>>();
        List<npe03__Recurring_Donation__c> convertedRDs = new List<npe03__Recurring_Donation__c>();

        for (npe03__Recurring_Donation__c rd : rds) {
            RD2_DataMigrationMapper mapper = new RD2_DataMigrationMapper(rd, isDryRunMode)
                .withRelatedOpportunities(oppsByRdId.get(rd.Id));

            if (mapper.isConverted()) {
                continue;
            }

            //track only records that have not been migrated yet
            totalRecords++;

            try {
                convertedRDs.add(mapper.convertToEnhancedRD());

            } catch (Exception e) {
                logger.addError(e, rd.Id);
                continue;
            }

            if (!mapper.openOppsToVoid.isEmpty()) {
                openOppsToVoidByRDId.put(rd.Id, mapper.openOppsToVoid);
            }
        }

        handleSaveAndLogging(convertedRDs, openOppsToVoidByRDId, logger);

        //even though the flag will be reset in actual execution,
        //set override to false for unit test verification
        RD2_EnablementService.isRecurringDonations2EnabledOverride = false;
    }

    /**
    * @description Logs batch job summary
    */
    public void finish(Database.BatchableContext context) {
        UTIL_BatchJobService.JobSummary summary = new UTIL_BatchJobService.JobSummary(batchJobId)
            .withTotalRecordsProcessed(totalRecords - totalRecordsFailed)
            .withTotalRecordsFailed(totalRecordsFailed)
            .withCompletedDate(Datetime.now());

        new RD2_DataMigrationEnablement.BatchJob().saveSummary(summary, isDryRunMode);
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
        AsyncApexJob batchJob = new UTIL_BatchJobService().getAsyncApexJob(batchJobId);

        String formattedDateSuffix = batchJob == null
            ? ''
            : ' ' + String.valueOf(batchJob.CreatedDate);

        String context = isDryRunMode ? LOG_CONTEXT_DRY_RUN : LOG_CONTEXT_MIGRATION;

        return context + formattedDateSuffix;
    }

    /**
    * @description Save records and log all exceptions and errors generated during records' validation and save
    * @param convertedRDs Converted Recurring Donations
    * @param openOppsToVoidByRDId Open Opportunities by Recurring Donation Id to void
    * @param logger Exception/error log container
    * @return void
    */
    @TestVisible
    private void handleSaveAndLogging(
        List<npe03__Recurring_Donation__c> convertedRDs,
        Map<Id, List<Opportunity>> openOppsToVoidByRDId,
        Logger logger
    ) {
        Savepoint sp = Database.setSavepoint();

        Set<Id> savedRDIds = saveRecurringDonations(convertedRDs, logger);

        voidOpenOpportunities(savedRDIds, openOppsToVoidByRDId, logger);

        if (this.isDryRunMode || logger.isRelatedRecordFailed) {
            Database.rollback(sp);

            totalRecordsFailed += logger.isRelatedRecordFailed
                ? convertedRDs.size() //every record failed regardless of the run mode
                : logger.countRecordsFailed; //track individual records that failed
        } else {
            totalRecordsFailed += logger.countRecordsFailed;
        }

        logger.processErrors();
    }

    /**
    * @description Save Recurring Donations
    * @param convertedRDs Converted Recurring Donations
    * @param logger Exception/error log container
    * @return Set<Id> Successfully saved Recurring Donation Ids
    */
    private Set<Id> saveRecurringDonations(List<npe03__Recurring_Donation__c> convertedRDs,  Logger logger) {

        List<Database.SaveResult> saveResults = convertedRDs.isEmpty()
            ? new List<Database.SaveResult>()
            : Database.update(convertedRDs, false);

        logger.addErrors(saveResults, convertedRDs);

        return getSavedRecordIds(saveResults);
    }

    /**
    * @description Returns Ids of records that were saved successfully
    * @param saveResults Insert/update DML save results
    * @return Set<Id>
    */
    private Set<Id> getSavedRecordIds(List<Database.SaveResult> saveResults) {
        Set<Id> recordIds = new Set<Id>();

        for (Database.SaveResult result : saveResults) {
            if (result.isSuccess()) {
                recordIds.add(result.getId());
            }
        }

        return recordIds;
    }

    /**
    * @description Handles Open Opportunities that should be voided (sets them to Closed Lost or deletes them)
    * @param savedRDIds Ids of successfully saved Recurring Donations
    * @param openOppsToVoidByRDId To be voided Open Opportunities by Recurring Donation Id
    * @param logger Exception/error log container
    * @return void
    */
    private void voidOpenOpportunities(Set<Id> savedRDIds, Map<Id, List<Opportunity>> openOppsToVoidByRDId, Logger logger) {
        List<Opportunity> opps = new List<Opportunity>();
        for (Id rdId : savedRDIds) {
            if (openOppsToVoidByRDId.containsKey(rdId)) {
                opps.addAll(openOppsToVoidByRDId.get(rdId));
            }
        }

        if (opps.isEmpty()) {
            return;
        }

        List<Object> dmlResults = new List<Object>();
        if (rdSettings.npe03__Open_Opportunity_Behavior__c == RD2_Constants.CloseActions.Delete_Open_Opportunities.name()) {
            dmlResults = Database.delete(opps, false);

        } else if (rdSettings.npe03__Open_Opportunity_Behavior__c == RD2_Constants.CloseActions.Mark_Opportunities_Closed_Lost.name()) {
            for (Opportunity opp : opps) {
                opp.StageName = System.Label.npe03.RecurringDonationClosedLostOpportunityStage;

                //Overwrite the Opp Installment Number so this Opp can be recognized and excluded
                //by RD2 Opp processing services when determining the next Opp with the same Close Date on the Recurring Donation
                opp.Recurring_Donation_Installment_Number__c = MIGRATION_INSTALLMENT_NUMBER_FLAG;
                //Indicate the Opp was set as Closed Lost due to switching to the new enhanced (RD2) processing
                opp.Closed_Lost_Reason__c = logContext;
            }

            dmlResults = Database.update(opps, false);
        }

        logger.addErrors(dmlResults, opps);
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
            'CreatedDate',
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


    /**
    * @description Builds and creates logs for errors and exceptions.
    * The current logger version is the ERR_Handler wrapper.
    */
    public class Logger {
        /* @description Contains error results */
        @TestVisible
        private ERR_Handler.Errors errorResult = new ERR_Handler.Errors();

        /* @description Primary records' SObjectType */
        private SObjectType sObjType;

        /**
        * @description Context in which logs are created.
        * Users can filter Error__c records by providing log context.
        */
        private String context;

        /* @description Exception error type */
        private String exceptionErrorType;

        /* @description Contains number of failed primary records. It excludes related records. */
        public Integer countRecordsFailed { get; private set; }

        /* @description Indicates if there is error on a related record DML operation */
        public Boolean isRelatedRecordFailed { get; private set; }

        /**
        * @description Default constructor applicable to Recurring Donations
        * @param context Log context
        * @param exceptionErrorType Error record Error Type value to log exception details
        */
        public Logger(String context) {
            this(npe03__Recurring_Donation__c.SObjectType, context, LOG_EXCEPTION_ERROR_TYPE);
        }

        /**
        * @description Constructor
        * @param sObjType Primary record SObjectType
        * @param context Log context
        * @param exceptionErrorType Error record Error Type value to log exception details
        */
        public Logger(SObjectType sObjType, String context, String exceptionErrorType) {
            this.sObjType = sObjType;
            this.context = context;
            this.exceptionErrorType = exceptionErrorType;

            countRecordsFailed = 0;
            isRelatedRecordFailed = false;
        }

        /**
        * @description Constructs log record and adds it into the error log container
        * @param e Exception
        * @param recordId Id Recurring Donation record Id
        * @return void
        */
        public void addError(Exception e, Id recordId) {
            Error__c errorRecord = new Error__c(
                Context_Type__c = context,
                Datetime__c = System.now(),
                Related_Record_ID__c = recordId,
                Record_URL__c = ERR_Handler.getRecordURL(recordId),
                Error_Type__c = exceptionErrorType,
                Full_Message__c = e.getMessage()
            );

            errorResult.errorRecords.add(errorRecord);
            countRecordsFailed++;
        }

        /**
        * @description Constructs and collects error logs for records that failed in the DML operation
        * @param dmlResults Insert/update/delete DML operation results
        * @param records Records which were saved/deleted by the DML operation
        * @return void
        */
        public void addErrors(List<Object> dmlResults, List<SObject> records) {
            if (records.isEmpty()) {
                return;
            }

            ERR_Handler.Errors dmlErrors = ERR_Handler.getErrorsOnly(dmlResults, records);

            if (!dmlErrors.errorsExist) {
                return;
            }

            if (records[0].getSObjectType() == sObjType) {
                countRecordsFailed += dmlErrors.errorRecords.size();

            } else {
                isRelatedRecordFailed = true;
            }

            errorResult.errorRecords.addAll(
                dmlErrors.errorRecords
            );
        }

        /**
        * @description Creates Error__c record for each errorResult.errorRecords
        * @return void
        */
        public void processErrors() {
            errorResult.errorsExist = !errorResult.errorRecords.isEmpty();

            ERR_Handler.processErrorsOnly(errorResult, context);
        }
    }

    /**
    * @description Custom data migration exception
    */
    private class MigrationException extends Exception { }
}