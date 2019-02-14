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
@IsTest (isParallel=true)
private class CRLP_Batch_Base_TEST {

    @isTest
    private static void testAccountHardCreditGetWhereClause_Standard(){
        configureIncrementalMode(CRLP_RollupProcessingOptions.RollupType.AccountHardCredit, true);

        // Create the test data
        CRLP_RollupAccount_TEST.mockRollupCMTValues();

        CRLP_Account_BATCH accountBatchJob = new CRLP_Account_BATCH(new List<Id>());
        accountBatchJob.initializeJobData();

        String whereClause = accountBatchJob.getWhereClause();
        System.assert(whereClause.contains('WHERE') == false, 'The standard where clause for the inner join ' +
                'should NOT contain a where filter on the Opportunities.');
    }

    @isTest
    private static void testAccountHardCreditGetWhereClause_IncrementalMode(){
        configureIncrementalMode(CRLP_RollupProcessingOptions.RollupType.AccountHardCredit, true);

        // Create the test data
        CRLP_RollupAccount_TEST.mockRollupCMTValues();

        CRLP_Account_BATCH accountBatchJob = new CRLP_Account_BATCH(new List<Id>());
        accountBatchJob.initializeJobData();
        accountBatchJob.isScheduledJob = true; // Set the Batch Base isScheduledJob flag to true.
        // This is necessary because the Schedulable Job constructs and submits a separate instance of the
        // CRLP_Account_BATCH class.  So we "mock" the isScheduledJob value here, to test the correct
        // response from the getWhereClause() method below.

        String generatedWhereClause = accountBatchJob.getWhereClause();
        System.assert(generatedWhereClause.contains('FROM'));
        System.assert(generatedWhereClause.contains('WHERE'), 'The incremental mode ' +
                'where clause for the inner join should contain a where filter on the Opportunities.');
        System.assert(generatedWhereClause.contains('LAST_N_YEARS:' + 
                new RollupInfo(CRLP_RollupProcessingOptions.RollupType.AccountHardCredit).maxYearsAgoInteger));
    }

    @isTest
    private static void testAccountHardCreditGetWhereClause_IncrementalMode_DaysOnly() {
        configureIncrementalMode(CRLP_RollupProcessingOptions.RollupType.AccountHardCredit, true);

        // Create the test data
        CRLP_RollupAccount_TEST.mockRollupCMTValues();

        deactivateTimeBoundRollups(
                CRLP_RollupProcessingOptions.RollupType.AccountHardCredit,
                CRLP_Operation.TimeBoundOperationType.Years_Ago);

        CRLP_Account_Batch accountBatchJob = new CRLP_Account_Batch(new List<Id>());
        accountBatchJob.initializeJobData();
        accountBatchJob.isScheduledJob = true;

        String generatedWhereClause = accountBatchJob.getWhereClause();
        System.assert(generatedWhereClause.contains('WHERE'), 'The incremental mode ' +
                'where clause for the inner join should contain a where filter on the Opportunities.');
        System.assert(generatedWhereClause.contains('LAST_N_DAYS:' +
                new RollupInfo(CRLP_RollupProcessingOptions.RollupType.AccountHardCredit).maxDaysBackInteger));
    }

    @isTest
    private static void testAccountHardCreditGetWhereClause_IncrementalMode_YearsOnly() {
        configureIncrementalMode(CRLP_RollupProcessingOptions.RollupType.AccountHardCredit, true);

        // Create the test data
        CRLP_RollupAccount_TEST.mockRollupCMTValues();

        deactivateTimeBoundRollups(
                CRLP_RollupProcessingOptions.RollupType.AccountHardCredit,
                CRLP_Operation.TimeBoundOperationType.Days_Back);

        CRLP_Account_Batch accountBatchJob = new CRLP_Account_Batch(new List<Id>());
        accountBatchJob.initializeJobData();
        accountBatchJob.isScheduledJob = true;

        String generatedWhereClause = accountBatchJob.getWhereClause();
        System.assert(generatedWhereClause.contains('WHERE'), 'The incremental mode ' +
                'where clause for the inner join should contain a where filter on the Opportunities.');
        Integer lastNYears =
                new RollupInfo(CRLP_RollupProcessingOptions.RollupType.AccountHardCredit).maxYearsAgoInteger;
        System.assert(generatedWhereClause.contains('LAST_N_YEARS:' + lastNYears));
    }

    @isTest
    private static void testAccountHardCreditGetWhereClause_IncrementalMode_CustomSettingFalse() {
        configureIncrementalMode(CRLP_RollupProcessingOptions.RollupType.AccountHardCredit, false);

        // Create the test data
        CRLP_RollupAccount_TEST.mockRollupCMTValues();

        CRLP_Account_BATCH accountBatchJob = new CRLP_Account_BATCH(new List<Id>());
        accountBatchJob.initializeJobData();
        accountBatchJob.isScheduledJob = true;

        String whereClause = accountBatchJob.getWhereClause();
        System.assert(whereClause.contains('WHERE') == false, 'The standard where clause should be used ' +
                'for the inner join when the custom setting is set to false.');
    }


