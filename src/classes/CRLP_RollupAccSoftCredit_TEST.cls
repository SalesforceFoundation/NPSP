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
* @description Unit Test for the Account Soft Credit to Account Rollups
*/
@isTest
private class CRLP_RollupAccSoftCredit_TEST {

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

        // Create a single Filter Group (no need for filter rules here)
        String filterGroupId1 = CMT_UnitTestData_TEST.getNewRecordId();
        String filterGroupId2 = CMT_UnitTestData_TEST.getNewRecordId();

        // Simple testing filters for IsWon, RecordType, and Paid/Written Off
        String filterGroupsJSON = '[' +
                CMT_UnitTestData_TEST.createFilterGroupRecord(filterGroupId1, 'TestFilterGroup1-IsWon') + ',' +
                CMT_UnitTestData_TEST.createFilterGroupRecord(filterGroupId2, 'TestFilterGroup2-IsWon-IsInf') +
                ']';
        String filterRulesJSON = '[' +
                CMT_UnitTestData_TEST.createFilterRuleRecord(null, filterGroupId1, 'Group1.Rule1', 'Opportunity', 'IsWon', 'Equals', 'True') + ',' +
                CMT_UnitTestData_TEST.createFilterRuleRecord(null, filterGroupId1, 'Group1.Rule2', 'Opportunity', 'RecordTypeId', 'Equals', rtDonation.DeveloperName) + ',' +

                CMT_UnitTestData_TEST.createFilterRuleRecord(null, filterGroupId2, 'Group2.Rule1', 'Opportunity', 'IsWon', 'Equals', 'True') + ',' +
                CMT_UnitTestData_TEST.createFilterRuleRecord(null, filterGroupId2, 'Group2.Rule2', 'Opportunity', 'RecordTypeId', 'Equals', rtDonation.DeveloperName) + ',' +
                CMT_UnitTestData_TEST.createFilterRuleRecord(null, filterGroupId2, 'Group2.Rule3', 'Account_Soft_Credit__c', 'Role__c', 'Equals', 'Influencer') +
                ']';

        // Deserialize the filter group and filter rule to use for the tests
        CMT_FilterRule_SEL.cachedFilterGroups = (List<Filter_Group__mdt>)JSON.deserialize(filterGroupsJSON, List<Filter_Group__mdt>.class);
        CMT_FilterRule_SEL.cachedFilterRules = (List<Filter_Rule__mdt>)JSON.deserialize(filterRulesJSON, List<Filter_Rule__mdt>.class);

        // Create a single Rollup that uses the above Filter Group
        // TODO Add many more rollup variations to this
        String rollupsJSON = '[' +

                // Using nonsense fields for Account Soft Credit tests since we don't package anything for Account Soft Credits

                CMT_UnitTestData_TEST.createRollupRecord('Total Account Soft Credits', filterGroupId1,
                        CMT_UnitTestData_TEST.RollupRecordType.AccountSoftCreditToAccount, 'Matching_Gift_Amount_Max__c',
                        CRLP_Operation.RollupType.SUM, 'Amount__c') + ',' +

                CMT_UnitTestData_TEST.createRollupRecord('Largest Account Soft Credit', filterGroupId1,
                        CMT_UnitTestData_TEST.RollupRecordType.AccountSoftCreditToAccount, 'Matching_Gift_Amount_Min__c',
                        CRLP_Operation.RollupType.LARGEST, 'Amount__c') + ',' +

                CMT_UnitTestData_TEST.createRollupRecord('Date of Last Inf Soft Credit', filterGroupId2,
                        CMT_UnitTestData_TEST.RollupRecordType.AccountSoftCreditToAccount, 'Matching_Gift_Info_Updated__c',
                        CRLP_Operation.RollupType.LAST, 'CloseDate') +

                ']';

        // Deserialize the rollups to use for testing
        CRLP_Rollup_SEL.cachedRollups = (List<Rollup__mdt>) JSON.deserialize(rollupsJSON, List<Rollup__mdt>.class);
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
        Account softCreditAcc = [SELECT Id FROM Account WHERE Id != :hardCreditAccId];

