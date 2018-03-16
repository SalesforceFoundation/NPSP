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
* @group Custom Metadata Types
* @description Tests for CMT Filter Rule related actions
*/
@isTest(IsParallel=true)
private class CMT_FilterRuleEvaluation_TEST {

    private static Id filterGroupId1, filterGroupId2, filterGroupId3;

    /**
     * @description Because unit tests cannot actually insert Custom Metadata Types and there's no real way to know
     * exactly what's in the CMT objects, we can use this method to mock the contents of the cached MDT queries
     * for the unit tests
     */
    private static void mockFilterCMTValues() {

        filterGroupId1 = CMT_UnitTestData_TEST.getNewRecordId();
        filterGroupId2 = CMT_UnitTestData_TEST.getNewRecordId();
        filterGroupId3 = CMT_UnitTestData_TEST.getNewRecordId();

        String closedWonStage = UTIL_UnitTestData_TEST.getClosedWonStage();
        String donationRTId = UTIL_RecordTypes.getRecordTypeIdForGiftsTests(Opportunity.SObjectType);
        String anotherId = UTIL_RecordTypes.getRecordTypeIdForMembershipTests(Opportunity.SObjectType);
        RecordType rtDonation = [SELECT DeveloperName FROM RecordType WHERE Id = :donationRTId LIMIT 1];

        String filterGroupsJSON = '[' +
                CMT_UnitTestData_TEST.createFilterGroupRecord(filterGroupId1, 'Test Group 1') + ',' +
                CMT_UnitTestData_TEST.createFilterGroupRecord(filterGroupId2, 'Test Group 2') + ',' +
                CMT_UnitTestData_TEST.createFilterGroupRecord(filterGroupId3, 'Test Group 3') +
            ']';

        String filterRulesJSON = '[' +
            /*  FILTER RULES FOR FILTER GROUP 1 -- Opportunity only String, Boolean and Date fields */
                CMT_UnitTestData_TEST.createFilterRuleRecord(null, filterGroupId1, 'Group1.Rule1', 'Opportunity', 'IsWon', 'Equals', 'True') + ',' +
                CMT_UnitTestData_TEST.createFilterRuleRecord(null, filterGroupId1, 'Group1.Rule2', 'Opportunity', 'StageName', 'Starts_With', closedWonStage) + ',' +
                CMT_UnitTestData_TEST.createFilterRuleRecord(null, filterGroupId1, 'Group1.Rule3', 'Opportunity', 'StageName', 'Equals', closedWonStage.toUpperCase()) + ',' +
                CMT_UnitTestData_TEST.createFilterRuleRecord(null, filterGroupId1, 'Group1.Rule4', 'Opportunity', 'StageName', 'Contains', closedWonStage.right(3)) + ',' +
                CMT_UnitTestData_TEST.createFilterRuleRecord(null, filterGroupId1, 'Group1.Rule5', 'Opportunity', 'Type', 'Equals', '') + ',' +
                CMT_UnitTestData_TEST.createFilterRuleRecord(null, filterGroupId1, 'Group1.Rule6', 'Opportunity', 'NextStep', 'Contains', 'TEST') + ',' +
                CMT_UnitTestData_TEST.createFilterRuleRecord(null, filterGroupId1, 'Group1.Rule7', 'Opportunity', 'NextStep', 'Does_Not_Contain', 'NothingAtAll') + ',' +
                CMT_UnitTestData_TEST.createFilterRuleRecord(null, filterGroupId1, 'Group1.Rule8', 'Opportunity', 'CloseDate', 'Equals', 'THIS_YEAR') + ',' +
                CMT_UnitTestData_TEST.createFilterRuleRecord(null, filterGroupId1, 'Group1.Rule9', 'Opportunity', 'CloseDate', 'Equals', 'THIS_MONTH') + ',' +
                CMT_UnitTestData_TEST.createFilterRuleRecord(null, filterGroupId1, 'Group1.Rule10', 'Opportunity', 'CloseDate', 'Not_Equals', 'LAST_YEAR') + ',' +
                CMT_UnitTestData_TEST.createFilterRuleRecord(null, filterGroupId1, 'Group1.Rule11', 'Opportunity', 'CreatedDate', 'Equals', 'TODAY') + ',' +
                CMT_UnitTestData_TEST.createFilterRuleRecord(null, filterGroupId1, 'Group1.Rule12', 'Opportunity', 'CreatedDate', 'Equals', DateTime.Now().format('YYYY-MM-dd')) + ',' +
                CMT_UnitTestData_TEST.createFilterRuleRecord(null, filterGroupId1, 'Group1.Rule13', 'Opportunity', 'CreatedDate', 'Greater_Or_Equal', DateTime.Now().addDays(-1).format('YYYY-MM-dd hh:mm:ssZ')) + ',' +
                CMT_UnitTestData_TEST.createFilterRuleRecord(null, filterGroupId1, 'Group1.Rule14', 'Opportunity', 'CreatedDate', 'Less_Or_Equal', DateTime.Now().addDays(1).format('YYYY-MM-dd hh:mm:ssZ')) + ',' +
                CMT_UnitTestData_TEST.createFilterRuleRecord(null, filterGroupId1, 'Group1.Rule15', 'Opportunity', 'CreatedDate', 'Greater', DateTime.Now().addDays(-2).format('YYYY-MM-dd hh:mm:ssZ')) + ',' +
                CMT_UnitTestData_TEST.createFilterRuleRecord(null, filterGroupId1, 'Group1.Rule16', 'Opportunity', 'CreatedDate', 'Less', DateTime.Now().addDays(2).format('YYYY-MM-dd hh:mm:ssZ')) + ',' +
                CMT_UnitTestData_TEST.createFilterRuleRecord(null, filterGroupId1, 'Group1.Rule17', 'Opportunity', 'CreatedDate', 'Greater', 'YESTERDAY') + ',' +

                /*  FILTER RULES FOR FILTER GROUP 2 -- Opportunity with RecordTypeId, RecordType.DeveloperName, StageName, OCR.Role, Amount */
                CMT_UnitTestData_TEST.createFilterRuleRecord(null, filterGroupId2, 'Group2.Rule1', 'Opportunity', 'IsWon', 'Not_Equals', 'False') + ',' +
                CMT_UnitTestData_TEST.createFilterRuleRecord(null, filterGroupId2, 'Group2.Rule2', 'Opportunity', 'RecordTypeId', 'In_List', donationRTId + ';' + anotherId) + ',' +
                CMT_UnitTestData_TEST.createFilterRuleRecord(null, filterGroupId2, 'Group2.Rule2', 'Opportunity', 'RecordTypeId', 'In_List', rtDonation.DeveloperName) + ',' +
                CMT_UnitTestData_TEST.createFilterRuleRecord(null, filterGroupId2, 'Group2.Rule2', 'Opportunity', 'RecordTypeId', 'Equals', rtDonation.DeveloperName) + ',' +
                CMT_UnitTestData_TEST.createFilterRuleRecord(null, filterGroupId2, 'Group1.Rule3', 'Opportunity', 'Primary_Contact__c', 'Not_Equals', '') + ',' +
                CMT_UnitTestData_TEST.createFilterRuleRecord(null, filterGroupId2, 'Group2.Rule4', 'Opportunity', 'Amount', 'Greater', '0') + ',' +
                CMT_UnitTestData_TEST.createFilterRuleRecord(null, filterGroupId2, 'Group2.Rule5', 'Opportunity', 'Amount', 'Not_Equals', '') + ',' +
                CMT_UnitTestData_TEST.createFilterRuleRecord(null, filterGroupId2, 'Group2.Rule6', 'Opportunity', 'Amount', 'Less_Or_Equal', '1000000000') + ',' +
                CMT_UnitTestData_TEST.createFilterRuleRecord(null, filterGroupId2, 'Group2.Rule7', 'Opportunity', 'Amount', 'Greater_Or_Equal', '0') + ',' +
                CMT_UnitTestData_TEST.createFilterRuleRecord(null, filterGroupId2, 'Group2.Rule8', 'Opportunity', 'Recurring_Donation_Installment_Number__c', 'Not_Equals', '1') + ',' +
                CMT_UnitTestData_TEST.createFilterRuleRecord(null, filterGroupId2, 'Group2.Rule9', 'Opportunity', 'Recurring_Donation_Installment_Number__c', 'Greater_Or_Equal', '0') + ',' +
                CMT_UnitTestData_TEST.createFilterRuleRecord(null, filterGroupId2, 'Group2.Rule10', 'Partial_Soft_Credit__c', 'Role_Name__c', 'In_List', 'Donor;Member') + ',' +
                CMT_UnitTestData_TEST.createFilterRuleRecord(null, filterGroupId2, 'Group2.Rule11', 'Partial_Soft_Credit__c', 'Role_Name__c', 'Not_In_List', 'InvalidRole') +
            ']';

        // Count the number of records that there should be in the group and rule JSON strings
        Integer numGroups = filterGroupsJSON.countMatches('Filter_Group__mdt');
        Integer numRules = filterRulesJSON.countMatches('Filter_Rule__mdt');

        // Deserialize the JSON strings into the FilterGroup and FilterRule MDT types respectively
        CMT_FilterRule_SEL.cachedFilterGroups = (List<Filter_Group__mdt>)JSON.deserialize(
                filterGroupsJSON, List<Filter_Group__mdt>.class);
        CMT_FilterRule_SEL.cachedFilterRules = (List<Filter_Rule__mdt>)JSON.deserialize(
                filterRulesJSON, List<Filter_Rule__mdt>.class);

        // Validate that the expected number of Filter Groups and Filter Rule records were deserialized.
        System.AssertEquals(numGroups, CMT_FilterRule_SEL.cachedFilterGroups.size(),
            'There should have been ' + numGroups + ' Filter_Group__mdt records deserialized');
        System.AssertEquals(numRules, CMT_FilterRule_SEL.cachedFilterRules.size(),
            'There should have been ' + numRules + ' Filter_Rule__mdt records deserialized');
    }

