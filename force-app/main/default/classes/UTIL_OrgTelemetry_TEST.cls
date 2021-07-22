/*
    Copyright (c) 2018, Salesforce.org
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
* @date 2018
* @group Utilities
* @description Unit Tests related to the org telemetry class
*/
@IsTest
private class UTIL_OrgTelemetry_TEST {

    private static UTIL_FeatureManagement_TEST.Mock featureManagementMock = new UTIL_FeatureManagement_TEST.Mock();

    /**
     * @description Number of new Gift-Entry BGE related Data Import records created within the last 30 days
     */
    private static final Integer NUM_NEWGE_BGE_ROWS_30_DAYS_AGO = 2;


    /**
     * @description Number of BGE related Data Import records created within the last 30 days
     */
    private static final Integer NUM_BGE_ROWS_30_DAYS_AGO = 2;

    /**
     * @description Number of BDI related Data Import records created within the last 30 days
     */
    private static final Integer NUM_BDI_ROWS_30_DAYS_AGO = 3;

    /**
     * @description Number of BDI related Data Import records created within the last 60 days
     */
    private static final Integer NUM_DI_ROWS_60_DAYS_AGO = 2;

    /**
     * @description Create a single Account, Contact and Opportunity to use for the telemetry test data
     **/
    @TestSetup
    private static void testDataSetup() {
        Contact c = UTIL_UnitTestData_TEST.getContact();
        insert c;

        c = [SELECT Id, FirstName, LastName, AccountId FROM Contact LIMIT 1];

        Opportunity opp = new Opportunity (
            Name = 'Test Opp ' + c.FirstName + ' ' + c.LastName,
            Amount = 1000,
            CloseDate = Date.today(),
            StageName = UTIL_UnitTestData_TEST.getClosedWonStage(),
            Primary_Contact__c = c.Id
        );
        insert opp;

        npe03__Recurring_Donation__c rd = new TEST_RecurringDonationBuilder()
            .withContact(c.Id)
            .withPlannedInstallments(3)
            .withAmount(100)
            .withInstallmentPeriodYearly()
            .withDateEstablished(Date.newInstance(2018,6,15))
            .withScheduleTypeMultiplyValue()
            .withOpenEndedStatusOpen()
            .build();
        insert rd;

        DataImportBatch__c diBatch = new DataImportBatch__c(GiftBatch__c = true);
        DataImportBatch__c newDIBatch = new DataImportBatch__c(GiftBatch__c = true, 
            Batch_Gift_Entry_Version__c = 2);


        insert new List<DataImportBatch__c> {diBatch, newDIBatch};

        List<DataImport__c> bdiRows = buildDataImports(NUM_BDI_ROWS_30_DAYS_AGO, null);
        List<DataImport__c> bgeRows = buildDataImports(NUM_BGE_ROWS_30_DAYS_AGO, diBatch.Id);
        List<DataImport__c> newBGERows = buildDataImports(NUM_NEWGE_BGE_ROWS_30_DAYS_AGO, newDIBatch.Id);
        List<DataImport__c> bdiRows60DaysAgo = buildDataImports(NUM_DI_ROWS_60_DAYS_AGO, null);

        insert bdiRows;
        insert bgeRows;
        insert newBGERows;
        insert bdiRows60DaysAgo;

        Datetime sixtyDaysAgo = Datetime.now().addDays(-60);
        for (DataImport__c di : bdiRows60DaysAgo) {
            Test.setCreatedDate(di.Id, sixtyDaysAgo);
        }
    }

