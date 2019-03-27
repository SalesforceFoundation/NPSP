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
private class UTIL_OrgTelemetry_SObject_BATCH_TEST {

    private static UTIL_FeatureManagement_TEST.Mock featureManagementMock = new UTIL_FeatureManagement_TEST.Mock();

    /**
     * @description Create test data needed for the unit tests in this class
     */
    @TestSetup
    static void testDataSetup() {
        TDTM_Config_API.disableAllTriggers();

        npe03__Recurring_Donation__c openRd = new npe03__Recurring_Donation__c(
            npe03__Amount__c = 100,
            npe03__Open_Ended_Status__c = System.Label.npe03.RecurringDonationOpenStatus
        );

        npe03__Recurring_Donation__c closedRd = new npe03__Recurring_Donation__c(
            npe03__Amount__c = 1200,
            npe03__Open_Ended_Status__c = System.Label.npe03.RecurringDonationClosedStatus
        );

        insert new List<npe03__Recurring_Donation__c>{ openRd, closedRd };

        Map<Schema.SObjectField, Object> fieldValues = new Map<Schema.SObjectField, Object> {
            Opportunity.Amount => 100,
            Opportunity.npe03__Recurring_Donation__c => openRd.Id
        };

        //Build opps for open recurring donation
        List<Opportunity> opps = buildOpps(1, fieldValues);

        //Build opps for closed recurring donation
        fieldValues.put(Opportunity.npe03__Recurring_Donation__c, closedRd.Id);
        opps.addAll(buildOpps(12, fieldValues));

        insert opps;
    }

    /**
     * @description Provide coverage test for the executed batch job. There's no way to verify that the
     * job executed; and the job itself modifies no data that can be validated against.
     * The lack of a failed test itself is an implicit assert that the batch job completed.
     */
    @IsTest
    static void testSObjectBatchJob() {
        Test.startTest();
        Database.executeBatch(
            new UTIL_OrgTelemetry_SObject_BATCH(UTIL_OrgTelemetry_SObject_BATCH.TelemetryBatchJobMode.OPPORTUNITIES), 20);
        Test.stopTest();
    }

    /**
     * @description Confirms job modes query for the correct SObject type
     */
    @IsTest
    static void jobModeShouldReturnCorrectQuery() {
        UTIL_OrgTelemetry_SObject_BATCH oppBatch =
            new UTIL_OrgTelemetry_SObject_BATCH(UTIL_OrgTelemetry_SObject_BATCH.TelemetryBatchJobMode.OPPORTUNITIES);

        String oppBatchQuery = oppBatch.start(null).getQuery();
        System.assert(Database.query(oppBatchQuery) instanceof List<Opportunity>,
            'OPPORTUNITIES job mode should query Opportunities');

        UTIL_OrgTelemetry_SObject_BATCH rdBatch =
            new UTIL_OrgTelemetry_SObject_BATCH(UTIL_OrgTelemetry_SObject_BATCH.TelemetryBatchJobMode.RECURRING_DONATIONS);

        String rdBatchQuery = rdBatch.start(null).getQuery();
        System.assert(Database.query(rdBatchQuery) instanceof List<npe03__Recurring_Donation__c>,
            'OPPORTUNITIES job mode should query Recurring Donations');
    }

    /**
     * @description Confirms Recurring Donation Opportunity counts are calculated correctly
     */
    @IsTest
    static void shouldCalculateCorrectRecurringDonationOppMetrics() {
        UTIL_OrgTelemetry_SObject_BATCH oppBatch =
            new UTIL_OrgTelemetry_SObject_BATCH(UTIL_OrgTelemetry_SObject_BATCH.TelemetryBatchJobMode.OPPORTUNITIES);

        String oppBatchQuery = oppBatch.start(null).getQuery();
        List<Opportunity> opps = Database.query(oppBatchQuery);

        Test.startTest();
        oppBatch.execute(null, opps);
        Test.stopTest();

        System.assertEquals(13, oppBatch.rdAllOppsCount,
            'The number of opps should be tracked correctly');
        System.assertEquals(1, oppBatch.rdOpenStatusOppsCount,
            'The number of open ended opps should be tracked correctly');
    }

