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
private class CMT_FilterRule_TEST {

    /**
     * @description Because unit tests cannot actually insert Custom Metadata Types and there's no real way to know
     * exactly what's in the CMT objects, we can use this method to mock the contents of the cached MDT queries
     * for the unit tests
     */
    private static void mockFilterCMTValues() {

        String filterGroupId = CMT_UnitTestData_TEST.getNewRecordId();
        String filterGroupsJSON = '[' + CMT_UnitTestData_TEST.createFilterGroupRecord(filterGroupId, 'TestFilterGroup') + ']';

        String filterRulesJSON = '[' +
                CMT_UnitTestData_TEST.createFilterRuleRecord(null, filterGroupId, 'TestRule1', 'Opportunity', 'IsWon', 'Equals', 'True') + ',' +
                CMT_UnitTestData_TEST.createFilterRuleRecord(null, filterGroupId, 'TestRule2', 'Opportunity', 'IsClosed', 'Equals', 'True') + ',' +
                CMT_UnitTestData_TEST.createFilterRuleRecord(null, filterGroupId, 'TestRule3', 'Opportunity', 'CloseDate', 'Equals', 'THIS_YEAR') + ',' +
                CMT_UnitTestData_TEST.createFilterRuleRecord(null, filterGroupId, 'TestRule4', 'Partial_Soft_Credit__c', 'Role_Name__c', 'In_List', 'Donor;Member') +
            ']';

        CMT_FilterRule_SEL.cachedFilterGroups = (List<Filter_Group__mdt>)JSON.deserialize(
                filterGroupsJSON, List<Filter_Group__mdt>.class);

        CMT_FilterRule_SEL.cachedFilterRules = (List<Filter_Rule__mdt>)JSON.deserialize(
                filterRulesJSON, List<Filter_Rule__mdt>.class);
    }

    /**
     * @description Test the FilterGroup and FilterRule selector methods. Relies on hardcoded JSON deserialized
     * MDT data for these tests.
     */
    private static testMethod void test_FilterRule_Selectors() {

        mockFilterCMTValues();

        System.AssertEquals(1, CMT_FilterRule_SEL.getFilterGroupsById().size(), 'There should be one Filter Group');

        Map<Id, List<Filter_Rule__mdt>> filterRulesByGroup = CMT_FilterRule_SEL.getFilterRulesByGroup();
        Id filterGroupId = (new List<Id>(filterRulesByGroup.keySet()))[0];
        List<Filter_Rule__mdt> filterRules =  filterRulesByGroup.get(filterGroupId);
        System.AssertEquals(1, filterRulesByGroup.size(), 'There should be one Filter Group');
        System.AssertEquals(4, filterRules.size(), 'There should be four Filter Rules in the Filter Group');

        // Test that a list of fields to query is returned
        String objName = CMT_FilterRule_SEL.cachedFilterRules[0].Object__c;
        String queryFields = CMT_FilterRule_SEL.getReferencedFieldsByObjectAsString(Schema.getGlobalDescribe().get(objName));
        System.Assert(String.isNotEmpty(queryFields),
            'There should be at least one referenced field for the ' + objName + ' object in Filter_Rule__mdt');

        // Test that a query can be built and executed, though it's likely there will be zero rows returned
        // so don't attempt to validate the result.
        String soql = 'SELECT Id,' + queryFields + ' FROM ' + objName + ' LIMIT 1';
        List<SObject> test = database.query(soql);

        System.AssertEquals(true, CMT_FilterRule_SEL.getReferencedFieldsByObject(Partial_Soft_Credit__c.SObjectType).size() > 0,
                'There should be at least one referenced field for the Partial_Soft_Credit object in Filter_Rule__mdt');
    }

