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
@isTest(IsParallel=false)
private class UTIL_OrgTelemetry_TEST {

    /**
     * @description Create a single Account, Contact and Opportunity to use for the telemetry test data
     **/
    @TestSetup
    static void testDataSetup() {
        Contact c = UTIL_UnitTestData_TEST.getContact();
        insert c;

        c = [SELECT Id, FirstName, LastName, AccountId FROM Contact LIMIT 1];
        Id acctId = c.AccountId;

        String closedStage = UTIL_UnitTestData_TEST.getClosedWonStage();

        Opportunity opp = new Opportunity (
                Name = 'Test Opp ' + c.FirstName + ' ' + c.LastName,
                Amount = 1000,
                CloseDate = Date.today(),
                StageName = closedStage,
                Primary_Contact__c = c.Id
        );
        insert opp;
    }

    /**
     * @description Submits the telemetry batch job to execute. This will only execute a single child iteration
     * and not the entire set of data. It's not possible to determine if the job actually completed.
     * It's not possible to validate that the call to System.FeatureManagement() call succeeded.
     */
    static testMethod void test_telemetryBatchJob() {
        Test.startTest();
        UTIL_OrgTelemetry_SVC.dispatchTelemetryBatchJob();
        Test.stopTest();
    }

    /**
     * @description Test that the NPSP_Settings telemetry data is retrieved.
     * It's not possible to validate that the call to System.FeatureManagement() call succeeded.
     */
    static testMethod void test_telemetry_NPSP_Settings() {
        Test.startTest();
        Integer currQueryCount = Limits.getQueries();
        UTIL_OrgTelemetry_SVC telemetrySvc = new UTIL_OrgTelemetry_SVC();
        telemetrySvc.processTelemetryType(UTIL_OrgTelemetry_SVC.TelemetryTypeEnum.NPSP_Settings);
        System.Assert(Limits.getQueries() > currQueryCount, 'There should be at least one new query executed');
        Test.stopTest();
    }

    /**
     * @description Test that the org settings telemetry data is retrieved.
     * It's not possible to validate that the call to System.FeatureManagement() call succeeded.
     */
    static testMethod void test_telemetry_Org_Environment() {
        Test.startTest();
        Integer currQueryCount = Limits.getQueries();
        UTIL_OrgTelemetry_SVC telemetrySvc = new UTIL_OrgTelemetry_SVC();
        telemetrySvc.processTelemetryType(UTIL_OrgTelemetry_SVC.TelemetryTypeEnum.Org_Environment);
        System.Assert(Limits.getQueries() > currQueryCount, 'There should be at least one new query executed');
        Test.stopTest();
    }

    /**
     * @description Test that the MaxNumRelatedOpps settings telemetry data is retrieved.
     * that the call to System.FeatureManagement() call succeeded.
     */
    static testMethod void test_telemetry_Data_MaxNumRelatedOpps() {
        Test.startTest();
        Integer currQueryCount = Limits.getQueries();
        UTIL_OrgTelemetry_SVC telemetrySvc = new UTIL_OrgTelemetry_SVC();
        telemetrySvc.processTelemetryType(UTIL_OrgTelemetry_SVC.TelemetryTypeEnum.Data_MaxNumRelatedOpps);
        System.AssertEquals(currQueryCount+1, Limits.getQueries(), 'There should be one new query executed');
        Test.stopTest();
    }

    /**
     * @description Test that the Data_Count_of_RD_Opps_All settings telemetry data is retrieved.
     * It's not possible to validate that the call to System.FeatureManagement() call succeeded.
     */
    static testMethod void test_telemetry_Data_Count_of_RD_Opps_All() {
        Test.startTest();
        Integer currQueryCount = Limits.getQueries();
        UTIL_OrgTelemetry_SVC telemetrySvc = new UTIL_OrgTelemetry_SVC();
        telemetrySvc.processTelemetryType(UTIL_OrgTelemetry_SVC.TelemetryTypeEnum.Data_Count_of_RD_Opps_All);
        System.AssertEquals(currQueryCount+1, Limits.getQueries(), 'There should be one new query executed');
        Test.stopTest();
    }

    /**
     * @description Test that the Data_Count_of_RD_Opps_OpenEnded settings telemetry data is retrieved.
     * It's not possible to validate that the call to System.FeatureManagement() call succeeded.
     */
    static testMethod void test_telemetry_Data_Count_of_RD_Opps_OpenEnded() {
        Test.startTest();
        Integer currQueryCount = Limits.getQueries();
        UTIL_OrgTelemetry_SVC telemetrySvc = new UTIL_OrgTelemetry_SVC();
        telemetrySvc.processTelemetryType(UTIL_OrgTelemetry_SVC.TelemetryTypeEnum.Data_Count_of_RD_Opps_OpenEnded);
        System.AssertEquals(currQueryCount+1, Limits.getQueries(), 'There should be one new query executed');
        Test.stopTest();
    }

    /**
     * @description Test that the Data_CountOfErrorLog settings telemetry data is retrieved.
     * It's not possible to validate that the call to System.FeatureManagement() call succeeded.
     */
    static testMethod void test_telemetry_Data_CountOfErrorLog() {
        Test.startTest();
        Integer currQueryCount = Limits.getQueries();
        UTIL_OrgTelemetry_SVC telemetrySvc = new UTIL_OrgTelemetry_SVC();
        telemetrySvc.processTelemetryType(UTIL_OrgTelemetry_SVC.TelemetryTypeEnum.Data_CountOfErrorLog);
        System.AssertEquals(currQueryCount+1, Limits.getQueries(), 'There should be one new query executed');
        Test.stopTest();
    }
}