    /**
     * @description Test that the NPSP_Settings telemetry data is retrieved.
     */
    @IsTest
    private static void validateNPSPSettingsTelemetry() {
        UTIL_CustomSettingsFacade.getRecurringDonationsSettingsForTest(
            new npe03__Recurring_Donations_Settings__c()
        );

        UTIL_FeatureManagement_TEST.Mock asyncFeatureManagementMock = new UTIL_FeatureManagement_TEST.Mock();
        UTIL_OrgTelemetry_SVC.asyncTelemetrySvc.featureManager =
            (UTIL_FeatureManagement) Test.createStub(UTIL_FeatureManagement.class, asyncFeatureManagementMock);

        Test.startTest();
        UTIL_OrgTelemetry_SVC.asyncProcessNpspSettingsTelemetry();

        Integer currQueryCount = Limits.getQueries();

        UTIL_OrgTelemetry_SVC telemetrySvc = new UTIL_OrgTelemetry_SVC();
        telemetrySvc.featureManager = (UTIL_FeatureManagement) Test.createStub(UTIL_FeatureManagement.class, featureManagementMock);

        telemetrySvc.processTelemetryType(UTIL_OrgTelemetry_SVC.TelemetryBatchCategory.NPSP_Settings);

        System.assertEquals(currQueryCount, Limits.getQueries(), 'There should no new queries executed because these only reference static custom setting');
        Test.stopTest();

        String expectedKey = UTIL_OrgTelemetry_SVC.TelemetryBatchCategory.NPSP_Settings.name();
        System.assertNotEquals(
            null,
            featureManagementMock.packageBooleanValuesByName.get(
                UTIL_OrgTelemetry_SVC.TelemetryParameterName.IsEnabled_HouseholdAcctModel.name()
            ),
            'setPackageBooleanValue should have been called with the feature IsEnabled_HouseholdAcctModel'
        );

        System.assertNotEquals(
            null,
            featureManagementMock.packageBooleanValuesByName.get(
                UTIL_OrgTelemetry_SVC.TelemetryParameterName.IsEnabled_AutomaticPayments.name()
            ),
            'setPackageBooleanValue should have been called with the feature IsEnabled_AutomaticPayments'
        );

        System.assertNotEquals(
            null,
            featureManagementMock.packageBooleanValuesByName.get(
                UTIL_OrgTelemetry_SVC.TelemetryParameterName.IsEnabled_DefaultGAU.name()
            ),
            'setPackageBooleanValue should have been called with the feature IsEnabled_DefaultGAU'
        );

        System.assertNotEquals(
            null,
            featureManagementMock.packageBooleanValuesByName.get(
                UTIL_OrgTelemetry_SVC.TelemetryParameterName.IsEnabled_AddressVerification.name()
            ),
            'setPackageBooleanValue should have been called with the feature IsEnabled_AddressVerification'
        );

        System.assertNotEquals(
            null,
            featureManagementMock.packageBooleanValuesByName.get(
                UTIL_OrgTelemetry_SVC.TelemetryParameterName.IsEnabled_CustomizableRollups.name()
            ),
            'setPackageBooleanValue should have been called with the feature IsEnabled_CustomizableRollups'
        );

        System.assertNotEquals(
            null,
            featureManagementMock.packageBooleanValuesByName.get(
                UTIL_OrgTelemetry_SVC.TelemetryParameterName.IsEnabled_BDICMT.name()
            ),
            'setPackageBooleanValue should have been called with the feature IsEnabled_BDICMT'
        );

        System.assertNotEquals(
            null,
            featureManagementMock.packageBooleanValuesByName.get(
                UTIL_OrgTelemetry_SVC.TelemetryParameterName.IsEnabled_GiftEntry.name()
            ),
            'setPackageBooleanValue should have been called with the feature IsEnabled_GiftEntry'
        );        

        System.assertNotEquals(
            null,
            featureManagementMock.packageBooleanValuesByName.get(
                UTIL_OrgTelemetry_SVC.TelemetryParameterName.IsEnabled_RecurringDonations2.name()
            ),
            'setPackageBooleanValue should have been called with the feature IsEnabled_RecurringDonations2'
        );

        System.assertNotEquals(
            null,
            featureManagementMock.packageBooleanValuesByName.get(
                UTIL_OrgTelemetry_SVC.TelemetryParameterName.IsEnabled_PaymentAllocations.name()
            ),
            'setPackageBooleanValue should have been called with the feature IsEnabled_PaymentAllocations'
        );
    }