    /**
     * @description Test various User Interface methods in the UI Service class
     */
    private static testMethod void test_OperationMethods() {
        mockFilterCMTValues();

        test.startTest();

        // Validate that the operation supporting methods retrieve and return the expected values
        System.AssertEquals(CMT_FilterRule.FilterOperation.EQUALS, CMT_FilterRuleUI_SVC.getFilterOperationFromString('Equals'));
        System.AssertEquals(CMT_FilterRuleUI_SVC.getFilterOperations().get(CMT_FilterRule.FilterOperation.EQUALS), 'Equals');

        // Validate that fields are returned for the given SObject
        System.AssertNotEquals(0, CMT_FilterRuleUI_SVC.getAvailableFields(Opportunity.SObjectType).size());
        System.AssertEquals(10, CMT_FilterRuleUI_SVC.getAvailableFields(OpportunityContactRole.SObjectType).size(),
                'There should be exactly 10 available fields for the OpportunityContactRole object\n' +
                CMT_FilterRuleUI_SVC.getAvailableFields(OpportunityContactRole.SObjectType));
    }

    /**
     * @description Validate all of the date constant comparisons to ensure that each date constant matches the
     * expected value
     */
    private static testMethod void test_DateConstantComparison() {
        System.AssertEquals(true, CMT_FilterRuleEvaluation_SVC.compareDateTypeWithConstant(SoapType.DATE, Date.Today(), 'TODAY', CMT_FilterRule.FilterOperation.EQUALS),
                'A Date comparison for TODAY should return true');
        System.AssertEquals(true, CMT_FilterRuleEvaluation_SVC.compareDateTypeWithConstant(SoapType.DATE, Date.Today().addDays(-1), 'YESTERDAY', CMT_FilterRule.FilterOperation.EQUALS),
                'A Date comparison for YESTERDAY should return true');
        System.AssertEquals(true, CMT_FilterRuleEvaluation_SVC.compareDateTypeWithConstant(SoapType.DATE, Date.Today(), 'YESTERDAY', CMT_FilterRule.FilterOperation.GREATER),
                'A Date comparison for YESTERDAY should return true');

        System.AssertEquals(false, CMT_FilterRuleEvaluation_SVC.compareDateTypeWithConstant(SoapType.DATE, Date.Today().addMonths(-1), 'TODAY', CMT_FilterRule.FilterOperation.EQUALS),
                'A Date comparison for TODAY should return false');
        System.AssertEquals(false, CMT_FilterRuleEvaluation_SVC.compareDateTypeWithConstant(SoapType.DATE, Date.Today().addDays(-3), 'YESTERDAY', CMT_FilterRule.FilterOperation.EQUALS),
                'A Date comparison for YESTERDAY should return false');

        System.AssertEquals(true, CMT_FilterRuleEvaluation_SVC.compareDateTypeWithConstant(SoapType.DATE, Date.Today(), 'THIS_WEEK', CMT_FilterRule.FilterOperation.EQUALS),
                'A Date comparison for THIS_WEEK should return true');
        System.AssertEquals(true, CMT_FilterRuleEvaluation_SVC.compareDateTypeWithConstant(SoapType.DATE, Date.Today().toStartOfWeek().addDays(-1), 'LAST_WEEK', CMT_FilterRule.FilterOperation.EQUALS),
                'A Date comparison for LAST_WEEK should return true');
        System.AssertEquals(true, CMT_FilterRuleEvaluation_SVC.compareDateTypeWithConstant(SoapType.DATE, Date.Today().addMonths(1), 'THIS_WEEK', CMT_FilterRule.FilterOperation.GREATER),
                'A Date comparison for THIS_WEEK should return true');
        System.AssertEquals(true, CMT_FilterRuleEvaluation_SVC.compareDateTypeWithConstant(SoapType.DATE, Date.Today().addMonths(-1), 'LAST_WEEK', CMT_FilterRule.FilterOperation.LESS),
                'A Date comparison for LAST_WEEK should return true');

        System.AssertEquals(true, CMT_FilterRuleEvaluation_SVC.compareDateTypeWithConstant(SoapType.DATE, Date.Today(), 'THIS_MONTH', CMT_FilterRule.FilterOperation.EQUALS),
                'A Date comparison for THIS_MONTH should return true');
        System.AssertEquals(true, CMT_FilterRuleEvaluation_SVC.compareDateTypeWithConstant(SoapType.DATE, Date.Today().addMonths(-1), 'LAST_MONTH', CMT_FilterRule.FilterOperation.EQUALS),
                'A Date comparison for LAST_MONTH should return true');
        System.AssertEquals(true, CMT_FilterRuleEvaluation_SVC.compareDateTypeWithConstant(SoapType.DATE, Date.Today().addMonths(-2), 'TWO_MONTHS_AGO', CMT_FilterRule.FilterOperation.EQUALS),
                'A Date comparison for TWO_MONTHS_AGO should return true');

        System.AssertEquals(true, CMT_FilterRuleEvaluation_SVC.compareDateTypeWithConstant(SoapType.DATE, Date.Today(), 'THIS_YEAR', CMT_FilterRule.FilterOperation.EQUALS),
                'A Date comparison for THIS_YEAR should return true');
        System.AssertEquals(true, CMT_FilterRuleEvaluation_SVC.compareDateTypeWithConstant(SoapType.DATE, Date.Today().addYears(-1), 'LAST_YEAR', CMT_FilterRule.FilterOperation.EQUALS),
                'A Date comparison for LAST_YEAR should return true');
        System.AssertEquals(true, CMT_FilterRuleEvaluation_SVC.compareDateTypeWithConstant(SoapType.DATE, Date.Today(), 'LAST_YEAR', CMT_FilterRule.FilterOperation.GREATER_OR_EQUAL),
                'A Date comparison for LAST_YEAR should return true');
        System.AssertEquals(true, CMT_FilterRuleEvaluation_SVC.compareDateTypeWithConstant(SoapType.DATETIME, DateTime.Now().addYears(-2), 'TWO_YEARS_AGO', CMT_FilterRule.FilterOperation.EQUALS),
                'A DateTime comparison for TWO_YEARS_AGO should return true');
    }