    @isTest
    private static void testContactHardCreditGetWhereClause_IncrementalMode() {
        configureIncrementalMode(CRLP_RollupProcessingOptions.RollupType.ContactHardCredit, true);

        // Create the test data
        CRLP_RollupContact_TEST.mockRollupCMTValues();

        CRLP_Contact_BATCH contactBatchJob = new CRLP_Contact_BATCH(new List<Id>());
        contactBatchJob.initializeJobData();
        contactBatchJob.isScheduledJob = true;

        String generatedWhereClause = contactBatchJob.getWhereClause();
        System.assert(generatedWhereClause.contains('WHERE'), 'The incremental mode ' +
                'where clause for the inner join should contain a where filter on the Opportunities.');
        System.assert(generatedWhereClause.contains('LAST_N_YEARS:' +
                new RollupInfo(CRLP_RollupProcessingOptions.RollupType.ContactHardCredit).maxYearsAgoInteger));
    }

    @isTest
    private static void testContactHardCreditGetWhereClause_IncrementalMode_DaysOnly() {
        configureIncrementalMode(CRLP_RollupProcessingOptions.RollupType.ContactHardCredit, true);

        // Create the test data
        CRLP_RollupContact_TEST.mockRollupCMTValues();

        deactivateTimeBoundRollups(
                CRLP_RollupProcessingOptions.RollupType.ContactHardCredit,
                CRLP_Operation.TimeBoundOperationType.Years_Ago);

        CRLP_Contact_BATCH contactBatchJob = new CRLP_Contact_BATCH(new List<Id>());
        contactBatchJob.initializeJobData();
        contactBatchJob.isScheduledJob = true;

        String generatedWhereClause = contactBatchJob.getWhereClause();
        System.assert(generatedWhereClause.contains('WHERE'), 'The incremental mode ' +
                'where clause for the inner join should contain a where filter on the Opportunities.');
        System.assert(generatedWhereClause.contains('LAST_N_DAYS:' +
                new RollupInfo(CRLP_RollupProcessingOptions.RollupType.ContactHardCredit).maxDaysBackInteger));
    }

    @isTest
    private static void testContactHardCreditGetWhereClause_IncrementalMode_YearsOnly() {
        configureIncrementalMode(CRLP_RollupProcessingOptions.RollupType.ContactHardCredit, true);

        // Create the test data
        CRLP_RollupContact_TEST.mockRollupCMTValues();

        deactivateTimeBoundRollups(
                CRLP_RollupProcessingOptions.RollupType.ContactHardCredit,
                CRLP_Operation.TimeBoundOperationType.Days_Back);

        CRLP_Contact_BATCH contactBatchJob = new CRLP_Contact_BATCH(new List<Id>());
        contactBatchJob.initializeJobData();
        contactBatchJob.isScheduledJob = true;

        String generatedWhereClause = contactBatchJob.getWhereClause();
        System.assert(generatedWhereClause.contains('WHERE'), 'The incremental mode ' +
        'where clause for the inner join should contain a where filter on the Opportunities.');
        Integer lastNYears =
                new RollupInfo(CRLP_RollupProcessingOptions.RollupType.ContactHardCredit).maxYearsAgoInteger;
        System.assert(generatedWhereClause.contains('LAST_N_YEARS:' + lastNYears));
    }

    @isTest
    private static void testContactHardCreditGetWhereClause_IncrementalMode_CustomSettingFalse() {
        configureIncrementalMode(CRLP_RollupProcessingOptions.RollupType.ContactHardCredit, false);

        // Create the test data
        CRLP_RollupContact_TEST.mockRollupCMTValues();

        CRLP_Contact_BATCH contactBatchJob = new CRLP_Contact_BATCH(new List<Id>());
        contactBatchJob.initializeJobData();
        contactBatchJob.isScheduledJob = true;

        String whereClause = contactBatchJob.getWhereClause();
        System.assert(whereClause.contains('WHERE') == false, 'The standard where clause should be used ' +
                'for the inner join when the custom setting is set to false.');
    }

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

    private static void configureIncrementalMode(CRLP_RollupProcessingOptions.RollupType jobType, Boolean isIncrementalMode) {
        if (jobType == CRLP_RollupProcessingOptions.RollupType.AccountHardCredit) {
            UTIL_CustomSettingsFacade.getRollupSettingsForTests(new Customizable_Rollup_Settings__c (
                    Customizable_Rollups_Enabled__c = true,
                    AccountHardCreditNonSkew_Incremental__c = isIncrementalMode
            ));
        } else if (jobType == CRLP_RollupProcessingOptions.RollupType.ContactHardCredit) {
            UTIL_CustomSettingsFacade.getRollupSettingsForTests(new Customizable_Rollup_Settings__c (
                    Customizable_Rollups_Enabled__c = true,
                    ContactHardCreditNonSkew_Incremental__c = isIncrementalMode
            ));
        }
    }

    private class RollupInfo {
        Integer maxDaysBackInteger = null;
        Integer maxYearsAgoInteger = null;

        RollupInfo(CRLP_RollupProcessingOptions.RollupType jobType) {
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

    private static Boolean isAccountHardCreditRollup(Rollup__mdt rollup) {
        return rollup.Summary_Object__c == 'Account' && rollup.Detail_Object__c == 'Opportunity';
    }

    private static Boolean isContactHardCreditRollup(Rollup__mdt rollup) {
        return rollup.Summary_Object__c == 'Contact' && rollup.Detail_Object__c == 'Opportunity';
    }
}