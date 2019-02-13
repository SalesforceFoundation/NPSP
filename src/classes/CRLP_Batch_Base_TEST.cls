/**
 * Created by kenneth.lewis on 2019-02-13.
 */

@IsTest
private class CRLP_Batch_Base_TEST {

    @isTest
    private static void testAccountHardCreditGetWhereClause_Standard(){
        // Start by enabling Customizable Rollups and setting the incremental mode
        UTIL_CustomSettingsFacade.getRollupSettingsForTests(new Customizable_Rollup_Settings__c (
                Customizable_Rollups_Enabled__c = true,
                AccountHardCreditNonSkew_Incremental__c = true
        ));

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
        // Start by enabling Customizable Rollups and setting the incremental mode
        UTIL_CustomSettingsFacade.getRollupSettingsForTests(new Customizable_Rollup_Settings__c (
                Customizable_Rollups_Enabled__c = true,
                AccountHardCreditNonSkew_Incremental__c = true // Set the custom setting value to true
        ));

        // Create the test data
        CRLP_RollupAccount_TEST.mockRollupCMTValues();

        // Get the max Days_Ago and Years_Back to use in assertions below.
        Integer maxDaysBackInteger = 0;
        Integer maxYearsAgoInteger = 0;
        for (Rollup__mdt rollup : CRLP_Rollup_SEL.cachedRollups) {
            if (rollup.Summary_Object__c != 'Account' ||
                    rollup.Detail_Object__c != 'Opportunity') {
                continue;
            }
            if (rollup.Time_Bound_Operation_Type__c == 'Years_Ago'
                    && rollup.Integer__c > maxYearsAgoInteger) {
                maxYearsAgoInteger = (Integer) rollup.Integer__c;
            } else if (rollup.Time_Bound_Operation_Type__c == 'Days_Back'
                    && rollup.Integer__c > maxDaysBackInteger) {
                maxDaysBackInteger = (Integer) rollup.Integer__c;
            }
        }

        CRLP_Account_BATCH accountBatchJob = new CRLP_Account_BATCH(new List<Id>());
        accountBatchJob.initializeJobData();
        accountBatchJob.isScheduledJob = true; // Set the Batch Base isScheduledJob flag to true.
        // This is necessary because the Schedulable Job constructs and submits a separate instance of the
        // CRLP_Account_BATCH class.  So we "mock" the isScheduledJob value here, to test the correct
        // response from the getWhereClause() method below.

        String partialDetailObjectWhereClause = 'FROM Opportunity ALLROWS ' +
                'WHERE CloseDate >= LAST_N_DAYS:' + maxDaysBackInteger + ' ' +
                'OR CloseDate >= LAST_N_YEARS:' + maxYearsAgoInteger + ')';

        String generatedWhereClause = accountBatchJob.getWhereClause();
        System.assert(generatedWhereClause.contains(partialDetailObjectWhereClause) == true, 'The incremental mode ' +
                'where clause for the inner join should contain a where filter on the Opportunities.');
    }

    @isTest
    private static void testAccountHardCreditGetWhereClause_IncrementalMode_DaysOnly() {
        // Start by enabling Customizable Rollups and setting the incremental mode
        UTIL_CustomSettingsFacade.getRollupSettingsForTests(new Customizable_Rollup_Settings__c (
                Customizable_Rollups_Enabled__c = true,
                AccountHardCreditNonSkew_Incremental__c = true // Set the custom setting value to true
        ));

        // Create the test data
        CRLP_RollupAccount_TEST.mockRollupCMTValues();

        // Deactivate the Years_Ago rollups, to simulate having only Days_Back time-bound rollups active
        // and get the max Days_Ago to use in assertions below.
        Integer maxDaysBackInteger = 0;
        for (Rollup__mdt rollup : CRLP_Rollup_SEL.cachedRollups) {
            if (rollup.Time_Bound_Operation_Type__c == 'Years_Ago') {
                rollup.Active__c = false;
            } else if (rollup.Time_Bound_Operation_Type__c == 'Days_Back'
                    && rollup.Integer__c > maxDaysBackInteger) {
                maxDaysBackInteger = (Integer) rollup.Integer__c;
            }
        }

        CRLP_Account_Batch accountBatchJob = new CRLP_Account_Batch(new List<Id>());
        accountBatchJob.initializeJobData();
        accountBatchJob.isScheduledJob = true; // Set the Batch Base isScheduledJob flag to true.
        // This is necessary because the Schedulable Job constructs and submits a separate instance of the
        // CRLP_Account_Batch class.  So we "mock" the isScheduledJob value here, to test the correct
        // response from the getWhereClause() method below.

        String partialDetailObjectWhereClause = 'FROM Opportunity ALLROWS ' +
                'WHERE CloseDate >= LAST_N_DAYS:' + maxDaysBackInteger + ')';
        String generatedWhereClause = accountBatchJob.getWhereClause();
        System.assert(generatedWhereClause.contains(partialDetailObjectWhereClause) == true, 'The incremental mode ' +
                'where clause for the inner join should contain a LAST_N_DAYS where filter on the Opportunities.');
    }

