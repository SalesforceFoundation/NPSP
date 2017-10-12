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
     * @description It's not possible to create custom metadata type records through a Unit Test, so
     * these tests will only run if there are actually records in the objects in the org.
     */
    static testMethod void test_CMT_Selectors() {
        // If there are no CMT Filter Groups, just exit out.
        if (CMT_FilterRule_SEL.cachedFilterGroups.size() == 0) {
            return;
        }

        System.AssertNotEquals(0, CMT_FilterRule_SEL.filterRulesByGroup().size(),
            'There should be at least one Filter Group');
        System.AssertNotEquals(0, CMT_FilterRule_SEL.filterGroupsById().size(),
            'There should be at least one Filter Group');

        // Test that a list of fields to query is returned
        String objName = CMT_FilterRule_SEL.cachedFilterRules[0].Object__c;
        String queryFields = CMT_FilterRule_SEL.getReferencedFieldByObjectAsString(Schema.getGlobalDescribe().get(objName));
        System.Assert(String.isNotEmpty(queryFields),
            'There should be at least one referenced field for the ' + objName + ' object in Filter_Rule__mdt');

        // Test that a query can be built and executed, though it's likely there will be zero rows returned
        // so don't attempt to validate the result.
        String soql = 'SELECT Id,' + queryFields + ' FROM ' + objName + ' LIMIT 1';
        List<SObject> test = database.query(soql);
    }
}