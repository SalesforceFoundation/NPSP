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
* @description Unit Test for the Opportunity/Payment to Account Rollups (Hard Credit Only)
*/
@isTest
private class CRLP_RollupAccount_TEST {

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
        Account acc = UTIL_UnitTestData_TEST.createMultipleTestAccounts(1, CAO_Constants.HH_ACCOUNT_TYPE)[0];
        insert acc;
    }

    /**
     * @description Create Rollup__mdt records to test rolling up from the Opp and Payment objects to the Account
     */
    private static void mockRollupCMTValues() {

        String donationRTId = UTIL_RecordTypes.getRecordTypeIdForGiftsTests(Opportunity.SObjectType);
        String membershipRTId = UTIL_RecordTypes.getRecordTypeIdForMembershipTests(Opportunity.SObjectType);
        RecordType rtDonation = [SELECT DeveloperName FROM RecordType WHERE Id = :donationRTId LIMIT 1];
        RecordType rtMembership = [SELECT DeveloperName FROM RecordType WHERE Id = :membershipRTId LIMIT 1];

        // Create a single Filter Group (no need for filter rules here)
        String filterGroupId1 = CMT_UnitTestData_TEST.getNewRecordId();
        String filterGroupId2 = CMT_UnitTestData_TEST.getNewRecordId();

        // Simple testing filters for IsWon, RecordType, and Paid/Written Off
        String filterGroupsJSON = '[' +
                CMT_UnitTestData_TEST.createFilterGroupRecord(filterGroupId1, 'TestFilterGroup1-IsWon+Paid') + ',' +
                CMT_UnitTestData_TEST.createFilterGroupRecord(filterGroupId2, 'TestFilterGroup2-IsWon+WrittenOff') +
            ']';
        String filterRulesJSON = '[' +
                CMT_UnitTestData_TEST.createFilterRuleRecord(null, filterGroupId1, 'Group1.Rule1', 'Opportunity', 'IsWon', 'Equals', 'True') + ',' +
                CMT_UnitTestData_TEST.createFilterRuleRecord(null, filterGroupId1, 'Group1.Rule2', 'Opportunity', 'RecordTypeId', 'Equals', rtDonation.DeveloperName) + ',' +
                CMT_UnitTestData_TEST.createFilterRuleRecord(null, filterGroupId1, 'Group1.Rule3', 'npe01__OppPayment__c', 'npe01__Paid__c', 'Equals', 'True') + ',' +

                CMT_UnitTestData_TEST.createFilterRuleRecord(null, filterGroupId2, 'Group2.Rule1', 'Opportunity', 'IsWon', 'Equals', 'True') + ',' +
                CMT_UnitTestData_TEST.createFilterRuleRecord(null, filterGroupId2, 'Group2.Rule2', 'Opportunity', 'RecordTypeId', 'Equals', rtDonation.DeveloperName) + ',' +
                CMT_UnitTestData_TEST.createFilterRuleRecord(null, filterGroupId2, 'Group2.Rule3', 'npe01__OppPayment__c', 'npe01__Written_Off__c', 'Equals', 'True') +
            ']';

        // Deserialize the filter group and filter rule to use for the tests
        CMT_FilterRule_SEL.cachedFilterGroups = (List<Filter_Group__mdt>)JSON.deserialize(filterGroupsJSON, List<Filter_Group__mdt>.class);
        CMT_FilterRule_SEL.cachedFilterRules = (List<Filter_Rule__mdt>)JSON.deserialize(filterRulesJSON, List<Filter_Rule__mdt>.class);

        // Create a single Rollup that uses the above Filter Group
        // TODO Add many more rollup variations to this
        String rollupsJSON = '[' +
                CMT_UnitTestData_TEST.createRollupRecord('Household Total Donations All Time', filterGroupId1,
                        CMT_UnitTestData_TEST.RollupRecordType.OppToAcct,
                        'npo02__TotalOppAmount__c', CRLP_Operation.RollupType.SUM, 'Amount') + ',' +

                CMT_UnitTestData_TEST.createRollupRecord('Average Total Donations All Time', filterGroupId1,
                        CMT_UnitTestData_TEST.RollupRecordType.OppToAcct,
                        'npo02__AverageAmount__c', CRLP_Operation.RollupType.AVERAGE, 'Amount') + ',' +

                CMT_UnitTestData_TEST.createRollupRecord('Household Total Donations Last 2 Years', filterGroupId1,
                        CMT_UnitTestData_TEST.RollupRecordType.OppToAcct,
                        'npo02__OppAmount2YearsAgo__c', CRLP_Operation.RollupType.SUM, 'Amount',
                        CRLP_Operation.TimeBoundOperationType.YEARS_AGO, 2) + ',' +

                CMT_UnitTestData_TEST.createRollupRecord('Largest Donation All Time', filterGroupId1,
                        CMT_UnitTestData_TEST.RollupRecordType.OppToAcct,
                        'npo02__LargestAmount__c', CRLP_Operation.RollupType.LARGEST, 'Amount') + ',' +

                CMT_UnitTestData_TEST.createRollupRecord('Smallest Donation All Time', filterGroupId1,
                        CMT_UnitTestData_TEST.RollupRecordType.OppToAcct,
                        'npo02__SmallestAmount__c', CRLP_Operation.RollupType.Smallest, 'Amount') + ',' +

                CMT_UnitTestData_TEST.createRollupRecord('Years Donated', filterGroupId1,
                        CMT_UnitTestData_TEST.RollupRecordType.OppToAcct,
                        'Description', CRLP_Operation.RollupType.YEARS_DONATED, '') + ',' +

                CMT_UnitTestData_TEST.createRollupRecord('Current Donation Streak', filterGroupId1,
                        CMT_UnitTestData_TEST.RollupRecordType.OppToAcct,
                        'npo02__NumberOfMembershipOpps__c', CRLP_Operation.RollupType.Donor_Streak, '') + ',' +

                CMT_UnitTestData_TEST.createRollupRecord('Best Year', filterGroupId1,
                        CMT_UnitTestData_TEST.RollupRecordType.OppToAcct,
                        'npo02__Best_Gift_Year__c', CRLP_Operation.RollupType.BEST_YEAR, '') + ',' +

                CMT_UnitTestData_TEST.createRollupRecord('Last Gift Date', filterGroupId1,
                        CMT_UnitTestData_TEST.RollupRecordType.OppToAcct,
                        'npo02__LastCloseDate__c', CRLP_Operation.RollupType.LAST, 'CloseDate') + ',' +

                CMT_UnitTestData_TEST.createRollupRecord('First Gift Date', filterGroupId1,
                        CMT_UnitTestData_TEST.RollupRecordType.OppToAcct,
                        'npo02__FirstCloseDate__c', CRLP_Operation.RollupType.First, 'CloseDate') + ',' +

                /* Payment Rollups for Total Paid and Total Written Off - using a field that can hold the value */
                CMT_UnitTestData_TEST.createRollupRecord('Total Payments', filterGroupId1,
                        CMT_UnitTestData_TEST.RollupRecordType.PmtToAcct,
                        'AnnualRevenue', CRLP_Operation.RollupType.SUM, 'npe01__Payment_Amount__c') + ',' +

                CMT_UnitTestData_TEST.createRollupRecord('Total Writeoffs', filterGroupId2,
                        CMT_UnitTestData_TEST.RollupRecordType.PmtToAcct,
                        'npo02__LastMembershipAmount__c', CRLP_Operation.RollupType.SUM, 'npe01__Payment_Amount__c') + ',' +

                // Using a nonsense field for an Account Soft Credit test since we don't package anything for Account Soft Credits
                CMT_UnitTestData_TEST.createRollupRecord('Total Account Soft Credits', filterGroupId1,
                        CMT_UnitTestData_TEST.RollupRecordType.AccountSoftCreditToAccount, 'npo02__Best_Gift_Year_Total__c',
                        CRLP_Operation.RollupType.SUM, 'Amount__c') +
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
     * @description Test some simple rollups from the Opportunity/Payment object to the Account using
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
                Rollups_Contact_Soft_Credit_Batch_Size__c = 200,
                Rollups_Account_Batch_Size__c = 20,
                Rollups_Contact_Batch_Size__c = 20
        ));
        UTIL_CustomSettingsFacade.getContactsSettingsForTests(new npe01__Contacts_And_Orgs_Settings__c(
                npe01__Opportunity_Contact_Role_Default_role__c = 'Donor',
                npe01__Account_Processor__c = CAO_Constants.HH_ACCOUNT_PROCESSOR,
                npe01__Payments_Enabled__c = true
        ));

        UTIL_CustomSettingsFacade.getHouseholdsSettingsForTests(new npo02__Households_Settings__c (
                npo02__Household_Rules__c = HH_Households.ALL_PROCESSOR,
                npo02__Household_Member_Contact_Role__c = label.npo02.Household_Member_Contact_Role,
                npo02__Household_Contact_Roles_On__c = true,
                npo02__Always_Rollup_to_Primary_Contact__c = false
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
        Contact c = [SELECT Id, FirstName, LastName, AccountId FROM Contact LIMIT 1];
        Id hardCreditAccId = c.AccountId;

        String closedStage = UTIL_UnitTestData_TEST.getClosedWonStage();
        Id rtId = UTIL_RecordTypes.getRecordTypeIdForGiftsTests(Opportunity.SObjectType);

        List<Opportunity> opps = new List<Opportunity>();
        Date closeDate = Date.Today().addMonths(-100);
        Decimal totalDonations = 0, total2YearsAgo = 0;
        Decimal maxAmt = 1000;
        Decimal baseAmt = 100;
        Integer cnt = 100;
        String bestGiftYear;
        Set<String> donationYears = new Set<String>();
        Date lastCloseDate;
        for (Integer n=0; n<cnt; n++) {
            Decimal amt = (n==50 ? maxAmt : baseAmt);
            opps.add(new Opportunity (
                    Name = 'Test Opp ' + c.FirstName + ' ' + c.LastName,
                    Amount = amt,
                    CloseDate = closeDate.addMonths(n),
                    StageName = closedStage,
                    Primary_Contact__c = c.Id,
                    RecordTypeId = rtId
            ));
            totalDonations += amt;
            if (closeDate.addMonths(n).year() == Date.Today().addYears(-2).year()) {
                total2YearsAgo += amt;
            }
            String donationYr = closeDate.addMonths(n).year().format().replace(',','');
            donationYears.add(donationYr);
            if (amt == maxAmt) {
                bestGiftYear = donationYr;
            }
            lastCloseDate = closeDate.addMonths(n);
        }

        // create one closed opportunity to ensure it's not included in our rollups
        opps.add(new Opportunity (
                Name = 'Test Opp ' + c.FirstName + ' ' + c.LastName,
                Amount = 500,
                CloseDate = Date.Today().addDays(1),
                StageName = UTIL_UnitTestData_TEST.getClosedLostStage(),
                Primary_Contact__c = c.Id,
                RecordTypeId = rtId
        ));

        insert opps;

        npe01__OppPayment__c pmt1 = [SELECT npe01__Written_Off__c, npe01__Paid__c FROM npe01__OppPayment__c
        WHERE npe01__Opportunity__r.IsWon = false LIMIT 1];
        pmt1.npe01__Written_Off__c = true;
        pmt1.npe01__Paid__c = false;    // technically this does not cause a DML change!?

        npe01__OppPayment__c pmt2 = [SELECT npe01__Written_Off__c, npe01__Paid__c FROM npe01__OppPayment__c
            WHERE npe01__Opportunity__r.IsWon = true AND npe01__Written_Off__c = false AND Id != :pmt1.Id LIMIT 1];
        pmt2.npe01__Written_Off__c = true;
        pmt2.npe01__Paid__c = false;

        Test.startTest();

        // Because data is being modified by the above, any cached filter evaluations are now invalid
        // so before issuing the DML against the payment records, clear any cached eval results
        CMT_FilterRuleEvaluation_SVC.cachedFilterEvalResults.clear();
        update new List<npe01__OppPayment__c>{ pmt1, pmt2 };

        system.assertEquals(cnt, [SELECT Count() FROM npe01__OppPayment__c WHERE npe01__Opportunity__r.IsWon = true],
                'There should be 100 payment records on closed won opps');
        system.assertEquals(1, [SELECT Count() FROM npe01__OppPayment__c WHERE npe01__Written_Off__c = true
                                AND npe01__Paid__c = false AND npe01__Opportunity__r.IsWon = true],
                'There should be 1 written off payment record on a closed won opp');
        system.assertEquals(10800, ([SELECT Sum(npe01__Payment_Amount__c) Amt FROM npe01__OppPayment__c
                                WHERE npe01__Paid__c = true AND npe01__Opportunity__r.IsWon = true])[0].get('Amt'),
                'The total Amount of all Paid Payments should be $10800');

        String baseAccountQuery = CRLP_Query_SEL.buildObjectQueryForRollup(Account.SObjectType);

        String hardCreditAccQuery = baseAccountQuery + ' WHERE Id = :hardCreditAccId LIMIT 1';
        Account hardCreditAcc = database.query(hardCreditAccQuery);

        // Make sure everything is null first!
        if (tt != TestType.TestTrigger) {
            System.assertEquals(0, hardCreditAcc.npo02__TotalOppAmount__c);
            System.assertEquals(0, hardCreditAcc.npo02__AverageAmount__c);
            System.assertEquals(0, hardCreditAcc.npo02__OppAmount2YearsAgo__c);
            System.assertEquals(0, hardCreditAcc.npo02__LargestAmount__c);
            System.assertEquals(0, hardCreditAcc.npo02__SmallestAmount__c);
            System.assertEquals(null, hardCreditAcc.npo02__LastCloseDate__c);
            System.assertEquals(null, hardCreditAcc.npo02__FirstCloseDate__c);
            System.assertEquals(null, hardCreditAcc.npo02__Best_Gift_Year__c);
        }

        // Now test the rollups to the Account from the Opportunity
        if (tt == TestType.TestTrigger) {
            // No need to execute anything special here. If the triggers worked as expected, then
            // the data will be rolled up automatically upon the stopTest().
        } else if (tt == TestType.TestBatch) {
            CRLP_RollupBatch_SVC.executeBatchRollupJob(CRLP_RollupProcessingOptions.RollupType.AccountHardCredit,
                    CRLP_RollupProcessingOptions.BatchJobMode.NonSkewMode, null, null);

        } else if (tt == TestType.testSkewBatch) {
            CRLP_RollupBatch_SVC.executeBatchRollupJob(CRLP_RollupProcessingOptions.RollupType.AccountHardCredit,
                    CRLP_RollupProcessingOptions.BatchJobMode.SkewMode, new List<Id>{
                            hardCreditAccId
                    }, null);

        } else if (tt == TestType.TestQueueuable) {
            System.enqueueJob(new CRLP_RollupQueueable(new List<Id>{
                    hardCreditAccId
            }));

        }
        Test.stopTest();

        // Query the Accounts with all the target fields specified in the rollups
        hardCreditAcc = database.query(hardCreditAccQuery);

        // Basic rollup asserts using existing NPSP rollup fields.
        System.assertEquals(totalDonations, hardCreditAcc.npo02__TotalOppAmount__c);
        System.assertEquals(totalDonations.divide(cnt, 2, System.RoundingMode.HALF_UP), hardCreditAcc.npo02__AverageAmount__c);
        System.assertEquals(total2YearsAgo, hardCreditAcc.npo02__OppAmount2YearsAgo__c);
        System.assertEquals(lastCloseDate, hardCreditAcc.npo02__LastCloseDate__c);
        System.assertEquals(closeDate, hardCreditAcc.npo02__FirstCloseDate__c);
        System.assertEquals(maxAmt, hardCreditAcc.npo02__LargestAmount__c);
        System.assertEquals(baseAmt, hardCreditAcc.npo02__SmallestAmount__c);
        System.assertEquals(bestGiftYear, hardCreditAcc.npo02__Best_Gift_Year__c);

        // These 4 use other fields on the Account object since there are no NPSP related fields to store the values in
        System.assertEquals(totalDonations - baseAmt, hardCreditAcc.AnnualRevenue,
                'Total Payments should match total donations less $100 because one payment has been marked as written off');
        System.assertEquals(baseAmt, hardCreditAcc.npo02__LastMembershipAmount__c, 'The Amount written off does not match');
        System.assertEquals(donationYears.size(), hardCreditAcc.npo02__NumberOfMembershipOpps__c, 'The current streak should be all the years');
        System.assertEquals(donationYears.size(), hardCreditAcc.Description.split(';').size(), 'The list of donated years should match');

    }
}