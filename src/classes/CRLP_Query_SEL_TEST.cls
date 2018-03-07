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
    static testMethod void test_ResultsQueryBuilder() {
        // Create mock instances of the CMT objects to use for the tests
        CRLP_Rollup_SEL_TEST.mockRollupCMTValues();

        Test.startTest();

        String soql = CRLP_Query_SEL.buildObjectQueryForRollup(Opportunity.SObjectType);
        List<Opportunity> opps = database.query(soql);
        System.AssertEquals(0, opps.size(), 'There should be no results, but the query should work');

        soql = CRLP_Query_SEL.buildObjectQueryForRollup(Account.SObjectType);
        List<Account> accts = database.query(soql);
        System.AssertEquals(0, accts.size(), 'There should be no results, but the query should work');

        soql = CRLP_Query_SEL.buildDetailObjectQueryForRollup(Opportunity.SObjectType, new List<SObjectType>{
                npe01__OppPayment__c.SObjectType, Allocation__c.SObjectType, OpportunityContactRole.SObjectType});
        List<Opportunity> opps2 = database.query(soql);
        System.AssertEquals(0, opps2.size(), 'There should be no results, but the query should work');

        soql = CRLP_Query_SEL.buildDetailObjectQueryForRollup(Allocation__c.SObjectType, new List<SObjectType>());
        List<Allocation__c> allocs = database.query(soql);
        System.AssertEquals(0, allocs.size(), 'There should be no results, but the query should work');

        soql = CRLP_Query_SEL.buildDetailObjectQueryForRollup(OpportunityContactRole.SObjectType, new List<SObjectType>());
        List<OpportunityContactRole> ocrs = database.query(soql);
        System.AssertEquals(0, ocrs.size(), 'There should be no results, but the query should work');

        soql = CRLP_Query_SEL.buildDetailObjectQueryForRollup(Opportunity.SObjectType, new List<SObjectType>{
                Partial_Soft_Credit__c.SObjectType});
        opps = database.query(soql);
        System.AssertEquals(0, ocrs.size(), 'There should be no results, but the query should work');

    }

}