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
* @group Selectors
* @description Unit Test for the Rollup Definition Custom Metadata Type object selector
*/
@isTest
private class RLLP_Rollup_SEL_TEST {

    /**
     * @description Because unit tests cannot actually insert Custom Metadata Types and there's no real way to know
     * exactly what's in the CMT objects, we can use this method to mock the contents of the cached MDT queries
     * for the unit tests
     */
    private static void mockRollupCMTValues() {

        // Create a single Rollup
        RLLP_Rollup_SEL.cachedRollups = (List<Rollup__mdt>)JSON.deserialize('[' +
                    '{"attributes":{"type":"Rollup__mdt"},' +
                    '"Id":"000000000000000C01","DeveloperName":"Household_Total_Donations_AllTime",' +
                    '"MasterLabel":"Total Opportunity Value to Household","Active__c":true,' +
                    '"Description__c":"Total Opportunity Value to Household",' +
                    '"Filter_Group__c":"000000000000000A01","Operation__c":"Sum","Amount_Field__c":"Opportunity.Amount",' +
                    '"Amount_Object__c":"Opportunity","Date_Field__c":"Opportunity.CloseDate",' +
                    '"Date_Object__c":"Opportunity","Detail_Field__c":"Opportunity.AccountId","Detail_Object__c":"Opportunity",' +
                    '"Summary_Field__c":"Account.AnnualRevenue","Summary_Object__c":"Account",' +
                    '"Filter_Group__r":{"attributes":{"type":"Filter_Group__mdt","url":"/services/data/v41.0/sobjects/Filter_Group__mdt/000000000000000A01"},' +
                    '"Id":"000000000000000A01","MasterLabel":"ClosedWonOpportunities"},' +
                    '"Amount_Field__r":{"attributes":{"type":"FieldDefinition","url":"/services/data/v41.0/sobjects/FieldDefinition/Opportunity.Amount"},' +
                    '"Id":"000000000000000AAA","DurableId":"Opportunity.Amount","QualifiedApiName":"Amount"},' +
                    '"Amount_Object__r":{"attributes":{"type":"EntityDefinition","url":"/services/data/v41.0/sobjects/EntityDefinition/Opportunity"},' +
                    '"Id":"000000000000000AAA","DurableId":"Opportunity","QualifiedApiName":"Opportunity"},' +
                    '"Date_Field__r":{"attributes":{"type":"FieldDefinition","url":"/services/data/v41.0/sobjects/FieldDefinition/Opportunity.CloseDate"},' +
                    '"Id":"000000000000000AAA","DurableId":"Opportunity.CloseDate","QualifiedApiName":"CloseDate"},' +
                    '"Date_Object__r":{"attributes":{"type":"EntityDefinition","url":"/services/data/v41.0/sobjects/EntityDefinition/Opportunity"},' +
                    '"Id":"000000000000000AAA","DurableId":"Opportunity","QualifiedApiName":"Opportunity"},' +
                    '"Detail_Field__r":{"attributes":{"type":"FieldDefinition","url":"/services/data/v41.0/sobjects/FieldDefinition/Opportunity.Amount"},' +
                    '"Id":"000000000000000AAA","DurableId":"Opportunity.AccountId","QualifiedApiName":"AccountId"},' +
                    '"Detail_Object__r":{"attributes":{"type":"EntityDefinition","url":"/services/data/v41.0/sobjects/EntityDefinition/Opportunity"},' +
                    '"Id":"000000000000000AAA","DurableId":"Opportunity","QualifiedApiName":"Opportunity"},' +
                    '"Summary_Field__r":{"attributes":{"type":"FieldDefinition","url":"/services/data/v41.0/sobjects/FieldDefinition/Account.AnnualRevenue"},' +
                    '"Id":"000000000000000AAA","DurableId":"Account.AnnualRevenue","QualifiedApiName":"AnnualRevenue"},' +
                    '"Summary_Object__r":{"attributes":{"type":"EntityDefinition","url":"/services/data/v41.0/sobjects/EntityDefinition/Account"},' +
                    '"Id":"000000000000000AAA","DurableId":"Account","QualifiedApiName":"Account"}}' +
                ']', List<Rollup__mdt>.class);

        // Create a single Filter Group
        CMT_FilterRule_SEL.cachedFilterGroups = (List<Filter_Group__mdt>)JSON.deserialize(
                    '[{"attributes":{"type":"Filter_Group__mdt"},"Id":"000000000000000A01",' +
                    '"MasterLabel":"ClosedWonOpportunities",' +
                    '"DeveloperName":"ClosedWonOpportunities",' +
                    '"Is_Deleted__c":false}]', List<Filter_Group__mdt>.class);

        // Create 2 Filter Rules for the above Filter Group
        CMT_FilterRule_SEL.cachedFilterRules = (List<Filter_Rule__mdt>)JSON.deserialize('[' +
                '{"attributes":{"type":"Filter_Rule__mdt"},"Id":"000000000000000B01","MasterLabel":"ClosedWon-Rule-1",' +
                    '"DeveloperName":"ClosedWon_Rule_1","Filter_Group__c":"000000000000000A01",' +
                    '"Field__c":"Opportunity.IsWon","Object__c":"Opportunity","Operator__c":"Equals","Constant__c":"True",' +
                    '"Is_Deleted__c":false,"Field__r":{"attributes":{"type":"FieldDefinition","url":"/services/data/v41.0/sobjects/FieldDefinition/Opportunity.IsWon"},' +
                    '"Id":"000000000000000AAA","DurableId":"Opportunity.IsWon","QualifiedApiName":"IsWon"},' +
                    '"Object__r":{"attributes":{"type":"EntityDefinition","url":"/services/data/v41.0/sobjects/EntityDefinition/Opportunity"},' +
                    '"Id":"000000000000000AAA","DurableId":"Opportunity","QualifiedApiName":"Opportunity"}},' +
                '{"attributes":{"type":"Filter_Rule__mdt"},"Id":"000000000000000B02","MasterLabel":"ClosedWon-Rule-2",' +
                    '"DeveloperName":"ClosedWon_Rule_2","Filter_Group__c":"000000000000000A01",' +
                    '"Field__c":"Opportunity.IsClosed","Object__c":"Opportunity","Operator__c":"Equals","Constant__c":"True",' +
                    '"Is_Deleted__c":false,"Field__r":{"attributes":{"type":"FieldDefinition","url":"/services/data/v41.0/sobjects/FieldDefinition/Opportunity.IsClosed"},' +
                    '"Id":"000000000000000AAA","DurableId":"Opportunity.IsClosed","QualifiedApiName":"IsClosed"},' +
                    '"Object__r":{"attributes":{"type":"EntityDefinition","url":"/services/data/v41.0/sobjects/EntityDefinition/Opportunity"},' +
                    '"Id":"000000000000000AAA","DurableId":"Opportunity","QualifiedApiName":"Opportunity"}}' +
                ']', List<Filter_Rule__mdt>.class);
    }