    /**
     * @description Confirms that the payment opportunities count settings telemetry data is defaulted correctly
     */
    @IsTest
    private static void validateCountOfPaymentsOppsTelemetry() {
        UTIL_CustomSettingsFacade.getContactsSettingsForTests(
            new npe01__Contacts_And_Orgs_Settings__c(
                npe01__Payments_Enabled__c = true
            )
        );

        Test.startTest();

        UTIL_OrgTelemetry_SVC telemetrySvc = new UTIL_OrgTelemetry_SVC();
        telemetrySvc.featureManager = (UTIL_FeatureManagement) Test.createStub(UTIL_FeatureManagement.class, featureManagementMock);

        telemetrySvc.processTelemetryType(UTIL_OrgTelemetry_SVC.TelemetryBatchCategory.Data_CountPaymentOpps);

        Test.stopTest();

        System.assertEquals(
            -1,
            featureManagementMock.packageIntegerValuesByName.get(
                UTIL_OrgTelemetry_SVC.TelemetryParameterName.Data_CountOppsWithMultiplePayments.name()
            ),
            'setPackageIntegerValue should have been called with the feature Data_CountOppsWithMultiplePayments and defaulted to -1'
        );

        /*
        /* TODO: Holding on Data_OppPaymentsWithoutPaymentsEnabled metric, reenable test when
                 you move forward with Data_OppPaymentsWithoutPaymentsEnabled
        System.assertEquals(
            -1,
            featureManagementMock.packageIntegerValuesByName.get(
                UTIL_OrgTelemetry_SVC.TelemetryParameterName.Data_OppPaymentsWithoutPaymentsEnabled.name()
            ),
            'setPackageIntegerValue should have been called with the feature Data_OppPaymentsWithoutPaymentsEnabled and defaulted to -1'
        );
        */
    }

    /**
     * @description Test that the org settings telemetry data is retrieved
     */
    @IsTest
    private static void validateOrgEnvironmentTelemetry() {
        Test.startTest();
        Integer currQueryCount = Limits.getQueries();

        UTIL_OrgTelemetry_SVC telemetrySvc = new UTIL_OrgTelemetry_SVC();
        telemetrySvc.featureManager = (UTIL_FeatureManagement) Test.createStub(UTIL_FeatureManagement.class, featureManagementMock);

        telemetrySvc.processTelemetryType(UTIL_OrgTelemetry_SVC.TelemetryBatchCategory.Org_Environment);

        System.assert(Limits.getQueries() > currQueryCount, 'There should be at least one new query executed');
        Test.stopTest();

        System.assertNotEquals(
            null,
            featureManagementMock.packageBooleanValuesByName.get(
                UTIL_OrgTelemetry_SVC.TelemetryParameterName.Org_IsEnabled_AdvancedMultiCurrency.name()
            ),
            'setPackageBooleanValue should have been called with the feature Org_IsEnabled_AdvancedMultiCurrency'
        );

        System.assertNotEquals(
            null,
            featureManagementMock.packageIntegerValuesByName.get(
                UTIL_OrgTelemetry_SVC.TelemetryParameterName.Org_CountNonEnglishLanguages.name()
            ),
            'setPackageIntegerValue should have been called with the feature Org_CountNonEnglishLanguages'
        );

        System.assertNotEquals(
            null,
            featureManagementMock.packageIntegerValuesByName.get(
                UTIL_OrgTelemetry_SVC.TelemetryParameterName.Org_LongestRunningBatchLast7Days.name()
            ),
            'setPackageIntegerValue should have been called with the feature Org_LongestRunningBatchLast7Days'
        );

        System.assertNotEquals(
            null,
            featureManagementMock.packageIntegerValuesByName.get(
                UTIL_OrgTelemetry_SVC.TelemetryParameterName.Org_CountTimedOutBatchJobsLast7Days.name()
            ),
            'setPackageIntegerValue should have been called with the feature Org_CountTimedOutBatchJobsLast7Days'
        );
    }

