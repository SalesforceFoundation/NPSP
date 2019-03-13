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
* @group Customizable Rollups Operations Services
* @description Unit Tests for the Opportunity to Account and Contact Rollups
*/
@IsTest(isParallel=true)
private class CRLP_Batch_Base_TEST {

    /******************************** Incremental Mode Tests *****************************/

    @isTest
    private static void accountHardCreditRollupGeneratesIncrementalModeJoinQuery() {
        CRLP_RollupProcessingOptions.RollupType jobType =
                CRLP_RollupProcessingOptions.RollupType.AccountHardCredit;
        configureIncrementalMode(jobType, true);

        CRLP_Batch_Base_NonSkew accountBatchJob = getBatchJobInstanceWithData(jobType, null);
        accountBatchJob.isScheduledJob = true; // Set the Batch Base isScheduledJob flag to true.
        // This is necessary because the Schedulable Job constructs and submits a separate instance of the
        // CRLP_Account_BATCH class.  So we "mock" the isScheduledJob value here, to test the correct
        // response from the getWhereClause() method below.

        String generatedWhereClause = accountBatchJob.getMainQueryInnerJoinFilter();
        System.assert(generatedWhereClause.contains('FROM'));
        System.assert(generatedWhereClause.contains('WHERE'), 'The incremental mode ' +
                'where clause for the inner join should contain a where filter on the Opportunities.');
        System.assert(generatedWhereClause.contains('LAST_N_YEARS:' + new RollupInfo().maxYearsAgoInteger));
        System.assert(!batchStartOuterQueryContainsOrderByAndLimit(accountBatchJob),
                'The outer query should not contain "ORDER BY" or "LIMIT".');
    }

    @isTest
    private static void accountHardCreditRollupGeneratesLastNDaysJoinQuery() {
        CRLP_RollupProcessingOptions.RollupType jobType =
                CRLP_RollupProcessingOptions.RollupType.AccountHardCredit;
        configureIncrementalMode(jobType, true);

        deactivateTimeBoundRollups(
                jobType,
                CRLP_Operation.TimeBoundOperationType.Years_Ago);

        CRLP_Batch_Base_NonSkew accountBatchJob = getBatchJobInstanceWithData(jobType, null);
        accountBatchJob.isScheduledJob = true;

        String generatedWhereClause = accountBatchJob.getMainQueryInnerJoinFilter();
        System.assert(generatedWhereClause.contains('WHERE'), 'The incremental mode ' +
                'where clause for the inner join should contain a where filter on the Opportunities.');
        System.assert(generatedWhereClause.contains('LAST_N_DAYS:' + new RollupInfo().maxDaysBackInteger));
        System.assert(!batchStartOuterQueryContainsOrderByAndLimit(accountBatchJob),
                'The outer query should not contain "ORDER BY" or "LIMIT".');
    }

    @isTest
    private static void accountHardCreditRollupGeneratesLastNYearsJoinQuery() {
        CRLP_RollupProcessingOptions.RollupType jobType =
                CRLP_RollupProcessingOptions.RollupType.AccountHardCredit;
        configureIncrementalMode(jobType, true);

        deactivateTimeBoundRollups(
                jobType,
                CRLP_Operation.TimeBoundOperationType.Days_Back);

        CRLP_Batch_Base_NonSkew accountBatchJob = getBatchJobInstanceWithData(jobType, null);
        accountBatchJob.isScheduledJob = true;

        String generatedWhereClause = accountBatchJob.getMainQueryInnerJoinFilter();
        System.assert(generatedWhereClause.contains('WHERE'), 'The incremental mode ' +
                'where clause for the inner join should contain a where filter on the Opportunities.');
        Integer lastNYears = new RollupInfo().maxYearsAgoInteger;
        System.assert(generatedWhereClause.contains('LAST_N_YEARS:' + lastNYears));
        System.assert(!batchStartOuterQueryContainsOrderByAndLimit(accountBatchJob),
                'The outer query should not contain "ORDER BY" or "LIMIT".');
    }

