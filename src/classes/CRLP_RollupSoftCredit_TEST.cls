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
* @description Unit Test for the Soft Credit to Account/Contact Rollups
*/
@isTest
private class CRLP_RollupSoftCredit_TEST {

    private Enum TestType {
        TestBatchContact, TestBatchAccount, testSkewBatchContact, TestWithAlwaysRollupToPrimary
    }

    /**
     * @description Test Setup: Insert a dummy contact and let it create an Account. The Opportunity data has to
     * be created in the actual unit test to allow for the trigger test to run
     */
    @TestSetup
    private static void setupBaseTestData() {

        Account orgAcct = new Account(Name = 'CRLP-ORG-TEST', npe01__SYSTEMIsIndividual__c = false);
        insert orgAcct;

        Contact c = UTIL_UnitTestData_TEST.getContact();
        c.FirstName = 'TEST-1';
        insert c;

        c = [SELECT Id, FirstName, LastName, AccountId FROM Contact LIMIT 1];
        Id acctId = c.AccountId;
        Id conId = c.Id;

        // Create two additional family members
        Contact c2 = new Contact(LastName = 'CRLP-UNITTEST-PSC', FirstName = 'TEST-2', AccountId = c.AccountId);
        Contact c3 = new Contact(LastName = 'CRLP-UNITTEST-PSC', FirstName = 'TEST-3', AccountId = c.AccountId);

        // Create one more Contact that is used to test filters
        Contact c4 = new Contact(LastName = 'CRLP-UNITTEST-PSC', FirstName = 'TEST-4');

        insert new List<Contact>{ c2, c3, c4 };

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

    static testMethod void test_Rollups_Contact() {
        testRollupsServices(TestType.testBatchContact);
    }
    static testMethod void test_Rollups_ContactSkew() {
        testRollupsServices(TestType.testSkewBatchContact);
    }
    static testMethod void test_Rollups_Account() {
        testRollupsServices(TestType.testBatchAccount);
    }
    static testMethod void test_Rollups_AlwaysRollupToPrimaryEnabled() {
        testRollupsServices(TestType.TestWithAlwaysRollupToPrimary);
    }

    /**
     * @description Test some simple rollups from the Opportunity/Payment object to the Contact using
     * the LDV Batch Job method - the only method supported by the soft credit rollup process
     */
    private static void testRollupsServices(TestType tt) {

        // Start by enabling Customizable Rollups (which disables all legacy rollup operations)
        UTIL_CustomSettingsFacade.getRollupSettingsForTests(new Customizable_Rollup_Settings__c (
                Customizable_Rollups_Enabled__c = true,
                Rollups_Limit_on_Attached_Opps_for_Skew__c = (tt == TestType.testSkewBatchContact ? 50 : 200),
                Rollups_Account_SkewMode_Batch_Size__c = 600,
                Rollups_Contact_SkewMode_Batch_Size__c = 600,
                Rollups_Contact_Soft_Credit_Batch_Size__c = 600,
                Rollups_Account_Soft_Credit_Batch_Size__c = 600,
                Rollups_Account_Batch_Size__c = 20,
                Rollups_Contact_Batch_Size__c = 20
            ));

        UTIL_CustomSettingsFacade.getContactsSettingsForTests(new npe01__Contacts_And_Orgs_Settings__c(
                npe01__Opportunity_Contact_Role_Default_role__c = 'Donor',
                npe01__Account_Processor__c = CAO_Constants.HH_ACCOUNT_PROCESSOR,
                npe01__Payments_Enabled__c = false
            ));

        UTIL_CustomSettingsFacade.getHouseholdsSettingsForTests(new npo02__Households_Settings__c (
                npo02__Household_Rules__c = HH_Households.ALL_PROCESSOR,
                npo02__Household_Member_Contact_Role__c = label.npo02.Household_Member_Contact_Role,
                npo02__Household_Contact_Roles_On__c = true,
                npo02__Always_Rollup_to_Primary_Contact__c = (tt == TestType.TestWithAlwaysRollupToPrimary)
            ));


        // Create the test data
        mockRollupCMTValues();

        // Disable all rollup triggers to avoid governer or unit test limit issues
        UTIL_UnitTestData_TEST.disableRollupTriggers();
        UTIL_UnitTestData_TEST.disableCustomizableRollupTriggers();

        Account orgAcct = [SELECT Id, Name FROM Account WHERE npe01__SYSTEMIsIndividual__c = false LIMIT 1];

        // Insert a dummy Contact and 100 Opportunity records
        // Retrieve the dummy Contact and then insert 100 Opportunity records
        Contact c1, c2, c3, c4;
        Id acctId, conId;
        for (Contact cx : [SELECT Id, FirstName, LastName, AccountId FROM Contact WHERE AccountId != :orgAcct.Id]) {
            if (cx.FirstName == 'TEST-1') {
                acctId = cx.AccountId;
                conId = cx.Id;
                c1 = cx;
            } else if (cx.FirstName == 'TEST-2') {
                c2 = cx;
            } else if (cx.FirstName == 'TEST-3') {
                c3 = cx;
            } else if (cx.FirstName == 'TEST-4') {
                c4 = cx;
            }
        }

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
                    Name = 'Test Opp ' + c1.FirstName + ' ' + c1.LastName,
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
            
            String donationYr = UTIL_String.removeNonNumericCharacters(closeDate.addMonths(n).year().format());
            donationYears.add(donationYr);
            if (amt == maxAmt) {
                bestGiftYear = donationYr;
                largestGiftDate = closeDate.addMonths(n);
            }
            lastCloseDate = closeDate.addMonths(n);
        }

        // create one closed opportunity to ensure it's not included in our rollups
        opps.add(new Opportunity (
                Name = 'Test Opp ' + c1.FirstName + ' ' + c1.LastName,
                Amount = 500,
                CloseDate = Date.Today().addDays(1),
                StageName = UTIL_UnitTestData_TEST.getClosedLostStage(),
                Primary_Contact__c = conId,
                RecordTypeId = rtId
        ));

        // create one closed won Organization opportunity to ensure it's not included in the Contact Hard Credit rollups
        Decimal orgDonationAmt = 50000;
        Date orgDonationDate = Date.Today().addDays(-30);
        opps.add(new Opportunity (
                Name = 'Test Org Opp ' + c1.FirstName + ' ' + c1.LastName,
                AccountId = orgAcct.Id,
                Amount = orgDonationAmt,
                CloseDate = orgDonationDate,
                StageName = closedStage,
                Primary_Contact__c = c4.Id,
                RecordTypeId = rtId,
                npe01__Do_Not_Automatically_Create_Payment__c = true
        ));

        insert opps;

        // Change the OCR Role on the org donation so that it will roll up as a soft credit.
        OpportunityContactRole orgOCR = [SELECT Id, OpportunityId, ContactId, Role FROM OpportunityContactRole
                    WHERE Opportunity.AccountId = :orgAcct.Id AND IsPrimary = True LIMIT 1];
        orgOCR.Role = label.npo02.Household_Member_Contact_Role;
        update orgOCR;

        //Create duplicate Non Primary OCRs to test the Rollup for duplicate OCRs.
        List<OpportunityContactRole> duplicateNonPrimaryOCRs = [
            SELECT OpportunityId, ContactId, Role, IsPrimary 
            FROM OpportunityContactRole 
            WHERE IsPrimary = false 
            AND Opportunity.IsWon = true
        ].deepClone();
        insert duplicateNonPrimaryOCRs;

        Test.startTest();

        system.assertEquals((cnt * 3) + duplicateNonPrimaryOCRs.size() + 1, [SELECT Count() FROM OpportunityContactRole WHERE Opportunity.IsWon = true],
                'There should be 301 OCR records on closed won opps');

        List<Id> contactIds = new List<Id>{ c1.Id, c2.Id, c3.Id, c4.Id };

        // Now test the rollups to the Account from the Opportunity - use large batch size to get all OCR's at once
        if (tt == TestType.testSkewBatchContact || tt == TestType.TestWithAlwaysRollupToPrimary) {
            CRLP_RollupBatch_SVC.executeBatchRollupJob(CRLP_RollupProcessingOptions.RollupType.ContactSoftCredit,
                    CRLP_RollupProcessingOptions.BatchJobMode.SkewMode, contactIds, null);
        } else if (tt == TestType.TestBatchContact) {
            CRLP_RollupBatch_SVC.executeBatchRollupJob(CRLP_RollupProcessingOptions.RollupType.ContactSoftCredit,
                    CRLP_RollupProcessingOptions.BatchJobMode.NonSkewMode, null, null);
        } else if (tt == TestType.TestBatchAccount) {
            CRLP_RollupBatch_SVC.executeBatchRollupJob(CRLP_RollupProcessingOptions.RollupType.AccountContactSoftCredit,
                    CRLP_RollupProcessingOptions.BatchJobMode.NonSkewMode, null, null);
        }
        Test.stopTest();

        // Query the Contact with Soft Credits with all the target fields specified in the rollups
        if (tt != TestType.TestBatchAccount) {
            Id c2Id = c2.Id;
            String conQuery = CRLP_Query_SEL.buildObjectQueryForRollup(Contact.SObjectType) + ' WHERE Id = :c2Id LIMIT 1';
            c2 = database.query(conQuery);

            // Basic rollup asserts using existing NPSP rollup fields.
            System.assertEquals(totalDonations, c2.npo02__Soft_Credit_Total__c);
            System.assertEquals(cnt, c2.Number_of_Soft_Credits__c);
            System.assertEquals(firstCloseDate, c2.First_Soft_Credit_Date__c);
            System.assertEquals(largestGiftDate, c2.Largest_Soft_Credit_Date__c);
            System.assertEquals(baseAmt, c2.Last_Soft_Credit_Amount__c);
            System.assertEquals(maxAmt, c2.Largest_Soft_Credit_Amount__c);

            // Query the Primary Contact (should have NO Soft Credit)
            conQuery = CRLP_Query_SEL.buildObjectQueryForRollup(Contact.SObjectType) + ' WHERE Id = :conId LIMIT 1';
            c1 = database.query(conQuery);
            System.assert(c1.npo02__Soft_Credit_Total__c == null || c1.npo02__Soft_Credit_Total__c == 0,
                    'The Total Soft Credits for this contact should be null or zero');

            // Query the Contact listed as the primary on an organizational opportunity. This contact
            // has only this one soft credit attributed to them.
            Id c4Id = c4.Id;
            conQuery = CRLP_Query_SEL.buildObjectQueryForRollup(Contact.SObjectType) + ' WHERE Id = :c4Id LIMIT 1';
            c4 = database.query(conQuery);
            if (tt != TestType.TestWithAlwaysRollupToPrimary) {
                System.assertEquals(orgDonationAmt, c4.npo02__Soft_Credit_Total__c);
                System.assertEquals(1, c4.Number_of_Soft_Credits__c);
            } else {
                System.assertEquals(null, c4.npo02__Soft_Credit_Total__c);
                System.assertEquals(null, c4.Number_of_Soft_Credits__c);
            }
        }

        // Basic rollup asserts using existing NPSP rollup fields.
        if (tt == TestType.TestBatchAccount) {
            // Query the Household
            String acctQuery = CRLP_Query_SEL.buildObjectQueryForRollup(Account.SObjectType) + ' WHERE Id = :acctId LIMIT 1';
            Account a = database.query(acctQuery);

            System.assertEquals(totalDonations, a.npo02__TotalOppAmount__c);
            System.assertEquals(cnt, a.npo02__NumberOfClosedOpps__c);
            System.assertEquals(firstCloseDate, a.npo02__FirstCloseDate__c);
            System.assertEquals(baseAmt, a.npo02__LastOppAmount__c);
            System.assertEquals(maxAmt, a.npo02__LargestAmount__c);
        }
    }
}