    /**
     * @description test the evaluation method to process a given SObject against a FilterGroup
     */
    static testMethod void test_evaluateFilterRules() {
        mockFilterCMTValues();

        Contact c = UTIL_UnitTestData_TEST.getContact();
        insert c;
        c = [SELECT Id, AccountId, FirstName, LastName FROM Contact LIMIT 1];

        Opportunity o = new Opportunity (
                Name = 'Test Opp ' + c.FirstName + c.LastName,
                Amount = 1000,
                CloseDate = Date.Today().toStartOfMonth().addDays(1),
                StageName = UTIL_UnitTestData_TEST.getClosedWonStage(),
                Primary_Contact__c = c.Id,
                RecordTypeId = UTIL_RecordTypes.getRecordTypeIdForGiftsTests(Opportunity.sObjectType),
                NextStep = 'Test Next Step'
        );
        insert o;
        System.AssertEquals(1, [SELECT Count() FROM OpportunityContactRole]);

        Partial_Soft_Credit__c psc = new Partial_Soft_Credit__c(
                Opportunity__c = o.Id,
                Contact__c = c.Id,
                Role_Name__c = 'Donor',
                Amount__c = o.Amount
        );
        insert psc;

        // Query the Opportunity and the child OCR and Payment records to use in the evaluation
        String soql = CRLP_Query_SEL.buildDetailObjectQueryForRollup(Opportunity.SObjectType,
                new List<SObjectType>{OpportunityContactRole.SObjectType, npe01__OppPayment__c.SObjectType, Partial_Soft_Credit__c.SObjectType});
        o = database.query(soql);

        Test.startTest();

         System.AssertEquals(True, CMT_FilterRuleEvaluation_SVC.evaluateFilterGroup(new List<SObject>{o}, filterGroupId1));
         System.AssertEquals(True, CMT_FilterRuleEvaluation_SVC.evaluateFilterGroup(
                 new List<SObject>{o, o.OpportunityContactRoles[0]}, filterGroupId2));

        // TODO Add more tests
    }

}