    @isTest
    private static void testAccountHardCreditGetWhereClause_IncrementalMode_YearsOnly() {
        // Start by enabling Customizable Rollups and setting the incremental mode
        UTIL_CustomSettingsFacade.getRollupSettingsForTests(new Customizable_Rollup_Settings__c (
                Customizable_Rollups_Enabled__c = true,
                AccountHardCreditNonSkew_Incremental__c = true // Set the custom setting value to true
        ));

        // Create the test data
        CRLP_RollupAccount_TEST.mockRollupCMTValues();

        // Deactivate the Days_Back rollups, to simulate having only Days_Back time-bound rollups active
        // and get the max Years_Ago to use in assertions below.
        Integer maxYearsBackInteger = 0;
        for (Rollup__mdt rollup : CRLP_Rollup_SEL.cachedRollups) {
            if (rollup.Time_Bound_Operation_Type__c == 'Days_Back') {
                rollup.Active__c = false;
            } else if (rollup.Time_Bound_Operation_Type__c == 'Years_Ago'
                    && rollup.Integer__c > maxYearsBackInteger) {
                maxYearsBackInteger = (Integer) rollup.Integer__c;
            }
        }

        CRLP_Account_Batch accountBatchJob = new CRLP_Account_Batch(new List<Id>());
        accountBatchJob.initializeJobData();
        accountBatchJob.isScheduledJob = true; // Set the Batch Base isScheduledJob flag to true.
        // This is necessary because the Schedulable Job constructs and submits a separate instance of the
        // CRLP_Account_Batch class.  So we "mock" the isScheduledJob value here, to test the correct
        // response from the getWhereClause() method below.

        String partialDetailObjectWhereClause = 'FROM Opportunity ALLROWS ' +
                'WHERE CloseDate >= LAST_N_YEARS:' + maxYearsBackInteger + ')';
        String generatedWhereClause = accountBatchJob.getWhereClause();
        System.assert(generatedWhereClause.contains(partialDetailObjectWhereClause) == true, 'The incremental mode ' +
                'where clause for the inner join should contain a LAST_N_YEARS where filter on the Opportunities.');
    }

    @isTest
    private static void testAccountHardCreditGetWhereClause_IncrementalMode_CustomSettingFalse() {
        // Start by enabling Customizable Rollups and setting the incremental mode
        UTIL_CustomSettingsFacade.getRollupSettingsForTests(new Customizable_Rollup_Settings__c (
                Customizable_Rollups_Enabled__c = true,
                AccountHardCreditNonSkew_Incremental__c = false // Set the custom setting to false
        ));

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
        // Start by enabling Customizable Rollups and setting the incremental mode
        UTIL_CustomSettingsFacade.getRollupSettingsForTests(new Customizable_Rollup_Settings__c (
                Customizable_Rollups_Enabled__c = true,
                ContactHardCreditNonSkew_Incremental__c = true // Set the custom setting value to true
        ));

        // Create the test data
        CRLP_RollupContact_TEST.mockRollupCMTValues();

        // Get the max Days_Ago and Years_Back to use in assertions below.
        Integer maxDaysBackInteger = 0;
        Integer maxYearsAgoInteger = 0;
        for (Rollup__mdt rollup : CRLP_Rollup_SEL.cachedRollups) {
            if (rollup.Summary_Object__c != 'Contact' ||
                    rollup.Detail_Object__c != 'Opportunity') {
                continue;
            }
            if (rollup.Time_Bound_Operation_Type__c == 'Years_Ago'
                    && rollup.Integer__c > maxYearsAgoInteger) {
                maxYearsAgoInteger = (Integer) rollup.Integer__c;
            } else if (rollup.Time_Bound_Operation_Type__c == 'Days_Back'
                    && rollup.Integer__c > maxDaysBackInteger) {
                maxDaysBackInteger = (Integer) rollup.Integer__c;
            }
        }

        CRLP_Contact_BATCH contactBatchJob = new CRLP_Contact_BATCH(new List<Id>());
        contactBatchJob.initializeJobData();
        contactBatchJob.isScheduledJob = true; // Set the Batch Base isScheduledJob flag to true.
        // This is necessary because the Schedulable Job constructs and submits a separate instance of the
        // CRLP_Contact_BATCH class.  So we "mock" the isScheduledJob value here, to test the correct
        // response from the getWhereClause() method below.

        String partialDetailObjectWhereClause = 'FROM Opportunity ALLROWS ' +
                'WHERE CloseDate >= LAST_N_DAYS:' + maxDaysBackInteger + ' ' +
                'OR CloseDate >= LAST_N_YEARS:' + maxYearsAgoInteger + ')';

        String generatedWhereClause = contactBatchJob.getWhereClause();
        System.assert(generatedWhereClause.contains(partialDetailObjectWhereClause) == true, 'The incremental mode ' +
                'where clause for the inner join should contain a where filter on the Opportunities.');
    }

