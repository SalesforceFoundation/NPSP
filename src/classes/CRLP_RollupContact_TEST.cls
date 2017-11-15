/*
    Copyright (c) 2017, Salesforce.org
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
* @date 2017
* @group Customizable Rollups Operations Services
* @description Unit Test for the Opportunity/Payment to Account Rollups
*/
@isTest
private class CRLP_RollupContact_TEST {

    /**
     * @description Create Rollup__mdt records to test rolling up from the Opp and Payment objects to the Account
     */
    private static void mockRollupCMTValues() {

        // Create a single Filter Group (no need for filter rules here)
        String filterGroupId1 = CMT_UnitTestData_TEST.getNewRecordId();
        String filterGroupId2 = CMT_UnitTestData_TEST.getNewRecordId();

        // Extremely simple Filter Rule for IsWon only
        String filterGroupsJSON = '[' +
                CMT_UnitTestData_TEST.createFilterGroupRecord(filterGroupId1, 'TestFilterGroup1-IsWon+Paid') + ',' +
                CMT_UnitTestData_TEST.createFilterGroupRecord(filterGroupId2, 'TestFilterGroup2-IsWon+WrittenOff') +
            ']';
        String filterRulesJSON = '[' +
                CMT_UnitTestData_TEST.createFilterRuleRecord(null, filterGroupId1, 'Group1.Rule1', 'Opportunity', 'IsWon', 'Equals', 'True') + ',' +
                CMT_UnitTestData_TEST.createFilterRuleRecord(null, filterGroupId1, 'Group1.Rule2', 'npe01__OppPayment__c', 'npe01__Paid__c', 'Equals', 'True') + ',' +

                CMT_UnitTestData_TEST.createFilterRuleRecord(null, filterGroupId2, 'Group2.Rule1', 'Opportunity', 'IsWon', 'Equals', 'True') + ',' +
                CMT_UnitTestData_TEST.createFilterRuleRecord(null, filterGroupId2, 'Group2.Rule2', 'npe01__OppPayment__c', 'npe01__Written_Off__c', 'Equals', 'True') +
            ']';

        // Deserialize the filter group and filter rule to use for the tests
        CMT_FilterRule_SEL.cachedFilterGroups = (List<Filter_Group__mdt>)JSON.deserialize(filterGroupsJSON, List<Filter_Group__mdt>.class);
        CMT_FilterRule_SEL.cachedFilterRules = (List<Filter_Rule__mdt>)JSON.deserialize(filterRulesJSON, List<Filter_Rule__mdt>.class);

        // Create a single Rollup that uses the above Filter Group
        String rollupsJSON = '[' +
                CMT_UnitTestData_TEST.createRollupRecordOppToContact('Donor Total Donations All Time', filterGroupId1,
                        'npo02__TotalOppAmount__c', CRLP_Operation.RollupType.SUM, 'Amount',
                        CRLP_Operation.YearlyOperationType.ALL_TIME, 0) + ',' +

                CMT_UnitTestData_TEST.createRollupRecordOppToContact('Average Donations All Time', filterGroupId1,
                        'npo02__AverageAmount__c', CRLP_Operation.RollupType.AVERAGE, 'Amount',
                        CRLP_Operation.YearlyOperationType.ALL_TIME, 0) + ',' +

                CMT_UnitTestData_TEST.createRollupRecordOppToContact('Donor Donations Last 2 Years', filterGroupId1,
                        'npo02__OppAmount2YearsAgo__c', CRLP_Operation.RollupType.SUM, 'Amount',
                        CRLP_Operation.YearlyOperationType.YEARS_AGO, 2) + ',' +

                CMT_UnitTestData_TEST.createRollupRecordOppToContact('Max Donation All Time', filterGroupId1,
                        'npo02__LargestAmount__c', CRLP_Operation.RollupType.LARGEST, 'Amount',
                        CRLP_Operation.YearlyOperationType.ALL_TIME, 0) + ',' +

                CMT_UnitTestData_TEST.createRollupRecordOppToContact('Years Donated', filterGroupId1,
                        'Description', CRLP_Operation.RollupType.YEARS_DONATED, '',
                        CRLP_Operation.YearlyOperationType.ALL_TIME, 0) + ',' +

                CMT_UnitTestData_TEST.createRollupRecordOppToContact('Current Donation Streak', filterGroupId1,
                        'npo02__NumberOfMembershipOpps__c', CRLP_Operation.RollupType.CURRENT_STREAK, '',
                        null, 0) + ',' +

                CMT_UnitTestData_TEST.createRollupRecordOppToContact('Best Year', filterGroupId1,
                        'npo02__Best_Gift_Year__c', CRLP_Operation.RollupType.BEST_YEAR, '',
                        null, 0) + ',' +

                /* Using SingleResult operation to get the last gift date */
                CMT_UnitTestData_TEST.createRollupRecord('Last Gift Date', filterGroupId1,
                        'Contact', 'npo02__LastCloseDate__c', CRLP_Operation.RollupType.LAST,
                        'Opportunity', 'CloseDate',
                        CRLP_Operation.YearlyOperationType.ALL_TIME, 0, false) + ',' +

                /* Payment Rollups for Total Paid and Total Written Off - using a field that can hold the value */
                CMT_UnitTestData_TEST.createRollupRecordPaymentToContact('Total Payments', filterGroupId1,
                        'First_Soft_Credit_Amount__c', CRLP_Operation.RollupType.SUM, 'npe01__Payment_Amount__c',
                        CRLP_Operation.YearlyOperationType.ALL_TIME, 0) + ',' +

                CMT_UnitTestData_TEST.createRollupRecordPaymentToContact('Total Writeoffs', filterGroupId2,
                        'npo02__LastMembershipAmount__c', CRLP_Operation.RollupType.SUM, 'npe01__Payment_Amount__c',
                        CRLP_Operation.YearlyOperationType.ALL_TIME, 0) +

                ']';

        // Deserialize the rollups to use for testing
        CRLP_Rollup_SEL.cachedRollups = (List<Rollup__mdt>) JSON.deserialize(rollupsJSON, List<Rollup__mdt>.class);
    }

