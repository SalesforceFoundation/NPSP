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

    @isTest
    private static void accountHardCreditRollupGeneratesStandardJoinQueryWhenNotScheduledJob() {
        configureIncrementalMode(CRLP_RollupProcessingOptions.RollupType.AccountHardCredit, true);

        CRLP_Account_BATCH accountBatchJob = new CRLP_Account_BATCH(new List<Id>());
        accountBatchJob.initializeJobData();

        String whereClause = accountBatchJob.getMainQueryInnerJoinFilter();
        System.assert(whereClause.contains('WHERE') == false, 'The standard query for the inner join ' +
                'should NOT contain a where filter on the Opportunities when not a scheduled job.');
    }

    @isTest
    private static void accountHardCreditRollupGeneratesIncrementalModeJoinQuery() {
        configureIncrementalMode(CRLP_RollupProcessingOptions.RollupType.AccountHardCredit, true);

        CRLP_Account_BATCH accountBatchJob = new CRLP_Account_BATCH(new List<Id>());
        accountBatchJob.initializeJobData();
        accountBatchJob.isScheduledJob = true; // Set the Batch Base isScheduledJob flag to true.
        // This is necessary because the Schedulable Job constructs and submits a separate instance of the
        // CRLP_Account_BATCH class.  So we "mock" the isScheduledJob value here, to test the correct
        // response from the getWhereClause() method below.

        String generatedWhereClause = accountBatchJob.getMainQueryInnerJoinFilter();
        System.assert(generatedWhereClause.contains('FROM'));
        System.assert(generatedWhereClause.contains('WHERE'), 'The incremental mode ' +
                'where clause for the inner join should contain a where filter on the Opportunities.');
        System.assert(generatedWhereClause.contains('LAST_N_YEARS:' + new RollupInfo().maxYearsAgoInteger));
    }

    @isTest
    private static void accountHardCreditRollupGeneratesLastNDaysJoinQuery() {
        configureIncrementalMode(CRLP_RollupProcessingOptions.RollupType.AccountHardCredit, true);

        deactivateTimeBoundRollups(
                CRLP_RollupProcessingOptions.RollupType.AccountHardCredit,
                CRLP_Operation.TimeBoundOperationType.Years_Ago);

        CRLP_Account_BATCH accountBatchJob = new CRLP_Account_BATCH(new List<Id>());
        accountBatchJob.initializeJobData();
        accountBatchJob.isScheduledJob = true;

        String generatedWhereClause = accountBatchJob.getMainQueryInnerJoinFilter();
        System.assert(generatedWhereClause.contains('WHERE'), 'The incremental mode ' +
                'where clause for the inner join should contain a where filter on the Opportunities.');
        System.assert(generatedWhereClause.contains('LAST_N_DAYS:' + new RollupInfo().maxDaysBackInteger));
    }

    @isTest
    private static void accountHardCreditRollupGeneratesLastNYearsJoinQuery() {
        configureIncrementalMode(CRLP_RollupProcessingOptions.RollupType.AccountHardCredit, true);

        deactivateTimeBoundRollups(
                CRLP_RollupProcessingOptions.RollupType.AccountHardCredit,
                CRLP_Operation.TimeBoundOperationType.Days_Back);

        CRLP_Account_BATCH accountBatchJob = new CRLP_Account_BATCH(new List<Id>());
        accountBatchJob.initializeJobData();
        accountBatchJob.isScheduledJob = true;

        String generatedWhereClause = accountBatchJob.getMainQueryInnerJoinFilter();
        System.assert(generatedWhereClause.contains('WHERE'), 'The incremental mode ' +
                'where clause for the inner join should contain a where filter on the Opportunities.');
        Integer lastNYears = new RollupInfo().maxYearsAgoInteger;
        System.assert(generatedWhereClause.contains('LAST_N_YEARS:' + lastNYears));
    }

    @isTest
    private static void accountHardCreditRollupGeneratesLastNDaysJoinQueryWithCustomSettingFalse() {
        configureIncrementalMode(CRLP_RollupProcessingOptions.RollupType.AccountHardCredit, false);

        CRLP_Account_BATCH accountBatchJob = new CRLP_Account_BATCH(new List<Id>());
        accountBatchJob.initializeJobData();
        accountBatchJob.isScheduledJob = true;

        String whereClause = accountBatchJob.getMainQueryInnerJoinFilter();
        System.assert(whereClause.contains('WHERE') == false, 'The standard where clause should be used ' +
                'for the inner join when the custom setting is set to false.');
    }

    @isTest
    private static void contactHardCreditRollupGeneratesStandardJoinQueryWhenNotScheduledJob() {
        configureIncrementalMode(CRLP_RollupProcessingOptions.RollupType.ContactHardCredit, true);

        CRLP_Contact_BATCH contactBatchJob = new CRLP_Contact_BATCH(new List<Id>());
        contactBatchJob.initializeJobData();

        String whereClause = contactBatchJob.getMainQueryInnerJoinFilter();
        System.assert(whereClause.contains('WHERE') == false, 'The standard query for the inner join ' +
                'should NOT contain a where filter on the Opportunities when not a scheduled job.');
    }

    @isTest
    private static void contactHardCreditRollupGeneratesIncrementalModeJoinQuery() {
        configureIncrementalMode(CRLP_RollupProcessingOptions.RollupType.ContactHardCredit, true);

        CRLP_Contact_BATCH contactBatchJob = new CRLP_Contact_BATCH(new List<Id>());
        contactBatchJob.initializeJobData();
        contactBatchJob.isScheduledJob = true;

        String generatedWhereClause = contactBatchJob.getMainQueryInnerJoinFilter();
        System.assert(generatedWhereClause.contains('FROM'));
        System.assert(generatedWhereClause.contains('WHERE'), 'The incremental mode ' +
                'where clause for the inner join should contain a where filter on the Opportunities.');
        System.assert(generatedWhereClause.contains('LAST_N_YEARS:' + new RollupInfo().maxYearsAgoInteger));
    }

    @isTest
    private static void contactHardCreditRollupGeneratesLastNDaysJoinQuery() {
        configureIncrementalMode(CRLP_RollupProcessingOptions.RollupType.ContactHardCredit, true);

        deactivateTimeBoundRollups(
                CRLP_RollupProcessingOptions.RollupType.ContactHardCredit,
                CRLP_Operation.TimeBoundOperationType.Years_Ago);

        CRLP_Contact_BATCH contactBatchJob = new CRLP_Contact_BATCH(new List<Id>());
        contactBatchJob.initializeJobData();
        contactBatchJob.isScheduledJob = true;

        String generatedWhereClause = contactBatchJob.getMainQueryInnerJoinFilter();
        System.assert(generatedWhereClause.contains('WHERE'), 'The incremental mode ' +
                'where clause for the inner join should contain a where filter on the Opportunities.');
        System.assert(generatedWhereClause.contains('LAST_N_DAYS:' + new RollupInfo().maxDaysBackInteger));
    }

    @isTest
    private static void contactHardCreditRollupGeneratesLastNYearsJoinQuery() {
        configureIncrementalMode(CRLP_RollupProcessingOptions.RollupType.ContactHardCredit, true);

        deactivateTimeBoundRollups(
                CRLP_RollupProcessingOptions.RollupType.ContactHardCredit,
                CRLP_Operation.TimeBoundOperationType.Days_Back);

        CRLP_Contact_BATCH contactBatchJob = new CRLP_Contact_BATCH(new List<Id>());
        contactBatchJob.initializeJobData();
        contactBatchJob.isScheduledJob = true;

        String generatedWhereClause = contactBatchJob.getMainQueryInnerJoinFilter();
        System.assert(generatedWhereClause.contains('WHERE'), 'The incremental mode ' +
                'where clause for the inner join should contain a where filter on the Opportunities.');
        Integer lastNYears = new RollupInfo().maxYearsAgoInteger;
        System.assert(generatedWhereClause.contains('LAST_N_YEARS:' + lastNYears));
    }

    @isTest
    private static void contactHardCreditRollupGeneratesLastNDaysJoinQueryWithCustomSettingFalse() {
        configureIncrementalMode(CRLP_RollupProcessingOptions.RollupType.ContactHardCredit, false);

        CRLP_Contact_BATCH contactBatchJob = new CRLP_Contact_BATCH(new List<Id>());
        contactBatchJob.initializeJobData();
        contactBatchJob.isScheduledJob = true;

        String whereClause = contactBatchJob.getMainQueryInnerJoinFilter();
        System.assert(whereClause.contains('WHERE') == false, 'The standard where clause should be used ' +
                'for the inner join when the custom setting is set to false.');
    }

    @isTest
    private static void accountHardCreditRollupWithUserDefinedJoinGeneratesProperJoinQuery() {
        String userDefinedLastNDaysFieldOverride = 'LastModifiedDate';
        Integer userDefinedLastNDaysValueOverride = 44;
        configureIncrementalFieldOverrides(
                CRLP_RollupProcessingOptions.RollupType.AccountHardCredit,
                userDefinedLastNDaysFieldOverride,
                userDefinedLastNDaysValueOverride);

        CRLP_Account_BATCH accountBatchJob = new CRLP_Account_BATCH(new List<Id>());
        accountBatchJob.initializeJobData();
        accountBatchJob.isScheduledJob = true;

        String generatedWhereClause = accountBatchJob.getMainQueryInnerJoinFilter();
        System.assert(generatedWhereClause.contains('WHERE'), 'The incremental mode ' +
                'where clause for the inner join should contain a where filter on the Opportunities.');
        System.assert(generatedWhereClause.contains(userDefinedLastNDaysFieldOverride));
        System.assert(generatedWhereClause.contains(String.valueOf(userDefinedLastNDaysValueOverride)));
    }

    @isTest
    private static void contactHardCreditRollupWithUserDefinedJoinGeneratesProperJoinQuery() {
        String userDefinedLastNDaysFieldOverride = 'LastModifiedDate';
        Integer userDefinedLastNDaysValueOverride = 555;
        configureIncrementalFieldOverrides(
                CRLP_RollupProcessingOptions.RollupType.ContactHardCredit,
                userDefinedLastNDaysFieldOverride,
                userDefinedLastNDaysValueOverride);

        CRLP_Contact_BATCH contactBatchJob = new CRLP_Contact_BATCH(new List<Id>());
        contactBatchJob.initializeJobData();
        contactBatchJob.isScheduledJob = true;

        String generatedWhereClause = contactBatchJob.getMainQueryInnerJoinFilter();
        System.assert(generatedWhereClause.contains('WHERE'), 'The incremental mode ' +
                'where clause for the inner join should contain a where filter on the Opportunities.');
        System.assert(generatedWhereClause.contains(userDefinedLastNDaysFieldOverride));
        System.assert(generatedWhereClause.contains(String.valueOf(userDefinedLastNDaysValueOverride)));
    }

    @isTest
    private static void accountHardCreditRollupChunkModeFirstJobQueryContainsOrderByLimit() {
        Integer chunkSize = 500;
        configureChunkMode(CRLP_RollupProcessingOptions.RollupType.AccountHardCredit, chunkSize);

        CRLP_Account_BATCH accountBatchJob = new CRLP_Account_BATCH();
        accountBatchJob.initializeJobData();

        String query = accountBatchJob.getBatchStartQuery(
                accountBatchJob.chunkModeLastProcessedId,
                accountBatchJob.batchSizeChunkLimit,
                accountBatchJob.fieldsToCheckForNonZero
        );

        System.assertEquals(null, accountBatchJob.chunkModeLastProcessedId,
                'chunkModeStartingId should be null for this, the first chunk mode job ' +
                        '(created using the empty constructor).');

        System.assert(query.contains('ORDER BY Id'),
                'All chunk mode queries should contain "ORDER BY Id"');

        System.assertEquals(chunkSize, accountBatchJob.batchSizeChunkLimit,
                'batchSizeChunkLimit should equal chunkSize');

        System.assert(query.contains('LIMIT ' + chunkSize),
                'All chunk mode queries should contain chunk size "LIMIT ' + chunkSize + '"');
    }

    @isTest
    private static void accountHardCreditRollupChunkModeQueryContainsOrderByLimitId() {
        CRLP_RollupProcessingOptions.RollupType jobType =
                CRLP_RollupProcessingOptions.RollupType.AccountHardCredit;
        Integer chunkSize = 500;
        Id chunkModeLastProcessedId = getAccountOrContactIdForTesting(jobType);
        configureChunkMode(jobType, chunkSize);

        CRLP_Account_BATCH accountBatchJob = new CRLP_Account_BATCH(chunkModeLastProcessedId);
        accountBatchJob.initializeJobData();

        String query = accountBatchJob.getBatchStartQuery(
                accountBatchJob.chunkModeLastProcessedId,
                accountBatchJob.batchSizeChunkLimit,
                accountBatchJob.fieldsToCheckForNonZero
        );

        System.assertEquals(chunkModeLastProcessedId, accountBatchJob.chunkModeLastProcessedId,
                'chunkModeStartingId should equal testAccount.Id');

        System.assert(query.contains(' > \'' + accountBatchJob.chunkModeLastProcessedId + '\''),
                'This chunk mode query should contain " > ' + accountBatchJob.chunkModeLastProcessedId + '"');

        System.assert(query.contains('ORDER BY Id'),
                'All chunk mode queries should contain "ORDER BY Id"');

        System.assertEquals(chunkSize, accountBatchJob.batchSizeChunkLimit,
                'batchSizeChunkLimit should equal chunkSize');

        System.assert(query.contains('LIMIT ' + chunkSize),
                'All chunk mode queries should contain "LIMIT ' + chunkSize + '"');
    }

    @isTest
    private static void contactHardCreditRollupChunkModeFirstJobQueryContainsOrderByLimit() {
        Integer chunkSize = 500;
        configureChunkMode(CRLP_RollupProcessingOptions.RollupType.ContactHardCredit, chunkSize);

        CRLP_Contact_BATCH contactBatchJob = new CRLP_Contact_BATCH();
        contactBatchJob.initializeJobData();

        String query = contactBatchJob.getBatchStartQuery(
                contactBatchJob.chunkModeLastProcessedId,
                contactBatchJob.batchSizeChunkLimit,
                contactBatchJob.fieldsToCheckForNonZero
        );

        System.assertEquals(null, contactBatchJob.chunkModeLastProcessedId,
                'chunkModeStartingId should be null for this, the first chunk mode job ' +
                        '(created using the empty constructor).');

        System.assert(query.contains('ORDER BY Id'),
                'All chunk mode queries should contain "ORDER BY Id"');

        System.assertEquals(chunkSize, contactBatchJob.batchSizeChunkLimit,
                'batchSizeChunkLimit should equal chunkSize');

        System.assert(query.contains('LIMIT ' + chunkSize),
                'All chunk mode queries should contain chunk size "LIMIT ' + chunkSize + '"');
    }

    @isTest
    private static void contactHardCreditRollupChunkModeQueryContainsOrderByLimitId() {
        CRLP_RollupProcessingOptions.RollupType jobType =
                CRLP_RollupProcessingOptions.RollupType.ContactHardCredit;
        Integer chunkSize = 500;
        Id chunkModeLastProcessedId = getAccountOrContactIdForTesting(jobType);
        configureChunkMode(jobType, chunkSize);

        CRLP_Contact_BATCH contactBatchJob = new CRLP_Contact_BATCH(chunkModeLastProcessedId);
        contactBatchJob.initializeJobData();

        String query = contactBatchJob.getBatchStartQuery(
                contactBatchJob.chunkModeLastProcessedId,
                contactBatchJob.batchSizeChunkLimit,
                contactBatchJob.fieldsToCheckForNonZero
        );

        System.assertEquals(chunkModeLastProcessedId, contactBatchJob.chunkModeLastProcessedId,
                'chunkModeStartingId should equal testAccount.Id');

        System.assert(query.contains(' > \'' + contactBatchJob.chunkModeLastProcessedId + '\''),
                'This chunk mode query should contain " > ' + contactBatchJob.chunkModeLastProcessedId + '"');

        System.assert(query.contains('ORDER BY Id'),
                'All chunk mode queries should contain "ORDER BY Id"');

        System.assertEquals(chunkSize, contactBatchJob.batchSizeChunkLimit,
                'batchSizeChunkLimit should equal chunkSize');

        System.assert(query.contains('LIMIT ' + chunkSize),
                'All chunk mode queries should contain "LIMIT ' + chunkSize + '"');
    }

    @isTest
    private static void contactSoftCreditRollupChunkModeFirstJobQueryContainsOrderByLimit() {
        Integer chunkSize = 500;
        configureChunkMode(CRLP_RollupProcessingOptions.RollupType.ContactSoftCredit, chunkSize);

        CRLP_Contact_SoftCredit_BATCH contactBatchJob = new CRLP_Contact_SoftCredit_BATCH();
        contactBatchJob.initializeJobData();

        String query = contactBatchJob.getBatchStartQuery(
                contactBatchJob.chunkModeLastProcessedId,
                contactBatchJob.batchSizeChunkLimit,
                contactBatchJob.fieldsToCheckForNonZero
        );

        System.assertEquals(null, contactBatchJob.chunkModeLastProcessedId,
                'chunkModeStartingId should be null for this, the first chunk mode job ' +
                        '(created using the empty constructor).');

        System.assert(query.contains('ORDER BY Id'),
                'All chunk mode queries should contain "ORDER BY Id"');

        System.assertEquals(chunkSize, contactBatchJob.batchSizeChunkLimit,
                'batchSizeChunkLimit should equal chunkSize');

        System.assert(query.contains('LIMIT ' + chunkSize),
                'All chunk mode queries should contain chunk size "LIMIT ' + chunkSize + '"');
    }

    @isTest
    private static void contactSoftCreditRollupChunkModeQueryContainsOrderByLimitId() {
        CRLP_RollupProcessingOptions.RollupType jobType =
                CRLP_RollupProcessingOptions.RollupType.ContactSoftCredit;
        Integer chunkSize = 500;
        Id chunkModeLastProcessedId = getAccountOrContactIdForTesting(jobType);
        configureChunkMode(jobType, chunkSize);

        CRLP_Contact_SoftCredit_BATCH contactBatchJob =
                new CRLP_Contact_SoftCredit_BATCH(chunkModeLastProcessedId);
        contactBatchJob.initializeJobData();

        String query = contactBatchJob.getBatchStartQuery(
                contactBatchJob.chunkModeLastProcessedId,
                contactBatchJob.batchSizeChunkLimit,
                contactBatchJob.fieldsToCheckForNonZero
        );

        System.debug(LoggingLevel.ERROR, '*** variable value: ' + query);
        System.assertEquals(chunkModeLastProcessedId, contactBatchJob.chunkModeLastProcessedId,
                'chunkModeStartingId should equal testAccount.Id');

        System.assert(query.contains(' > \'' + contactBatchJob.chunkModeLastProcessedId + '\''),
                'This chunk mode query should contain " > ' + contactBatchJob.chunkModeLastProcessedId + '"');

        System.assert(query.contains('ORDER BY Id'),
                'All chunk mode queries should contain "ORDER BY Id"');

        System.assertEquals(chunkSize, contactBatchJob.batchSizeChunkLimit,
                'batchSizeChunkLimit should equal chunkSize');

        System.assert(query.contains('LIMIT ' + chunkSize),
                'All chunk mode queries should contain "LIMIT ' + chunkSize + '"');
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

        Customizable_Rollup_Settings__c settings = UTIL_CustomSettingsFacade.getRollupSettingsForTests(
                new Customizable_Rollup_Settings__c (
                        Customizable_Rollups_Enabled__c = true
                ));

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

        Customizable_Rollup_Settings__c settings = UTIL_CustomSettingsFacade.getRollupSettingsForTests(
                new Customizable_Rollup_Settings__c (
                        Customizable_Rollups_Enabled__c = true,
                        Rollups_Limit_on_Attached_Opps_for_Skew__c = 200
                ));

        switch on (jobType) {

            when AccountHardCredit {
                settings.Rollups_Account_HardCredit_ChunkSize__c = chunkSize;
                // Create the test data
                CRLP_RollupAccount_TEST.mockRollupCMTValues();
            }

            when ContactHardCredit {
                settings.Rollups_Contact_HardCredit_ChunkSize__c = chunkSize;
                CRLP_RollupContact_TEST.mockRollupCMTValues();
            }

            when ContactSoftCredit {
                settings.Rollups_Contact_SoftCredit_ChunkSize__c = chunkSize;
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

}