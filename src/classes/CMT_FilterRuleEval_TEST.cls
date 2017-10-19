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
private class CMT_FilterRuleEval_TEST {

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
        String donationRTId = UTIL_RecordTypes.getRecordTypeIdForGiftsTests(Opportunity.sObjectType);

        String filterGroupsJSON = '[' +
                CMT_UnitTestData_TEST.buildCMTObjectJSON('Filter_Group__mdt', 'Test Group 1', filterGroupId1,
                        new List<CMT_UnitTestData_TEST.CMT_Field>{
                        new CMT_UnitTestData_TEST.CMT_Field('Is_Deleted__c', CMT_UnitTestData_TEST.CMTFieldType.FldBoolean, False)
                    }) + ',' +
                CMT_UnitTestData_TEST.buildCMTObjectJSON('Filter_Group__mdt', 'Test Group 2', filterGroupId2,
                        new List<CMT_UnitTestData_TEST.CMT_Field>{
                                new CMT_UnitTestData_TEST.CMT_Field('Is_Deleted__c', CMT_UnitTestData_TEST.CMTFieldType.FldBoolean, False)
                    }) + ',' +
                CMT_UnitTestData_TEST.buildCMTObjectJSON('Filter_Group__mdt', 'Test Group 3', filterGroupId3,
                        new List<CMT_UnitTestData_TEST.CMT_Field>{
                                new CMT_UnitTestData_TEST.CMT_Field('Is_Deleted__c', CMT_UnitTestData_TEST.CMTFieldType.FldBoolean, False)
                    }) +
                ']';

