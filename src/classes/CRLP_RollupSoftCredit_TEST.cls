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
* @description Unit Test for the Soft Credit to Account/Contact Rollups
*/
@isTest
private class CRLP_RollupSoftCredit_TEST {

    private Enum TestType {
        TestTrigger, TestQueueuable, TestBatch, TestLDV
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

        // Simple testing filter IsWon, RecordType, and SoftCredit Role Name
        String filterGroupsJSON = '[' +
                CMT_UnitTestData_TEST.createFilterGroupRecord(filterGroupId1, 'TestFilterGroup1-IsWon+SoftCredit') +
            ']';
        String filterRulesJSON = '[' +
                CMT_UnitTestData_TEST.createFilterRuleRecord(null, filterGroupId1, 'Group1.Rule1', 'Opportunity', 'IsWon', 'Equals', 'True') + ',' +
                CMT_UnitTestData_TEST.createFilterRuleRecord(null, filterGroupId1, 'Group1.Rule2', 'Opportunity', 'RecordTypeId', 'Equals', rtDonation.DeveloperName) + ',' +
                CMT_UnitTestData_TEST.createFilterRuleRecord(null, filterGroupId1, 'Group1.Rule3', 'Partial_Soft_Credit__c', 'Role_Name__c', 'In_List', 'Matched Donor;Soft Credit;Household Member') +
            ']';

        // Deserialize the filter group and filter rule to use for the tests
        CMT_FilterRule_SEL.cachedFilterGroups = (List<Filter_Group__mdt>)JSON.deserialize(filterGroupsJSON, List<Filter_Group__mdt>.class);
        CMT_FilterRule_SEL.cachedFilterRules = (List<Filter_Rule__mdt>)JSON.deserialize(filterRulesJSON, List<Filter_Rule__mdt>.class);

        // Create a single Rollup that uses the above Filter Group
        // TODO Add many more rollup variations to this
        String rollupsJSON = '[' +
                /* CONTACT SOFT-CREDIT ROLL-UPS */
                CMT_UnitTestData_TEST.createRollupRecord('Contact: Soft Credits - Total', filterGroupId1,
                        CMT_UnitTestData_TEST.RollupRecordType.SoftCreditToContact,
                        'npo02__Soft_Credit_Total__c', CRLP_Operation.RollupType.SUM, 'Amount__c') + ',' +

                CMT_UnitTestData_TEST.createRollupRecord('Contact: Soft Credits - Count All', filterGroupId1,
                        CMT_UnitTestData_TEST.RollupRecordType.SoftCreditToContact,
                        'Number_of_Soft_Credits__c', CRLP_Operation.RollupType.COUNT, '') + ',' +

                CMT_UnitTestData_TEST.createRollupRecord('Contact: Soft Credits - Last Amount', filterGroupId1,
                        CMT_UnitTestData_TEST.RollupRecordType.SoftCreditToContact,
                        'Last_Soft_Credit_Amount__c', CRLP_Operation.RollupType.LAST, 'Amount__c') + ',' +

                CMT_UnitTestData_TEST.createRollupRecord('Contact: Soft Credits - Largest Amount', filterGroupId1,
                        CMT_UnitTestData_TEST.RollupRecordType.SoftCreditToContact,
                        'Largest_Soft_Credit_Amount__c', CRLP_Operation.RollupType.LARGEST, 'Amount__c') + ',' +

                CMT_UnitTestData_TEST.createRollupRecord('Contact: Soft Credits - Date of Largest', filterGroupId1,
                        CMT_UnitTestData_TEST.RollupRecordType.SoftCreditToContact,
                        'Largest_Soft_Credit_Date__c', CRLP_Operation.RollupType.LARGEST, 'CloseDate') + ',' +

                CMT_UnitTestData_TEST.createRollupRecord('Contact: Soft Credits - First Date', filterGroupId1,
                        CMT_UnitTestData_TEST.RollupRecordType.SoftCreditToContact,
                        'First_Soft_Credit_Date__c', CRLP_Operation.RollupType.FIRST, 'CloseDate') + ',' +

                /* ACCOUNT SOFT-CREDIT ROLL-UPS (there are no packaged soft credit fields, so using hard credit fields to test) */
                CMT_UnitTestData_TEST.createRollupRecord('Account: Soft Credits - Total', filterGroupId1,
                        CMT_UnitTestData_TEST.RollupRecordType.ContactSoftCreditToAccount,
                        'npo02__TotalOppAmount__c', CRLP_Operation.RollupType.SUM, 'Amount__c') + ',' +

                CMT_UnitTestData_TEST.createRollupRecord('Account: Soft Credits - Count All', filterGroupId1,
                        CMT_UnitTestData_TEST.RollupRecordType.ContactSoftCreditToAccount,
                        'npo02__NumberOfClosedOpps__c', CRLP_Operation.RollupType.COUNT, '') + ',' +

                CMT_UnitTestData_TEST.createRollupRecord('Account: Soft Credits - Last Amount', filterGroupId1,
                        CMT_UnitTestData_TEST.RollupRecordType.ContactSoftCreditToAccount,
                        'npo02__LastOppAmount__c', CRLP_Operation.RollupType.LAST, 'Amount__c') + ',' +

                CMT_UnitTestData_TEST.createRollupRecord('Account: Soft Credits - Largest Amount', filterGroupId1,
                        CMT_UnitTestData_TEST.RollupRecordType.ContactSoftCreditToAccount,
                        'npo02__LargestAmount__c', CRLP_Operation.RollupType.LARGEST, 'Amount__c') + ',' +

                CMT_UnitTestData_TEST.createRollupRecord('Account: Soft Credits - First Date', filterGroupId1,
                        CMT_UnitTestData_TEST.RollupRecordType.ContactSoftCreditToAccount,
                        'npo02__FirstCloseDate__c', CRLP_Operation.RollupType.FIRST, 'CloseDate') +

                ']';

        // Deserialize the rollups to use for testing
        CRLP_Rollup_SEL.cachedRollups = (List<Rollup__mdt>) JSON.deserialize(rollupsJSON, List<Rollup__mdt>.class);

    }