    /**
     * @description Validates constructor can handle when Constant__c is a string for instead of Id for RecordTypeId
     */
    private static testMethod void constructorShouldHandleRecordTypeDeveloperName() {
        String filterRulesJSON =
            CMT_UnitTestData_TEST.createFilterRuleRecord(null, null, 'TestRule1', 'Opportunity', 'RecordTypeId', 'In_List', 'Membership');

        Filter_Rule__mdt ruleMetadata = (Filter_Rule__mdt)JSON.deserialize(filterRulesJSON, Filter_Rule__mdt.class);

        CMT_FilterRule filterRule = new CMT_FilterRule(ruleMetadata);

        System.assert(filterRule.compare instanceOf CMT_FilterRule.CompareStrings, 'The filter should have the correct compare type');
    }

    /**
     * @description Validates constructor can handle when Constant__c is in a date format for instead of datetime for
     * a datetime field
     */
    private static testMethod void constructorShouldHandleDateTimesStoredAsDates() {
        String filterRulesJSON =
            CMT_UnitTestData_TEST.createFilterRuleRecord(null, null, 'TestRule1', 'Opportunity', 'CreatedDate', 'Greater', '2018-01-01');

        Filter_Rule__mdt ruleMetadata = (Filter_Rule__mdt)JSON.deserialize(filterRulesJSON, Filter_Rule__mdt.class);
        CMT_FilterRule filterRule = new CMT_FilterRule(ruleMetadata);

        System.assert(filterRule.compare instanceOf CMT_FilterRule.CompareDates, 'The filter should have the correct compare type');
    }