        String filterRulesJSON = '[' +
            /*  FILTER RULES FOR FILTER GROUP 1 -- Opportunity only Boolean and Date fields */
                CMT_UnitTestData_TEST.buildCMTObjectJSON('Filter_Rule__mdt', 'Group1.TestRule1',
                        CMT_UnitTestData_TEST.getNewRecordId(), new List<CMT_UnitTestData_TEST.CMT_Field>{
                                new CMT_UnitTestData_TEST.CMT_Field('Filter_Group__c', CMT_UnitTestData_TEST.CMTFieldType.FldText, filterGroupId1),
                                new CMT_UnitTestData_TEST.CMT_Field('Object__c', CMT_UnitTestData_TEST.CMTFieldType.FldEntity, 'Opportunity'),
                                new CMT_UnitTestData_TEST.CMT_Field('Field__c', CMT_UnitTestData_TEST.CMTFieldType.FldField, 'Opportunity.IsWon'),
                                new CMT_UnitTestData_TEST.CMT_Field('Operator__c', CMT_UnitTestData_TEST.CMTFieldType.FldText, 'Equals'),
                                new CMT_UnitTestData_TEST.CMT_Field('Constant__c', CMT_UnitTestData_TEST.CMTFieldType.FldText, 'true')
                        }) + ',' +
                CMT_UnitTestData_TEST.buildCMTObjectJSON('Filter_Rule__mdt', 'Group1.TestRule2',
                        CMT_UnitTestData_TEST.getNewRecordId(), new List<CMT_UnitTestData_TEST.CMT_Field>{
                                new CMT_UnitTestData_TEST.CMT_Field('Filter_Group__c', CMT_UnitTestData_TEST.CMTFieldType.FldText, filterGroupId1),
                                new CMT_UnitTestData_TEST.CMT_Field('Object__c', CMT_UnitTestData_TEST.CMTFieldType.FldEntity, 'Opportunity'),
                                new CMT_UnitTestData_TEST.CMT_Field('Field__c', CMT_UnitTestData_TEST.CMTFieldType.FldField, 'Opportunity.StageName'),
                                new CMT_UnitTestData_TEST.CMT_Field('Operator__c', CMT_UnitTestData_TEST.CMTFieldType.FldText, 'Equals'),
                                new CMT_UnitTestData_TEST.CMT_Field('Constant__c', CMT_UnitTestData_TEST.CMTFieldType.FldText, closedWonStage.toUpperCase())
                        }) + ',' +
                CMT_UnitTestData_TEST.buildCMTObjectJSON('Filter_Rule__mdt', 'Group1.TestRule3',
                        CMT_UnitTestData_TEST.getNewRecordId(), new List<CMT_UnitTestData_TEST.CMT_Field>{
                                new CMT_UnitTestData_TEST.CMT_Field('Filter_Group__c', CMT_UnitTestData_TEST.CMTFieldType.FldText, filterGroupId1),
                                new CMT_UnitTestData_TEST.CMT_Field('Object__c', CMT_UnitTestData_TEST.CMTFieldType.FldEntity, 'Opportunity'),
                                new CMT_UnitTestData_TEST.CMT_Field('Field__c', CMT_UnitTestData_TEST.CMTFieldType.FldField, 'Opportunity.CloseDate'),
                                new CMT_UnitTestData_TEST.CMT_Field('Operator__c', CMT_UnitTestData_TEST.CMTFieldType.FldText, 'Equals'),
                                new CMT_UnitTestData_TEST.CMT_Field('Constant__c', CMT_UnitTestData_TEST.CMTFieldType.FldText, 'THIS_YEAR')
                        }) + ',' +
                CMT_UnitTestData_TEST.buildCMTObjectJSON('Filter_Rule__mdt', 'Group1.TestRule4',
                        CMT_UnitTestData_TEST.getNewRecordId(), new List<CMT_UnitTestData_TEST.CMT_Field>{
                                new CMT_UnitTestData_TEST.CMT_Field('Filter_Group__c', CMT_UnitTestData_TEST.CMTFieldType.FldText, filterGroupId1),
                                new CMT_UnitTestData_TEST.CMT_Field('Object__c', CMT_UnitTestData_TEST.CMTFieldType.FldEntity, 'Opportunity'),
                                new CMT_UnitTestData_TEST.CMT_Field('Field__c', CMT_UnitTestData_TEST.CMTFieldType.FldField, 'Opportunity.CloseDate'),
                                new CMT_UnitTestData_TEST.CMT_Field('Operator__c', CMT_UnitTestData_TEST.CMTFieldType.FldText, 'Equals'),
                                new CMT_UnitTestData_TEST.CMT_Field('Constant__c', CMT_UnitTestData_TEST.CMTFieldType.FldText, 'THIS_MONTH')
                        }) + ',' +
                CMT_UnitTestData_TEST.buildCMTObjectJSON('Filter_Rule__mdt', 'Group1.TestRule5',
                        CMT_UnitTestData_TEST.getNewRecordId(), new List<CMT_UnitTestData_TEST.CMT_Field>{
                                new CMT_UnitTestData_TEST.CMT_Field('Filter_Group__c', CMT_UnitTestData_TEST.CMTFieldType.FldText, filterGroupId1),
                                new CMT_UnitTestData_TEST.CMT_Field('Object__c', CMT_UnitTestData_TEST.CMTFieldType.FldEntity, 'Opportunity'),
                                new CMT_UnitTestData_TEST.CMT_Field('Field__c', CMT_UnitTestData_TEST.CMTFieldType.FldField, 'Opportunity.CloseDate'),
                                new CMT_UnitTestData_TEST.CMT_Field('Operator__c', CMT_UnitTestData_TEST.CMTFieldType.FldText, 'Not_Equals'),
                                new CMT_UnitTestData_TEST.CMT_Field('Constant__c', CMT_UnitTestData_TEST.CMTFieldType.FldText, 'LAST_YEAR')
                        }) + ',' +
                CMT_UnitTestData_TEST.buildCMTObjectJSON('Filter_Rule__mdt', 'Group1.TestRule6',
                        CMT_UnitTestData_TEST.getNewRecordId(), new List<CMT_UnitTestData_TEST.CMT_Field>{
                                new CMT_UnitTestData_TEST.CMT_Field('Filter_Group__c', CMT_UnitTestData_TEST.CMTFieldType.FldText, filterGroupId1),
                                new CMT_UnitTestData_TEST.CMT_Field('Object__c', CMT_UnitTestData_TEST.CMTFieldType.FldEntity, 'Opportunity'),
                                new CMT_UnitTestData_TEST.CMT_Field('Field__c', CMT_UnitTestData_TEST.CMTFieldType.FldField, 'Opportunity.Amount'),
                                new CMT_UnitTestData_TEST.CMT_Field('Operator__c', CMT_UnitTestData_TEST.CMTFieldType.FldText, 'Greater'),
                                new CMT_UnitTestData_TEST.CMT_Field('Constant__c', CMT_UnitTestData_TEST.CMTFieldType.FldText, '0')
                        }) + ',' +
                CMT_UnitTestData_TEST.buildCMTObjectJSON('Filter_Rule__mdt', 'Group1.TestRule7',
                        CMT_UnitTestData_TEST.getNewRecordId(), new List<CMT_UnitTestData_TEST.CMT_Field>{
                                new CMT_UnitTestData_TEST.CMT_Field('Filter_Group__c', CMT_UnitTestData_TEST.CMTFieldType.FldText, filterGroupId1),
                                new CMT_UnitTestData_TEST.CMT_Field('Object__c', CMT_UnitTestData_TEST.CMTFieldType.FldEntity, 'Opportunity'),
                                new CMT_UnitTestData_TEST.CMT_Field('Field__c', CMT_UnitTestData_TEST.CMTFieldType.FldField, 'Opportunity.Primary_Contact__c'),
                                new CMT_UnitTestData_TEST.CMT_Field('Operator__c', CMT_UnitTestData_TEST.CMTFieldType.FldText, 'Not_Equals'),
                                new CMT_UnitTestData_TEST.CMT_Field('Constant__c', CMT_UnitTestData_TEST.CMTFieldType.FldText, '')
                        }) + ',' +
                CMT_UnitTestData_TEST.buildCMTObjectJSON('Filter_Rule__mdt', 'Group1.TestRule8',
                        CMT_UnitTestData_TEST.getNewRecordId(), new List<CMT_UnitTestData_TEST.CMT_Field>{
                                new CMT_UnitTestData_TEST.CMT_Field('Filter_Group__c', CMT_UnitTestData_TEST.CMTFieldType.FldText, filterGroupId1),
                                new CMT_UnitTestData_TEST.CMT_Field('Object__c', CMT_UnitTestData_TEST.CMTFieldType.FldEntity, 'Opportunity'),
                                new CMT_UnitTestData_TEST.CMT_Field('Field__c', CMT_UnitTestData_TEST.CMTFieldType.FldField, 'Opportunity.StageName'),
                                new CMT_UnitTestData_TEST.CMT_Field('Operator__c', CMT_UnitTestData_TEST.CMTFieldType.FldText, 'Contains'),
                                new CMT_UnitTestData_TEST.CMT_Field('Constant__c', CMT_UnitTestData_TEST.CMTFieldType.FldText, closedWonStage.right(3))
                        }) + ',' +
                CMT_UnitTestData_TEST.buildCMTObjectJSON('Filter_Rule__mdt', 'Group1.TestRule9',
                        CMT_UnitTestData_TEST.getNewRecordId(), new List<CMT_UnitTestData_TEST.CMT_Field>{
                                new CMT_UnitTestData_TEST.CMT_Field('Filter_Group__c', CMT_UnitTestData_TEST.CMTFieldType.FldText, filterGroupId1),
                                new CMT_UnitTestData_TEST.CMT_Field('Object__c', CMT_UnitTestData_TEST.CMTFieldType.FldEntity, 'Opportunity'),
                                new CMT_UnitTestData_TEST.CMT_Field('Field__c', CMT_UnitTestData_TEST.CMTFieldType.FldField, 'Opportunity.CreatedDate'),
                                new CMT_UnitTestData_TEST.CMT_Field('Operator__c', CMT_UnitTestData_TEST.CMTFieldType.FldText, 'Equals'),
                                new CMT_UnitTestData_TEST.CMT_Field('Constant__c', CMT_UnitTestData_TEST.CMTFieldType.FldText, DateTime.Now().format('YYYY-MM-dd'))
                        }) + ',' +

