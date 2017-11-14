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
private class CRLP_RollupAccount_TEST {

    /**
     * @description Create Rollup__mdt records to test rolling up from the Opp and Payment objects to the Account
     */
    private static void mockRollupCMTValues() {

        // Create a single Filter Group (no need for filter rules here)
        String filterGroupId = CMT_UnitTestData_TEST.getNewRecordId();

        // Extremely simple Filter Rule for IsWon only
        String filterGroupsJSON = '[' + CMT_UnitTestData_TEST.createFilterGroupRecord(filterGroupId, 'TestFilterGroup') + ']';
        String filterRulesJSON = '[' +
                CMT_UnitTestData_TEST.createFilterRuleRecord(null, filterGroupId, 'Group1.Rule1', 'Opportunity', 'IsWon', 'Equals', 'True') +
                ']';

        // Deserialize the filter group and filter rule to use for the tests
        CMT_FilterRule_SEL.cachedFilterGroups = (List<Filter_Group__mdt>)JSON.deserialize(filterGroupsJSON, List<Filter_Group__mdt>.class);
        CMT_FilterRule_SEL.cachedFilterRules = (List<Filter_Rule__mdt>)JSON.deserialize(filterRulesJSON, List<Filter_Rule__mdt>.class);

        // Create a single Rollup that uses the above Filter Group
        String rollupsJSON = '[' +
                CMT_UnitTestData_TEST.createRollupRecordOppToAccount('Household Total Donations All Time', filterGroupId,
                        'npo02__TotalOppAmount__c', CRLP_Operation.RollupType.SUM.name(), 'AccountId',
                        CRLP_Operation.YearlyOperationType.ALL_TIME.name(), 0) + ',' +

                CMT_UnitTestData_TEST.createRollupRecordOppToAccount('Average Total Donations All Time', filterGroupId,
                        'npo02__AverageAmount__c', CRLP_Operation.RollupType.AVERAGE.name(), 'AccountId',
                        CRLP_Operation.YearlyOperationType.ALL_TIME.name(), 0) + ',' +

                CMT_UnitTestData_TEST.createRollupRecordOppToAccount('Household Total Donations Last 2 Years', filterGroupId,
                        'npo02__OppAmount2YearsAgo__c', CRLP_Operation.RollupType.SUM.name(), 'AccountId',
                        CRLP_Operation.YearlyOperationType.YEARS_BACK.name(), 2) + ',' +

                CMT_UnitTestData_TEST.createRollupRecordOppToAccount('Max Donation All Time', filterGroupId,
                        'npo02__LargestAmount__c', CRLP_Operation.RollupType.LARGEST.name(), 'AccountId',
                        CRLP_Operation.YearlyOperationType.ALL_TIME.name(), 0) + ',' +

                CMT_UnitTestData_TEST.createRollupRecordOppToAccount('Years Donated', filterGroupId,
                        'Description', CRLP_Operation.RollupType.YEARS_DONATED.name(), 'AccountId',
                        CRLP_Operation.YearlyOperationType.ALL_TIME.name(), 0) + ',' +

                CMT_UnitTestData_TEST.createRollupRecordOppToAccount('Current Donation Streak', filterGroupId,
                        'npo02__LastMembershipAmount__c', CRLP_Operation.RollupType.CURRENT_STREAK.name(), 'AccountId',
                        CRLP_Operation.YearlyOperationType.ALL_TIME.name(), 0) + ',' +

                CMT_UnitTestData_TEST.createRollupRecordOppToAccount('Best Year', filterGroupId,
                        'npo02__Best_Gift_Year__c', CRLP_Operation.RollupType.BEST_YEAR.name(), 'AccountId',
                        CRLP_Operation.YearlyOperationType.ALL_TIME.name(), 0) + ',' +

                CMT_UnitTestData_TEST.createRollupRecordPaymentToAccount('Total Payments', filterGroupId,
                        'AnnualRevenue', CRLP_Operation.RollupType.SUM.name(), 'npe01__Payment_Amount__c',
                        CRLP_Operation.YearlyOperationType.ALL_TIME.name(), 0) +

                ']';

        // Deserialize the rollups to use for testing
        CRLP_Rollup_SEL.cachedRollups = (List<Rollup__mdt>) JSON.deserialize(rollupsJSON, List<Rollup__mdt>.class);
    }

    /**
     * @description Test some simple rollups from the Opportunity/Payment object to the Account
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

        String closedStage = UTIL_UnitTestData_TEST.getClosedWonStage();
        Id rtId = UTIL_RecordTypes.getRecordTypeIdForGiftsTests(Opportunity.SObjectType);

        List<Opportunity> opps = new List<Opportunity>();
        Date closeDate = Date.Today().addMonths(-100);
        Decimal totalDonations = 0, totalLast2Years = 0;
        String bestGiftYear;
        Set<String> donationYears = new Set<String>();
        for (Integer n=0; n<100; n++) {
            Decimal amt = (n==50 ? 1000 : 100);
            opps.add(new Opportunity (
                    Name = 'Test Opp ' + c.FirstName + ' ' + c.LastName,
                    Amount = amt,
                    CloseDate = closeDate.addMonths(n),
                    StageName = closedStage,
                    Primary_Contact__c = c.Id,
                    RecordTypeId = rtId
            ));
            totalDonations += amt;
            if (closeDate.addMonths(n).year() >= Date.Today().addYears(-1).year()) {
                totalLast2Years += amt;
            }
            String donationYr = closeDate.addMonths(n).year().format().replace(',','');
            donationYears.add(donationYr);
            if (amt == 1000) {
                bestGiftYear = donationYr;
            }
        }

        // create one closed opportunity to ensure it's not included in our rollups
        opps.add(new Opportunity (
                Name = 'Test Opp ' + c.FirstName + ' ' + c.LastName,
                Amount = 500,
                CloseDate = Date.Today().addDays(-120),
                StageName = UTIL_UnitTestData_TEST.getClosedLostStage(),
                Primary_Contact__c = c.Id,
                RecordTypeId = rtId
        ));
        insert opps;

        system.assertEquals(100, [SELECT Count() FROM npe01__OppPayment__c WHERE npe01__Opportunity__r.IsWon = true],
            'There should be 100 payment records on closed won opps');

        Test.startTest();

        // Now test the rollups to the Account from the Opportunity
        CRLP_RollupAccount_SVC.rollupSingleAccount(acctId);

        // Query the Account with all the target fields specified in the rollups
        String acctQuery = CRLP_Query_SEL.getResultsQuery(Account.SObjectType);
        acctQuery += ' WHERE Id = :acctId LIMIT 1';
        Account a = database.query(acctQuery);

        System.assertEquals(1000, a.npo02__LargestAmount__c);
        System.assertEquals(totalDonations, a.npo02__TotalOppAmount__c);
        System.assertEquals((totalDonations / 100), a.npo02__AverageAmount__c);
        System.assertEquals(totalDonations, a.AnnualRevenue, 'Total Payments should match total donations');
        System.assertEquals(totalLast2Years, a.npo02__OppAmount2YearsAgo__c);
        System.assertEquals(bestGiftYear, a.npo02__Best_Gift_Year__c);
        System.assertEquals(donationYears.size(), a.npo02__LastMembershipAmount__c, 'The current streak should be all the years');
        System.assertEquals(donationYears.size(), a.Description.split(';').size(), 'The list of donated years should match');
    }
}