    /**
     * @description Test some simple rollups from the Opportunity/Payment object to the Contact
     * TODO Add many more rollup variations to this
     */
    static testMethod void test_OperationRollupService() {

        // Start by enabling Customizable Rollups (which disables all legacy rollup operations)
        UTIL_CustomSettingsFacade.getHouseholdsSettingsForTests(
                new npo02__Households_Settings__c (
                        npo02__Household_Rules__c = HH_Households.ALL_PROCESSOR,
                        Customizable_Rollups_Enabled__c = true
                ));

        // Create the test data
        mockRollupCMTValues();

        // Insert a dummy Contact and 100 Opportunity records
        Contact c = new Contact(LastName = 'UNITTEST', FirstName = 'TEST');
        insert c;
        c = [SELECT Id, FirstName, LastName, AccountId FROM Contact LIMIT 1];
        Id acctId = c.AccountId;
        Id conId = c.Id;

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
                    Primary_Contact__c = conId,
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
                Primary_Contact__c = conId,
                RecordTypeId = rtId
        ));
        insert opps;

        // Mark two payments as written off; though only one should be rolled up
        npe01__OppPayment__c pmt1 = [SELECT npe01__Written_Off__c, npe01__Paid__c FROM npe01__OppPayment__c
        WHERE npe01__Opportunity__r.IsWon = false LIMIT 1];
        pmt1.npe01__Written_Off__c = true;
        pmt1.npe01__Paid__c = false;

        npe01__OppPayment__c pmt2 = [SELECT npe01__Written_Off__c, npe01__Paid__c FROM npe01__OppPayment__c
        WHERE npe01__Opportunity__r.IsWon = true LIMIT 1];
        pmt2.npe01__Written_Off__c = true;
        pmt2.npe01__Paid__c = false;

        update new List<npe01__OppPayment__c>{ pmt1, pmt2 };

        system.assertEquals(cnt, [SELECT Count() FROM npe01__OppPayment__c WHERE npe01__Opportunity__r.IsWon = true],
                'There should be 100 payment records on closed won opps');
        system.assertEquals(cnt, [SELECT Count() FROM OpportunityContactRole WHERE Opportunity.IsWon = true],
                'There should be 100 OCR records on closed won opps');

        Test.startTest();

        // Now test the rollups to the Account from the Opportunity
        CRLP_RollupContact_SVC.rollupSingleContact(conId);

        // Query the Account with all the target fields specified in the rollups
        String conQuery = CRLP_Query_SEL.getResultsQuery(Contact.SObjectType) + ' WHERE Id = :conId LIMIT 1';
        c = database.query(conQuery);

        // Basic rollup asserts using existing NPSP rollup fields.
        System.assertEquals(maxAmt, c.npo02__LargestAmount__c);
        System.assertEquals(lastCloseDate, c.npo02__LastCloseDate__c);
        System.assertEquals(totalDonations, c.npo02__TotalOppAmount__c);
        System.assertEquals((totalDonations / cnt), c.npo02__AverageAmount__c);
        System.assertEquals(total2YearsAgo, c.npo02__OppAmount2YearsAgo__c);
        System.assertEquals(bestGiftYear, c.npo02__Best_Gift_Year__c);

        // These 4 use other fields on the Contact object since there are no NPSP related fields to store the values in
        System.assertEquals(totalDonations - baseAmt, c.First_Soft_Credit_Amount__c,
                'Total Payments should match total donations less $100 because one payment has been marked as written off');
        System.assertEquals(baseAmt, c.npo02__LastMembershipAmount__c, 'The Amount written off does not match');
        System.assertEquals(donationYears.size(), c.npo02__NumberOfMembershipOpps__c, 'The current streak should be all the years');
        System.assertEquals(donationYears.size(), c.Description.split(';').size(), 'The list of donated years should match');
    }
}