    /**
     * @description Validates constructor can handle when Constant__c is null for a record type ID
     */
    private static testMethod void constructorShouldHandleNullRecordTypeIds() {
        String filterRulesJSON =
            CMT_UnitTestData_TEST.createFilterRuleRecord(null, null, 'TestRule1', 'Opportunity', 'RecordTypeId', 'In_List', null);

        Filter_Rule__mdt ruleMetadata = (Filter_Rule__mdt)JSON.deserialize(filterRulesJSON, Filter_Rule__mdt.class);
        //need to null out Constant__c since null is cast as a string
        ruleMetadata.Constant__c = null;

        CMT_FilterRule filterRule = new CMT_FilterRule(ruleMetadata);

        System.assert(filterRule.compare instanceOf CMT_FilterRule.CompareIds, 'The filter should have the correct compare type');
    }

    /**
     * @description Validates constructor can handle when Constant__c is null for a datetime
     */
    private static testMethod void constructorShouldHandleNullDates() {
        String filterRulesJSON =
            CMT_UnitTestData_TEST.createFilterRuleRecord(null, null, 'TestRule1', 'Opportunity', 'CreatedDate', 'Greater', null);

        Filter_Rule__mdt ruleMetadata = (Filter_Rule__mdt)JSON.deserialize(filterRulesJSON, Filter_Rule__mdt.class);
        //need to null out Constant__c since null is cast as a string
        ruleMetadata.Constant__c = null;

        CMT_FilterRule filterRule = new CMT_FilterRule(ruleMetadata);

        System.assert(filterRule.compare instanceOf CMT_FilterRule.CompareDateTimes, 'The filter should have the correct compare type');
    }

    /**
     * @description Validates isIncluded handles null IDs
     */
    private static testMethod void isIncludedShouldHandleNullIds() {
        String filterRulesJSON = '[' +
            CMT_UnitTestData_TEST.createFilterRuleRecord(null, null, 'TestRule1', 'Opportunity', 'RecordTypeId', 'In_List', null) + ',' +
            CMT_UnitTestData_TEST.createFilterRuleRecord(null, null, 'TestRule2', 'Opportunity', 'RecordTypeId', 'Not_In_List', null) + ',' +
            CMT_UnitTestData_TEST.createFilterRuleRecord(null, null, 'TestRule3', 'Opportunity', 'RecordTypeId', 'Equals', null) + ',' +
            CMT_UnitTestData_TEST.createFilterRuleRecord(null, null, 'TestRule4', 'Opportunity', 'RecordTypeId', 'Not_Equals', null) +
        ']';

        List<Filter_Rule__mdt> rulesMetadata = (List<Filter_Rule__mdt>)JSON.deserialize(
            filterRulesJSON, List<Filter_Rule__mdt>.class);

        for (Filter_Rule__mdt rule : rulesMetadata) {
            //need to null out Constant__c since null is cast as a string
            rule.Constant__c = null;
        }

        Opportunity oppToCompare = new Opportunity(RecordTypeId = UTIL_UnitTestData_TEST.mockId(RecordType.getSObjectType()));

        CMT_FilterRule inListRule = new CMT_FilterRule(rulesMetadata[0]);
        System.assertEquals(false, inListRule.isIncluded(oppToCompare),
            'The in list rule should evaluate to false for a null Id in the rule');

        CMT_FilterRule notInListRule = new CMT_FilterRule(rulesMetadata[1]);
        System.assertEquals(true, notInListRule.isIncluded(oppToCompare),
            'The not in list rule should evaluate to true for a null Id in the rule');

        CMT_FilterRule equalsRule = new CMT_FilterRule(rulesMetadata[2]);
        System.assertEquals(false, equalsRule.isIncluded(oppToCompare),
            'The equals rule should evaluate to false for a null Id in the rule');

        CMT_FilterRule notEqualsRule = new CMT_FilterRule(rulesMetadata[3]);
        System.assertEquals(true, notEqualsRule.isIncluded(oppToCompare),
            'The not equals rule should evaluate to true for a null Id in the rule');
    }
}