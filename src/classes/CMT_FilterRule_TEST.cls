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
* @description Selector class for FilterGroups and FilterRule Custom Metadata Type objects
*/
@isTest
private class CMT_FilterRule_TEST {

    /**
     * @description Because unit tests cannot actually insert Custom Metadata Types and there's no real way to know
     * exactly what's in the CMT objects, we can use this method to mock the contents of the cached MDT queries
     * for the unit tests
     */
    private static void mockFilterCMTValues() {
        CMT_FilterRule_SEL.cachedFilterGroups = (List<Filter_Group__mdt>)JSON.deserialize(
                '[{"attributes":{"type":"Filter_Group__mdt"},' +
                '"Id":"000000000000000BBB","MasterLabel":"TEST",' +
                '"DeveloperName":"TEST","Is_Deleted__c":false}]', List<Filter_Group__mdt>.class);

        CMT_FilterRule_SEL.cachedFilterRules = (List<Filter_Rule__mdt>)JSON.deserialize('[' +
                '{"attributes":{"type":"Filter_Rule__mdt"},' +
                '"Id":"000000000000000CCC","MasterLabel":"Rule 2","DeveloperName":"Rule_2","Filter_Group__c":"000000000000000BBB",' +
                '"Field__c":"Opportunity.IsWon","Object__c":"Opportunity","Operator__c":"Equals","Constant__c":"TRUE","Is_Deleted__c":false,' +
                '"Field__r":{"attributes":{"type":"FieldDefinition","url":"/services/data/v41.0/sobjects/FieldDefinition/Opportunity.IsWon"},' +
                '"Id":"000000000000000AAA","DurableId":"Opportunity.IsWon","QualifiedApiName":"IsWon"},"Object__r":{"attributes":{"type":"EntityDefinition","url":"/services/data/v41.0/sobjects/EntityDefinition/Opportunity"},' +
                '"Id":"000000000000000AAA","DurableId":"Opportunity","QualifiedApiName":"Opportunity"}},' +
                '{"attributes":{"type":"Filter_Rule__mdt"},' +
                '"Id":"000000000000000DDD","MasterLabel":"Rule 3","DeveloperName":"Rule_3","Filter_Group__c":"000000000000000BBB",' +
                '"Field__c":"Opportunity.CloseDate","Object__c":"Opportunity","Operator__c":"Equals","Constant__c":"THIS_YEAR","Is_Deleted__c":false,' +
                '"Field__r":{"attributes":{"type":"FieldDefinition","url":"/services/data/v41.0/sobjects/FieldDefinition/Opportunity.CloseDate"},' +
                '"Id":"000000000000000AAA","DurableId":"Opportunity.CloseDate","QualifiedApiName":"CloseDate"},"Object__r":{"attributes":{"type":"EntityDefinition","url":"/services/data/v41.0/sobjects/EntityDefinition/Opportunity"},' +
                '"Id":"000000000000000AAA","DurableId":"Opportunity","QualifiedApiName":"Opportunity"}},' +
                '{"attributes":{"type":"Filter_Rule__mdt"},' +
                '"Id":"000000000000000EEE","MasterLabel":"Rule 1","DeveloperName":"Rule_1","Filter_Group__c":"000000000000000BBB",' +
                '"Field__c":"Opportunity.IsClosed","Object__c":"Opportunity","Operator__c":"Equals","Constant__c":"TRUE","Is_Deleted__c":false,' +
                '"Field__r":{"attributes":{"type":"FieldDefinition","url":"/services/data/v41.0/sobjects/FieldDefinition/Opportunity.IsClosed"},' +
                '"Id":"000000000000000AAA","DurableId":"Opportunity.IsClosed","QualifiedApiName":"IsClosed"},"Object__r":{"attributes":{"type":"EntityDefinition","url":"/services/data/v41.0/sobjects/EntityDefinition/Opportunity"},' +
                '"Id":"000000000000000AAA","DurableId":"Opportunity","QualifiedApiName":"Opportunity"}}]', List<Filter_Rule__mdt>.class);
    }

    /**
     * @description Test the FilterGroup and FilterRule selector methods. Relies on hardcoded JSON deserialized
     * MDT data for these tests.
     */
    static testMethod void test_CMT_Selectors() {

        mockFilterCMTValues();

        System.AssertEquals(1, CMT_FilterRule_SEL.getFilterGroupsById().size(), 'There should be one Filter Group');

        Map<Id, List<Filter_Rule__mdt>> filterRulesByGroup = CMT_FilterRule_SEL.getFilterRulesByGroup();
        Id filterGroupId = (new List<Id>(filterRulesByGroup.keySet()))[0];
        List<Filter_Rule__mdt> filterRules =  filterRulesByGroup.get(filterGroupId);
        System.AssertEquals(1, filterRulesByGroup.size(), 'There should be one Filter Group');
        System.AssertEquals(3, filterRules.size(), 'There should be three Filter Rules in the Filter Group');

        // Test that a list of fields to query is returned
        String objName = CMT_FilterRule_SEL.cachedFilterRules[0].Object__c;
        String queryFields = CMT_FilterRule_SEL.getReferencedFieldsByObjectAsString(Schema.getGlobalDescribe().get(objName));
        System.Assert(String.isNotEmpty(queryFields),
            'There should be at least one referenced field for the ' + objName + ' object in Filter_Rule__mdt');

        // Test that a query can be built and executed, though it's likely there will be zero rows returned
        // so don't attempt to validate the result.
        String soql = 'SELECT Id,' + queryFields + ' FROM ' + objName + ' LIMIT 1';
        List<SObject> test = database.query(soql);
    }
}