    @isTest
    private static void accountHardCreditRollupGeneratesLastNDaysJoinQueryWithCustomSettingFalse() {
        CRLP_RollupProcessingOptions.RollupType jobType =
                CRLP_RollupProcessingOptions.RollupType.AccountHardCredit;
        configureIncrementalMode(jobType, false);

        CRLP_Batch_Base_NonSkew accountBatchJob = getBatchJobInstanceWithData(jobType, null);
        accountBatchJob.isScheduledJob = true;

        String whereClause = accountBatchJob.getMainQueryInnerJoinFilter();
        System.assert(whereClause.contains('WHERE') == false, 'The standard where clause should be used ' +
                'for the inner join when the custom setting is set to false.');
        System.assert(!batchStartOuterQueryContainsOrderByAndLimit(accountBatchJob),
                'The outer query should not contain "ORDER BY" or "LIMIT".');
    }

    @isTest
    private static void accountHardCreditRollupWithUserDefinedJoinGeneratesProperJoinQuery() {
        CRLP_RollupProcessingOptions.RollupType jobType =
                CRLP_RollupProcessingOptions.RollupType.AccountHardCredit;
        String userDefinedLastNDaysFieldOverride = 'LastModifiedDate';
        Integer userDefinedLastNDaysValueOverride = 44;
        configureIncrementalFieldOverrides(
                jobType,
                userDefinedLastNDaysFieldOverride,
                userDefinedLastNDaysValueOverride);

        CRLP_Batch_Base_NonSkew accountBatchJob = getBatchJobInstanceWithData(jobType, null);
        accountBatchJob.isScheduledJob = true;

        String generatedWhereClause = accountBatchJob.getMainQueryInnerJoinFilter();
        System.assert(generatedWhereClause.contains('WHERE'), 'The incremental mode ' +
                'where clause for the inner join should contain a where filter on the Opportunities.');
        System.assert(generatedWhereClause.contains(userDefinedLastNDaysFieldOverride));
        System.assert(generatedWhereClause.contains(String.valueOf(userDefinedLastNDaysValueOverride)));
        System.assert(!batchStartOuterQueryContainsOrderByAndLimit(accountBatchJob),
                'The outer query should not contain "ORDER BY" or "LIMIT".');
    }

    @isTest
    private static void contactHardCreditRollupGeneratesStandardJoinQueryWhenNotScheduledJob() {
        CRLP_RollupProcessingOptions.RollupType jobType =
                CRLP_RollupProcessingOptions.RollupType.ContactHardCredit;
        configureIncrementalMode(jobType, true);

        CRLP_Batch_Base_NonSkew contactBatchJob = getBatchJobInstanceWithData(jobType, null);

        String whereClause = contactBatchJob.getMainQueryInnerJoinFilter();
        System.assert(whereClause.contains('WHERE') == false, 'The standard query for the inner join ' +
                'should NOT contain a where filter on the Opportunities when not a scheduled job.');
        System.assert(!batchStartOuterQueryContainsOrderByAndLimit(contactBatchJob),
                'The outer query should not contain "ORDER BY" or "LIMIT".');
    }

    @isTest
    private static void contactHardCreditRollupGeneratesIncrementalModeJoinQuery() {
        CRLP_RollupProcessingOptions.RollupType jobType =
                CRLP_RollupProcessingOptions.RollupType.ContactHardCredit;
        configureIncrementalMode(jobType, true);

        CRLP_Batch_Base_NonSkew contactBatchJob = getBatchJobInstanceWithData(jobType, null);
        contactBatchJob.isScheduledJob = true;

        String generatedWhereClause = contactBatchJob.getMainQueryInnerJoinFilter();
        System.assert(generatedWhereClause.contains('FROM'));
        System.assert(generatedWhereClause.contains('WHERE'), 'The incremental mode ' +
                'where clause for the inner join should contain a where filter on the Opportunities.');
        System.assert(generatedWhereClause.contains('LAST_N_YEARS:' + new RollupInfo().maxYearsAgoInteger));
        System.assert(!batchStartOuterQueryContainsOrderByAndLimit(contactBatchJob),
                'The outer query should not contain "ORDER BY" or "LIMIT".');
    }