    /**
     * @description Test that the MaxNumRelatedOpps settings telemetry data is retrieved.
     */
    @IsTest
    private static void validateMaxNumRelatedOppsTelemetry() {
        Integer maxNumRelatedOpps = 10;

        Account accountWithMaxOpps = new Account(Name = 'Test Account', npo02__NumberOfClosedOpps__c = maxNumRelatedOpps);
        Account accountWithOpps = new Account(Name = 'Test Account 2', npo02__NumberOfClosedOpps__c = 1);
        insert new List<Account>{ accountWithMaxOpps, accountWithOpps };

        Test.startTest();
        Integer currQueryCount = Limits.getQueries();

        UTIL_OrgTelemetry_SVC telemetrySvc = new UTIL_OrgTelemetry_SVC();
        telemetrySvc.featureManager = (UTIL_FeatureManagement) Test.createStub(UTIL_FeatureManagement.class, featureManagementMock);

        telemetrySvc.processTelemetryType(UTIL_OrgTelemetry_SVC.TelemetryBatchCategory.Data_MaxNumRelatedOpps);

        System.assertEquals(currQueryCount+1, Limits.getQueries(), 'There should be one new query executed');
        Test.stopTest();

        System.assertEquals(
            maxNumRelatedOpps,
            featureManagementMock.packageIntegerValuesByName.get(
                UTIL_OrgTelemetry_SVC.TelemetryParameterName.Data_MaxNumRelatedOpps.name()
            ),
            'setPackageIntegerValue should have been called with the feature Data_MaxNumRelatedOpps and set with the max number of opportunities on an account'
        );
    }

    /**
     * @description Test that the DataCountOfRD settings telemetry data is retrieved.
     */
    @IsTest
    private static void validateCountOfRDOppsTelemetry() {
        Test.startTest();

        UTIL_OrgTelemetry_SVC telemetrySvc = new UTIL_OrgTelemetry_SVC();
        telemetrySvc.featureManager = (UTIL_FeatureManagement) Test.createStub(UTIL_FeatureManagement.class, featureManagementMock);

        telemetrySvc.processTelemetryType(UTIL_OrgTelemetry_SVC.TelemetryBatchCategory.Data_CountRdOpps);

        Test.stopTest();

        System.assertEquals(
            -1,
            featureManagementMock.packageIntegerValuesByName.get(
                UTIL_OrgTelemetry_SVC.TelemetryParameterName.Data_CountRdOppsAll.name()
            ),
            'setPackageIntegerValue should have been called with the feature Data_CountRdOppsAll and defaulted to -1'
        );

        System.assertEquals(
            -1,
            featureManagementMock.packageIntegerValuesByName.get(
                UTIL_OrgTelemetry_SVC.TelemetryParameterName.Data_CountRdOppsOpenEnded.name()
            ),
            'setPackageIntegerValue should have been called with the feature Data_CountRdOppsOpenEnded and defaulted to -1'
        );
    }

    /**
     * @description Test that the Data_CountRecurringDonations settings telemetry data is retrieved.
     */
    @IsTest
    private static void validateCountOfRecurringDonationsTelemetry() {
        Test.startTest();

        UTIL_OrgTelemetry_SVC telemetrySvc = new UTIL_OrgTelemetry_SVC();
        telemetrySvc.featureManager = (UTIL_FeatureManagement) Test.createStub(UTIL_FeatureManagement.class, featureManagementMock);

        telemetrySvc.processTelemetryType(UTIL_OrgTelemetry_SVC.TelemetryBatchCategory.Data_CountRecurringDonations);

        Test.stopTest();

        System.assertEquals(
            -1,
            featureManagementMock.packageIntegerValuesByName.get(
                UTIL_OrgTelemetry_SVC.TelemetryParameterName.Data_CountRecurringDonationsAll.name()
            ),
            'setPackageIntegerValue should have been called with the feature Data_CountRecurringDonationsAll and defaulted to -1'
        );

        System.assertEquals(
            -1,
            featureManagementMock.packageIntegerValuesByName.get(
                UTIL_OrgTelemetry_SVC.TelemetryParameterName.Data_CountRdsWithDiffAmount.name()
            ),
            'setPackageIntegerValue should have been called with the feature Data_CountRdsWithDiffAmount and defaulted to -1'
        );
    }

