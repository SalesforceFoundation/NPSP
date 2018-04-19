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
@isTest(IsParallel=true)
private class UTIL_OrgTelemetry_TEST {

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

    static testMethod void test_telemetry() {
        UTIL_OrgTelemetry_SVC.submitFeatureTelemetryToLMO_ASync();
    }
}