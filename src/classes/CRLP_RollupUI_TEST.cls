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
* @group Rollups
* @group-content ../../ApexDocContent/Rollups2.htm
* @description Lightning Component Server Controller for the Rollups UI page CRLP_Setup.
*/

@isTest
public class CRLP_RollupUI_TEST {

    /*********************************************************************************************************
    * @description Tests getRollupDefinitions()
    */
    public static testMethod void testGetRollupDefinitions() {

        // Create the test CMDT data
        mockRollupCMTValues();

        List<CRLP_RollupUI_SVC.RollupTableItem> rollups = CRLP_RollupUI_SVC.getRollupDefinitions();
        System.assertEquals(2,rollups.size());

    }

    /*********************************************************************************************************
    * @description Tests getFilterGroupDefinitions()
    */
    public static testMethod void testGetFilterGroupDefinitions() {

        // Create the test CMDT data
        mockRollupCMTValues();

        List<CRLP_RollupUI_SVC.FilterGroupTableItem> filterGroups = CRLP_RollupUI_SVC.getFilterGroupDefinitions();
        System.assertEquals(1,filterGroups.size());

    }

    /*********************************************************************************************************
    * @description Tests setupFilterGroupDetail()
    */
    public static testMethod void testSetupFilterGroupDetail() {

        // Create the test CMDT data
        mockRollupCMTValues();

        Filter_Group__mdt filterGroup = CMT_FilterRule_SEL.cachedFilterGroups[0];

        List<String> objectList = new List<String>{'Opportunity'};

        CRLP_RollupUI_SVC.FilterGroupModel filterGroupModel = CRLP_RollupUI_SVC.setupFilterGroupDetail(filterGroup.Id, objectList);

        System.assertEquals(filterGroup,filterGroupModel.filterGroup, 'The Filter Group should match what was passed in');
        System.assertEquals(3,filterGroupModel.filterRuleList.size(), 'There should be 3 Filter Rules');
        System.assertEquals(13,filterGroupModel.operators.size(), 'There should be 13 operators');
        System.assertEquals(objectList.size(),filterGroupModel.filterFieldsByDataType.size(), 'There should be one entry for each object passed in');

    }

    /*********************************************************************************************************
    * @description Tests setupRollupGrid()
    */
    public static testMethod void testSetupRollupGrid() {

        // Create the test CMDT data
        mockRollupCMTValues();

        String jsonModel = CRLP_RollupUI_SVC.setupRollupGrid();
        System.assertNotEquals(null, jsonModel, 'JSON string of entire model should be returned.');
    }

    /*********************************************************************************************************
    * @description Tests setupRollupDetail()
    */
    public static testMethod void testSetupRollupDetail() {

        // Create the test CMDT data
        mockRollupCMTValues();

        Rollup__mdt rollup = CRLP_Rollup_SEL.cachedRollups[0];

        List<String> targetObjectNames = new List<String>{'Account','Contact'};
        List<String> detailObjectNames = new List<String>{'Opportunity'};

        String jsonModel = CRLP_RollupUI_SVC.setupRollupDetail(rollup.Id, targetObjectNames, detailObjectNames);
        System.assertNotEquals(null, jsonModel, 'JSON string of entire model should be returned.');
    }

    /*********************************************************************************************************
    * @description Tests saveRollup()
    */
    public static testMethod void testSaveRollup() {

        // Create the test CMDT data
        mockRollupCMTValues();

        List<CRLP_RollupUI_SVC.RollupTableItem> rollups = CRLP_RollupUI_SVC.getRollupDefinitions();
        System.assertEquals(2,rollups.size());

        // note: string pulled from debug logs based on an actual call
        String rollupString = '{"label":"UDR: Acct: Customer Priority","summaryObject":"Account","summaryField":"CustomerPriority__c","isActive":true,"summaryObjectLabel":"Account","description":"testing json","detailObject":"Opportunity","detailField":"npe01__Member_Level__c","amountField":"Amount","dateField":"CloseDate","operation":"Smallest","timeBoundOperationType":"All_Time","useFiscalYear":null,"filterGroup":"N/A","filterGroupLabel":"Allocations: Closed Won excluding RTs","detailObjectLabel":"Opportunity","dateObjectLabel":"Opportunity","dateObject":"Opportunity","summaryFieldLabel":"Customer Priority","filterGroupRecordName":"NPSP_Allocations_Filter","detailFieldLabel":"Member Level"}';
        CRLP_RollupUI_SVC.saveRollup(rollupString);

        rollups = CRLP_RollupUI_SVC.getRollupDefinitions();
        //System.assertEquals(3,rollups.size());

    }

    /**
    * @description Create test Rollup__mdt records
    */
    private static void mockRollupCMTValues() {

        String donationRTId = UTIL_RecordTypes.getRecordTypeIdForGiftsTests(Opportunity.SObjectType);
        String membershipRTId = UTIL_RecordTypes.getRecordTypeIdForMembershipTests(Opportunity.SObjectType);
        RecordType rtDonation = [SELECT DeveloperName FROM RecordType WHERE Id = :donationRTId LIMIT 1];

        // Create a single Filter Group
        String filterGroupId1 = CMT_UnitTestData_TEST.getNewRecordId();

        // Simple testing filters
        String filterGroupsJSON = '[' +
                CMT_UnitTestData_TEST.createFilterGroupRecord(filterGroupId1, 'TestFilterGroup1-IsWon+Paid') +
                ']';
        String filterRulesJSON = '[' +
                CMT_UnitTestData_TEST.createFilterRuleRecord(null, filterGroupId1, 'Group1.Rule1', 'Opportunity', 'IsWon', 'Equals', 'True') + ',' +
                CMT_UnitTestData_TEST.createFilterRuleRecord(null, filterGroupId1, 'Group1.Rule2', 'Opportunity', 'RecordTypeId', 'Equals', rtDonation.DeveloperName) + ',' +
                CMT_UnitTestData_TEST.createFilterRuleRecord(null, filterGroupId1, 'Group1.Rule3', 'npe01__OppPayment__c', 'npe01__Paid__c', 'Equals', 'True') +
                ']';

        // Deserialize the filter group and filter rule to use for the tests
        CMT_FilterRule_SEL.cachedFilterGroups = (List<Filter_Group__mdt>) JSON.deserialize(filterGroupsJSON, List<Filter_Group__mdt>.class);
        CMT_FilterRule_SEL.cachedFilterRules = (List<Filter_Rule__mdt>) JSON.deserialize(filterRulesJSON, List<Filter_Rule__mdt>.class);

        // Create 2 rollups that use the above Filter Group
        String rollupsJSON = '[' +
                CMT_UnitTestData_TEST.createRollupRecord('Total Donations All Time', filterGroupId1,
                        CMT_UnitTestData_TEST.RollupRecordType.OppToContact,
                        'npo02__TotalOppAmount__c', CRLP_Operation.RollupType.SUM, 'Amount') + ',' +

                CMT_UnitTestData_TEST.createRollupRecord('Average Donations All Time', filterGroupId1,
                        CMT_UnitTestData_TEST.RollupRecordType.OppToContact,
                        'npo02__AverageAmount__c', CRLP_Operation.RollupType.AVERAGE, 'Amount') +
                ']';

        // Deserialize the rollups to use for testing
        CRLP_Rollup_SEL.cachedRollups = (List<Rollup__mdt>) JSON.deserialize(rollupsJSON, List<Rollup__mdt>.class);
    }

}