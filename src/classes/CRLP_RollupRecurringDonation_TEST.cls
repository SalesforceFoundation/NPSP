
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
* @group Customizable Rollups Operations Services
* @description Unit Test for the Opportunity to Recurring Donation Rollups
*/
@isTest
private class CRLP_RollupRecurringDonation_TEST {

    private Enum TestType {
        TestTrigger, TestQueueuable, TestBatch, testSkewBatch
    }

    /**
     * @description Test Setup: Insert a dummy contact and let it create an Account. The Opportunity data has to
     * be created in the actual unit test to allow for the trigger test to run
     */
    @TestSetup
    private static void setupBaseTestData() {
        Contact c = UTIL_UnitTestData_TEST.getContact();
        insert c;
    }

    /**
     * @description Create Rollup__mdt records to test rolling up from the Opp object to Recurring Donations
     */
    private static void mockRollupCMTValues() {

        // Create a single Filter Group (no need for filter rules here)
        String filterGroupId1 = CMT_UnitTestData_TEST.getNewRecordId();
        String filterGroupId2 = CMT_UnitTestData_TEST.getNewRecordId();

        // Simple testing filters for IsWon, RecordType, and Paid/Written Off
        String filterGroupsJSON = '[' +
                CMT_UnitTestData_TEST.createFilterGroupRecord(filterGroupId1, 'TestFilterGroup1-Pledged') + ',' +
                CMT_UnitTestData_TEST.createFilterGroupRecord(filterGroupId2, 'TestFilterGroup2-ClosedWon') +
                ']';
        String filterRulesJSON = '[' +
                CMT_UnitTestData_TEST.createFilterRuleRecord(null, filterGroupId1, 'Group1.Rule1', 'Opportunity', 'IsWon', 'Equals', 'False') + ',' +
                CMT_UnitTestData_TEST.createFilterRuleRecord(null, filterGroupId1, 'Group1.Rule2', 'Opportunity', 'IsClosed', 'Equals', 'False') + ',' +

                CMT_UnitTestData_TEST.createFilterRuleRecord(null, filterGroupId2, 'Group2.Rule1', 'Opportunity', 'IsWon', 'Equals', 'True') +
                ']';

        // Deserialize the filter group and filter rule to use for the tests
        CMT_FilterRule_SEL.cachedFilterGroups = (List<Filter_Group__mdt>)JSON.deserialize(filterGroupsJSON, List<Filter_Group__mdt>.class);
        CMT_FilterRule_SEL.cachedFilterRules = (List<Filter_Rule__mdt>)JSON.deserialize(filterRulesJSON, List<Filter_Rule__mdt>.class);

        // Create a Rollup that uses the above Filter Group
        String rollupsJSON = '[' +
                CMT_UnitTestData_TEST.createRollupRecord('RD Next Payment Date', filterGroupId1,
                        CMT_UnitTestData_TEST.RollupRecordType.OppToRD,
                        'npe03__Next_Payment_Date__c', CRLP_Operation.RollupType.First, 'CloseDate') + ',' +

                CMT_UnitTestData_TEST.createRollupRecord('RD Last Payment Date', filterGroupId2,
                        CMT_UnitTestData_TEST.RollupRecordType.OppToRD,
                        'npe03__Last_Payment_Date__c', CRLP_Operation.RollupType.Last, 'CloseDate') + ',' +

                CMT_UnitTestData_TEST.createRollupRecord('RD Total Paid Amount', filterGroupId2,
                        CMT_UnitTestData_TEST.RollupRecordType.OppToRD,
                        'npe03__Paid_Amount__c', CRLP_Operation.RollupType.SUM, 'Amount') + ',' +

                CMT_UnitTestData_TEST.createRollupRecord('RD Total Paid Installments', filterGroupId2,
                        CMT_UnitTestData_TEST.RollupRecordType.OppToRD,
                        'npe03__Total_Paid_Installments__c', CRLP_Operation.RollupType.Count, 'CloseDate') +

                ']';

        // Deserialize the rollups to use for testing
        CRLP_Rollup_SEL.cachedRollups = (List<Rollup__mdt>) JSON.deserialize(rollupsJSON, List<Rollup__mdt>.class);
    }

