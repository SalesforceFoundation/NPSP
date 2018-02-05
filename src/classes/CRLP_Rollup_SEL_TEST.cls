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
* @description Unit Test for the Rollup Definition Custom Metadata Type object selector
*/
@isTest(IsParallel=True)
public class CRLP_Rollup_SEL_TEST {

    /**
     * @description Because unit tests cannot actually insert Custom Metadata Types and there's no real way to know
     * exactly what's in the CMT objects, we can use this method to mock the contents of the cached MDT queries
     * for the unit tests
     */
    public static void mockRollupCMTValues() {

        // Create a single Filter Group (no need for filter rules here)
        String filterGroupId = CMT_UnitTestData_TEST.getNewRecordId();
        String filterGroupsJSON = '[' + CMT_UnitTestData_TEST.createFilterGroupRecord(filterGroupId, 'TestFilterGroup') + ']';
        CMT_FilterRule_SEL.cachedFilterGroups = (List<Filter_Group__mdt>)JSON.deserialize(filterGroupsJSON, List<Filter_Group__mdt>.class);

        // Create a single Rollup that uses the above Filter Group
        String rollupsJSON = '[' +
                CMT_UnitTestData_TEST.buildCMTObjectJSON('Rollup__mdt', 'Household Total Donations All Time',
                    CMT_UnitTestData_TEST.getNewRecordId(), new List<CMT_UnitTestData_TEST.CMT_Field>{
                        new CMT_UnitTestData_TEST.CMT_Field('Description__c', CMT_UnitTestData_TEST.CMTFieldType.FldText, 'Household Total Donations All Time'),
                        new CMT_UnitTestData_TEST.CMT_Field('Filter_Group__c', CMT_UnitTestData_TEST.CMTFieldType.FldText, filterGroupId),
                        new CMT_UnitTestData_TEST.CMT_Field('Active__c', CMT_UnitTestData_TEST.CMTFieldType.FldBoolean, True),
                        new CMT_UnitTestData_TEST.CMT_Field('Summary_Object__c', CMT_UnitTestData_TEST.CMTFieldType.FldEntity, 'Account'),
                        new CMT_UnitTestData_TEST.CMT_Field('Summary_Field__c', CMT_UnitTestData_TEST.CMTFieldType.FldField, 'Account.AnnualRevenue'),
                        new CMT_UnitTestData_TEST.CMT_Field('Detail_Object__c', CMT_UnitTestData_TEST.CMTFieldType.FldEntity, 'Opportunity'),
                        /*new CMT_UnitTestData_TEST.CMT_Field('Detail_Field__c', CMT_UnitTestData_TEST.CMTFieldType.FldField, 'Opportunity.AccountId'),*/
                        new CMT_UnitTestData_TEST.CMT_Field('Date_Object__c', CMT_UnitTestData_TEST.CMTFieldType.FldEntity, 'Opportunity'),
                        new CMT_UnitTestData_TEST.CMT_Field('Date_Field__c', CMT_UnitTestData_TEST.CMTFieldType.FldField, 'Opportunity.CloseDate'),
                        new CMT_UnitTestData_TEST.CMT_Field('Amount_Object__c', CMT_UnitTestData_TEST.CMTFieldType.FldEntity, 'Opportunity'),
                        new CMT_UnitTestData_TEST.CMT_Field('Amount_Field__c', CMT_UnitTestData_TEST.CMTFieldType.FldField, 'Opportunity.Amount')
                }) + ']';
        CRLP_Rollup_SEL.cachedRollups = (List<Rollup__mdt>) JSON.deserialize(
                rollupsJSON, List<Rollup__mdt>.class);
    }

    /**
     * @description Test the Rollup selector methods. Relies on hardcoded JSON deserialized
     * MDT data for these tests.
     */
    static testMethod void test_Rollup_Selectors() {

        mockRollupCMTValues();

        System.AssertEquals(1, CRLP_Rollup_SEL.getRollupDefinitions().size(), 'There should be 1 rollup definition');

        System.AssertEquals(1, CRLP_Rollup_SEL.getRollupsByDetailType().get(Opportunity.SObjectType).size(),
                'There should be 1 rollup for the Opportunity detail object');
        System.AssertEquals(1, CRLP_Rollup_SEL.getRollupsBySummaryType().get(Account.SObjectType).size(),
                'There should be 1 rollup for the Account summary object');
        System.AssertEquals(1, CRLP_Rollup_SEL.getRollupsByFilterGroup().size(),
                'There should be 1 filter group that has rollups');

        Integer expectedFldCount = 4;   // the 2 fields above PLUS the AccountID and PrimaryContactId fields
        if (UserInfo.isMultiCurrencyOrganization()) {
            expectedFldCount++;
        }
        System.AssertEquals(expectedFldCount, CRLP_Rollup_SEL.getReferencedFieldsByObject(Opportunity.SObjectType).size(),
                'There should be ' + expectedFldCount + ' Opportunity fields referenced across the rollup\n' +
                CRLP_Rollup_SEL.getReferencedFieldsByObjectAsString(Opportunity.SObjectType));

        // Test that a list of fields to query is returned
        String queryFields = CRLP_Rollup_SEL.getReferencedFieldsByObjectAsString(Opportunity.SObjectType);
        System.Assert(String.isNotEmpty(queryFields),
                'There should be at least one referenced field for the Opportunity object in Rollup__mdt');

        // Test that a query can be built and executed, though it's likely there will be zero rows returned
        // so don't attempt to validate the result.
        String soql = 'SELECT Id,' + queryFields + ' FROM Opportunity LIMIT 1';
        List<SObject> test = database.query(soql);
    }
}