    static testMethod void test_Rollups_SoftCredits() {
        testRollupsServices(TestType.TestLDV);
    }

    /**
     * @description Test some simple rollups from the Opportunity/Payment object to the Contact using
     * the LDV Batch Job method - the only method supported by the soft credit rollup process
     */
    private static void testRollupsServices(TestType tt) {

        // Start by enabling Customizable Rollups (which disables all legacy rollup operations)
        UTIL_CustomSettingsFacade.getHouseholdsSettingsForTests(
                new npo02__Households_Settings__c (
                        npo02__Household_Rules__c = HH_Households.ALL_PROCESSOR,
                        npo02__Household_Member_Contact_Role__c = label.npo02.Household_Member_Contact_Role,
                        npo02__Household_Contact_Roles_On__c = true
                ));

        UTIL_CustomSettingsFacade.getRollupSettingsForTests(new Customizable_Rollup_Settings__c (
                Customizable_Rollups_Enabled__c = true,
                Rollups_Limit_on_Attached_Opps_for_LDV__c = (tt == TestType.TestLDV ? 50 : 200),
                Rollups_LDV_Batch_Size__c = 600,
                Rollups_Account_Batch_Size__c = 20,
                Rollups_Contact_Batch_Size__c = 20
        ));

        UTIL_CustomSettingsFacade.getContactsSettingsForTests(new npe01__Contacts_And_Orgs_Settings__c(
                npe01__Opportunity_Contact_Role_Default_role__c = 'Donor',
                npe01__Account_Processor__c = CAO_Constants.HH_ACCOUNT_PROCESSOR,
                npe01__Payments_Enabled__c = false
        ));

        // Create the test data
        mockRollupCMTValues();

        // Disable all rollup triggers to avoid governer or unit test limit issues
        UTIL_UnitTestData_TEST.disableRollupTriggers();
        UTIL_UnitTestData_TEST.disableCustomizableRollupTriggers();

        // Insert a dummy Contact and 100 Opportunity records
        Contact c = UTIL_UnitTestData_TEST.getContact();
        insert c;
        c = [SELECT Id, FirstName, LastName, AccountId FROM Contact LIMIT 1];
        Id acctId = c.AccountId;
        Id conId = c.Id;

        // Create two additional family members
        Contact c2 = new Contact(LastName = 'UNITTEST-PSC', FirstName = 'TEST-1', AccountId = c.AccountId);
        Contact c3 = new Contact(LastName = 'UNITTEST-PSC', FirstName = 'TEST-2', AccountId = c.AccountId);

        // Create one more Contact that is used to test filters
        Contact c4 = new Contact(LastName = 'UNITTEST-PSC', FirstName = 'TEST-3');

        insert new List<Contact>{ c2, c3, c4 };

        String closedStage = UTIL_UnitTestData_TEST.getClosedWonStage();
        Id rtId = UTIL_RecordTypes.getRecordTypeIdForGiftsTests(Opportunity.SObjectType);

        List<Opportunity> opps = new List<Opportunity>();
        Date closeDate = Date.Today().addMonths(-100);
        Date firstCloseDate = closeDate;
        Decimal totalDonations = 0, total2YearsAgo = 0;
        Decimal maxAmt = 1000;
        Decimal baseAmt = 100;
        Integer cnt = 100;
        String bestGiftYear;
        Set<String> donationYears = new Set<String>();
        Date lastCloseDate, largestGiftDate;
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
            String donationYr = closeDate.addMonths(n).year().format().replace(',','');
            donationYears.add(donationYr);
            if (amt == maxAmt) {
                bestGiftYear = donationYr;
                largestGiftDate = closeDate.addMonths(n);
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

        system.assertEquals(opps.size(), [SELECT Count() FROM Opportunity WHERE Account.npe01__SYSTEMIsIndividual__c = TRUE]);

        Test.startTest();

        system.assertEquals(cnt * 3, [SELECT Count() FROM OpportunityContactRole WHERE Opportunity.IsWon = true],
                'There should be 300 OCR records on closed won opps');

        // Now test the rollups to the Account from the Opportunity - use large batch size to get all OCR's at once
        database.executeBatch(new CRLP_Rollup_SoftCredit_LDV_BATCH(), 600);
        Test.stopTest();

        // Query the Contact with Soft Credits with all the target fields specified in the rollups
        Id c2Id = c2.Id;
        String conQuery = CRLP_Query_SEL.getResultsQuery(Contact.SObjectType) + ' WHERE Id = :c2Id LIMIT 1';
        c2 = database.query(conQuery);

        // Basic rollup asserts using existing NPSP rollup fields.
        System.assertEquals(totalDonations, c2.npo02__Soft_Credit_Total__c);
        System.assertEquals(cnt, c2.Number_of_Soft_Credits__c);
        System.assertEquals(firstCloseDate, c2.First_Soft_Credit_Date__c);
        System.assertEquals(largestGiftDate, c2.Largest_Soft_Credit_Date__c);
        System.assertEquals(baseAmt, c2.Last_Soft_Credit_Amount__c);
        System.assertEquals(maxAmt, c2.Largest_Soft_Credit_Amount__c);

        // Query the Primary Contact (NO Soft Credit)
        conQuery = CRLP_Query_SEL.getResultsQuery(Contact.SObjectType) + ' WHERE Id = :conId LIMIT 1';
        c = database.query(conQuery);
        System.assert(c.npo02__Soft_Credit_Total__c == null || c.npo02__Soft_Credit_Total__c == 0,
                'The Total Soft Credits for this contact should be null or zero');

        // Query the Household Account and validate the soft-credit values
        Id c4Id = c4.Id;
        conQuery = CRLP_Query_SEL.getResultsQuery(Contact.SObjectType) + ' WHERE Id = :c4Id LIMIT 1';
        c = database.query(conQuery);
        System.assert(c.npo02__Soft_Credit_Total__c == null || c.npo02__Soft_Credit_Total__c == 0,
                'The Total Soft Credits for this contact should be null or zero');

        // Query the Contact with Soft Credits with all the target fields specified in the rollups
        String acctQuery = CRLP_Query_SEL.getResultsQuery(Account.SObjectType) + ' WHERE Id = :acctId LIMIT 1';
        Account a = database.query(acctQuery);

        // Basic rollup asserts using existing NPSP rollup fields.
        System.assertEquals(totalDonations, a.npo02__TotalOppAmount__c);
        System.assertEquals(cnt, a.npo02__NumberOfClosedOpps__c);
        System.assertEquals(firstCloseDate, a.npo02__FirstCloseDate__c);
        System.assertEquals(baseAmt, a.npo02__LastOppAmount__c);
        System.assertEquals(maxAmt, a.npo02__LargestAmount__c);
    }
}