    /**
     * @description Test that the Data_CountOfErrorLog settings telemetry data is retrieved.
     * It's not possible to validate that the call to System.FeatureManagement() call succeeded.
     */
    @IsTest
    private static void validateCountOfErrorLogTelemetry() {
        Integer numErrors = 10;
        List<Error__c> errors = new List<Error__c>();
        for (Integer i = 0; i < numErrors; i++) {
            errors.add(new Error__c());
        }
        insert errors;

        Test.startTest();
        Integer currQueryCount = Limits.getQueries();

        UTIL_OrgTelemetry_SVC telemetrySvc = new UTIL_OrgTelemetry_SVC();
        telemetrySvc.featureManager = (UTIL_FeatureManagement) Test.createStub(UTIL_FeatureManagement.class, featureManagementMock);

        telemetrySvc.processTelemetryType(UTIL_OrgTelemetry_SVC.TelemetryBatchCategory.Data_CountErrorLog);

        System.assertEquals(currQueryCount+1, Limits.getQueries(), 'There should be one new query executed');
        Test.stopTest();

        System.assertEquals(
            numErrors,
            featureManagementMock.packageIntegerValuesByName.get(
                UTIL_OrgTelemetry_SVC.TelemetryParameterName.Data_CountErrorLog.name()
            ),
            'setPackageIntegerValue should have been called with the feature Data_CountRdOppsOpenEnded and the correct number of errors'
        );
    }

    /**
     * @description Validates calculation in getMinutesBetween()
     */
    @IsTest
    private static void shouldCalculateMinutesBetweenTwoDateTimes() {
        UTIL_OrgTelemetry_SVC service = new UTIL_OrgTelemetry_SVC();
        DateTime startDate = DateTime.newInstanceGMT(2019, 03, 01, 23, 00,00);
        DateTime endDate = DateTime.newInstanceGMT(2019, 03, 02, 10, 00,00);

        System.assertEquals(660, service.getMinutesBetween(startDate, endDate),
            'The minutes between the two dates should be calculated correctly: ' + startDate + ' -> ' + endDate);
    }

    /**
     * @description Confirms BDI row counts are calculated correctly
     */
    @IsTest
    private static void validateCountOfBDIRowsTelemetry() {
        Test.startTest();
        Integer currQueryCount = Limits.getQueries();

        UTIL_OrgTelemetry_SVC telemetrySvc = new UTIL_OrgTelemetry_SVC();
        telemetrySvc.featureManager = (UTIL_FeatureManagement) Test.createStub(UTIL_FeatureManagement.class, featureManagementMock);

        telemetrySvc.processTelemetryType(UTIL_OrgTelemetry_SVC.TelemetryBatchCategory.Data_CountBDIRows);

        System.assertEquals(currQueryCount+1, Limits.getQueries(), 'There should be one new query executed');
        Test.stopTest();

        System.assertEquals(
            NUM_BDI_ROWS_30_DAYS_AGO + NUM_BGE_ROWS_30_DAYS_AGO + NUM_NEWGE_BGE_ROWS_30_DAYS_AGO,
            featureManagementMock.packageIntegerValuesByName.get(
                UTIL_OrgTelemetry_SVC.TelemetryParameterName.Data_CountBDIRowsLast30Days.name()
            ),
            'setPackageIntegerValue should have been called with the feature Data_CountBDIRowsLast30Days and set correctly'
        );
    }