    @isTest
    private static void contactHardCreditRollupGeneratesLastNDaysJoinQuery() {
        CRLP_RollupProcessingOptions.RollupType jobType =
                CRLP_RollupProcessingOptions.RollupType.ContactHardCredit;
        configureIncrementalMode(jobType, true);

        deactivateTimeBoundRollups(
                jobType,
                CRLP_Operation.TimeBoundOperationType.Years_Ago);

        CRLP_Batch_Base_NonSkew contactBatchJob = getBatchJobInstanceWithData(jobType, null);
        contactBatchJob.isScheduledJob = true;

        String generatedWhereClause = contactBatchJob.getMainQueryInnerJoinFilter();
        System.assert(generatedWhereClause.contains('WHERE'), 'The incremental mode ' +
                'where clause for the inner join should contain a where filter on the Opportunities.');
        System.assert(generatedWhereClause.contains('LAST_N_DAYS:' + new RollupInfo().maxDaysBackInteger));
        System.assert(!batchStartOuterQueryContainsOrderByAndLimit(contactBatchJob),
                'The outer query should not contain "ORDER BY" or "LIMIT".');
    }

    @isTest
    private static void contactHardCreditRollupGeneratesLastNYearsJoinQuery() {
        CRLP_RollupProcessingOptions.RollupType jobType =
                CRLP_RollupProcessingOptions.RollupType.ContactHardCredit;
        configureIncrementalMode(jobType, true);

        deactivateTimeBoundRollups(
                jobType,
                CRLP_Operation.TimeBoundOperationType.Days_Back);

        CRLP_Batch_Base_NonSkew contactBatchJob = getBatchJobInstanceWithData(jobType, null);
        contactBatchJob.isScheduledJob = true;

        String generatedWhereClause = contactBatchJob.getMainQueryInnerJoinFilter();
        System.assert(generatedWhereClause.contains('WHERE'), 'The incremental mode ' +
                'where clause for the inner join should contain a where filter on the Opportunities.');
        Integer lastNYears = new RollupInfo().maxYearsAgoInteger;
        System.assert(generatedWhereClause.contains('LAST_N_YEARS:' + lastNYears));
        System.assert(!batchStartOuterQueryContainsOrderByAndLimit(contactBatchJob),
                'The outer query should not contain "ORDER BY" or "LIMIT".');
    }

    @isTest
    private static void contactHardCreditRollupGeneratesLastNDaysJoinQueryWithCustomSettingFalse() {
        CRLP_RollupProcessingOptions.RollupType jobType =
                CRLP_RollupProcessingOptions.RollupType.ContactHardCredit;
        configureIncrementalMode(jobType, false);

        CRLP_Batch_Base_NonSkew contactBatchJob = getBatchJobInstanceWithData(jobType, null);
        contactBatchJob.isScheduledJob = true;

        String whereClause = contactBatchJob.getMainQueryInnerJoinFilter();
        System.assert(whereClause.contains('WHERE') == false, 'The standard where clause should be used ' +
                'for the inner join when the custom setting is set to false.');
        System.assert(!batchStartOuterQueryContainsOrderByAndLimit(contactBatchJob),
                'The outer query should not contain "ORDER BY" or "LIMIT".');
    }

    @isTest
    private static void contactHardCreditRollupWithUserDefinedJoinGeneratesProperJoinQuery() {
        CRLP_RollupProcessingOptions.RollupType jobType =
                CRLP_RollupProcessingOptions.RollupType.ContactHardCredit;
        String userDefinedLastNDaysFieldOverride = 'LastModifiedDate';
        Integer userDefinedLastNDaysValueOverride = 555;
        configureIncrementalFieldOverrides(
                jobType,
                userDefinedLastNDaysFieldOverride,
                userDefinedLastNDaysValueOverride);

        CRLP_Batch_Base_NonSkew contactBatchJob = getBatchJobInstanceWithData(jobType, null);
        contactBatchJob.isScheduledJob = true;

        String generatedWhereClause = contactBatchJob.getMainQueryInnerJoinFilter();
        System.assert(generatedWhereClause.contains('WHERE'), 'The incremental mode ' +
                'where clause for the inner join should contain a where filter on the Opportunities.');
        System.assert(generatedWhereClause.contains(userDefinedLastNDaysFieldOverride));
        System.assert(generatedWhereClause.contains(String.valueOf(userDefinedLastNDaysValueOverride)));
        System.assert(!batchStartOuterQueryContainsOrderByAndLimit(contactBatchJob),
                'The outer query should not contain "ORDER BY" or "LIMIT".');
    }

