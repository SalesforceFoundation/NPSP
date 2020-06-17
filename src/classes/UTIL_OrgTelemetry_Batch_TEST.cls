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
private class UTIL_OrgTelemetry_Batch_TEST {
    private static UTIL_FeatureManagement_TEST.Mock featureManagementMock = new UTIL_FeatureManagement_TEST.Mock();
    private static Integer NUM_DATA_IMPORT_RECORDS = 100;

    /**
     * @description Confirms that when there are no Recurring Donations, the finish method sets
     * telemetry and does not queue up the batch job
     */
    @isTest
    private static void shouldHandleNoRecurringDonationsToCount() {
        MockTelemetryBatch batch = new MockTelemetryBatch();
        batch.featureManager = (UTIL_FeatureManagement) Test.createStub(UTIL_FeatureManagement.class, featureManagementMock);

        batch.finish(null);

        System.assertEquals(null, batch.countByBatchMode.get(UTIL_OrgTelemetry_SObject_BATCH.TelemetryBatchJobMode.RECURRING_DONATIONS),
            'The RECURRING_DONATIONS should not be executed');

        assertOnTelemetryIntegerMetric(UTIL_OrgTelemetry_SVC.TelemetryParameterName.Data_CountRdOppsAll, 0);
        assertOnTelemetryIntegerMetric(UTIL_OrgTelemetry_SVC.TelemetryParameterName.Data_CountRdOppsOpenEnded, 0);
        assertOnTelemetryIntegerMetric(UTIL_OrgTelemetry_SVC.TelemetryParameterName.Data_CountRecurringDonationsAll, 0);
        assertOnTelemetryIntegerMetric(UTIL_OrgTelemetry_SVC.TelemetryParameterName.Data_CountRdsWithDiffAmount, 0);
    }

    /**
     * @description Confirms that when there are Recurring Donations, the finish method does not set
     * telemetry and does queue up the batch job
     */
    @isTest
    private static void shouldHandleRecurringDonationsToCount() {
        Account donorAccount = new Account(Name = 'foo');
        insert donorAccount;

        insert new TEST_RecurringDonationBuilder()
            .withInstallmentPeriodYearly()
            .withDateEstablished(System.today())
            .withAccount(donorAccount.Id)
            .withAmount(20)
            .withScheduleTypeMultiplyValue()
            .withOpenEndedStatusOpen()
            .build();
            
        MockTelemetryBatch batch = new MockTelemetryBatch();
        batch.featureManager = (UTIL_FeatureManagement) Test.createStub(UTIL_FeatureManagement.class, featureManagementMock);

        batch.finish(null);

        System.assertEquals(1, batch.countByBatchMode.get(UTIL_OrgTelemetry_SObject_BATCH.TelemetryBatchJobMode.RECURRING_DONATIONS),
            'The RECURRING_DONATIONS batch should be executed');

        System.assertEquals(1, batch.countByBatchMode.get(UTIL_OrgTelemetry_SObject_BATCH.TelemetryBatchJobMode.OPPORTUNITIES),
            'The OPPORTUNITIES batch should be executed');

        assertOnTelemetryIntegerMetric(UTIL_OrgTelemetry_SVC.TelemetryParameterName.Data_CountRdOppsAll, null);
        assertOnTelemetryIntegerMetric(UTIL_OrgTelemetry_SVC.TelemetryParameterName.Data_CountRdOppsOpenEnded, null);

        assertOnTelemetryIntegerMetric(UTIL_OrgTelemetry_SVC.TelemetryParameterName.Data_CountOppsWithMultiplePayments, null);
        /* TODO: Holding on Data_OppPaymentsWithoutPaymentsEnabled metric, reenable test when
                 you move forward with Data_OppPaymentsWithoutPaymentsEnabled */
        //assertOnTelemetryIntegerMetric(UTIL_OrgTelemetry_SVC.TelemetryParameterName.Data_OppPaymentsWithoutPaymentsEnabled, null);

        assertOnTelemetryIntegerMetric(UTIL_OrgTelemetry_SVC.TelemetryParameterName.Data_CountRecurringDonationsAll, null);
        assertOnTelemetryIntegerMetric(UTIL_OrgTelemetry_SVC.TelemetryParameterName.Data_CountRdsWithDiffAmount, null);
    }