    /**
     * @description Confirms BGE row counts are calculated correctly
     */
    @IsTest
    private static void validateCountOfBGERowsTelemetry() {
        Test.startTest();
        Integer currQueryCount = Limits.getQueries();

        UTIL_OrgTelemetry_SVC telemetrySvc = new UTIL_OrgTelemetry_SVC();
        telemetrySvc.featureManager = (UTIL_FeatureManagement) Test.createStub(UTIL_FeatureManagement.class, featureManagementMock);

        telemetrySvc.processTelemetryType(UTIL_OrgTelemetry_SVC.TelemetryBatchCategory.Data_CountBGERows);

        System.assertEquals(currQueryCount+1, Limits.getQueries(), 'There should be one new query executed');
        Test.stopTest();

        System.assertEquals(
            NUM_BGE_ROWS_30_DAYS_AGO,
            featureManagementMock.packageIntegerValuesByName.get(
                UTIL_OrgTelemetry_SVC.TelemetryParameterName.Data_CountBGERowsLast30Days.name()
            ),
            'setPackageIntegerValue should have been called with the feature Data_CountBGERowsLast30Days and set correctly'
        );
    }

    /**
    * @description Verifies that DataCount_ONETIME_Use set to 0 when RD2 is not enabled in the org
    */
    @IsTest
    private static void validateDataCount_ONETIME_UseSetTo0WhenRD2NotEnabled() {
        UTIL_OrgTelemetry_SVC telemetrySvc = new UTIL_OrgTelemetry_SVC();
        telemetrySvc.featureManager = (UTIL_FeatureManagement) Test.createStub(UTIL_FeatureManagement.class, featureManagementMock);

        Test.startTest();
        telemetrySvc.processTelemetryType(UTIL_OrgTelemetry_SVC.TelemetryBatchCategory.NPSP_Settings);
        Test.stopTest();

        System.assertEquals(
            0,
            featureManagementMock.packageIntegerValuesByName.get(
                UTIL_OrgTelemetry_SVC.TelemetryParameterName.DataCount_ONETIME_Use.name()
            ),
            'DataCount_ONETIME_Use should have been set to 0 when RD2 is not enabled'
        );
    }

    /**
    * @description Verifies that DataCount_ONETIME_Use set to 1 when RD2 is enabled but metadeploy is not completed
    */
    @IsTest
    private static void validateDataCount_ONETIME_UseSetTo1WhenMetadeployedNotCompleted() {
        RD2_EnablementService_TEST.setRecurringDonations2Enabled();

        UTIL_OrgTelemetry_SVC telemetrySvc = new UTIL_OrgTelemetry_SVC();
        telemetrySvc.featureManager = (UTIL_FeatureManagement) Test.createStub(UTIL_FeatureManagement.class, featureManagementMock);

        Test.startTest();
        telemetrySvc.processTelemetryType(UTIL_OrgTelemetry_SVC.TelemetryBatchCategory.NPSP_Settings);
        Test.stopTest();

        System.assertEquals(
            1,
            featureManagementMock.packageIntegerValuesByName.get(
                UTIL_OrgTelemetry_SVC.TelemetryParameterName.DataCount_ONETIME_Use.name()
            ),
            'DataCount_ONETIME_Use should have been set to 1 when RD2 is enabled but Day of Month field does not contain necessary value'
        );
    }

