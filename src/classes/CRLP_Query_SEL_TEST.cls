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
* @group Selectors
* @description Unit Test for the Rollup Results selector class
*/
@isTest(IsParallel=true)
private class CRLP_Query_SEL_TEST {

    /**
     * @description Test that the Results Query Builder returns valid SOQL statements for the Opportunity and Account
     * objects.
     */
    private static testMethod void test_ResultsQueryBuilder() {
        // Create mock instances of the CMT objects to use for the tests
        CRLP_Rollup_SEL_TEST.mockRollupCMTValues();

        Test.startTest();

        String soql = CRLP_Query_SEL.buildObjectQueryForRollup(Opportunity.SObjectType);
        List<Opportunity> opps = Database.query(soql);
        System.AssertEquals(0, opps.size(), 'There should be no results, but the query should work');

        soql = CRLP_Query_SEL.buildObjectQueryForRollup(Account.SObjectType);
        List<Account> accts = Database.query(soql);
        System.AssertEquals(0, accts.size(), 'There should be no results, but the query should work');

        soql = CRLP_Query_SEL.buildDetailObjectQueryForRollup(Opportunity.SObjectType, new List<SObjectType>{
                npe01__OppPayment__c.SObjectType, Allocation__c.SObjectType, OpportunityContactRole.SObjectType});
        List<Opportunity> opps2 = Database.query(soql);
        System.AssertEquals(0, opps2.size(), 'There should be no results, but the query should work');

        soql = CRLP_Query_SEL.buildDetailObjectQueryForRollup(Allocation__c.SObjectType, new List<SObjectType>());
        List<Allocation__c> allocs = Database.query(soql);
        System.AssertEquals(0, allocs.size(), 'There should be no results, but the query should work');

        soql = CRLP_Query_SEL.buildDetailObjectQueryForRollup(OpportunityContactRole.SObjectType, new List<SObjectType>());
        List<OpportunityContactRole> ocrs = Database.query(soql);
        System.AssertEquals(0, ocrs.size(), 'There should be no results, but the query should work');

        soql = CRLP_Query_SEL.buildDetailObjectQueryForRollup(Opportunity.SObjectType, new List<SObjectType>{
                Partial_Soft_Credit__c.SObjectType});
        opps = Database.query(soql);
        System.AssertEquals(0, ocrs.size(), 'There should be no results, but the query should work');

    }

    /**
     * @description Test that buildCommonQueryFilterOnOpportunity returns no WHERE clause when there are no rollups
     */
    private static testMethod void test_buildCommonQueryFilterOnOpportunity_NoRollups() {
        CRLP_Rollup_SEL.cachedRollups = new List<Rollup__mdt>();
        String whereClause = CRLP_Query_SEL.buildCommonQueryFilterOnOpportunity(Account.SObjectType, Opportunity.SObjectType);
        System.assert(String.isEmpty(whereClause), 'No WHERE clause should be returned when there are no rollups: ' + whereClause);
    }

    /**
     * @description Test that buildCommonQueryFilterOnOpportunity returns no WHERE clause when rollups are not
     * associated to a filter group.
     */
    private static testMethod void test_buildCommonQueryFilterOnOpportunity_NoFilterGroups() {
        CRLP_Rollup_SEL_TEST.mockRollupCMTValues();
        Id filterGroupId = CMT_FilterRule_SEL.cachedFilterGroups[0].Id;

        cacheFilterRule(filterGroupId, 'IsClosed', 'Equals', 'False');

        String whereClause = CRLP_Query_SEL.buildCommonQueryFilterOnOpportunity(Account.SObjectType, Opportunity.SObjectType);
        System.assert(!String.isEmpty(whereClause), 'A WHERE clause should be returned when there are rollups');

        for (Rollup__mdt r : CRLP_Rollup_SEL.cachedRollups) {
            r.Filter_Group__c = null;
        }

        whereClause = CRLP_Query_SEL.buildCommonQueryFilterOnOpportunity(Account.SObjectType, Opportunity.SObjectType);
        System.assert(String.isEmpty(whereClause),
            'A WHERE clause should not be returned when rollups are not associated to a filter group');
    }