        String closedStage = UTIL_UnitTestData_TEST.getClosedWonStage();
        Id rtId = UTIL_RecordTypes.getRecordTypeIdForGiftsTests(Opportunity.SObjectType);

        List<Opportunity> opps = new List<Opportunity>();
        Date closeDate = Date.Today().addMonths(-100);
        Decimal maxAmt = 1000;
        Decimal baseAmt = 100;
        Integer cnt = 100;
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
        }

        insert opps;

        // create 5 Account Soft Credits
        Integer accSCBaseAmt = 10;
        Integer accSCMaxAmt = 50;
        Integer ascCount = 5;
        Date lastInfluencerDate;
        List<Account_Soft_Credit__c> accSCs = new List<Account_Soft_Credit__c>();
        for (Integer i=0; i<ascCount; i++) {
            Decimal accSCAmt = (i==3 ? accSCMaxAmt : accSCBaseAmt);
            Account_Soft_Credit__c accSC = new Account_Soft_Credit__c (
                    Amount__c = accSCAmt,
                    Account__c = softCreditAcc.Id,
                    Opportunity__c = opps[i].Id,
                    Role__c = (i==5 ? 'Match' : 'Influencer')
            );
            accSCs.add(accSC);

            if (accSC.Role__c == 'Influencer') {
                lastInfluencerDate = opps[i].CloseDate;
            }
        }
        insert accSCs;

        Test.startTest();

        // Because data is being modified by the above, any cached filter evaluations are now invalid
        // so before issuing the DML against the payment records, clear any cached eval results
        CMT_FilterRuleEvaluation_SVC.cachedFilterEvalResults.clear();

        String baseAccountQuery = CRLP_Query_SEL.buildObjectQueryForRollup(Account.SObjectType);

        Id softCreditAccId = softCreditAcc.Id;
        String softCreditAccQuery = baseAccountQuery + ' WHERE Id = :softCreditAccId LIMIT 1';
        softCreditAcc = database.query(softCreditAccQuery);

        // Make sure everything is null first!
        if (tt != TestType.TestTrigger) {
            System.assertEquals(null, softCreditAcc.Matching_Gift_Amount_Max__c);
            System.assertEquals(null, softCreditAcc.Matching_Gift_Amount_Min__c);
            System.assertEquals(null, softCreditAcc.Matching_Gift_Info_Updated__c);
        }

        // Now test the rollups to the Account from the Account Soft Credit
        if (tt == TestType.TestTrigger) {

            // no account soft credit rollups in trigger mode

        } else if (tt == TestType.TestBatch) {

            CRLP_RollupBatch_SVC.executeBatchRollupJob(CRLP_RollupProcessingOptions.RollupType.AccountSoftCredit,
                    CRLP_RollupProcessingOptions.BatchJobMode.NonSkewMode, null, null);

        } else if (tt == TestType.testSkewBatch) {

            CRLP_RollupBatch_SVC.executeBatchRollupJob(CRLP_RollupProcessingOptions.RollupType.AccountSoftCredit,
                    CRLP_RollupProcessingOptions.BatchJobMode.SkewMode, new List<Id>{
                            softCreditAccId
                    }, null);

        } else if (tt == TestType.TestQueueuable) {

            // no account soft credit rollups in queueable mode

        }
        Test.stopTest();

        // Query the Accounts with all the target fields specified in the rollups
        softCreditAcc = database.query(softCreditAccQuery);

        // Account Soft Credit rollup assert uses nonsense NPSP field not otherwise used in these tests
        // Account Soft Credit rollups run in batch mode only
        if (tt == TestType.TestBatch || tt == TestType.testSkewBatch) {
            System.assertEquals((accSCBaseAmt * (ascCount-1)) + accSCMaxAmt, softCreditAcc.Matching_Gift_Amount_Max__c, 'The total of Account Soft Credits is incorrect.');
            System.assertEquals(accSCMaxAmt, softCreditAcc.Matching_Gift_Amount_Min__c, 'The Largest Account Soft Credits is incorrect.');
            System.assertEquals(lastInfluencerDate, softCreditAcc.Matching_Gift_Info_Updated__c, 'The Date of Last Account Soft Credit is incorrect.');
        }
    }
}