    /**
    * @description Verifies that DataCount_ONETIME_Use set to 2 when RD2 is enabled, metadeploy is completed,
    *   but Next Payment Date rollup is enabled
    */
    @IsTest
    private static void validateDataCount_ONETIME_UseSetTo2WhenNextPaymentDateRollupEnabled() {
        if(!isRD2MetadataDeployed()) {
            return;
        }

        RD2_EnablementService_TEST.setRecurringDonations2Enabled();
        mockRD2EnablementState();
        RD2_EnablementDelegate_TEST.mockCustomizableRollups();

        UTIL_OrgTelemetry_SVC telemetrySvc = new UTIL_OrgTelemetry_SVC();
        telemetrySvc.featureManager = (UTIL_FeatureManagement) Test.createStub(UTIL_FeatureManagement.class, featureManagementMock);

        Test.startTest();
        telemetrySvc.processTelemetryType(UTIL_OrgTelemetry_SVC.TelemetryBatchCategory.NPSP_Settings);
        Test.stopTest();

        System.assertEquals(
            2,
            featureManagementMock.packageIntegerValuesByName.get(
                UTIL_OrgTelemetry_SVC.TelemetryParameterName.DataCount_ONETIME_Use.name()
            ),
            'DataCount_ONETIME_Use should have been set to 2 when RD2 is but Next Payment Date Rollup is enabled'
        );
    }

    /**
    * @description Verifies that DataCount_ONETIME_Use set to 10 when RD2 is fully enabled
    */
    @IsTest
    private static void validateDataCount_ONETIME_UseSetTo3WhenRD2FullyEnabled() {
        if(!isRD2MetadataDeployed()) {
            return;
        }

        RD2_EnablementService_TEST.setRecurringDonations2Enabled();
        mockRD2EnablementState();
        CRLP_Rollup_SEL.cachedRollups = new List<Rollup__mdt>();

        UTIL_OrgTelemetry_SVC telemetrySvc = new UTIL_OrgTelemetry_SVC();
        telemetrySvc.featureManager = (UTIL_FeatureManagement) Test.createStub(UTIL_FeatureManagement.class, featureManagementMock);

        Test.startTest();
        telemetrySvc.processTelemetryType(UTIL_OrgTelemetry_SVC.TelemetryBatchCategory.NPSP_Settings);
        Test.stopTest();

        System.assertEquals(
            10,
            featureManagementMock.packageIntegerValuesByName.get(
                UTIL_OrgTelemetry_SVC.TelemetryParameterName.DataCount_ONETIME_Use.name()
            ),
            'DataCount_ONETIME_Use should have been set to 10 when RD2 is fully enabled'
        );
    }


    /**
     * @description Builds test data import records
     */
    private static List<DataImport__c> buildDataImports(Integer numDataImports, Id diBatchId) {
        List<DataImport__c> dis = new List<DataImport__c>();

        for (Integer i = 0; i < numDataImports; i++) {
             DataImport__c di = new DataImport__c();

            if (diBatchId != null) {
                di.NPSP_Data_Import_Batch__c = diBatchId;
            }

            dis.add(di);
        }

        return dis;
    }

    /**
    * @description Check if RD2 metadata is deployed by verifying if the "Day Of Month" field contains 'Last Day' value and remove '31'
    * @return Boolean
    */
    private static Boolean isRD2MetadataDeployed() {
        List<SelectOption> options = UTIL_Describe.getSelectOptions(
            'npe03__Recurring_Donation__c', String.valueOf(npe03__Recurring_Donation__c.Day_Of_Month__c)
        );
        
        Boolean hasLastDay = false;
        Boolean is31stRemoved = true;

        for (SelectOption option : options) {
            if (option.getValue() == RD2_Constants.DAY_OF_MONTH_LAST_DAY) {
                hasLastDay = true;
            } else if (option.getValue() == '31') {
                is31stRemoved = false;
            }
        }
        return hasLastDay && is31stRemoved;
    }

    /**
    * @description Mock Recurring Donation Custom Setting Enablement State
    */
    private static void mockRD2EnablementState() {
        RD2_EnablementDelegate_CTRL.EnablementState expectedState = new RD2_EnablementDelegate_CTRL.EnablementState();
        expectedState.isMetaLaunched = true;
        RD2_EnablementDelegate_TEST.setEnablementState(JSON.serialize(expectedState));
    }
}