    /******************************** Chunk Mode Tests *****************************/

    @isTest
    private static void chunkModeRollupHasAdditionalRecordsToProcess() {
        CRLP_RollupProcessingOptions.RollupType jobType =
                CRLP_RollupProcessingOptions.RollupType.AccountHardCredit;
        Integer chunkSize = 1;
        Id lastIdProcessed = getAccountOrContactIdForTesting(jobType);
        configureChunkMode(jobType, chunkSize);

        Id nextIdToBeProcessed = getAccountOrContactIdForTesting(jobType);
        Opportunity opportunityForAdditionalAccount = new Opportunity(
                AccountId = nextIdToBeProcessed,
                StageName = 'Open',
                CloseDate = date.today(), name = 'test');
        insert opportunityForAdditionalAccount;

        // With chunk mode enabled, the second and subsequent jobs are constructed with
        // the lastProcessedId constructor, passing in the Id to use in the start query.
        CRLP_Batch_Base_NonSkew accountBatchJob = getBatchJobInstanceWithData(
                jobType,
                lastIdProcessed);

        System.assert(accountBatchJob.hasAdditionalRecordsToProcess(lastIdProcessed),
            'hasAdditionalRecordsToProcess should be true, ' +
                    'since the chunk size is 1 and there is another Account to process.');
    }

    @isTest
    private static void accountHardCreditRollupChunkModeFirstJobQueryContainsOrderByLimit() {
        CRLP_RollupProcessingOptions.RollupType jobType =
                CRLP_RollupProcessingOptions.RollupType.AccountHardCredit;
        Integer chunkSize = 500;
        configureChunkMode(jobType, chunkSize);

        // With chunk mode enabled, the first job is constructed with
        // the empty constructor and does not pass in a lastProcessedId.
        CRLP_Batch_Base_NonSkew accountBatchJob = getBatchJobInstanceWithData(jobType, null);

        System.assertEquals(null, accountBatchJob.lastIdProcessed,
                'chunkModeStartingId should be null for this, the first chunk mode job ' +
                        '(created using the empty constructor).');

        System.assertEquals(chunkSize, accountBatchJob.batchSizeChunkLimit,
                'batchSizeChunkLimit should equal chunkSize');

        System.assert(batchStartOuterQueryContainsOrderByAndLimit(accountBatchJob),
                'The chunk mode start query should always contain "ORDER BY" and "LIMIT".');
    }

    @isTest
    private static void accountHardCreditRollupChunkModeQueryContainsOrderByLimitId() {
        CRLP_RollupProcessingOptions.RollupType jobType =
                CRLP_RollupProcessingOptions.RollupType.AccountHardCredit;
        Integer chunkSize = 500;
        Id lastIdProcessed = getAccountOrContactIdForTesting(jobType);
        configureChunkMode(jobType, chunkSize);

        CRLP_Batch_Base_NonSkew accountBatchJob = getBatchJobInstanceWithData(
                jobType,
                lastIdProcessed);

        System.assertEquals(lastIdProcessed, accountBatchJob.lastIdProcessed,
                'chunkModeStartingId should equal testAccount.Id');

        System.assertEquals(chunkSize, accountBatchJob.batchSizeChunkLimit,
                'batchSizeChunkLimit should equal chunkSize');

        System.assert(batchStartQueryContainsChunkModeId(accountBatchJob),
                'This chunk mode query should contain " > ' + accountBatchJob.lastIdProcessed + '"');

        System.assert(batchStartOuterQueryContainsOrderByAndLimit(accountBatchJob),
                'The chunk mode start query should always contain "ORDER BY" and "LIMIT".');
    }

