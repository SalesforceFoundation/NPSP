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
* @description Recurring Donations enablement options and status tests
*
*/
@isTest(IsParallel=false)
public with sharing class RD2_EnablementDelegate_TEST {

    private static final TEST_SObjectGateway.AsyncApexJobGateway jobGateway = new TEST_SObjectGateway.AsyncApexJobGateway();
    private static final TEST_SObjectGateway.ErrorGateway errorGateway = new TEST_SObjectGateway.ErrorGateway();

    /****
    * @description Creates data required for unit tests
    */
    @TestSetup
    private static void setUp() {
        insert UTIL_UnitTestData_TEST.getContact();
    }

    /****
    * @description Verifies enablement state values are not set by default
    */
    @isTest
    private static void shouldReturnDefaultEnablementStateWhenNotSetup() {
        setEnablementState(null);

        RD2_EnablementDelegate_CTRL.service = (RD2_EnablementService) Test.createStub(
            RD2_EnablementService.class, new RD2_EnablementService_TEST.Stub()
        );

        RD2_EnablementDelegate_CTRL.EnablementState expectedState = new RD2_EnablementDelegate_CTRL.EnablementState();

        assertEnablementState(expectedState, RD2_EnablementDelegate_CTRL.getEnablementState());
    }

    /****
    * @description Verifies enablement state isReady reflects enablement service
    * enhanced Recurring Donations ready status
    */
    @isTest
    private static void shouldSetEnablementStateIsReady() {
        setEnablementState(null);

        RD2_EnablementDelegate_CTRL.service = (RD2_EnablementService) Test.createStub(
            RD2_EnablementService.class, new RD2_EnablementService_TEST.Stub().withRecurringDonations2Ready()
        );

        RD2_EnablementDelegate_CTRL.EnablementState expectedState = new RD2_EnablementDelegate_CTRL.EnablementState();
        expectedState.isReady = true;

        assertEnablementState(expectedState, RD2_EnablementDelegate_CTRL.getEnablementState());
    }

    /****
    * @description Verifies enablement state isEnabled reflects enablement service
    * enhanced Recurring Donations enabled status
    */
    @isTest
    private static void shouldSetEnablementStateIsEnabled() {
        setEnablementState(null);

        RD2_EnablementDelegate_CTRL.service = (RD2_EnablementService) Test.createStub(
            RD2_EnablementService.class, new RD2_EnablementService_TEST.Stub().withRecurringDonations2Enabled()
        );

        RD2_EnablementDelegate_CTRL.EnablementState expectedState = new RD2_EnablementDelegate_CTRL.EnablementState();
        expectedState.isEnabled = true;

        assertEnablementState(expectedState, RD2_EnablementDelegate_CTRL.getEnablementState());
    }

    /****
    * @description Verifies user action to confirm enablement is saved
    */
    @isTest
    private static void shouldConfirmEnablement() {
        setEnablementState(null);

        RD2_EnablementDelegate_CTRL.service = (RD2_EnablementService) Test.createStub(
            RD2_EnablementService.class, new RD2_EnablementService_TEST.Stub().withRecurringDonations2Ready()
        );

        RD2_EnablementDelegate_CTRL.confirmEnablement();

        RD2_EnablementDelegate_CTRL.EnablementState expectedState = new RD2_EnablementDelegate_CTRL.EnablementState();
        expectedState.isReady = true;
        expectedState.isConfirmed = true;

        assertEnablementState(expectedState, RD2_EnablementDelegate_CTRL.getEnablementState());
    }

    /****
    * @description Verifies user action to enable Recurring Donations
    */
    @isTest
    private static void shouldEnableEnhancedRDs() {
        RD2_EnablementDelegate_CTRL.enableEnhancement();

        System.assertEquals(true, STG_Panel.stgService.stgRD.isRecurringDonations2Enabled__c, 'Custom Settings field should be set');

        List<AsyncApexJob> asyncJobs = [SELECT Id
            FROM AsyncApexJob
            WHERE ApexClass.Name = 'RD2_EnablementDelegate_CTRL'
            LIMIT 1];
        System.assert(!asyncJobs.isEmpty(), 'Expected to find a Queueable job after enabling Enhanced Recurring Donations');
    }

    /****
    * @description Verifies MetaDeploy URL is returned
    */
    @isTest
    private static void shouldReturnMetaDeployURL() {
        if (UTIL_Namespace.isCustomerOrg()) {
            return;
        }

        String url = RD2_EnablementDelegate_CTRL.getMetaDeployURL();

        String expectedUrl = 'https://install.salesforce.org/products/npsp/npsp-rd2-pilot';

        System.assertEquals(expectedURL, url, 'URL should match');
    }

    /****
    * @description Verifies user action to launch MetaDeploy is saved
    */
    @isTest
    private static void shouldLaunchMetaDeploy() {
        mockCustomizableRollups();

        RD2_EnablementDelegate_CTRL.EnablementState expectedState = new RD2_EnablementDelegate_CTRL.EnablementState();
        expectedState.isConfirmed = true;
        setEnablementState(JSON.serialize(expectedState));

        stubRD2ReadyAndEnabled();

        RD2_EnablementDelegate_CTRL.launchMetaDeploy();

        expectedState.isReady = true;
        expectedState.isEnabled = true;
        expectedState.isMetaLaunched = true;

        assertEnablementState(expectedState, RD2_EnablementDelegate_CTRL.getEnablementState());

        AsyncApexJob enablementJob = new TEST_SObjectGateway.AsyncApexJobGateway().getRecord('RD2_EnablementDelegate_CTRL');
        System.assertNotEquals(null, enablementJob, 'Expected to find a Queueable job after clicking the MetaDeploy link');
    }

    /****
    * @description Verifies user action to confirm MetaDeploy is saved
    */
    @isTest
    private static void shouldConfirmMetaDeploy() {
        RD2_EnablementDelegate_CTRL.EnablementState expectedState = new RD2_EnablementDelegate_CTRL.EnablementState();
        expectedState.isConfirmed = true;
        expectedState.isMetaLaunched = true;
        setEnablementState(JSON.serialize(expectedState));
        
        stubRD2ReadyAndEnabled();

        RD2_EnablementDelegate_CTRL.dayOfMonthPicklistValue = '1';

        RD2_EnablementDelegate_CTRL.confirmMetaDeploy();

        expectedState.isReady = true;
        expectedState.isEnabled = true;
        expectedState.isMetaConfirmed = true;

        assertEnablementState(expectedState, RD2_EnablementDelegate_CTRL.getEnablementState());
    }

    /****
    * @description Verifies user action to confirm MetaDeploy throws an exception when metadata is not installed
    */
    @isTest
    private static void shouldThrowExceptionWhenMetaDeployIsConfirmedButNotInstalled() {
        mockCustomizableRollups();

        RD2_EnablementDelegate_CTRL.EnablementState expectedState = new RD2_EnablementDelegate_CTRL.EnablementState();
        expectedState.isConfirmed = true;
        expectedState.isMetaLaunched = true;
        setEnablementState(JSON.serialize(expectedState));
        
        stubRD2ReadyAndEnabled();

        //mock value that does not exist but is expected
        RD2_EnablementDelegate_CTRL.dayOfMonthPicklistValue = '32';

        Exception actualException;
        try {
            RD2_EnablementDelegate_CTRL.confirmMetaDeploy();
        } catch (AuraHandledException e) {
            actualException = e;
        }

        System.assertNotEquals(null, actualException, 'The exception should be thrown');
        System.assertEquals(System.Label.RD2_EnablementMetaDeployConfirmError,
            actualException.getMessage(), 'The exception message should match');

        expectedState.isReady = true;
        expectedState.isEnabled = true;
        expectedState.isMetaConfirmed = false;

        assertEnablementState(expectedState, RD2_EnablementDelegate_CTRL.getEnablementState());
    }

    /**
     * @description Verifies Enhanced Recurring Donations dry run migration batch job is executed.
     * If metadata deployment is not checked, dry run part 2 is not visible.
     */
    @IsTest
    private static void shouldRunDryRun() {
        setRDSettings();

        insert getLegacyRecurringDonationBuilder(getContact().Id).build();

        RD2_EnablementDelegate_CTRL.EnablementState expectedState = new RD2_EnablementDelegate_CTRL.EnablementState();
        setEnablementState(JSON.serialize(expectedState));

        Test.startTest();
        Id jobId = RD2_EnablementDelegate_CTRL.runDryRun();
        Test.stopTest();
        
        AsyncApexJob job = jobGateway.getRecord('RD2_DataMigrationDryRun_BATCH');
        System.assertEquals(1, job.JobItemsProcessed,
            'The batch should have run with one child batch processed'
        );

        assertEnablementState(expectedState, RD2_EnablementDelegate_CTRL.getEnablementState());
    }

    /**
     * @description Verifies Enhanced Recurring Donations dry run migration batch job sets "isDryRun2" 
     * if metadata deployment has been confirmed
     */
    @IsTest
    private static void shouldAllowDryRunAfterMetaDeployIsConfirmed() {
        setRDSettings();

        insert getLegacyRecurringDonationBuilder(getContact().Id).build();

        RD2_EnablementDelegate_CTRL.dayOfMonthPicklistValue = '1';
        stubRD2ReadyAndEnabled();
        RD2_EnablementService_TEST.setRecurringDonations2Enabled();

        RD2_EnablementDelegate_CTRL.EnablementState expectedState = new RD2_EnablementDelegate_CTRL.EnablementState();
        expectedState.isReady = true;
        expectedState.isConfirmed = true;
        expectedState.isEnabled = true;
        expectedState.isMetaLaunched = true;
        expectedState.isMetaConfirmed = true;
        setEnablementState(JSON.serialize(expectedState));        

        Test.startTest();
        Id jobId = RD2_EnablementDelegate_CTRL.runDryRun();
        Test.stopTest();

        List<Error__c> errors = errorGateway.getRecords();
        System.assertEquals(0, errors.size(), 'No error should be logged: ' + errors);

        expectedState.isDryRun2 = true;
        assertEnablementState(expectedState, RD2_EnablementDelegate_CTRL.getEnablementState());
    }

    /****
    * @description Verifies migration enabled flag is checked when user skips dry run
    */
    @isTest
    private static void shouldEnableMigrationWhenUserSkipsOptionalDryRun() {
        RD2_EnablementDelegate_CTRL.EnablementState expectedState = new RD2_EnablementDelegate_CTRL.EnablementState();
        expectedState.isReady = true;
        expectedState.isEnabled = true;
        setEnablementState(JSON.serialize(expectedState));
        
        stubRD2ReadyAndEnabled();

        RD2_EnablementDelegate_CTRL.skipDryRun();

        expectedState.isMigrationEnabled = true;
        assertEnablementState(expectedState, RD2_EnablementDelegate_CTRL.getEnablementState());
    }

    /****
    * @description Verifies migration enabled flag is unchecked when user skips migration 
    * and goes back to the validation
    */
    @isTest
    private static void shouldDisableMigrationWhenUserNavigatesBackToDryRun() {
        RD2_EnablementDelegate_CTRL.EnablementState expectedState = new RD2_EnablementDelegate_CTRL.EnablementState();
        expectedState.isReady = true;
        expectedState.isEnabled = true;
        setEnablementState(JSON.serialize(expectedState));
        
        stubRD2ReadyAndEnabled();

        RD2_EnablementDelegate_CTRL.skipMigration();

        expectedState.isMigrationEnabled = false;
        assertEnablementState(expectedState, RD2_EnablementDelegate_CTRL.getEnablementState());
    }

    /**
     * @description Verifies Enhanced Recurring Donations migration batch job is executed
     */
    @IsTest
    private static void shouldRunMigration() {
        setRDSettings();

        insert getLegacyRecurringDonationBuilder(getContact().Id).build();

        RD2_EnablementService_TEST.setRecurringDonations2Enabled();

        Test.startTest();
        Id jobId = RD2_EnablementDelegate_CTRL.runMigration();
        Test.stopTest();

        AsyncApexJob job = jobGateway.getRecord('RD2_DataMigration_BATCH');
        System.assertEquals(1, job.JobItemsProcessed,
            'The batch should have run with one child batch processed'
        );
    }


    // Helpers
    ////////////////

    /****
    * @description Returns contact record
    * @return Contact
    */
    private static Contact getContact() {
        return [
            SELECT FirstName, LastName, AccountId
            FROM Contact
            LIMIT 1
        ];
    }

    /****
    * @description Sets enablement state in the custom settings
    * @param state
    * @return void
    */
    private static void setEnablementState(String state) {
        UTIL_CustomSettingsFacade.getRecurringDonationsSettingsForTest(
            new npe03__Recurring_Donations_Settings__c(
                RecurringDonations2EnablementState__c = state,
                npe03__Open_Opportunity_Behavior__c = RD2_Constants.CloseActions.Mark_Opportunities_Closed_Lost.name(),
                npe03__Maximum_Donations__c = 50,
                npe03__Opportunity_Forecast_Months__c = 6
            )
        );
    }

    /****
    * @description Asserts expected and actual enablement states values match
    * @param expectedState Expected enablement state
    * @param state Actual enablement state
    * @return void
    */
    private static void assertEnablementState(RD2_EnablementDelegate_CTRL.EnablementState expectedState, RD2_EnablementDelegate_CTRL.EnablementState state) {
        System.assertEquals(expectedState.isReady, state.isReady, 'isReady should match: ' + state);
        System.assertEquals(expectedState.isConfirmed, state.isConfirmed, 'isConfirmed should match: ' + state);
        System.assertEquals(expectedState.isEnabled, state.isEnabled, 'isEnabled should match: ' + state);
        System.assertEquals(expectedState.isMetaLaunched, state.isMetaLaunched, 'isMetaLaunched should match: ' + state);
        System.assertEquals(expectedState.isMetaConfirmed, state.isMetaConfirmed, 'isMetaConfirmed should match: ' + state);
    }

    /****
    * @description Set enablement service to return true for the enablement ready and enabled state
    * @return void
    */
    private static void stubRD2ReadyAndEnabled() {
        RD2_EnablementDelegate_CTRL.service = (RD2_EnablementService) Test.createStub(
            RD2_EnablementService.class,
            new RD2_EnablementService_TEST.Stub()
                .withRecurringDonations2Ready()
                .withRecurringDonations2Enabled()
        );
    }

    /**
     * @description Mock the Next Donation Date customizable rollup
     */
    private static void mockCustomizableRollups() {
        String rollupsJSON = '[' +
            CMT_UnitTestData_TEST.createRollupRecord('RD Next Payment Date', null,
                CMT_UnitTestData_TEST.RollupRecordType.OppToRD,
                'npe03__Next_Payment_Date__c', CRLP_Operation.RollupType.First, 'CloseDate') +
            ']';

        // Deserialize the rollups to use for testing
        CRLP_Rollup_SEL.cachedRollups = (List<Rollup__mdt>) JSON.deserialize(rollupsJSON, List<Rollup__mdt>.class);
    }

    /**
     * @description Sets RD Settings 
     * @return void
     */
    private static void setRDSettings() {
        UTIL_CustomSettingsFacade.getRecurringDonationsSettingsForTest(
            new npe03__Recurring_Donations_Settings__c(
                npe03__Open_Opportunity_Behavior__c = RD2_Constants.CloseActions.Mark_Opportunities_Closed_Lost.name(),
                npe03__Maximum_Donations__c = 50,
                npe03__Opportunity_Forecast_Months__c = 6
            )
        );
    }

    /**
     * @description Instantiate a legacy recurring donation for a specific ContactId
     * @param contactId
     * @return TEST_RecurringDonationBuilder New Recurring Donation builder
     */
    private static TEST_RecurringDonationBuilder getLegacyRecurringDonationBuilder(Id contactId) {
        return TEST_RecurringDonationBuilder.constructLegacyBuilder()
            .withId(null)
            .withDateEstablished(Date.today().addMonths(-1))
            .withOpenEndedStatusOpen()
            .withContact(contactId)
            .withAmount(100)
            .withInstallmentPeriodMonthly()
            .withDayOfMonth('1');
    }
}