    /**
     * @description Test that the buildCommonQueryFilterOnOpportunity returns valid WHERE clause in SOQL statements
     * objects.
     */
    private static testMethod void test_buildCommonQueryFilterOnOpportunity_BuildsValidWhereClause() {
        CRLP_Rollup_SEL_TEST.mockRollupCMTValues();
        Id filterGroupId = CMT_FilterRule_SEL.cachedFilterGroups[0].Id;

        List<Id> recordTypeIds = new List<Id>();
        for (RecordType rt : [SELECT Id FROM RecordType WHERE SObjectType = :String.valueOf(Opportunity.SObjectType)]) {
            recordTypeIds.add(rt.Id);
        }
        String recordTypeConstantIds = String.join(recordTypeIds,';');

        cacheFilterRule(filterGroupId, 'RecordTypeId', 'In_List', recordTypeConstantIds);
        executeQueryWithOppFilter();

        cacheFilterRule(filterGroupId, 'RecordTypeId', 'Not_In_List', recordTypeConstantIds);
        executeQueryWithOppFilter();

        cacheFilterRule(filterGroupId, 'RecordTypeId', 'Equals', recordTypeConstantIds);
        executeQueryWithOppFilter();

        cacheFilterRule(filterGroupId, 'RecordTypeId', 'Not_Equals', recordTypeConstantIds);
        executeQueryWithOppFilter();

        cacheFilterRule(filterGroupId, 'RecordTypeId', 'In_List', null);
        executeQueryWithOppFilter();

        cacheFilterRule(filterGroupId, 'RecordTypeId', 'Not_In_List', null);
        executeQueryWithOppFilter();

        cacheFilterRule(filterGroupId, 'RecordTypeId', 'Equals', null);
        executeQueryWithOppFilter();

        cacheFilterRule(filterGroupId, 'RecordTypeId', 'Not_Equals', null);
        executeQueryWithOppFilter();

        cacheFilterRule(filterGroupId, 'IsClosed', 'Equals', 'False');
        executeQueryWithOppFilter();

        cacheFilterRule(filterGroupId, 'IsClosed', 'Not_Equals', 'False');
        executeQueryWithOppFilter();

        cacheFilterRule(filterGroupId, 'IsWon', 'Equals', 'True');
        executeQueryWithOppFilter();

        cacheFilterRule(filterGroupId, 'IsWon', 'Not_Equals', 'True');
        executeQueryWithOppFilter();
    }

    /**
     * @description Builds filter rule and executes SOQL query using buildCommonQueryFilterOnOpportunity results
     */
    private static void executeQueryWithOppFilter() {
        String soql = 'SELECT Id FROM Opportunity WHERE ';
        try {
            soql += CRLP_Query_SEL.buildCommonQueryFilterOnOpportunity(Account.SObjectType, Opportunity.SObjectType);
            Database.query(soql);

        } catch (QueryException ex) {
            System.assert(false, 'The query is invalid: ' + soql + '\n' + ex.getStackTraceString());
        }
    }

    /**
     * @description Replaces the filter rule cache with a filter rule for the given filter group
     */
    private static void cacheFilterRule(Id filterGroupId, String field, String operator, String constant) {
         String filterRulesJSON = '[' +
            CMT_UnitTestData_TEST.createFilterRuleRecord(
                null,
                filterGroupId,
                'TestRule',
                'Opportunity',
                'RecordTypeId',
                operator,
                constant
            ) +
        ']';

        List<Filter_Rule__mdt> rulesMetadata =
            (List<Filter_Rule__mdt>) JSON.deserialize(filterRulesJSON, List<Filter_Rule__mdt>.class);

        if (constant == null) {
            for (Filter_Rule__mdt rule : rulesMetadata) {
                //need to null out Constant__c since null is cast as a string
                rule.Constant__c = null;
            }
        }

        CMT_FilterRule_SEL.cachedFilterRules = rulesMetadata;
    }
}