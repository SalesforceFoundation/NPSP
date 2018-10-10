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
private class UTIL_OrgTelemetry_TEST {

    /**
     * @description Create a single Account, Contact and Opportunity to use for the telemetry test data
     **/
    @TestSetup
    static void testDataSetup() {
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

        npe03__Recurring_Donation__c rd = new npe03__Recurring_Donation__c(
                Name = 'UTIL_OrgTelemetry_TEST',
                npe03__Contact__c = c.Id,
                npe03__Installments__c = 3,
                npe03__Amount__c = 100,
                npe03__Installment_Period__c = System.Label.npe03.RecurringDonationInstallmentPeriodYearly,
                npe03__Date_Established__c = Date.newInstance(2018,6,15),
                npe03__Schedule_Type__c = System.Label.npe03.RecurringDonationMultiplyValue,
                npe03__Open_Ended_Status__c = System.Label.npe03.RecurringDonationOpenStatus
        );
        insert rd;
    }

    /**
     * @description Test that the NPSP_Settings telemetry data is retrieved.
     * It's not possible to validate that the call to System.FeatureManagement() call succeeded.
     */
    @IsTest
    static void validateNPSPSettingsTelemetry() {
        Test.startTest();
        UTIL_OrgTelemetry_SVC.asyncProcessNpspSettingsTelemetry();

        Integer currQueryCount = Limits.getQueries();
        UTIL_OrgTelemetry_SVC telemetrySvc = new UTIL_OrgTelemetry_SVC();
        telemetrySvc.processTelemetryType(UTIL_OrgTelemetry_SVC.TelemetryBatchCategory.NPSP_Settings);

        System.assertEquals(currQueryCount, Limits.getQueries(), 'There should no new queries executed because these only reference static custom setting');
        Test.stopTest();
    }

    /**
     * @description Test that the org settings telemetry data is retrieved.
     * It's not possible to validate that the call to System.FeatureManagement() call succeeded.
     */
    @IsTest
    static void validateOrgEnvironmentTelemetry() {
        Test.startTest();
        Integer currQueryCount = Limits.getQueries();

        UTIL_OrgTelemetry_SVC telemetrySvc = new UTIL_OrgTelemetry_SVC();
        telemetrySvc.processTelemetryType(UTIL_OrgTelemetry_SVC.TelemetryBatchCategory.Org_Environment);

        System.assert(Limits.getQueries() > currQueryCount, 'There should be at least one new query executed');
        Test.stopTest();
    }

    /**
     * @description Test that the MaxNumRelatedOpps settings telemetry data is retrieved.
     * that the call to System.FeatureManagement() call succeeded.
     */
    @IsTest
    static void validateMaxNumRelatedOppsTelemetry() {
        Test.startTest();
        Integer currQueryCount = Limits.getQueries();

        UTIL_OrgTelemetry_SVC telemetrySvc = new UTIL_OrgTelemetry_SVC();
        telemetrySvc.processTelemetryType(UTIL_OrgTelemetry_SVC.TelemetryBatchCategory.Data_MaxNumRelatedOpps);

        System.assertEquals(currQueryCount+1, Limits.getQueries(), 'There should be one new query executed');
        Test.stopTest();
    }

    /**
     * @description Test that the DataCountOfRD settings telemetry data is retrieved.
     * It's not possible to validate that the call to System.FeatureManagement() call succeeded.
     */
    @IsTest
    static void validateCountOfRDOppsTelemetry() {
        Test.startTest();

        UTIL_OrgTelemetry_SVC telemetrySvc = new UTIL_OrgTelemetry_SVC();
        telemetrySvc.processTelemetryType(UTIL_OrgTelemetry_SVC.TelemetryBatchCategory.Data_CountRdOpps);

        Test.stopTest();
        // Haven't found a way to assert that this job is have been queued to execute.
        // This category no longer does a query and there is no way to check the value of a featureParameter
        // in a unit test.
    }

    /**
     * @description Test that the Data_CountOfErrorLog settings telemetry data is retrieved.
     * It's not possible to validate that the call to System.FeatureManagement() call succeeded.
     */
    @IsTest
    static void validateCountOfErrorLogTelemetry() {
        Test.startTest();
        Integer currQueryCount = Limits.getQueries();

        UTIL_OrgTelemetry_SVC telemetrySvc = new UTIL_OrgTelemetry_SVC();
        telemetrySvc.processTelemetryType(UTIL_OrgTelemetry_SVC.TelemetryBatchCategory.Data_CountErrorLog);

        System.assertEquals(currQueryCount+1, Limits.getQueries(), 'There should be one new query executed');
        Test.stopTest();
    }
}