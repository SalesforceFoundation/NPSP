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
     * @description Submits the telemetry batch job to execute. This will only execute a single child iteration
     * and not the entire set of data. It's not possible to determine if the job actually completed.
     * It's not possible to validate that the call to System.FeatureManagement() call succeeded.
     * This specific test needs to be in a separate test class to avoid an internal error that is thrown when
     * testing along side other methods that call the same featureParameter value used by this test.
     */
    @IsTest
    static void validateTelemetryBatchJob() {
        Test.startTest();
        UTIL_OrgTelemetry_SVC.dispatchTelemetryBatchJob();
        Test.stopTest();
    }

    /**
     * @description Confirms that when there are no Recurring Donations, the finish method sets
     * Data_CountRdOppsAll and Data_CountRdOppsOpenEnded to 0 and does not queue up the batch job. Can only test this negative
     * case as running the batch will cause internal error to be thrown when
     * testing along side other methods that call the same featureParameter value used by this test.
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

        System.assertEquals(
            0,
            featureManagementMock.packageIntegerValuesByName.get(
                UTIL_OrgTelemetry_SVC.TelemetryParameterName.Data_CountRdOppsAll.name()
            ),
            'setPackageIntegerValue should have been called with the feature Data_CountRdOppsAll and set to 0'
        );

        System.assertEquals(
            0,
            featureManagementMock.packageIntegerValuesByName.get(
                UTIL_OrgTelemetry_SVC.TelemetryParameterName.Data_CountRdOppsOpenEnded.name()
            ),
            'setPackageIntegerValue should have been called with the feature Data_CountRdOppsOpenEnded and set to 0'
        );
    }

    /**
     * @description Confirms that when there are no Recurring Donations, the finish method sets
     * Data_CountOppsWithMultiplePayments and Data_OppPaymentsWithoutPaymentsEnabled to 0 and does not queue up the
     * batch job. Can only test this negative case as running the batch will cause internal error to be thrown when
     * testing along side other methods that call the same featureParameter value used by this test.
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

        System.assertEquals(
            0,
            featureManagementMock.packageIntegerValuesByName.get(
                UTIL_OrgTelemetry_SVC.TelemetryParameterName.Data_CountOppsWithMultiplePayments.name()
            ),
            'setPackageIntegerValue should have been called with the feature Data_CountOppsWithMultiplePayments and set to 0'
        );

        System.assertEquals(
            0,
            featureManagementMock.packageIntegerValuesByName.get(
                UTIL_OrgTelemetry_SVC.TelemetryParameterName.Data_OppPaymentsWithoutPaymentsEnabled.name()
            ),
            'setPackageIntegerValue should have been called with the feature Data_OppPaymentsWithoutPaymentsEnabled and set to 0'
        );
    }
}