    /**
     * @description Confirms that when there are no Payments, the finish method sets
     * telemetry and does not queue up the batch job
     */
    @isTest
    private static void shouldHandleNoPayments() {
        MockTelemetryBatch batch = new MockTelemetryBatch();
        batch.featureManager = (UTIL_FeatureManagement) Test.createStub(UTIL_FeatureManagement.class, featureManagementMock);

        batch.finish(null);

        System.assertEquals(null, batch.countByBatchMode.get(UTIL_OrgTelemetry_SObject_BATCH.TelemetryBatchJobMode.OPPORTUNITIES),
            'The OPPORTUNITIES batch should not be executed');

        assertOnTelemetryIntegerMetric(UTIL_OrgTelemetry_SVC.TelemetryParameterName.Data_CountOppsWithMultiplePayments, 0);
        /* TODO: Holding on Data_OppPaymentsWithoutPaymentsEnabled metric, reenable test when
                 you move forward with Data_OppPaymentsWithoutPaymentsEnabled */
        //assertOnTelemetryIntegerMetric(UTIL_OrgTelemetry_SVC.TelemetryParameterName.Data_OppPaymentsWithoutPaymentsEnabled, 0);

        assertOnTelemetryIntegerMetric(UTIL_OrgTelemetry_SVC.TelemetryParameterName.Data_CountRdOppsAll, 0);
        assertOnTelemetryIntegerMetric(UTIL_OrgTelemetry_SVC.TelemetryParameterName.Data_CountRdOppsOpenEnded, 0);
    }

    /**
     * @description Confirms that when there are Opportunities with a mulitple payments and auto payments are enabled,
     * the batch job is queued. Using shouldExecutePaymentsTelemetryBatch to test instead of finish to prevent internal
     * error that gets thrown when multiple tests in the same class set a FeatureParameter
     */
    @isTest
    private static void shouldHandlePaymentsToCount() {
        setupOppWithPayments(2);

        MockTelemetryBatch batch = new MockTelemetryBatch();
        batch.featureManager = (UTIL_FeatureManagement) Test.createStub(UTIL_FeatureManagement.class, featureManagementMock);

        batch.finish(null);

        System.assertEquals(1, batch.countByBatchMode.get(UTIL_OrgTelemetry_SObject_BATCH.TelemetryBatchJobMode.OPPORTUNITIES),
            'The OPPORTUNITIES batch should be executed');

        assertOnTelemetryIntegerMetric(UTIL_OrgTelemetry_SVC.TelemetryParameterName.Data_CountOppsWithMultiplePayments, null);
        /* TODO: Holding on Data_OppPaymentsWithoutPaymentsEnabled metric, reenable test when
                 you move forward with Data_OppPaymentsWithoutPaymentsEnabled */
        //assertOnTelemetryIntegerMetric(UTIL_OrgTelemetry_SVC.TelemetryParameterName.Data_OppPaymentsWithoutPaymentsEnabled, null);

        assertOnTelemetryIntegerMetric(UTIL_OrgTelemetry_SVC.TelemetryParameterName.Data_CountRdOppsAll, null);
        assertOnTelemetryIntegerMetric(UTIL_OrgTelemetry_SVC.TelemetryParameterName.Data_CountRdOppsOpenEnded, null);
    }

    /**
     * @description Confirms that when there are no qualified Data Import records, the finish method sets
     * telemetry and does not queue up the batch job
     */
    @IsTest
    private static void shouldHandleNoDataImportsToCount() {
        MockTelemetryBatch batch = new MockTelemetryBatch();
        batch.featureManager = (UTIL_FeatureManagement) Test.createStub(
                UTIL_FeatureManagement.class, featureManagementMock);
        batch.finish(null);

        System.assertEquals(null, batch.countByBatchMode.get(
                UTIL_OrgTelemetry_SObject_BATCH.TelemetryBatchJobMode.GE_BATCH_DATA_IMPORTS),
                'The Data Import Batch should not be executed');

        assertOnTelemetryIntegerMetric(
                UTIL_OrgTelemetry_SVC.TelemetryParameterName.Data_CountGERowsLast30DaysBatch, 0);
    }