    @isTest
    private static void contactHardCreditRollupChunkModeFirstJobQueryContainsOrderByLimit() {
        CRLP_RollupProcessingOptions.RollupType jobType =
                CRLP_RollupProcessingOptions.RollupType.ContactHardCredit;
        Integer chunkSize = 500;
        configureChunkMode(jobType, chunkSize);

        CRLP_Batch_Base_NonSkew contactBatchJob = getBatchJobInstanceWithData(jobType, null);

        System.assertEquals(null, contactBatchJob.lastIdProcessed,
                'chunkModeStartingId should be null for this, the first chunk mode job ' +
                        '(created using the empty constructor).');

        System.assertEquals(chunkSize, contactBatchJob.batchSizeChunkLimit,
                'batchSizeChunkLimit should equal chunkSize');

        System.assert(batchStartOuterQueryContainsOrderByAndLimit(contactBatchJob),
                'The chunk mode start query should always contain "ORDER BY" and "LIMIT".');
    }

    @isTest
    private static void contactHardCreditRollupChunkModeQueryContainsOrderByLimitId() {
        CRLP_RollupProcessingOptions.RollupType jobType =
                CRLP_RollupProcessingOptions.RollupType.ContactHardCredit;
        Integer chunkSize = 500;
        Id lastIdProcessed = getAccountOrContactIdForTesting(jobType);
        configureChunkMode(jobType, chunkSize);

        CRLP_Batch_Base_NonSkew contactBatchJob = getBatchJobInstanceWithData(
                jobType,
                lastIdProcessed);

        System.assertEquals(lastIdProcessed, contactBatchJob.lastIdProcessed,
                'chunkModeStartingId should equal testAccount.Id');

        System.assertEquals(chunkSize, contactBatchJob.batchSizeChunkLimit,
                'batchSizeChunkLimit should equal chunkSize');

        System.assert(batchStartQueryContainsChunkModeId(contactBatchJob),
                'This chunk mode query should contain " > ' + contactBatchJob.lastIdProcessed + '"');

        System.assert(batchStartOuterQueryContainsOrderByAndLimit(contactBatchJob),
                'The chunk mode start query should always contain "ORDER BY" and "LIMIT".');
    }

    @isTest
    private static void contactSoftCreditRollupChunkModeFirstJobQueryContainsOrderByLimit() {
        CRLP_RollupProcessingOptions.RollupType jobType =
                CRLP_RollupProcessingOptions.RollupType.ContactSoftCredit;
        Integer chunkSize = 500;
        configureChunkMode(CRLP_RollupProcessingOptions.RollupType.ContactSoftCredit, chunkSize);

        CRLP_Batch_Base_NonSkew contactBatchJob = getBatchJobInstanceWithData(jobType, null);

        System.assertEquals(null, contactBatchJob.lastIdProcessed,
                'chunkModeStartingId should be null for this, the first chunk mode job ' +
                        '(created using the empty constructor).');

        System.assertEquals(chunkSize, contactBatchJob.batchSizeChunkLimit,
                'batchSizeChunkLimit should equal chunkSize');

        System.assert(batchStartOuterQueryContainsOrderByAndLimit(contactBatchJob),
                'The chunk mode start query should always contain "ORDER BY" and "LIMIT".');
    }

    @isTest
    private static void contactSoftCreditRollupChunkModeQueryContainsOrderByLimitId() {
        CRLP_RollupProcessingOptions.RollupType jobType =
                CRLP_RollupProcessingOptions.RollupType.ContactSoftCredit;
        Integer chunkSize = 500;
        Id chunkModeLastProcessedId = getAccountOrContactIdForTesting(jobType);
        configureChunkMode(jobType, chunkSize);

        CRLP_Batch_Base_NonSkew contactBatchJob = getBatchJobInstanceWithData(
                jobType,
                chunkModeLastProcessedId);

        System.assertEquals(chunkModeLastProcessedId, contactBatchJob.lastIdProcessed,
                'chunkModeStartingId should equal testAccount.Id');

        System.assertEquals(chunkSize, contactBatchJob.batchSizeChunkLimit,
                'batchSizeChunkLimit should equal chunkSize');

        System.assert(batchStartQueryContainsChunkModeId(contactBatchJob),
                'This chunk mode query should contain " > ' + contactBatchJob.lastIdProcessed + '"');

        System.assert(batchStartOuterQueryContainsOrderByAndLimit(contactBatchJob),
                'The chunk mode start query should always contain "ORDER BY" and "LIMIT".');
    }