                /*  FILTER RULES FOR FILTER GROUP 2 -- Opportunity with RecordTypeId, StageName and OCR.Role */
                CMT_UnitTestData_TEST.buildCMTObjectJSON('Filter_Rule__mdt', 'Group2.TestRule1',
                        CMT_UnitTestData_TEST.getNewRecordId(), new List<CMT_UnitTestData_TEST.CMT_Field>{
                                new CMT_UnitTestData_TEST.CMT_Field('Filter_Group__c', CMT_UnitTestData_TEST.CMTFieldType.FldText, filterGroupId2),
                                new CMT_UnitTestData_TEST.CMT_Field('Object__c', CMT_UnitTestData_TEST.CMTFieldType.FldEntity, 'Opportunity'),
                                new CMT_UnitTestData_TEST.CMT_Field('Field__c', CMT_UnitTestData_TEST.CMTFieldType.FldField, 'Opportunity.StageName'),
                                new CMT_UnitTestData_TEST.CMT_Field('Operator__c', CMT_UnitTestData_TEST.CMTFieldType.FldText, 'Equals'),
                                new CMT_UnitTestData_TEST.CMT_Field('Constant__c', CMT_UnitTestData_TEST.CMTFieldType.FldText, closedWonStage)
                        }) + ',' +
                CMT_UnitTestData_TEST.buildCMTObjectJSON('Filter_Rule__mdt', 'Group2.TestRule2',
                        CMT_UnitTestData_TEST.getNewRecordId(), new List<CMT_UnitTestData_TEST.CMT_Field>{
                                new CMT_UnitTestData_TEST.CMT_Field('Filter_Group__c', CMT_UnitTestData_TEST.CMTFieldType.FldText, filterGroupId2),
                                new CMT_UnitTestData_TEST.CMT_Field('Object__c', CMT_UnitTestData_TEST.CMTFieldType.FldEntity, 'Opportunity'),
                                new CMT_UnitTestData_TEST.CMT_Field('Field__c', CMT_UnitTestData_TEST.CMTFieldType.FldField, 'Opportunity.RecordTypeId'),
                                new CMT_UnitTestData_TEST.CMT_Field('Operator__c', CMT_UnitTestData_TEST.CMTFieldType.FldText, 'Equals'),
                                new CMT_UnitTestData_TEST.CMT_Field('Constant__c', CMT_UnitTestData_TEST.CMTFieldType.FldText, donationRTId)
                        }) + ',' +
                CMT_UnitTestData_TEST.buildCMTObjectJSON('Filter_Rule__mdt', 'Group2.TestRule3',
                        CMT_UnitTestData_TEST.getNewRecordId(), new List<CMT_UnitTestData_TEST.CMT_Field>{
                                new CMT_UnitTestData_TEST.CMT_Field('Filter_Group__c', CMT_UnitTestData_TEST.CMTFieldType.FldText, filterGroupId2),
                                new CMT_UnitTestData_TEST.CMT_Field('Field_OpportunityContactRole_Role__c', CMT_UnitTestData_TEST.CMTFieldType.FldBoolean, True),
                                new CMT_UnitTestData_TEST.CMT_Field('Object__c', CMT_UnitTestData_TEST.CMTFieldType.FldEntity, 'Opportunity'),
                                new CMT_UnitTestData_TEST.CMT_Field('Field__c', CMT_UnitTestData_TEST.CMTFieldType.FldField, 'Opportunity.Id'),
                                new CMT_UnitTestData_TEST.CMT_Field('Operator__c', CMT_UnitTestData_TEST.CMTFieldType.FldText, 'Equals'),
                                new CMT_UnitTestData_TEST.CMT_Field('Constant__c', CMT_UnitTestData_TEST.CMTFieldType.FldText, 'Donor')
                        }) + ',' +
                CMT_UnitTestData_TEST.buildCMTObjectJSON('Filter_Rule__mdt', 'Group2.TestRule4',
                        CMT_UnitTestData_TEST.getNewRecordId(), new List<CMT_UnitTestData_TEST.CMT_Field>{
                                new CMT_UnitTestData_TEST.CMT_Field('Filter_Group__c', CMT_UnitTestData_TEST.CMTFieldType.FldText, filterGroupId2),
                                new CMT_UnitTestData_TEST.CMT_Field('Object__c', CMT_UnitTestData_TEST.CMTFieldType.FldEntity, 'Opportunity'),
                                new CMT_UnitTestData_TEST.CMT_Field('Field__c', CMT_UnitTestData_TEST.CMTFieldType.FldField, 'Opportunity.Type'),
                                new CMT_UnitTestData_TEST.CMT_Field('Operator__c', CMT_UnitTestData_TEST.CMTFieldType.FldText, 'Equals'),
                                new CMT_UnitTestData_TEST.CMT_Field('Constant__c', CMT_UnitTestData_TEST.CMTFieldType.FldText, '')
                        }) + ',' +
                CMT_UnitTestData_TEST.buildCMTObjectJSON('Filter_Rule__mdt', 'Group2.TestRule5',
                        CMT_UnitTestData_TEST.getNewRecordId(), new List<CMT_UnitTestData_TEST.CMT_Field>{
                                new CMT_UnitTestData_TEST.CMT_Field('Filter_Group__c', CMT_UnitTestData_TEST.CMTFieldType.FldText, filterGroupId2),
                                new CMT_UnitTestData_TEST.CMT_Field('Object__c', CMT_UnitTestData_TEST.CMTFieldType.FldEntity, 'Opportunity'),
                                new CMT_UnitTestData_TEST.CMT_Field('Field__c', CMT_UnitTestData_TEST.CMTFieldType.FldField, 'Opportunity.NextStep'),
                                new CMT_UnitTestData_TEST.CMT_Field('Operator__c', CMT_UnitTestData_TEST.CMTFieldType.FldText, 'Starts_With'),
                                new CMT_UnitTestData_TEST.CMT_Field('Constant__c', CMT_UnitTestData_TEST.CMTFieldType.FldText, 'TEST')
                        }) + ',' +
                CMT_UnitTestData_TEST.buildCMTObjectJSON('Filter_Rule__mdt', 'Group2.TestRule6',
                        CMT_UnitTestData_TEST.getNewRecordId(), new List<CMT_UnitTestData_TEST.CMT_Field>{
                                new CMT_UnitTestData_TEST.CMT_Field('Filter_Group__c', CMT_UnitTestData_TEST.CMTFieldType.FldText, filterGroupId2),
                                new CMT_UnitTestData_TEST.CMT_Field('Object__c', CMT_UnitTestData_TEST.CMTFieldType.FldEntity, 'Opportunity'),
                                new CMT_UnitTestData_TEST.CMT_Field('Field__c', CMT_UnitTestData_TEST.CMTFieldType.FldField, 'Opportunity.Amount'),
                                new CMT_UnitTestData_TEST.CMT_Field('Operator__c', CMT_UnitTestData_TEST.CMTFieldType.FldText, 'Not_Equals'),
                                new CMT_UnitTestData_TEST.CMT_Field('Constant__c', CMT_UnitTestData_TEST.CMTFieldType.FldText, '')
                        }) +
                ']';