    /**
     * @description Confirms Recurring Donation counts are calculated correctly
     */
    @IsTest
    static void shouldCalculateCorrectRecurringDonationMetrics() {
        UTIL_OrgTelemetry_SObject_BATCH rdBatch =
            new UTIL_OrgTelemetry_SObject_BATCH(UTIL_OrgTelemetry_SObject_BATCH.TelemetryBatchJobMode.RECURRING_DONATIONS);

        String rdBatchQuery = rdBatch.start(null).getQuery();
        List<npe03__Recurring_Donation__c> recurringDonations = Database.query(rdBatchQuery);

        Test.startTest();
        rdBatch.execute(null, recurringDonations);
        Test.stopTest();

        System.assertEquals(2, rdBatch.rdAllCount,
            'The number of Recurring Donations should be tracked correctly');

        System.assertEquals(1, rdBatch.rdDiffCount,
            'The number of Recurring Donations with an amount differing from its opportunities should be tracked correctly');
    }

    /**
     * @description Confirms Recurring Donation Opportunity metrics are captured in FeatureManagement
     * at the end of the batch
     */
    @isTest
    private static void shouldCaptureRecurringDonationOppMetricsInFeatureManagement() {
        UTIL_OrgTelemetry_SObject_BATCH oppBatch =
            new UTIL_OrgTelemetry_SObject_BATCH(UTIL_OrgTelemetry_SObject_BATCH.TelemetryBatchJobMode.OPPORTUNITIES);
        oppBatch.featureManager = (UTIL_FeatureManagement) Test.createStub(UTIL_FeatureManagement.class, featureManagementMock);

        oppBatch.rdAllOppsCount = 2;
        oppBatch.rdOpenStatusOppsCount = 1;

        oppBatch.rdAllCount = 4;
        oppBatch.rdDiffCount = 3;

        Test.startTest();
        oppBatch.finish(null);
        Test.stopTest();

        System.assertEquals(
            oppBatch.rdAllOppsCount,
            featureManagementMock.packageIntegerValuesByName.get(
                UTIL_OrgTelemetry_SVC.TelemetryParameterName.Data_CountRdOppsAll.name()
            ),
            'setPackageIntegerValue should have been called with the feature Data_CountRdOppsAll and set correctly'
        );

        System.assertEquals(
            oppBatch.rdOpenStatusOppsCount,
            featureManagementMock.packageIntegerValuesByName.get(
                UTIL_OrgTelemetry_SVC.TelemetryParameterName.Data_CountRdOppsOpenEnded.name()
            ),
            'setPackageIntegerValue should have been called with the feature Data_CountRdOppsOpenEnded and set correctly'
        );
    }

    /**
     * @description Confirms Recurring Donation metrics are captured in FeatureManagement at the end of the batch
     */
    @isTest
    private static void shouldCaptureRecurringDonationMetricsInFeatureManagement() {
        UTIL_OrgTelemetry_SObject_BATCH rdBatch =
            new UTIL_OrgTelemetry_SObject_BATCH(UTIL_OrgTelemetry_SObject_BATCH.TelemetryBatchJobMode.RECURRING_DONATIONS);
        rdBatch.featureManager = (UTIL_FeatureManagement) Test.createStub(UTIL_FeatureManagement.class, featureManagementMock);

        rdBatch.rdAllOppsCount = 2;
        rdBatch.rdOpenStatusOppsCount = 1;

        rdBatch.rdAllCount = 4;
        rdBatch.rdDiffCount = 3;

        Test.startTest();
        rdBatch.finish(null);
        Test.stopTest();

        System.assertEquals(
            rdBatch.rdAllCount,
            featureManagementMock.packageIntegerValuesByName.get(
                UTIL_OrgTelemetry_SVC.TelemetryParameterName.Data_CountRecurringDonationsAll.name()
            ),
            'setPackageIntegerValue should have been called with the feature Data_CountRecurringDonationsAll and set correctly'
        );

        System.assertEquals(
            rdBatch.rdDiffCount,
            featureManagementMock.packageIntegerValuesByName.get(
                UTIL_OrgTelemetry_SVC.TelemetryParameterName.Data_CountRdsWithDiffAmount.name()
            ),
            'setPackageIntegerValue should have been called with the feature Data_CountRdsWithDiffAmount and set correctly'
        );
    }

    /**
     * @description Builds test opportunity records with the given field values
     */
    private static List<Opportunity> buildOpps(Integer numOpps, Map<Schema.SObjectField, Object> fieldValues) {
        List<Opportunity> opps = new List<Opportunity>();

        for (Integer i = 0; i < numOpps; i++) {
            Opportunity opp = new Opportunity(
                Name = 'Test Opp ' + i,
                StageName = UTIL_UnitTestData_TEST.getClosedWonStage(),
                CloseDate = Date.today()
            );

            for (Schema.SObjectField field : fieldValues.keySet()) {
                opp.put(field, fieldValues.get(field));
            }

            opps.add(opp);
        }

        return opps;
    }
}