    /******************************** Helper Methods *****************************/

    /**
     * @description Activates or deactivates incremental mode for a RollupType.
     * Used to test customized rollup configurations.
     * @param jobType The RollupType whose incremental mode custom setting should be configured
     * @param isIncrementalMode Whether the incremental mode settings should be activated (true)
     * or deactivated (false)
     * @return The configured Customizable_Rollup_Settings__c record
     */
    private static Customizable_Rollup_Settings__c configureIncrementalMode(
            CRLP_RollupProcessingOptions.RollupType jobType,
            Boolean isIncrementalMode) {

        Customizable_Rollup_Settings__c settings =
                getRollupSettingsForTestsCustomizableRollupsEnabled();

        switch on (jobType) {
            when AccountHardCredit {
                settings.AccountHardCreditNonSkew_Incremental__c = isIncrementalMode;
                // Create the test data
                CRLP_RollupAccount_TEST.mockRollupCMTValues();
            }
            when ContactHardCredit {
                settings.ContactHardCreditNonSkew_Incremental__c = isIncrementalMode;
                CRLP_RollupContact_TEST.mockRollupCMTValues();
            }
        }
        return settings;
    }

    /**
     * @description Configures incremental mode field override custom settings fields.
     * @param jobType The RollupType whose user defined inner join override should be configured
     * @param overrideForLastNDaysField API name of the custom field that should be used in the user-defined
     * inner join override
     * @param overrideForLastNDaysValue Value that should be used with LAST_N_DAYS: in the user-defined
     * inner join override
     */
    private static void configureIncrementalFieldOverrides(
            CRLP_RollupProcessingOptions.RollupType jobType,
            String overrideForLastNDaysField,
            Integer overrideForLastNDaysValue) {

        Customizable_Rollup_Settings__c settings = configureIncrementalMode(jobType, true);

        settings.Rollups_IncrementalLastNDays_FldOverride__c = overrideForLastNDaysField;
        settings.Rollups_IncrementalLastNDays_ValOverride__c = overrideForLastNDaysValue;
        UTIL_CustomSettingsFacade.getRollupSettingsForTests(settings);
    }

    /**
     * @description Deactivates (in memory) rollups by rollup type and time-bound operation type.
     * Used to test customized rollup configurations.
     * @param jobType The RollupType whose time-bound rollups should be deactivated
     * @param timeBoundOperationType The TimeBoundOperationType to deactivate
     */
    private static void deactivateTimeBoundRollups(
            CRLP_RollupProcessingOptions.RollupType jobType,
            CRLP_Operation.TimeBoundOperationType timeBoundOperationType) {

        for (Rollup__mdt rollup : CRLP_Rollup_SEL.cachedRollups) {
            if ((jobType == CRLP_RollupProcessingOptions.RollupType.AccountHardCredit
                    && isAccountHardCreditRollup(rollup))
                    || (jobType == CRLP_RollupProcessingOptions.RollupType.ContactHardCredit
                    && isContactHardCreditRollup(rollup))) {
                if (rollup.Time_Bound_Operation_Type__c == timeBoundOperationType.name()) {
                    rollup.Active__c = false;
                }
            }
        }
    }

    /**
     * @description Checks if the rollup is an Account Hard Credit operation
     * @param rollup The Rollup custom metadata record to evaluate
     * @return True if the rollup is an Account Hard Credit operation, else false
     */
    private static Boolean isAccountHardCreditRollup(Rollup__mdt rollup) {
        return rollup.Summary_Object__c == 'Account' && rollup.Detail_Object__c == 'Opportunity';
    }