    static testMethod void test_Rollups_Queueable() {
        testRollupsServices(TestType.TestQueueuable);
    }
    static testMethod void test_Rollups_Batch() {
        testRollupsServices(TestType.TestBatch);
    }
    static testMethod void test_Rollups_SkewBatch() {
        testRollupsServices(TestType.testSkewBatch);
    }
    static testMethod void test_Rollups_Trigger() {
        testRollupsServices(TestType.TestTrigger);
    }

    /**
     * @description Test some simple rollups from the Opportunity object to Recurring Donations using
     * four different methods:
     * 1. Trigger based rollup
     * 2. Call a Queueuable method directly (simulates clicking a button to recalculate)
     * 3. Nightly Batch Job
     * 4. Nightly LDV Batch Job
     */
    private static void testRollupsServices(TestType tt) {

        // Start by enabling Customizable Rollups (which disables all legacy rollup operations)
        UTIL_CustomSettingsFacade.getRollupSettingsForTests(new Customizable_Rollup_Settings__c (
                Customizable_Rollups_Enabled__c = true,
                Rollups_Limit_on_Attached_Opps_for_Skew__c = (tt == TestType.testSkewBatch ? 50 : 200),
                Rollups_Account_SkewMode_Batch_Size__c = 200,
                Rollups_Contact_SkewMode_Batch_Size__c = 200,
                Rollups_Account_Soft_Credit_Batch_Size__c = 200,
                Rollups_Contact_Soft_Credit_Batch_Size__c = 200,
                Rollups_Account_Batch_Size__c = 20,
                Rollups_Contact_Batch_Size__c = 20
        ));

        UTIL_CustomSettingsFacade.getContactsSettingsForTests(new npe01__Contacts_And_Orgs_Settings__c(
                npe01__Opportunity_Contact_Role_Default_role__c = 'Donor',
                npe01__Account_Processor__c = CAO_Constants.HH_ACCOUNT_PROCESSOR
        ));

        UTIL_CustomSettingsFacade.getRecurringDonationsSettingsForTest(
                new npe03__Recurring_Donations_Settings__c(
                        npe03__Maximum_Donations__c = 50,
                        npe03__Open_Opportunity_Behavior__c = RD_RecurringDonations.RecurringDonationCloseOptions.Mark_Opportunities_Closed_Lost.name(),
                        Recurring_Donation_Batch_Size__c = 50
                ));

        // Create the test data
        mockRollupCMTValues();

        // Disable all legacy rollup triggers
        UTIL_UnitTestData_TEST.disableRollupTriggers();

        if (tt != TestType.TestTrigger) {
            // disable customizable rollup triggers to test the Batch & Queueuable logic
            UTIL_UnitTestData_TEST.disableCustomizableRollupTriggers();
        }

        // Retrieve the dummy Contact and then insert 100 Opportunity records
        Contact con = [SELECT Id, FirstName, LastName, AccountId FROM Contact LIMIT 1];
        Id acctId = con.AccountId;

        String closedStage = UTIL_UnitTestData_TEST.getClosedWonStage();

        Integer numOpps = 2;
        Integer numClosedOpps = 1;
        Decimal instAmt = 100;
        Date startDate = Date.newInstance(2000,1,1);
        // these two dates only work based on a monthly installment period
        Date lastPaymentDate = startDate.addMonths(numClosedOpps-1);
        Date nextPaymentDate = lastPaymentDate.addMonths(1);

        npe03__Recurring_Donation__c rd = new npe03__Recurring_Donation__c(
                Name = 'testRollupsServices',
                npe03__Installments__c = numOpps,
                npe03__Contact__c = con.Id,
                npe03__Amount__c = instAmt,
                npe03__Installment_Period__c = system.label.npe03.RecurringDonationInstallmentPeriodMonthly,
                npe03__Date_Established__c = startDate,
                npe03__Schedule_Type__c = system.label.npe03.RecurringDonationMultiplyValue,
                npe03__Open_Ended_Status__c = null
        );

        insert rd;

        rd = [SELECT npe03__Total_Paid_Installments__c
                , npe03__Next_Payment_Date__c
                , npe03__Last_Payment_Date__c
                , npe03__Paid_Amount__c FROM npe03__Recurring_Donation__c WHERE Id = :rd.Id];

        // In trigger context, the initial pledged opportunities should've rolled up as follows:
        if (tt == TestType.TestTrigger) {
            System.assertEquals(0, rd.npe03__Total_Paid_Installments__c);
            System.assertEquals(startDate, rd.npe03__Next_Payment_Date__c);
            System.assertEquals(null, rd.npe03__Last_Payment_Date__c);
            System.assertEquals(0, rd.npe03__Paid_Amount__c);
        }

        // In all other contexts, since triggers aren't running, just make sure everything is null first!
        if (tt != TestType.TestTrigger) {
            System.assertEquals(null, rd.npe03__Paid_Amount__c);
            System.assertEquals(null, rd.npe03__Total_Paid_Installments__c);
            System.assertEquals(null, rd.npe03__Last_Payment_Date__c);
            System.assertEquals(null, rd.npe03__Next_Payment_Date__c);
        }

        List<Opportunity> originalOpps = [SELECT Id
        FROM Opportunity
        WHERE npe03__Recurring_Donation__c = :rd.id];

        System.assertEquals(numOpps, originalOpps.size());

        for (Integer i = 0; i < numClosedOpps; i++) {
            originalOpps[i].StageName = closedStage;
        }

        update originalOpps;

        Test.startTest();

        system.assertEquals(1, [SELECT Count() FROM Opportunity WHERE IsWon = true],
                'There should be 1 ClosedWon Opp on the RD.');
        system.assertEquals(1, [SELECT Count() FROM Opportunity WHERE IsClosed = false],
                'There should be 1 Open Opp on the RD.');
        system.assertEquals(100, ([SELECT Sum(Amount) Amt FROM Opportunity
        WHERE IsWon = true])[0].get('Amt'),
                'The total Amount of all Closed Oppties should be $100');

        Id rdId = rd.Id;
        String rdQuery = CRLP_Query_SEL.buildObjectQueryForRollup(npe03__Recurring_Donation__c.SObjectType) + ' WHERE Id = :rdId LIMIT 1';
        rd = database.query(rdQuery);

        // Now test the rollups to the Recurring Donation from the Opportunity
        if (tt == TestType.TestTrigger) {
            // No need to execute anything special here. If the triggers worked as expected, then
            // the data will be rolled up automatically upon the stopTest().
        } else if (tt == TestType.TestBatch) {
            CRLP_RollupBatch_SVC.executeBatchRollupJob(CRLP_RollupProcessingOptions.RollupType.RecurringDonations,
                    CRLP_RollupProcessingOptions.BatchJobMode.NonSkewMode, null, null);
        } else if (tt == TestType.testSkewBatch) {
            CRLP_RollupBatch_SVC.executeBatchRollupJob(CRLP_RollupProcessingOptions.RollupType.RecurringDonations,
                    CRLP_RollupProcessingOptions.BatchJobMode.SkewMode, new List<Id>{rdId}, null);
        } else if (tt == TestType.TestQueueuable) {
            System.enqueueJob(new CRLP_RollupQueueable(new List<Id>{rdId}));
        }
        Test.stopTest();

        // Query the RD with all the target fields specified in the rollups
        rd = database.query(rdQuery);

        // Basic rollup asserts using existing NPSP rollup fields.
        System.assertEquals(numClosedOpps, rd.npe03__Total_Paid_Installments__c);
        System.assertEquals(nextPaymentDate, rd.npe03__Next_Payment_Date__c);
        System.assertEquals(lastPaymentDate, rd.npe03__Last_Payment_Date__c);
        System.assertEquals(instAmt * numClosedOpps, rd.npe03__Paid_Amount__c);

    }
}