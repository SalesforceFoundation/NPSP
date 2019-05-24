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
* @description Unit Test for the Default Customizable Rollups Configuration Builder classes
*/
@isTest(IsParallel=true)
private class CRLP_ConfigBuilder_TEST {

    /**
     * @description Create Rollup__mdt records to test rolling up from the Opp and Payment objects to the Account
     */
    private static void mockRollupCMTValues() {

        // Create a single Filter Group (no need for filter rules here)
        String filterGroupId1 = CMT_UnitTestData_TEST.getNewRecordId();

        // Simple testing filters for IsWon, RecordType, and Paid/Written Off
        String filterGroupsJSON = '[' +
                CMT_UnitTestData_TEST.createFilterGroupRecord(filterGroupId1, 'TestFilterGroup1-IsWon+Paid') +
                ']';
        String filterRulesJSON = '[' +
                CMT_UnitTestData_TEST.createFilterRuleRecord(null, filterGroupId1, 'Group1.Rule1', 'Opportunity', 'IsWon', 'Equals', 'True') + ',' +
                CMT_UnitTestData_TEST.createFilterRuleRecord(null, filterGroupId1, 'Group1.Rule2', 'Opportunity', 'RecordTypeId', 'Equals', 'Something') + ',' +
                CMT_UnitTestData_TEST.createFilterRuleRecord(null, filterGroupId1, 'Group1.Rule3', 'npe01__OppPayment__c', 'npe01__Paid__c', 'Equals', 'True') +
                ']';

        // Deserialize the filter group and filter rule to use for the tests
        CMT_FilterRule_SEL.cachedFilterGroups = (List<Filter_Group__mdt>)JSON.deserialize(filterGroupsJSON, List<Filter_Group__mdt>.class);
        CMT_FilterRule_SEL.cachedFilterRules = (List<Filter_Rule__mdt>)JSON.deserialize(filterRulesJSON, List<Filter_Rule__mdt>.class);

        // Create a single Rollup that uses the above Filter Group
        // TODO Add many more rollup variations to this
        String rollupsJSON = '[' +
                CMT_UnitTestData_TEST.createRollupRecord('Household Total Donations All Time', filterGroupId1,
                        CMT_UnitTestData_TEST.RollupRecordType.OppToAcct,
                        'npo02__TotalOppAmount__c', CRLP_Operation.RollupType.SUM, 'Amount') +
                ']';

        // Deserialize the rollups to use for testing
        CRLP_Rollup_SEL.cachedRollups = (List<Rollup__mdt>) JSON.deserialize(rollupsJSON, List<Rollup__mdt>.class);
    }

    static testMethod void test_CMTdeployment() {
        mockRollupCMTValues();

        Filter_Group__mdt fg = CMT_FilterRule_SEL.cachedFilterGroups[0];
        Filter_Rule__mdt fr = CMT_FilterRule_SEL.cachedFilterRules[0];
        Rollup__mdt rlp = CRLP_Rollup_SEL.cachedRollups[0];

        Test.startTest();

        CRLP_RollupCMT.FilterGroup filterGroup = new CRLP_RollupCMT.FilterGroup(fg);
        CRLP_RollupCMT.FilterRule filterRule = new CRLP_RollupCMT.FilterRule(fr);
        CRLP_RollupCMT.Rollup rollup = new CRLP_RollupCMT.Rollup(rlp);

        filterRule.isDeleted = true;
        filterGroup.description = 'Updated Description';
        rollup.isActive = false;

        CRLP_ConfigBuilder_SVC.queueRollupConfigForDeploy(new List<CRLP_RollupCMT.Rollup>{ rollup });
        CRLP_ConfigBuilder_SVC.queueRollupConfigForDeploy(new List<CRLP_RollupCMT.FilterRule>{ filterRule });
        CRLP_ConfigBuilder_SVC.queueRollupConfigForDeploy(new List<CRLP_RollupCMT.FilterGroup>{ filterGroup });

        String jobId = CRLP_ConfigBuilder_SVC.deployedQueuedMetadataTypes();
        CRLP_ConfigBuilder_SVC.clearQueue();

        // Construct our callback class
        CMT_MetadataAPI.MetadataCallBack callback = new CMT_MetadataAPI.MetadataCallBack(jobId);

        // Construct a dummy Context
        TestingDeployCallbackContext context = new TestingDeployCallbackContext();

        // Call the handleResult() method of our main Callback with our dummy context var
        callback.handleResult(null, context);

        Test.stopTest();

        // Verify that the callback method handler wrote a status update to the CustomizableRollupsSettings object
        Customizable_Rollup_Settings__c crlpSettings = UTIL_CustomSettingsFacade.getCustomizableRollupSettings();
        Map<String,String> result = (Map<String,String>)JSON.deserialize(crlpSettings.CMT_API_Status__c, Map<String,String>.class);
        system.assertNotEquals(null, result.get(jobId), result);
    }

    // DeployCallbackContext subclass for testing that returns myJobId
    public class TestingDeployCallbackContext extends Metadata.DeployCallbackContext {
        public override Id getCallbackJobId() {
            return '000000000122345';
        }
    }
}