    /**
     * @description Checks if the rollup is a Contact Hard Credit operation
     * @param rollup The Rollup custom metadata record to evaluate
     * @return True if the rollup is a Contact Hard Credit operation, else false
     */
    private static Boolean isContactHardCreditRollup(Rollup__mdt rollup) {
        return rollup.Summary_Object__c == 'Contact' && rollup.Detail_Object__c == 'Opportunity';
    }

    /**
     * @description Inner class used to calculate the maxDaysBack and maxYearsAgo values
     * for the test-configured rollups stored in memory.  Used for assertions in test methods.
     */
    private class RollupInfo {
        Integer maxDaysBackInteger = null;
        Integer maxYearsAgoInteger = null;

        RollupInfo() {
            for (Rollup__mdt rollup : CRLP_Rollup_SEL.cachedRollups) {
                if (isAccountHardCreditRollup(rollup) || isContactHardCreditRollup(rollup)) {
                    if (rollup.Time_Bound_Operation_Type__c == CRLP_Operation.TimeBoundOperationType.Years_Ago.name()
                            && (maxYearsAgoInteger == null || rollup.Integer__c > maxYearsAgoInteger)) {
                        maxYearsAgoInteger = (Integer) rollup.Integer__c;
                    } else if (rollup.Time_Bound_Operation_Type__c == CRLP_Operation.TimeBoundOperationType.Days_Back.name()
                            && (maxDaysBackInteger == null || rollup.Integer__c > maxDaysBackInteger)) {
                        maxDaysBackInteger = (Integer) rollup.Integer__c;
                    }
                }
            }
        }
    }

    /**
     * @description Configures incremental mode field override custom settings fields.
     * @param jobType RollupType for which chunk mode should be configured.
     * @param chunkSize The number of records to process in each chunk mode batch job. Used
     * in the batch start query.
     * @return The configured Customizable_Rollup_Settings__c record.
     */
    private static Customizable_Rollup_Settings__c configureChunkMode(
            CRLP_RollupProcessingOptions.RollupType jobType,
            Integer chunkSize) {

        Customizable_Rollup_Settings__c settings =
                getRollupSettingsForTestsCustomizableRollupsEnabled();

        switch on (jobType) {

            when AccountHardCredit {
                settings.ChunkSize_Account_HardCredit__c = chunkSize;
                // Create the test data
                CRLP_RollupAccount_TEST.mockRollupCMTValues();
            }

            when ContactHardCredit {
                settings.ChunkSize_Contact_HardCredit__c = chunkSize;
                CRLP_RollupContact_TEST.mockRollupCMTValues();
            }

            when ContactSoftCredit {
                settings.ChunkSize_Contact_SoftCredit__c = chunkSize;
                CRLP_RollupSoftCredit_TEST.mockRollupCMTValues();
            }
        }
        return settings;
    }

    /**
     * @description Inserts a simple Account for use in test methods
     * @return the Inserted AccountId
     */
    private static Id getAccountOrContactIdForTesting(CRLP_RollupProcessingOptions.RollupType jobType) {
        Account testAccount = new Account(Name = 'TestAccount1');
        insert testAccount;

        switch on (jobType) {
            when AccountHardCredit {
                return testAccount.Id;
            }
            when ContactHardCredit, ContactSoftCredit {
                Contact testContact = new Contact(
                        LastName='TestContact1',
                        Email='testcontact1@testemail.com',
                        AccountId = testAccount.Id
                );
                insert testContact;
                return testContact.Id;
            }
            when else {
                return null;
            }
        }
    }

    /**
     * @description Gets the query string from an instance of CRLP_Batch_Base_NonSkew and
     * checks whether it contains Order By and Limit clauses.
     * @param classInstance An instance of CRLP_Batch_Base_NonSkew class or its subclasses.
     * @return True if the query contains Order By and Limit, false otherwise.
     */
    private static Boolean batchStartOuterQueryContainsOrderByAndLimit(CRLP_Batch_Base_NonSkew classInstance) {
        return stringContainsOrderByAndLimit(
                getOuterQueryOrderByAndLimitString(
                        getBatchStartQuery(classInstance)));
    }

