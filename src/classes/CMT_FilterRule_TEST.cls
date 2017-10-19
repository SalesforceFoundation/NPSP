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
* @group Custom Metadata Types
* @description Tests for CMT Filter Rule related actions
*/
@isTest
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
                CMT_UnitTestData_TEST.createFilterRuleRecord(null, filterGroupId, 'TestRule4', 'OpportunityContactRole', 'Role', 'Equals', 'Solicitor') +
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
    static testMethod void test_FilterRule_Selectors() {

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

        System.AssertEquals(1, CMT_FilterRule_SEL.getReferencedFieldsByObject(OpportunityContactRole.SObjectType).size(),
                'There should be at least one referenced field for the OpportunityContactRole object in Filter_Rule__mdt');

    }

    /**
     * @description Test various User Interface methods in the UI Service class
     */
    static testMethod void test_OperationMethods() {
        mockFilterCMTValues();

        test.startTest();

        // Validate that the operation supporting methods retrieve and return the expected values
        System.AssertEquals(CMT_FilterRule.FilterOperation.EQUALS, CMT_FilterRuleUI_SVC.getFilterOperationFromString('Equals'));
        System.AssertEquals(CMT_FilterRuleUI_SVC.getFilterOperations().get(CMT_FilterRule.FilterOperation.EQUALS), 'Equals');

        // Validate the available filter operations based on specific field types
        System.AssertEquals(6, CMT_FilterRuleUI_SVC.getAvailableOperations('Opportunity', 'CloseDate').size(),
                'There should be six valid operations for a Date field');
        System.AssertEquals(6, CMT_FilterRuleUI_SVC.getAvailableOperations('Opportunity', 'Amount').size(),
                'There should be six valid operations for a Numeric field');
        System.AssertEquals(2, CMT_FilterRuleUI_SVC.getAvailableOperations('Opportunity', 'AccountId').size(),
                'There should be two valid operations for an Id field');
        System.AssertEquals(2, CMT_FilterRuleUI_SVC.getAvailableOperations('Opportunity', 'IsWon').size(),
                'There should be two valid operations for a Boolean field');
        System.AssertEquals(5, CMT_FilterRuleUI_SVC.getAvailableOperations('Opportunity', 'NextStep').size(),
                'There should be five valid operations for a Text field');
        System.AssertEquals(5, CMT_FilterRuleUI_SVC.getAvailableOperations('Opportunity', 'StageName').size(),
                'There should be five valid operations for a picklist field');

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
    static testMethod void test_DateConstantComparison() {
        System.AssertEquals(true, CMT_FilterRule.compareDateTypeWithConstant(SoapType.DATE, Date.Today(), 'TODAY', CMT_FilterRule.FilterOperation.EQUALS),
                'A Date comparison for TODAY should return true');
        System.AssertEquals(true, CMT_FilterRule.compareDateTypeWithConstant(SoapType.DATE, Date.Today().addDays(-1), 'YESTERDAY', CMT_FilterRule.FilterOperation.EQUALS),
                'A Date comparison for YESTERDAY should return true');
        System.AssertEquals(true, CMT_FilterRule.compareDateTypeWithConstant(SoapType.DATE, Date.Today(), 'YESTERDAY', CMT_FilterRule.FilterOperation.GREATER),
                'A Date comparison for YESTERDAY should return true');

        System.AssertEquals(false, CMT_FilterRule.compareDateTypeWithConstant(SoapType.DATE, Date.Today().addMonths(-1), 'TODAY', CMT_FilterRule.FilterOperation.EQUALS),
                'A Date comparison for TODAY should return false');
        System.AssertEquals(false, CMT_FilterRule.compareDateTypeWithConstant(SoapType.DATE, Date.Today().addDays(-3), 'YESTERDAY', CMT_FilterRule.FilterOperation.EQUALS),
                'A Date comparison for YESTERDAY should return false');

        System.AssertEquals(true, CMT_FilterRule.compareDateTypeWithConstant(SoapType.DATE, Date.Today(), 'THIS_WEEK', CMT_FilterRule.FilterOperation.EQUALS),
                'A Date comparison for THIS_WEEK should return true');
        System.AssertEquals(true, CMT_FilterRule.compareDateTypeWithConstant(SoapType.DATE, Date.Today().toStartOfWeek().addDays(-1), 'LAST_WEEK', CMT_FilterRule.FilterOperation.EQUALS),
                'A Date comparison for LAST_WEEK should return true');
        System.AssertEquals(true, CMT_FilterRule.compareDateTypeWithConstant(SoapType.DATE, Date.Today().addMonths(1), 'THIS_WEEK', CMT_FilterRule.FilterOperation.GREATER),
                'A Date comparison for THIS_WEEK should return true');
        System.AssertEquals(true, CMT_FilterRule.compareDateTypeWithConstant(SoapType.DATE, Date.Today().addMonths(-1), 'LAST_WEEK', CMT_FilterRule.FilterOperation.LESS),
                'A Date comparison for LAST_WEEK should return true');

        System.AssertEquals(true, CMT_FilterRule.compareDateTypeWithConstant(SoapType.DATE, Date.Today(), 'THIS_MONTH', CMT_FilterRule.FilterOperation.EQUALS),
                'A Date comparison for THIS_MONTH should return true');
        System.AssertEquals(true, CMT_FilterRule.compareDateTypeWithConstant(SoapType.DATE, Date.Today().addMonths(-1), 'LAST_MONTH', CMT_FilterRule.FilterOperation.EQUALS),
                'A Date comparison for LAST_MONTH should return true');
        System.AssertEquals(true, CMT_FilterRule.compareDateTypeWithConstant(SoapType.DATE, Date.Today().addMonths(-2), 'TWO_MONTHS_AGO', CMT_FilterRule.FilterOperation.EQUALS),
                'A Date comparison for TWO_MONTHS_AGO should return true');

        System.AssertEquals(true, CMT_FilterRule.compareDateTypeWithConstant(SoapType.DATE, Date.Today(), 'THIS_YEAR', CMT_FilterRule.FilterOperation.EQUALS),
                'A Date comparison for THIS_YEAR should return true');
        System.AssertEquals(true, CMT_FilterRule.compareDateTypeWithConstant(SoapType.DATE, Date.Today().addYears(-1), 'LAST_YEAR', CMT_FilterRule.FilterOperation.EQUALS),
                'A Date comparison for LAST_YEAR should return true');
        System.AssertEquals(true, CMT_FilterRule.compareDateTypeWithConstant(SoapType.DATE, Date.Today(), 'LAST_YEAR', CMT_FilterRule.FilterOperation.GREATER_OR_EQUAL),
                'A Date comparison for LAST_YEAR should return true');
        System.AssertEquals(true, CMT_FilterRule.compareDateTypeWithConstant(SoapType.DATETIME, DateTime.Now().addYears(-2), 'TWO_YEARS_AGO', CMT_FilterRule.FilterOperation.EQUALS),
                'A DateTime comparison for TWO_YEARS_AGO should return true');
    }

    /**
     * @description Validate the method that validates Filter Field+Operation+Value combinations that may be entered
     * by the User in the Rollups UI
     */
    static testMethod void test_ValidateFilterOperations() {

        System.AssertEquals(true, CMT_FilterRuleUI_SVC.validateFilterValue(Opportunity.CloseDate, CMT_FilterRule.FilterOperation.EQUALS, null),
            'A null value should be valid for a Date field Equals operation');
        System.AssertEquals(false, CMT_FilterRuleUI_SVC.validateFilterValue(Opportunity.CloseDate, CMT_FilterRule.FilterOperation.GREATER, null),
            'A null value should be invalid for a Date field Greater operation');

        String strValue = 'String Value';
        String dtValue = DateTime.now().format('YYYY-MM-dd');
        String dttmValue = DateTime.now().format('YYYY-MM-dd hh:mm:ss');
        String boolValue = 'true';
        String numValue = '100.23';
        String badValue = 'XYX';
        String validId = UTIL_RecordTypes.getRecordTypeIdForGiftsTests(Opportunity.SObjectType);

        // Date field tests
        System.AssertEquals(false, CMT_FilterRuleUI_SVC.validateFilterValue(Opportunity.CloseDate, CMT_FilterRule.FilterOperation.EQUALS, badValue),
            'A bad string value should be invalid for a Date field Equals operation');
        System.AssertEquals(true, CMT_FilterRuleUI_SVC.validateFilterValue(Opportunity.CloseDate, CMT_FilterRule.FilterOperation.LESS, dtValue),
            'A date string value should be valid for a Date field Less operation');
        System.AssertEquals(true, CMT_FilterRuleUI_SVC.validateFilterValue(Opportunity.CloseDate, CMT_FilterRule.FilterOperation.LESS, 'TODAY'),
            'A date constant value should be valid for a Date field Less operation');
        System.AssertEquals(false, CMT_FilterRuleUI_SVC.validateFilterValue(Opportunity.CloseDate, CMT_FilterRule.FilterOperation.GREATER, null),
                'A null constant value should be invalid for a Date field Greaeter operation');

        // DateTime field tests
        System.AssertEquals(false, CMT_FilterRuleUI_SVC.validateFilterValue(Opportunity.CreatedDate, CMT_FilterRule.FilterOperation.EQUALS, badValue),
                'A bad string value should be invalid for a DateTime field Equals operation');
        System.AssertEquals(true, CMT_FilterRuleUI_SVC.validateFilterValue(Opportunity.CreatedDate, CMT_FilterRule.FilterOperation.LESS, dtValue),
                'A date string value should be valid for a DateTime field Less operation');
        System.AssertEquals(true, CMT_FilterRuleUI_SVC.validateFilterValue(Opportunity.CreatedDate, CMT_FilterRule.FilterOperation.LESS, dttmValue),
                'A datetime string value should be valid for a DateTime field Less operation');
        System.AssertEquals(true, CMT_FilterRuleUI_SVC.validateFilterValue(Opportunity.CreatedDate, CMT_FilterRule.FilterOperation.LESS, 'TODAY'),
                'A date constant value should be valid for a DateTime field Less operation');

        // Boolean field tests
        System.AssertEquals(false, CMT_FilterRuleUI_SVC.validateFilterValue(Opportunity.IsWon, CMT_FilterRule.FilterOperation.EQUALS, badValue),
                'A bad string value should be invalid for a Boolean field Equals operation');
        System.AssertEquals(true, CMT_FilterRuleUI_SVC.validateFilterValue(Opportunity.IsWon, CMT_FilterRule.FilterOperation.EQUALS, boolValue),
                'A boolean string value should be valid for a Boolean field Equals operation');

        // Number field tests
        System.AssertEquals(false, CMT_FilterRuleUI_SVC.validateFilterValue(Opportunity.Amount, CMT_FilterRule.FilterOperation.EQUALS, badValue),
                'A bad string value should be invalid for a Number field Equals operation');
        System.AssertEquals(true, CMT_FilterRuleUI_SVC.validateFilterValue(Opportunity.Amount, CMT_FilterRule.FilterOperation.LESS, numValue),
                'A number string value should be valid for a Number field Less operation');

        // Id field tests
        System.AssertEquals(false, CMT_FilterRuleUI_SVC.validateFilterValue(Opportunity.AccountId, CMT_FilterRule.FilterOperation.EQUALS, badValue),
                'A bad string value should be invalid for an Id field Equals operation');
        System.AssertEquals(true, CMT_FilterRuleUI_SVC.validateFilterValue(Opportunity.AccountId, CMT_FilterRule.FilterOperation.EQUALS, validId),
                'An Id string value should be valid for a Id field Less operation');

    }
}