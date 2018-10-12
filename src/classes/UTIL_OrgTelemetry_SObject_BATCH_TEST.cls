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

    /**
     * @description Create test data needed for the unit tests in this class
     */
    @TestSetup
    static void testDataSetup() {

        Account a = new Account(Name = 'UTIL_OrgTelemetry_SObject_BATCH_TEST', Type = 'New');
        insert a;

        npe03__Recurring_Donation__c rd = new npe03__Recurring_Donation__c(
                Name = 'UTIL_OrgTelemetry_SObject_BATCH_TEST',
                npe03__Organization__c = a.Id,
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
     * @description Provide coverage test for the executed batch job. There's no way to verify that the
     * job executed; and the job itself modifies no data that can be validated against.
     * The lack of a failed test itself is an implicit assert that the batch job completed.
     */
    @IsTest
    static void testSObjectBatchJob() {
        Test.startTest();
        Database.executeBatch(
                new UTIL_OrgTelemetry_SObject_BATCH(UTIL_OrgTelemetry_SObject_BATCH.TelemetryBatchJobMode.RECURRING_DONATIONS), 20);
        Test.stopTest();
    }
}