    /**
     * @description Gets the query string from an instance of CRLP_Batch_Base_NonSkew and
     * checks whether it contains the last processed Id for chunk mode.
     * @param classInstance An instance of CRLP_Batch_Base_NonSkew class or its subclasses.
     * @return True if the query contains the last processed Id, false otherwise.
     */
    private static Boolean batchStartQueryContainsChunkModeId(CRLP_Batch_Base_NonSkew classInstance) {
        String query = getBatchStartQuery(classInstance);
        return query.contains(' > \'' + classInstance.lastIdProcessed + '\'');
    }

    /**
     * @description Calls getBatchStartQuery on an instance of CRLP_Batch_Base_NonSkew class or its subclasses.
     * @param classInstance An instance of CRLP_Batch_Base_NonSkew class or its subclasses.
     * @return The batch Start query string.
     */
    private static String getBatchStartQuery(CRLP_Batch_Base_NonSkew classInstance) {
        return classInstance.getBatchStartQuery(
                classInstance.lastIdProcessed,
                classInstance.batchSizeChunkLimit,
                classInstance.fieldsToCheckForNonZero
        );
    }

    /**
     * @description Checks if a string contains Order By and Limit.
     * @param queryString The string to analyze.
     * @return True if the string contains Order By and Limit, false otherwise.
     */
    private static Boolean stringContainsOrderByAndLimit(String queryString) {
        return String.isNotBlank(queryString) ?
                (queryString.contains('ORDER BY')
                        && queryString.contains('LIMIT')) : false;
    }

    /**
     * @description returns the last part of the outer query, used to test for the
     * presence of ORDER BY and LIMIT clauses.
     * @param query The query string to analyze.
     * @return A string that represents the characters to the right of the final ")" in
     * the query.  Null if there are no characters right of the last ")".
     */
    private static String getOuterQueryOrderByAndLimitString(String query){
        Integer i = query.lastIndexOf(')');
        String outerQueryOrderByAndLimitString = query.right(query.length() - i - 1);
        return outerQueryOrderByAndLimitString;
    }

    /**
     * @description Gets the Rollup Settings to be used for testing with Customizable
     * Rollups enabled.
     * @return The Customizable Rollups Custom Settings with Customizable Rollups enabled.
     */
    private static Customizable_Rollup_Settings__c getRollupSettingsForTestsCustomizableRollupsEnabled() {
        return UTIL_CustomSettingsFacade.getRollupSettingsForTests(
                new Customizable_Rollup_Settings__c (
                        Customizable_Rollups_Enabled__c = true
                ));
    }

    /**
     * @description Utility used to initialize an instance of the Non-Skew Batch Job for a
     * Rollup Type, and initialize its job data.
     * @param jobType The RollupType of the class instance to create.
     * @param chunkModeLastProcessedId An Id that is passed to the class instance for use in the
     * start method query when in chunk mode.
     * @return An instance of the CRLP_Batch_Base_NonSkew class.
     */
    private static CRLP_Batch_Base_NonSkew getBatchJobInstanceWithData(
            CRLP_RollupProcessingOptions.RollupType jobType,
            Id chunkModeLastProcessedId
    ) {
        CRLP_Batch_Base_NonSkew instance;
        switch on (jobType) {
            when AccountHardCredit {
                instance = chunkModeLastProcessedId == null ?
                        new CRLP_Account_BATCH() :
                        new CRLP_Account_BATCH(chunkModeLastProcessedId);
            }
            when ContactHardCredit {
                instance = chunkModeLastProcessedId == null ?
                        new CRLP_Contact_BATCH() :
                        new CRLP_Contact_BATCH(chunkModeLastProcessedId);
            }
            when ContactSoftCredit {
                instance = chunkModeLastProcessedId == null ?
                        new CRLP_Contact_SoftCredit_BATCH() :
                        new CRLP_Contact_SoftCredit_BATCH(chunkModeLastProcessedId);
            }
        }
        return instance;
    }

}