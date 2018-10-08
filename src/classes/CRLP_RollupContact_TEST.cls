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
* @description Unit Test for the Opportunity/Payment to Contact Rollups
*/
@isTest
private class CRLP_RollupContact_TEST {

    private Enum TestType {
        TestTrigger, TestQueueuable, TestBatch, testSkewBatch, TestWithAlwaysRollupToPrimary
    }

    /**
     * @description Test Setup: Insert a dummy contact and let it create an Account. The Opportunity data has to
     * be created in the actual unit test to allow for the trigger test to run
     */
    @TestSetup
    private static void setupBaseTestData() {
        Contact c1 = UTIL_UnitTestData_TEST.getContact();
        Contact c2 = UTIL_UnitTestData_TEST.getContact();
        insert new List<Contact>{c1, c2};
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
                /* The following rules test Inclusion and Exclusion filters against picklist fields that have and don't have any data */
                CMT_UnitTestData_TEST.createFilterRuleRecord(null, filterGroupId1, 'Group1.Rule3', 'Opportunity', 'Type', 'Equals', 'New') + ',' +
                CMT_UnitTestData_TEST.createFilterRuleRecord(null, filterGroupId1, 'Group1.Rule4', 'Opportunity', 'Type', 'Contains', 'New') + ',' +
                CMT_UnitTestData_TEST.createFilterRuleRecord(null, filterGroupId1, 'Group1.Rule5', 'Opportunity', 'Type', 'Starts_With', 'New') + ',' +
                CMT_UnitTestData_TEST.createFilterRuleRecord(null, filterGroupId1, 'Group1.Rule6', 'Opportunity', 'Type', 'Does_Not_Contain', 'Old') + ',' +
                CMT_UnitTestData_TEST.createFilterRuleRecord(null, filterGroupId1, 'Group1.Rule7', 'Opportunity', 'npe01__Membership_Origin__c', 'Does_Not_Contain', 'Nothing') + ',' +
                CMT_UnitTestData_TEST.createFilterRuleRecord(null, filterGroupId1, 'Group1.Rule8', 'Opportunity', 'npe01__Membership_Origin__c', 'Equals', '') + ',' +
                CMT_UnitTestData_TEST.createFilterRuleRecord(null, filterGroupId1, 'Group1.Rule9', 'Opportunity', 'npe01__Membership_Origin__c', 'Contains', '') + ',' +
                CMT_UnitTestData_TEST.createFilterRuleRecord(null, filterGroupId1, 'Group1.Rule10', 'Opportunity', 'npe01__Membership_Origin__c', 'Not_Equals', 'Nothing') + ',' +
                CMT_UnitTestData_TEST.createFilterRuleRecord(null, filterGroupId1, 'Group1.Rule11', 'Opportunity', 'npe01__Membership_Origin__c', 'Starts_With', '') + ',' +
                /* The following rule is for testing against paid payments */
                CMT_UnitTestData_TEST.createFilterRuleRecord(null, filterGroupId1, 'Group1.Rule12', 'npe01__OppPayment__c', 'npe01__Paid__c', 'Equals', 'True') + ',' +

                CMT_UnitTestData_TEST.createFilterRuleRecord(null, filterGroupId2, 'Group2.Rule1', 'Opportunity', 'IsWon', 'Equals', 'True') + ',' +
                CMT_UnitTestData_TEST.createFilterRuleRecord(null, filterGroupId2, 'Group2.Rule2', 'Opportunity', 'RecordTypeId', 'Equals', rtDonation.DeveloperName) + ',' +
                CMT_UnitTestData_TEST.createFilterRuleRecord(null, filterGroupId2, 'Group2.Rule4', 'npe01__OppPayment__c', 'npe01__Written_Off__c', 'Equals', 'True') +
            ']';

        // Deserialize the filter group and filter rule to use for the tests
        CMT_FilterRule_SEL.cachedFilterGroups = (List<Filter_Group__mdt>)JSON.deserialize(filterGroupsJSON, List<Filter_Group__mdt>.class);
        CMT_FilterRule_SEL.cachedFilterRules = (List<Filter_Rule__mdt>)JSON.deserialize(filterRulesJSON, List<Filter_Rule__mdt>.class);

        // Create a single Rollup that uses the above Filter Group
        String rollupsJSON = '[' +

                CMT_UnitTestData_TEST.createRollupRecord('Count Donations', filterGroupId1,
                        CMT_UnitTestData_TEST.RollupRecordType.OppToContact,
                        'npo02__NumberOfClosedOpps__c', CRLP_Operation.RollupType.COUNT, null, 'Fair_Market_Value__c') + ',' +

                CMT_UnitTestData_TEST.createRollupRecord('Total Donations All Time', filterGroupId1,
                        CMT_UnitTestData_TEST.RollupRecordType.OppToContact,
                        'npo02__TotalOppAmount__c', CRLP_Operation.RollupType.SUM, 'Amount') + ',' +

                CMT_UnitTestData_TEST.createRollupRecord('Average Donations All Time', filterGroupId1,
                        CMT_UnitTestData_TEST.RollupRecordType.OppToContact,
                        'npo02__AverageAmount__c', CRLP_Operation.RollupType.AVERAGE, 'Amount') + ',' +

                CMT_UnitTestData_TEST.createRollupRecord('Donations Last 2 Years', filterGroupId1,
                        CMT_UnitTestData_TEST.RollupRecordType.OppToContact,
                        'npo02__OppAmount2YearsAgo__c', CRLP_Operation.RollupType.SUM, 'Amount',
                        CRLP_Operation.TimeBoundOperationType.YEARS_AGO, 2) + ',' +

                /* Using nonsense fields to test Smallest with different Detail Field and Years Ago */
                CMT_UnitTestData_TEST.createRollupRecord('Num from Smallest Opp Last Year', filterGroupId1,
                        CMT_UnitTestData_TEST.RollupRecordType.OppToContact,
                        'Number_of_Soft_Credits__c', CRLP_Operation.RollupType.SMALLEST, 'Recurring_Donation_Installment_Number__c',
                        CRLP_Operation.TimeBoundOperationType.YEARS_AGO, 1) + ',' +

                /* Using nonsense fields to test Largest with different Detail Field and Years Ago */
                CMT_UnitTestData_TEST.createRollupRecord('Num from Largest Opp Last Year', filterGroupId1,
                        CMT_UnitTestData_TEST.RollupRecordType.OppToContact,
                        'Number_of_Soft_Credits_Last_N_Days__c', CRLP_Operation.RollupType.LARGEST, 'Recurring_Donation_Installment_Number__c',
                        CRLP_Operation.TimeBoundOperationType.YEARS_AGO, 1) + ',' +

                /* Using nonsense fields to test Smallest with different Detail Field and All Time */
                CMT_UnitTestData_TEST.createRollupRecord('Num from Smallest Opp All Time', filterGroupId1,
                        CMT_UnitTestData_TEST.RollupRecordType.OppToContact,
                        'Number_of_Soft_Credits_Last_Year__c', CRLP_Operation.RollupType.SMALLEST, 'Recurring_Donation_Installment_Number__c') + ',' +

                /* Using nonsense fields to test Largest with different Detail Field and All Time */
                CMT_UnitTestData_TEST.createRollupRecord('Num from Largest Opp All Time', filterGroupId1,
                        CMT_UnitTestData_TEST.RollupRecordType.OppToContact,
                        'Number_of_Soft_Credits_This_Year__c', CRLP_Operation.RollupType.LARGEST, 'Recurring_Donation_Installment_Number__c') + ',' +

                /* Using nonsense fields to test First with different Detail Field and Years Ago */
                CMT_UnitTestData_TEST.createRollupRecord('Num from First Opp Last Year', filterGroupId1,
                        CMT_UnitTestData_TEST.RollupRecordType.OppToContact,
                        'Number_of_Soft_Credits_Two_Years_Ago__c', CRLP_Operation.RollupType.FIRST, 'Recurring_Donation_Installment_Number__c',
                        CRLP_Operation.TimeBoundOperationType.YEARS_AGO, 1) + ',' +

                /* Using nonsense fields to test Last with different Detail Field and Years Ago */
                CMT_UnitTestData_TEST.createRollupRecord('Num from Last Opp Last Year', filterGroupId1,
                        CMT_UnitTestData_TEST.RollupRecordType.OppToContact,
                        'npo02__Household_Naming_Order__c', CRLP_Operation.RollupType.LAST, 'Recurring_Donation_Installment_Number__c',
                        CRLP_Operation.TimeBoundOperationType.YEARS_AGO, 1) + ',' +

                CMT_UnitTestData_TEST.createRollupRecord('Total Donations Last 365 Days', filterGroupId1,
                        CMT_UnitTestData_TEST.RollupRecordType.OppToContact,
                        'npo02__OppAmountLastNDays__c', CRLP_Operation.RollupType.SUM, 'Amount',
                        CRLP_Operation.TimeBoundOperationType.DAYS_BACK, 365) + ',' +

                CMT_UnitTestData_TEST.createRollupRecord('Count Donations Last 365 Days', filterGroupId1,
                        CMT_UnitTestData_TEST.RollupRecordType.OppToContact,
                        'npo02__OppsClosedLastNDays__c', CRLP_Operation.RollupType.COUNT, 'Amount',
                        CRLP_Operation.TimeBoundOperationType.DAYS_BACK, 365) + ',' +

                CMT_UnitTestData_TEST.createRollupRecord('Max Donation All Time', filterGroupId1,
                        CMT_UnitTestData_TEST.RollupRecordType.OppToContact,
                        'npo02__LargestAmount__c', CRLP_Operation.RollupType.LARGEST, 'Amount') + ',' +

                CMT_UnitTestData_TEST.createRollupRecord('Years Donated', filterGroupId1,
                        CMT_UnitTestData_TEST.RollupRecordType.OppToContact,
                        'Description', CRLP_Operation.RollupType.YEARS_DONATED, null, 'Amount') + ',' +

                CMT_UnitTestData_TEST.createRollupRecord('Current Donation Streak', filterGroupId1,
                        CMT_UnitTestData_TEST.RollupRecordType.OppToContact,
                        'npo02__NumberOfMembershipOpps__c', CRLP_Operation.RollupType.Donor_Streak, 'Amount') + ',' +

                CMT_UnitTestData_TEST.createRollupRecord('Best Year', filterGroupId1,
                        CMT_UnitTestData_TEST.RollupRecordType.OppToContact,
                        'npo02__Best_Gift_Year__c', CRLP_Operation.RollupType.BEST_YEAR, 'Amount') + ',' +

                CMT_UnitTestData_TEST.createRollupRecord('Custom Result Field Test', filterGroupId1,
                        CMT_UnitTestData_TEST.RollupRecordType.OppToContact,
                        'Department', CRLP_Operation.RollupType.FIRST, 'Type') + ',' +

                /* Using SingleResult operation to get the last gift date */
                CMT_UnitTestData_TEST.createRollupRecord('Last Gift Date', filterGroupId1,
                        CMT_UnitTestData_TEST.RollupRecordType.OppToContact,
                        'npo02__LastCloseDate__c', CRLP_Operation.RollupType.LAST, 'CloseDate') + ',' +

                /* Using SingleResult operation to get the first gift date */
                CMT_UnitTestData_TEST.createRollupRecord('First Gift Date', filterGroupId1,
                        CMT_UnitTestData_TEST.RollupRecordType.OppToContact,
                        'npo02__FirstCloseDate__c', CRLP_Operation.RollupType.FIRST, 'CloseDate') + ',' +

                /* Payment Rollups for Total Paid and Total Written Off - using a field that can hold the value */
                CMT_UnitTestData_TEST.createRollupRecord('Total Payments', filterGroupId1,
                        CMT_UnitTestData_TEST.RollupRecordType.PmtToContact,
                        'First_Soft_Credit_Amount__c', CRLP_Operation.RollupType.SUM, 'npe01__Payment_Amount__c') + ',' +

                CMT_UnitTestData_TEST.createRollupRecord('Total Writeoffs', filterGroupId2,
                        CMT_UnitTestData_TEST.RollupRecordType.PmtToContact,
                        'npo02__LastMembershipAmount__c', CRLP_Operation.RollupType.SUM, 'npe01__Payment_Amount__c') +

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
    static testMethod void test_Rollups_AlwaysRollupToPrimaryEnabled() {
        testRollupsServices(TestType.TestWithAlwaysRollupToPrimary);
    }

    /**
     * @description Test some simple rollups from the Opportunity/Payment object to the Contact using
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
                npo02__Always_Rollup_to_Primary_Contact__c = (tt == TestType.TestWithAlwaysRollupToPrimary)
            ));

        // Create the test data
        mockRollupCMTValues();

        // Disable all legacy rollup triggers
        UTIL_UnitTestData_TEST.disableRollupTriggers();

        if (tt != TestType.TestTrigger) {
            // disable customizable rollup triggers to test the Batch & Queueuable logic
            UTIL_UnitTestData_TEST.disableCustomizableRollupTriggers();
        }

        // Retrieve the dummy Contacts and then insert 100 Opportunity records
        List<Contact> cons = [SELECT Id, FirstName, LastName, AccountId FROM Contact LIMIT 2];
        Contact c = cons[0];
        Contact c4 = cons[1];
        Id acctId = c.AccountId;
        Id conId = c.Id;
        Id acct4Id = c4.AccountId;
        Id con4Id = c4.Id;

        // Insert a single test Contact that will have no Opportunities, but should end up getting
        // processed and this field cleared.
        Contact c2 = UTIL_UnitTestData_TEST.getContact();
        c2.npo02__NumberOfClosedOpps__c = 100;  // force to a value that should be cleared to 0 since there are no opps for it

        Contact c3 = UTIL_UnitTestData_TEST.getContact();
        c3.npo02__NumberOfClosedOpps__c = null; // force this to null and will verify that it remains as null at the end
        insert new List<Contact>{ c2, c3 };

        Account orgAcct = new Account(Name = 'OrgTest567890', npe01__SYSTEMIsIndividual__c = false);
        insert orgAcct;

        String closedStage = UTIL_UnitTestData_TEST.getClosedWonStage();
        Id rtId = UTIL_RecordTypes.getRecordTypeIdForGiftsTests(Opportunity.SObjectType);

        List<Opportunity> opps = new List<Opportunity>();
        Date closeDate = Date.Today().addMonths(-100);
        Decimal totalDonations = 0, total2YearsAgo = 0, last365Days = 0;
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
                    RecordTypeId = rtId,
                    Type = 'New'
            ));
            totalDonations += amt;
            if (closeDate.addMonths(n).year() == Date.Today().addYears(-2).year()) {
                total2YearsAgo += amt;
            }
            if (closeDate.addMonths(n).daysBetween(Date.Today()) <= 365) {
                last365Days += amt;
            }
            String donationYr = UTIL_String.removeNonNumericCharacters(closeDate.addMonths(n).year().format());
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
                RecordTypeId = rtId,
                Type = 'New'
        ));

        // create one closed won Organization opportunity to ensure it's not included in the Contact Hard Credit rollups
        Decimal orgDonationAmt = 50000;
        Date orgDonationDate = Date.Today().addDays(-30);
        opps.add(new Opportunity (
                Name = 'Test Org Opp ' + c.FirstName + ' ' + c.LastName,
                AccountId = orgAcct.Id,
                Amount = orgDonationAmt,
                CloseDate = orgDonationDate,
                StageName = closedStage,
                Primary_Contact__c = conId,
                RecordTypeId = rtId,
                npe01__Do_Not_Automatically_Create_Payment__c = true,
                Type = 'New'
        ));

        // create 4 opps for con4 to test single result opp edge cases
        Date earlyLastYear = Date.newInstance(Date.today().year()-1,1,1);
        Date lateLastYear = Date.newInstance(Date.today().year()-1,12,31);
        Date earlyThisYear = Date.newInstance(Date.today().year(),1,1);
        opps.add(new Opportunity (
                Name = 'Test Opp SRO 1' + c.FirstName + ' ' + c.LastName,
                AccountId = acct4Id,
                Amount = 100,
                CloseDate = earlyLastYear,
                StageName = closedStage,
                Primary_Contact__c = con4Id,
                RecordTypeId = rtId,
                Recurring_Donation_Installment_Number__c = 4,
                npe01__Do_Not_Automatically_Create_Payment__c = true,
                Type = 'New'
        ));
        opps.add(new Opportunity (
                Name = 'Test Opp SRO 2' + c.FirstName + ' ' + c.LastName,
                AccountId = acct4Id,
                Amount = 50,
                CloseDate = lateLastYear,
                StageName = closedStage,
                Primary_Contact__c = con4Id,
                RecordTypeId = rtId,
                Recurring_Donation_Installment_Number__c = 42,
                npe01__Do_Not_Automatically_Create_Payment__c = true,
                Type = 'New'
        ));
        opps.add(new Opportunity (
                Name = 'Test Opp SRO 3' + c.FirstName + ' ' + c.LastName,
                AccountId = acct4Id,
                Amount = 200,
                CloseDate = earlyThisYear,
                StageName = closedStage,
                Primary_Contact__c = con4Id,
                RecordTypeId = rtId,
                Recurring_Donation_Installment_Number__c = 314,
                npe01__Do_Not_Automatically_Create_Payment__c = true,
                Type = 'New'
        ));
        opps.add(new Opportunity (
                Name = 'Test Opp SRO 4' + c.FirstName + ' ' + c.LastName,
                AccountId = acct4Id,
                Amount = 25,
                CloseDate = Date.today(),
                StageName = closedStage,
                Primary_Contact__c = con4Id,
                RecordTypeId = rtId,
                Recurring_Donation_Installment_Number__c = 56,
                npe01__Do_Not_Automatically_Create_Payment__c = true,
                Type = 'New'
        ));

        insert opps;

        // Mark two payments as written off; though only one should be rolled up
        npe01__OppPayment__c pmt1 = [SELECT npe01__Written_Off__c, npe01__Paid__c FROM npe01__OppPayment__c
        WHERE npe01__Opportunity__r.IsWon = false LIMIT 1];
        pmt1.npe01__Written_Off__c = true;
        pmt1.npe01__Paid__c = false;

        npe01__OppPayment__c pmt2 = [SELECT npe01__Written_Off__c, npe01__Paid__c FROM npe01__OppPayment__c
        WHERE npe01__Opportunity__r.IsWon = true AND npe01__Written_Off__c = false AND Id != :pmt1.Id LIMIT 1];
        pmt2.npe01__Written_Off__c = true;
        pmt2.npe01__Paid__c = false;

        Decimal totalPayments = totalDonations - baseAmt;

        Test.startTest();

        // Because data is being modified by the above, any cached filter evaluations are now invalid
        // so before issuing the DML against the payment records, clear any cached eval results
        CMT_FilterRuleEvaluation_SVC.cachedFilterEvalResults.clear();
        update new List<npe01__OppPayment__c>{ pmt1, pmt2 };

        system.assertEquals(cnt, [SELECT Count() FROM npe01__OppPayment__c WHERE npe01__Opportunity__r.IsWon = true],
                'There should be 100 payment records on closed won opps');
        system.assertEquals(cnt+1, [SELECT Count() FROM OpportunityContactRole WHERE Opportunity.IsWon = true AND ContactId = :conId],
                'There should be 101 OCR records on closed won opps');

        // Now test the rollups to the Contact from the Opportunity
        if (tt == TestType.TestTrigger) {
            // No need to execute anything special here. If the triggers worked as expected, then
            // the data will be rolled up automatically upon the stopTest().
        } else if (tt == TestType.TestBatch) {
            CRLP_RollupBatch_SVC.executeBatchRollupJob(CRLP_RollupProcessingOptions.RollupType.ContactHardCredit,
                    CRLP_RollupProcessingOptions.BatchJobMode.NonSkewMode, null, null);
        } else if (tt == TestType.testSkewBatch) {
            CRLP_RollupBatch_SVC.executeBatchRollupJob(CRLP_RollupProcessingOptions.RollupType.ContactHardCredit,
                    CRLP_RollupProcessingOptions.BatchJobMode.SkewMode, new List<Id>{conId, con4Id}, null);
        } else if (tt == TestType.TestQueueuable || tt == TestType.TestWithAlwaysRollupToPrimary) {
            System.enqueueJob(new CRLP_RollupQueueable(new List<Id>{conId, con4Id}));
        }
        Test.stopTest();

        // Query the Contact with all the target fields specified in the rollups
        String conQuery = CRLP_Query_SEL.buildObjectQueryForRollup(Contact.SObjectType) + ' WHERE Id = :conId LIMIT 1';
        c = database.query(conQuery);
        conQuery = CRLP_Query_SEL.buildObjectQueryForRollup(Contact.SObjectType) + ' WHERE Id = :con4Id LIMIT 1';
        c4 = database.query(conQuery);

        // If the AlwaysRollupToPrimaryContact field is checked, the totals will include the org donation
        if (tt == TestType.TestWithAlwaysRollupToPrimary) {
            totalDonations += orgDonationAmt;
            last365Days += orgDonationAmt;
            maxAmt = orgDonationAmt;
            cnt++;
            bestGiftYear = UTIL_String.removeNonNumericCharacters(orgDonationDate.year().format());
            if (orgDonationDate > lastCloseDate) {
                lastCloseDate = orgDonationDate;
            }
        }

        // Basic rollup asserts using existing NPSP rollup fields.
        System.assertEquals(cnt, c.npo02__NumberOfClosedOpps__c);
        System.assertEquals(totalDonations, c.npo02__TotalOppAmount__c);
        System.assertEquals(maxAmt, c.npo02__LargestAmount__c);
        System.assertEquals(closeDate, c.npo02__FirstCloseDate__c);
        System.assertEquals(lastCloseDate, c.npo02__LastCloseDate__c);
        System.assertEquals(totalDonations.divide(cnt, 2, System.RoundingMode.HALF_UP), c.npo02__AverageAmount__c);
        System.assertEquals(total2YearsAgo, c.npo02__OppAmount2YearsAgo__c);
        System.assertEquals(bestGiftYear, c.npo02__Best_Gift_Year__c);
        System.assertEquals(last365Days, c.npo02__OppAmountLastNDays__c);
        System.assertEquals('New', c.Department);

        // These 10 use other fields on the Contact object since there are no NPSP related fields to store the values in
        System.assertEquals(totalPayments, c.First_Soft_Credit_Amount__c,
                'Total Payments should match total donations less $100 because one payment has been marked as written off');
        System.assertEquals(baseAmt, c.npo02__LastMembershipAmount__c, 'The Amount written off does not match');
        System.assertEquals(donationYears.size(), c.npo02__NumberOfMembershipOpps__c, 'The current streak should be all the years');
        System.assertEquals(donationYears.size(), c.Description.split(';').size(), 'The list of donated years should match');
        System.assertEquals(42, c4.Number_of_Soft_Credits__c);
        System.assertEquals(4, c4.Number_of_Soft_Credits_Last_N_Days__c);
        System.assertEquals(56, c4.Number_of_Soft_Credits_Last_Year__c);
        System.assertEquals(314, c4.Number_of_Soft_Credits_This_Year__c);
        System.assertEquals(4, c4.Number_of_Soft_Credits_Two_Years_Ago__c);
        System.assertEquals(42, c4.npo02__Household_Naming_Order__c);

        // THe batch process will query all Contacts, but these 2 are special circumstances to validate
        if (tt == TestType.TestBatch) {
            // Contact2.npo02__NumberOfClosedOpps__c was set to 100, but has attached opps, so it should be reset to 0.
            Id c2Id = c2.Id;
            conQuery = CRLP_Query_SEL.buildObjectQueryForRollup(Contact.SObjectType) + ' WHERE Id = :c2Id LIMIT 1';
            c2 = database.query(conQuery);
            System.assertEquals(0, c2.npo02__NumberOfClosedOpps__c);

            // Contact3.npo02__NumberOfClosedOpps__c was set to null and has attached opps, so it remain as
            // null (vs. being reset to 0).
            Id c3Id = c3.Id;
            conQuery = CRLP_Query_SEL.buildObjectQueryForRollup(Contact.SObjectType) + ' WHERE Id = :c3Id LIMIT 1';
            c3 = database.query(conQuery);
            System.assertEquals(null, c3.npo02__NumberOfClosedOpps__c);
        }
    }
}