    /**
    * @description Confirms that when there are qualified Data Import records, the batch job is queued.
     * Using shouldExecutePaymentsTelemetryBatch to test instead of finish to prevent internal
    * error that gets thrown when multiple tests in the same class set a FeatureParameter
    */
    @IsTest
    private static void shouldHandleGEDataImportsBatchToCount() {
        createQualifiedDIRecords(NUM_DATA_IMPORT_RECORDS);

        MockTelemetryBatch batch = new MockTelemetryBatch();
        batch.featureManager = (UTIL_FeatureManagement) Test.createStub(
                UTIL_FeatureManagement.class, featureManagementMock);

        batch.finish(null);

        System.assertEquals(1, batch.countByBatchMode.get(
                UTIL_OrgTelemetry_SObject_BATCH.TelemetryBatchJobMode.GE_BATCH_DATA_IMPORTS),
                'The Data Import batch should be executed'
        );

        assertOnTelemetryIntegerMetric(
                UTIL_OrgTelemetry_SVC.TelemetryParameterName.Data_CountGERowsLast30DaysBatch, null);
    }


    /**
     * @description Asserts on the provided telemetry integer metric
     */
    private static void assertOnTelemetryIntegerMetric(UTIL_OrgTelemetry_SVC.TelemetryParameterName metric, Integer expectedValue) {
        String metricName = metric.name();
        String messsage = expectedValue == null ?
            'The feature parameter metric ' + metricName + ' should not be set'
            : 'The feature parameter metric ' + metricName + ' should be set correctly';

        System.assertEquals(
            expectedValue,
            featureManagementMock.packageIntegerValuesByName.get(metricName),
            messsage
        );
    }

    /**
     * @description Creates an opportunity with specified number of payments
     */
    private static void setupOppWithPayments(Integer numPayments) {
        Opportunity opp = new Opportunity(
            Name = 'Test Opp ',
            StageName = UTIL_UnitTestData_TEST.getClosedWonStage(),
            CloseDate = Date.today()
        );

        insert opp;

        List<npe01__OppPayment__c> payments = new List<npe01__OppPayment__c>();
        for (Integer i = 0; i < numPayments; i++) {
            payments.add(new npe01__OppPayment__c(npe01__Payment_Amount__c = 100, npe01__Opportunity__c = opp.Id));
        }
        insert payments;
    }

    private static void createQualifiedDIRecords(Integer numberOfRecords) {
        List<DataImport__c> dataImports = UTIL_UnitTestData_TEST.createDIRecordsInANewGEBatch(numberOfRecords);
        insert dataImports;
    }

    /**
     * @description Mock implementation of UTIL_OrgTelemetry_BATCH that overrides executeTelemetrySObjectBatch
     * to prevent UTIL_OrgTelemetry_SObject_BATCH from running. Running the UTIL_OrgTelemetry_SObject_BATCH 
     * batch can can cause an internal error to get thrown due to tests in the same class both trying 
     * to set the same FeatureParameter.
     */
    private class MockTelemetryBatch extends UTIL_OrgTelemetry_BATCH {
        private Map<UTIL_OrgTelemetry_SObject_BATCH.TelemetryBatchJobMode, Integer> countByBatchMode = 
            new Map<UTIL_OrgTelemetry_SObject_BATCH.TelemetryBatchJobMode, Integer>();

        private virtual override void executeTelemetrySObjectBatch(UTIL_OrgTelemetry_SObject_BATCH.TelemetryBatchJobMode mode, Integer batchSize) {
            if (!countByBatchMode.containsKey(mode)) {
                countByBatchMode.put(mode, 0);
            }
            Integer currentCount = countByBatchMode.get(mode);
            countByBatchMode.put(mode, currentCount + 1);
        }
    }
}