    /**
     * @description Test the Rollup selector methods. Relies on hardcoded JSON deserialized
     * MDT data for these tests.
     */
    static testMethod void test_CMT_Selectors() {

        mockRollupCMTValues();

        System.AssertEquals(1, RLLP_Rollup_SEL.getRollupDefinitions().size(), 'There should be 1 rollup definition');

        System.AssertEquals(1, RLLP_Rollup_SEL.getRollupsByDetailType().get(Opportunity.SObjectType).size(),
                'There should be 1 rollup for the Opportunity detail object');
        System.AssertEquals(1, RLLP_Rollup_SEL.getRollupsBySummaryType().get(Account.SObjectType).size(),
                'There should be 1 rollup for the Account summary object');
        System.AssertEquals(1, RLLP_Rollup_SEL.getRollupsByFilterGroup().size(),
                'There should be 1 filter group that has rollups');

        System.AssertEquals(3, RLLP_Rollup_SEL.getReferencedFieldsByObject(Opportunity.SObjectType).size(),
                'There should be 3 Opportunity fields referenced across the rollup');

        // Test that a list of fields to query is returned
        String queryFields = RLLP_Rollup_SEL.getReferencedFieldsByObjectAsString(Opportunity.SObjectType);
        System.Assert(String.isNotEmpty(queryFields),
                'There should be at least one referenced field for the Opportunity object in Rollup__mdt');

        // Test that a query can be built and executed, though it's likely there will be zero rows returned
        // so don't attempt to validate the result.
        String soql = 'SELECT Id,' + queryFields + ' FROM Opportunity LIMIT 1';
        List<SObject> test = database.query(soql);
    }
}