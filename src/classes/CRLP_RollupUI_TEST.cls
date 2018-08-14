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
* @description Unit Tests for the Lightning Component Apex Controller for the CRLP UI.
*/

@isTest(IsParallel=true)
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

        Filter_Group__mdt filterGroupMdt = CMT_FilterRule_SEL.cachedFilterGroups[0];
        CRLP_RollupCMT.FilterGroup filterGroup = new CRLP_RollupCMT.FilterGroup(filterGroupMdt);

        List<String> objectList = new List<String>{'Opportunity'};

        String modelString = CRLP_RollupUI_SVC.setupFilterGroupDetail(filterGroup.recordId, objectList);
        CRLP_RollupUI_SVC.FilterGroupModel filterGroupModel = (CRLP_RollupUI_SVC.FilterGroupModel)JSON.deserialize(modelString, CRLP_RollupUI_SVC.FilterGroupModel.class);

        System.assertEquals(filterGroup.recordName,filterGroupModel.filterGroup.recordName, 'The Filter Group should match what was passed in');
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

        CRLP_RollupCMT.Rollup rollup = new CRLP_RollupCMT.Rollup('test');
        rollup.summaryObject = 'Account';
        rollup.summaryField = 'CustomerPriority__c';
        rollup.summaryObjectLabel = 'Account';
        rollup.detailObject = 'Opportunity';
        rollup.detailField = 'npe01__Member_Level__c';
        rollup.amountField = 'Amount';
        rollup.dateField = 'CloseDate';
        rollup.operation = 'Smallest';
        rollup.timeBoundOperationType = 'All_Time';
        rollup.detailObjectLabel = 'Opportunity';
        rollup.dateObjectLabel = 'Opportunity';
        rollup.dateObject = 'Opportunity';
        rollup.summaryFieldlabel = 'Customer Priority';
        rollup.filterGroupRecordName = 'NPSP_Allocations_Filter';
        rollup.detailFieldLabel = 'Member Level';

        String rollupString = JSON.serialize(rollup);

        CRLP_RollupUI_SVC.saveRollup(rollupString);

        // nothing to assert since CMDTs can't be inserted/updated in unit tests

    }

    /*********************************************************************************************************
    * @description Tests saveFilterGroupAndRules()
    */
    public static testMethod void testSaveFilterGroupAndRules() {

        CRLP_RollupCMT.FilterGroup filterGroup = new CRLP_RollupCMT.FilterGroup('test');

        List<CRLP_RollupCMT.FilterRule> rules = new List<CRLP_RollupCMT.FilterRule>();
        CRLP_RollupCMT.FilterRule rule = new CRLP_RollupCMT.FilterRule('testRule', 'test');
        rule.objectLabel = 'Opportunity';
        rule.objectName = 'Opportunity';
        rule.fieldLabel = 'Amount';
        rule.fieldName = 'Amount';
        rule.operationLabel = 'Equals';
        rule.operationName = 'Equals';
        rule.value = '1';
        rules.add(rule);

        filterGroup.rules = rules;

        String filterGroupString = JSON.serialize(filterGroup);

        CRLP_RollupUI_SVC.saveFilterGroupAndRules(filterGroupString);

        // nothing to assert since CMDTs can't be inserted/updated in unit tests

    }

    /*********************************************************************************************************
    * @description Tests getFilterRuleConstantPicklistOptions()
    */
    public static testMethod void testGetFilterRuleConstantPicklistOptions() {
        String objectName = 'Opportunity';
        String fieldName = 'StageName';
        List<Map<String,String>> options = CRLP_RollupUI_SVC.getFilterRuleConstantPicklistOptions(objectName, fieldName);
        List<PicklistEntry> picklistValues = Schema.getGlobalDescribe().get('Opportunity').getDescribe().fields.getMap().get('StageName').getDescribe().getPicklistValues();
        System.assertEquals(picklistValues.size(), options.size());
    }

    /*********************************************************************************************************
    * @description Tests getDeploymentStatus()
    */
    public static testMethod void testGetDeploymentStatus_Rollup() {

        // Create the test CMDT data
        mockRollupCMTValues();

        // Test a failure
        UTIL_CustomSettingsFacade.getRollupSettingsForTests(new Customizable_Rollup_Settings__c (
                Customizable_Rollups_Enabled__c = true,
                CMT_API_Status__c = '{ "jobId" : "Some Text" }'
        ));

        try {
            // we know this will fail because the rollupName is not found
            CRLP_RollupUI_SVC.getDeploymentStatus('jobId', 'rollupName', 'Rollup', 'create');
        } catch (Exception e) {
            System.assertNotEquals(null, e.getMessage());
        }

        try {
            // we know this will fail because the filterName is not found
            CRLP_RollupUI_SVC.getDeploymentStatus('jobId', 'rollupName', 'Filter', 'edit');
        } catch (Exception e) {
            System.assertNotEquals(null, e.getMessage());
        }

        // Test a success
        UTIL_CustomSettingsFacade.getRollupSettingsForTests(new Customizable_Rollup_Settings__c (
                Customizable_Rollups_Enabled__c = true,
                CMT_API_Status__c = '{ "jobId" : "'+Metadata.DeployStatus.Succeeded.name()+'" }'
        ));

        String recordName = CRLP_Rollup_SEL.cachedRollups[0].DeveloperName;
        String resultString = CRLP_RollupUI_SVC.getDeploymentStatus('jobId', recordName, 'Rollup', 'edit');
        CRLP_RollupUI_SVC.DeploymentResult response = (CRLP_RollupUI_SVC.DeploymentResult)JSON.deserialize(resultString, CRLP_RollupUI_SVC.DeploymentResult.class);

        System.assertNotEquals(null, response);

        resultString = CRLP_RollupUI_SVC.getDeploymentStatus('jobId', recordName, 'Filter', 'edit');
        response = (CRLP_RollupUI_SVC.DeploymentResult)JSON.deserialize(resultString, CRLP_RollupUI_SVC.DeploymentResult.class);

        System.assertNotEquals(null, response);

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