    @isTest
    private static void testContactHardCreditGetWhereClause_IncrementalMode_DaysOnly() {
        // Start by enabling Customizable Rollups and setting the incremental mode
        UTIL_CustomSettingsFacade.getRollupSettingsForTests(new Customizable_Rollup_Settings__c (
                Customizable_Rollups_Enabled__c = true,
                ContactHardCreditNonSkew_Incremental__c = true // Set the custom setting value to true
        ));

        // Create the test data
        CRLP_RollupContact_TEST.mockRollupCMTValues();

        // Deactivate the Years_Ago rollups, to simulate having only Days_Back time-bound rollups active
        // and get the max Days_Ago to use in assertions below.
        Integer maxDaysBackInteger = 0;
        for (Rollup__mdt rollup : CRLP_Rollup_SEL.cachedRollups) {
            if (rollup.Time_Bound_Operation_Type__c == 'Years_Ago') {
                rollup.Active__c = false;
            } else if (rollup.Time_Bound_Operation_Type__c == 'Days_Back'
                    && rollup.Integer__c > maxDaysBackInteger) {
                maxDaysBackInteger = (Integer) rollup.Integer__c;
            }
        }

        CRLP_Contact_BATCH contactBatchJob = new CRLP_Contact_BATCH(new List<Id>());
        contactBatchJob.initializeJobData();
        contactBatchJob.isScheduledJob = true; // Set the Batch Base isScheduledJob flag to true.
        // This is necessary because the Schedulable Job constructs and submits a separate instance of the
        // CRLP_Contact_BATCH class.  So we "mock" the isScheduledJob value here, to test the correct
        // response from the getWhereClause() method below.

        String partialDetailObjectWhereClause = 'FROM Opportunity ALLROWS ' +
                'WHERE CloseDate >= LAST_N_DAYS:' + maxDaysBackInteger + ')';
        String generatedWhereClause = contactBatchJob.getWhereClause();
        System.assert(generatedWhereClause.contains(partialDetailObjectWhereClause) == true, 'The incremental mode ' +
                'where clause for the inner join should contain a LAST_N_DAYS where filter on the Opportunities.');
    }

    @isTest
    private static void testContactHardCreditGetWhereClause_IncrementalMode_YearsOnly() {
        // Start by enabling Customizable Rollups and setting the incremental mode
        UTIL_CustomSettingsFacade.getRollupSettingsForTests(new Customizable_Rollup_Settings__c (
                Customizable_Rollups_Enabled__c = true,
                ContactHardCreditNonSkew_Incremental__c = true // Set the custom setting value to true
        ));

        // Create the test data
        CRLP_RollupContact_TEST.mockRollupCMTValues();

        // Deactivate the Days_Back rollups, to simulate having only Days_Back time-bound rollups active
        // and get the max Years_Ago to use in assertions below.
        Integer maxYearsBackInteger = 0;
        for (Rollup__mdt rollup : CRLP_Rollup_SEL.cachedRollups) {
            if (rollup.Time_Bound_Operation_Type__c == 'Days_Back') {
                rollup.Active__c = false;
            } else if (rollup.Time_Bound_Operation_Type__c == 'Years_Ago'
                    && rollup.Integer__c > maxYearsBackInteger) {
                maxYearsBackInteger = (Integer) rollup.Integer__c;
            }
        }

        CRLP_Contact_BATCH contactBatchJob = new CRLP_Contact_BATCH(new List<Id>());
        contactBatchJob.initializeJobData();
        contactBatchJob.isScheduledJob = true; // Set the Batch Base isScheduledJob flag to true.
        // This is necessary because the Schedulable Job constructs and submits a separate instance of the
        // CRLP_Contact_BATCH class.  So we "mock" the isScheduledJob value here, to test the correct
        // response from the getWhereClause() method below.

        String partialDetailObjectWhereClause = 'FROM Opportunity ALLROWS ' +
                'WHERE CloseDate >= LAST_N_YEARS:' + maxYearsBackInteger + ')';
        String generatedWhereClause = contactBatchJob.getWhereClause();
        System.assert(generatedWhereClause.contains(partialDetailObjectWhereClause) == true, 'The incremental mode ' +
                'where clause for the inner join should contain a LAST_N_YEARS where filter on the Opportunities.');
    }

    @isTest
    private static void testContactHardCreditGetWhereClause_IncrementalMode_CustomSettingFalse() {
        // Start by enabling Customizable Rollups and setting the incremental mode
        UTIL_CustomSettingsFacade.getRollupSettingsForTests(new Customizable_Rollup_Settings__c (
                Customizable_Rollups_Enabled__c = true,
                ContactHardCreditNonSkew_Incremental__c = false // Set the custom setting to false
        ));

        // Create the test data
        CRLP_RollupContact_TEST.mockRollupCMTValues();

        CRLP_Contact_BATCH contactBatchJob = new CRLP_Contact_BATCH(new List<Id>());
        contactBatchJob.initializeJobData();
        contactBatchJob.isScheduledJob = true;

        String whereClause = contactBatchJob.getWhereClause();
        System.assert(whereClause.contains('WHERE') == false, 'The standard where clause should be used ' +
                'for the inner join when the custom setting is set to false.');
    }
}