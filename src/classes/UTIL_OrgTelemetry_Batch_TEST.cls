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
@IsTest(IsParallel=false)
private class UTIL_OrgTelemetry_Batch_TEST {
    private static UTIL_FeatureManagement_TEST.Mock featureManagementMock = new UTIL_FeatureManagement_TEST.Mock();

    /**
     * @description Confirms that when there are no Recurring Donations, the finish method sets
     * telemetry and does not queue up the batch job
     */
    @isTest
    private static void shouldHandleNoRecurringDonationsToCount() {
        UTIL_OrgTelemetry_Batch batch = new UTIL_OrgTelemetry_Batch();
        batch.featureManager = (UTIL_FeatureManagement) Test.createStub(UTIL_FeatureManagement.class, featureManagementMock);

        batch.finish(null);

        Integer batchCount =  [
            SELECT COUNT()
            FROM AsyncApexJob
            WHERE JobType = 'BatchApex'
                AND ApexClass.Name = 'UTIL_OrgTelemetry_SObject_BATCH'
        ];

        System.assertEquals(0, batchCount, 'A batch should not be queued');

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

        insert new npe03__Recurring_Donation__c(
            Name = 'foo',
            npe03__Installment_Period__c = system.label.npe03.RecurringDonationInstallmentPeriodYearly,
            npe03__Date_Established__c= System.today(),
            npe03__Organization__c = donorAccount.Id,
            npe03__Amount__c = 20,
            npe03__Schedule_Type__c = system.label.npe03.RecurringDonationMultiplyValue,
            npe03__Open_Ended_Status__c = system.label.npe03.RecurringDonationOpenStatus
        );

        UTIL_OrgTelemetry_Batch batch = new UTIL_OrgTelemetry_Batch();
        batch.featureManager = (UTIL_FeatureManagement) Test.createStub(UTIL_FeatureManagement.class, featureManagementMock);

        batch.finish(null);

        Integer batchCount =  [
            SELECT COUNT()
            FROM AsyncApexJob
            WHERE JobType = 'BatchApex'
                AND ApexClass.Name = 'UTIL_OrgTelemetry_SObject_BATCH'
        ];

        System.assertEquals(2, batchCount, 'The correct number of batches should be queued');

        assertOnTelemetryIntegerMetric(UTIL_OrgTelemetry_SVC.TelemetryParameterName.Data_CountRdOppsAll, null);
        assertOnTelemetryIntegerMetric(UTIL_OrgTelemetry_SVC.TelemetryParameterName.Data_CountRdOppsOpenEnded, null);
        assertOnTelemetryIntegerMetric(UTIL_OrgTelemetry_SVC.TelemetryParameterName.Data_CountRecurringDonationsAll, null);
        assertOnTelemetryIntegerMetric(UTIL_OrgTelemetry_SVC.TelemetryParameterName.Data_CountRdsWithDiffAmount, null);
    }

    /**
     * @description Confirms that when there are no Payments, the finish method sets
     * telemetry and does not queue up the batch job
     */
    @isTest
    private static void shouldHandleNoOpportunitiesWithMultiplePayments() {
        UTIL_OrgTelemetry_Batch batch = new UTIL_OrgTelemetry_Batch();
        batch.featureManager = (UTIL_FeatureManagement) Test.createStub(UTIL_FeatureManagement.class, featureManagementMock);

        batch.finish(null);

        Integer batchCount =  [
            SELECT COUNT()
            FROM AsyncApexJob
            WHERE JobType = 'BatchApex'
                AND ApexClass.Name = 'UTIL_OrgTelemetry_SObject_BATCH'
        ];

        System.assertEquals(0, batchCount, 'A batch should not be queued');

        assertOnTelemetryIntegerMetric(UTIL_OrgTelemetry_SVC.TelemetryParameterName.Data_CountOppsWithMultiplePayments, 0);
        assertOnTelemetryIntegerMetric(UTIL_OrgTelemetry_SVC.TelemetryParameterName.Data_OppPaymentsWithoutPaymentsEnabled, 0);
    }

    /**
     * @description Confirms that when there are Opportunities with a mulitple payments and auto payments are enabled,
     * the batch job is queued. Using shouldExecutePaymentsTelemetryBatch to test instead of finish to prevent internal
     * error that gets thrown when multiple tests in the same class set a FeatureParameter
     */
    @isTest
    private static void shouldHandleOpportunitiesWithMultipleOpporutnitiesAndAutoPaymentsEnabled() {
        setupOppWithPayments(2);

        UTIL_CustomSettingsFacade.getContactsSettingsForTests(
            new npe01__Contacts_And_Orgs_Settings__c(npe01__Payments_Enabled__c = true)
        );

        UTIL_OrgTelemetry_Batch batch = new UTIL_OrgTelemetry_Batch();

        System.assertEquals(true, batch.shouldExecutePaymentsTelemetryBatch(), 'Should queue up batch');
    }

    /**
     * @description Confirms that when there are only Opportunities with a single payment and auto payments are enabled,
     * the batch job is not queued.
     */
    @isTest
    private static void shouldHandleOpportunitiesWithOnlySinglePaymentAndAutoPaymentsEnabled() {
        setupOppWithPayments(1);

        UTIL_CustomSettingsFacade.getContactsSettingsForTests(
            new npe01__Contacts_And_Orgs_Settings__c(npe01__Payments_Enabled__c = true)
        );

        UTIL_OrgTelemetry_Batch batch = new UTIL_OrgTelemetry_Batch();
        batch.featureManager = (UTIL_FeatureManagement) Test.createStub(UTIL_FeatureManagement.class, featureManagementMock);

        batch.finish(null);

        Integer batchCount =  [
            SELECT COUNT()
            FROM AsyncApexJob
            WHERE JobType = 'BatchApex'
                AND ApexClass.Name = 'UTIL_OrgTelemetry_SObject_BATCH'
        ];

        System.assertEquals(0, batchCount, 'A batch should not be queued');

        assertOnTelemetryIntegerMetric(UTIL_OrgTelemetry_SVC.TelemetryParameterName.Data_CountOppsWithMultiplePayments, 0);
        assertOnTelemetryIntegerMetric(UTIL_OrgTelemetry_SVC.TelemetryParameterName.Data_OppPaymentsWithoutPaymentsEnabled, 0);
    }

    /**
     * @description Confirms that when there are only Opportunities with a single payment and auto payments are disabled,
     * the batch job is queued. Using shouldExecutePaymentsTelemetryBatch to test instead of finish to prevent internal
     * error that gets thrown when multiple tests in the same class set a FeatureParameter
     */
    @isTest
    private static void shouldHandleOpportunitiesOnlySinglePaymentAndAutoPaymentsDisabled() {
        setupOppWithPayments(1);

        UTIL_CustomSettingsFacade.getContactsSettingsForTests(
            new npe01__Contacts_And_Orgs_Settings__c(npe01__Payments_Enabled__c = false)
        );

        UTIL_OrgTelemetry_Batch batch = new UTIL_OrgTelemetry_Batch();
        System.assertEquals(true, batch.shouldExecutePaymentsTelemetryBatch(), 'Should queue up batch');
    }

    /**
     * @description Asserts on provide telemetry integer metric
     */
    private static void assertOnTelemetryIntegerMetric(UTIL_OrgTelemetry_SVC.TelemetryParameterName metric, Integer expectedValue) {
        String metricName = metric.name();
        System.assertEquals(
            expectedValue,
            featureManagementMock.packageIntegerValuesByName.get(metricName),
            'The feature paraemter metric ' + metricName + ' should be set correctly'
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
}