        CMT_FilterRule_SEL.cachedFilterGroups = (List<Filter_Group__mdt>)JSON.deserialize(
                filterGroupsJSON, List<Filter_Group__mdt>.class);

        CMT_FilterRule_SEL.cachedFilterRules = (List<Filter_Rule__mdt>)JSON.deserialize(
                filterRulesJSON, List<Filter_Rule__mdt>.class);

        // Validate that the expected number of Filter Groups and Filter Rules were instantiated/deserialized.
        System.AssertEquals(3, CMT_FilterRule_SEL.cachedFilterGroups.size());
        System.AssertEquals(15, CMT_FilterRule_SEL.cachedFilterRules.size());
    }

    /**
     * @description test the evaluation method to process a given SObject against a FilterGroup
     */
    static testMethod void test_evaluateFilterRules() {
        mockFilterCMTValues();

        Contact c = new Contact(FirstName = 'UNITTEST', LastName = 'UNITTEST');
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

        // Query the Opportunity and the child OCR and Payment records to use in the evaluation
        String soql = RLLP_Query_SEL.getDetailsQuery(Opportunity.SObjectType,
                new List<SObjectType>{OpportunityContactRole.SObjectType, npe01__OppPayment__c.SObjectType});
        o = database.query(soql);

        Test.startTest();

        System.AssertEquals(True, CMT_FilterRuleEval_SVC.evaluateFilterGroup(new List<SObject>{o}, filterGroupId1));
        System.AssertEquals(True, CMT_FilterRuleEval_SVC.evaluateFilterGroup(
                new List<SObject>{o, o.OpportunityContactRoles[0]}, filterGroupId2));

        // TODO Add more tests

    }

}