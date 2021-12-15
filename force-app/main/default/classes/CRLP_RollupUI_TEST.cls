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

@isTest(IsParallel=false)
public class CRLP_RollupUI_TEST {

    private static User standardUser = UTIL_UnitTestData_TEST.createStandardProfileUser();

    /*********************************************************************************************************
    * @description Tests that get rollup definitions returns the current rollups
    */
    @isTest
    private static void getRollupDefinitionsReturnsTheCurrentRollups() {
        mockRollupCMTValues();
        List<CRLP_RollupUI_SVC.RollupTableItem> rollups = CRLP_RollupUI_SVC.getRollupDefinitions();
        System.assertEquals(2,rollups.size());
    }

    /*********************************************************************************************************
    * @description Tests that get filter group returns the current filter groups
    */
    @isTest
    private static void getFilterGroupsReturnsTheCurrentFilterGroups() {
        mockRollupCMTValues();
        List<CRLP_RollupUI_SVC.FilterGroupTableItem> filterGroups = CRLP_RollupUI_SVC.getFilterGroupDefinitions();
        System.assertEquals(1,filterGroups.size());
    }

    /*********************************************************************************************************
    * @description Tests that setup Filter Group generates the filter model
    */
    @isTest
    private static void setFilterGroupGeneratesTheFilterModel() {
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
    * @description Tests that setup rollup grid generates the rollup grid json model
    */
    @isTest
    private static void setupRollupGridGeneratesTheJsonModel() {
        mockRollupCMTValues();

        String jsonModel = CRLP_RollupUI_SVC.setupRollupGrid();
        System.assertNotEquals(null, jsonModel, 'JSON string of entire model should be returned.');
    }

    /*********************************************************************************************************
    * @description Tests that setup rollup detail generates the json model
    */
    @isTest
    private static void setupRollupDetailGeneratesTheJsonModel() {
        mockRollupCMTValues();
        Rollup__mdt rollup = CRLP_Rollup_SEL.cachedRollups[0];

        List<String> targetObjectNames = new List<String>{'Account','Contact'};
        List<String> detailObjectNames = new List<String>{'Opportunity'};

        String jsonModel = CRLP_RollupUI_SVC.setupRollupDetail(rollup.Id, targetObjectNames, detailObjectNames);
        System.assertNotEquals(null, jsonModel, 'JSON string of entire model should be returned.');
    }

    /***
    * @description Verifies if there are no exception thrown in setting up the Rollups when Einstein
    * insights platform is enabled in the org
    */
    @isTest
    private static void shouldNotThrowExceptionInCRLPSetupWhenEinsteinIsEnabled() {
        String errMessage = '';
        String scriptError = 'Script-thrown exception';

        mockRollupCMTValues();
        Rollup__mdt rollup = CRLP_Rollup_SEL.cachedRollups[0];

        List<String> targetObjectNames = new List<String>{'Account','Contact'};
        List<String> detailObjectNames = new List<String>{'Opportunity'};

        if (!UTIL_Namespace.isEinsteinInsightsInstalled()) {
            return;
        }

        try {
            String jsonModel = CRLP_RollupUI_SVC.setupRollupDetail(rollup.Id, targetObjectNames, detailObjectNames);
        } catch (Exception e) {
            errMessage = e.getMessage();
        }
        System.assert(!errMessage.contains(scriptError));
        System.assertEquals('', errMessage, 'No exception is returned when Einstein is enabled');
    }

    /***
    * @description Validate that the response from getdetailsfieldswithtype does not include the
    * System field for account object
    */
    @isTest
    private static void shouldNotHaveSystemFieldsInResponseFromGetDetailsType() {
        mockRollupCMTValues();
        Rollup__mdt rollup = CRLP_Rollup_SEL.cachedRollups[0];

        String detailObj = 'Account';

        List<Map<String, String>> detailNameToFieldTypeObj = CRLP_RollupUI_SVC.getDetailFieldsWithType(detailObj);

        for(Map<String,String> apiFieldNames: detailNameToFieldTypeObj) {
            System.assert(!apiFieldNames.get('name').containsIgnoreCase('npe01__SYSTEM_AccountType__c'),
                'The returned collection of Field API Names should not include the "npe01__SYSTEM_AccountType__c" field');
        }

    }

    /*********************************************************************************************************
    * @description Tests Saving a new Rollup With Summaries Disabled returns a job id for the deployment
    */
    @isTest
    private static void saveRollupReturnsDeploymentJob() {
        CRLP_RollupCMT.Rollup rollup = CRLP_RollupCMT_Test.generateRollup('test');
        String rollupString = JSON.serialize(rollup);

        Test.startTest();
        String saveResult = CRLP_RollupUI_SVC.saveRollup(rollupString);
        Test.stopTest();

        System.assertNotEquals(null, saveResult, 'Job Id should be returned from save');
    }

    /*********************************************************************************************************
    * @description Tests saveFilterGroup returns a job id for the deployment
    */
    @isTest
    public static void saveFilterGroupReturnsDeploymentJob() {

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

        Test.startTest();
        String saveResult = CRLP_RollupUI_SVC.saveFilterGroupAndRules(filterGroupString);
        Test.stopTest();

        System.assertNotEquals(null, saveResult, 'Job Id should be returned from save');
    }

    /*********************************************************************************************************
    * @description Tests getFilterRuleConstantPicklistOptions()
    */
    @isTest
    public static void getFilterRuleReturnsTheCurrentPicklist() {
        String objectName = 'Opportunity';
        String fieldName = 'StageName';

        List<Map<String,String>> options = CRLP_RollupUI_SVC.getFilterRuleConstantPicklistOptions(objectName, fieldName);
        List<PicklistEntry> picklistValues = Schema.getGlobalDescribe().get('Opportunity').getDescribe().fields.getMap().get('StageName').getDescribe().getPicklistValues();

        System.assertEquals(picklistValues.size(), options.size());
    }

    /*********************************************************************************************************
    * @description Tests getting the deployment status with invalid params throws an exception
    */
    @isTest
    public static void getInvalidDeploymentIdThrowsAnException() {
        mockRollupCMTValues();

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
    }

    /*********************************************************************************************************
    * @description Tests getting the deployment status with a valid id returns the json response
    */
    @isTest
    public static void getValidDeploymentReturnsJsonResponse() {
        mockRollupCMTValues();

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

    /*********************************************************************************************************
    * @description Verifies that setupRollupGrid() properly identifies user as System Admin
    */
    @isTest
    public static void shouldIdentifyUserAsSystemAdmin() {
        User sysAdmin = UTIL_UnitTestData_TEST.createUser(UTIL_Profile.SYSTEM_ADMINISTRATOR);

        System.runAs(sysAdmin) {
            CRLP_RollupUI_SVC.RollupGridModel model =
                (CRLP_RollupUI_SVC.RollupGridModel) JSON.deserialize(CRLP_RollupUI_SVC.setupRollupGrid(), CRLP_RollupUI_SVC.RollupGridModel.class);

            System.assertEquals(true, model.isSystemAdminUser, 'User should be identified as System Administrator');
        }
    }

    /*********************************************************************************************************
    * @description Verifies that setupRollupGrid() fails if the user is not an admin
    */
    @isTest
    private static void setupRollupGridShouldFailForNonAdmin() {
        // When
        AuraHandledException auraException;
        System.runAs(standardUser) {
            try {
                CRLP_RollupUI_SVC.setupRollupGrid();
            } catch (AuraHandledException ex) {
                auraException = ex;
            }
        }
        // Then
        System.assert(auraException != null, 'An AuraHandledException should throw if the user is not an admin.');
        System.assertEquals(Label.stgEditPermissionError, auraException.getMessage(), 'The aura handled exception ' +
                'thrown should be an insufficient privileges error.');
    }

    /*********************************************************************************************************
    * @description Verifies that getRollupDefinitions() fails if the user is not an admin
    */
    @isTest
    private static void getRollupDefinitionsShouldFailForNonAdmin() {
        // When
        AuraHandledException auraException;
        System.runAs(standardUser) {
            try {
                CRLP_RollupUI_SVC.getRollupDefinitions();
            } catch (AuraHandledException ex) {
                auraException = ex;
            }
        }
        // Then
        System.assert(auraException != null, 'An AuraHandledException should throw if the user is not an admin.');
        System.assertEquals(Label.stgEditPermissionError, auraException.getMessage(), 'The aura handled exception ' +
                'thrown should be an insufficient privileges error.');
    }

    /*********************************************************************************************************
    * @description Verifies that getFilterGroupDefinitions() fails if the user is not an admin
    */
    @isTest
    private static void getFilterGroupDefinitionsShouldFailForNonAdmin() {
        // When
        AuraHandledException auraException;
        System.runAs(standardUser) {
            try {
                CRLP_RollupUI_SVC.getFilterGroupDefinitions();
            } catch (AuraHandledException ex) {
                auraException = ex;
            }
        }
        // Then
        System.assert(auraException != null, 'An AuraHandledException should throw if the user is not an admin.');
        System.assertEquals(Label.stgEditPermissionError, auraException.getMessage(), 'The aura handled exception ' +
                'thrown should be an insufficient privileges error.');
    }

    /*********************************************************************************************************
    * @description Verifies that setupRollupDetail() fails if the user is not an admin
    */
    @isTest
    private static void setupRollupDetailShouldFailForNonAdmin() {
        // When
        AuraHandledException auraException;
        System.runAs(standardUser) {
            try {
                CRLP_RollupUI_SVC.setupRollupDetail(null, null, null);
            } catch (AuraHandledException ex) {
                auraException = ex;
            }
        }
        // Then
        System.assert(auraException != null, 'An AuraHandledException should throw if the user is not an admin.');
        System.assertEquals(Label.stgEditPermissionError, auraException.getMessage(), 'The aura handled exception ' +
                'thrown should be an insufficient privileges error.');
    }

    /*********************************************************************************************************
    * @description Verifies that setupFilterGroupDetail() fails if the user is not an admin
    */
    @isTest
    private static void setupFilterGroupDetailShouldFailForNonAdmin() {
        // When
        AuraHandledException auraException;
        System.runAs(standardUser) {
            try {
                CRLP_RollupUI_SVC.setupFilterGroupDetail(null, null);
            } catch (AuraHandledException ex) {
                auraException = ex;
            }
        }
        // Then
        System.assert(auraException != null, 'An AuraHandledException should throw if the user is not an admin.');
        System.assertEquals(Label.stgEditPermissionError, auraException.getMessage(), 'The aura handled exception ' +
                'thrown should be an insufficient privileges error.');
    }

    /*********************************************************************************************************
    * @description Verifies that saveRollup() fails if the user is not an admin
    */
    @isTest
    private static void saveRollupShouldFailForNonAdmin() {
        // When
        AuraHandledException auraException;
        System.runAs(standardUser) {
            try {
                CRLP_RollupUI_SVC.saveRollup(null);
            } catch (AuraHandledException ex) {
                auraException = ex;
            }
        }
        // Then
        System.assert(auraException != null, 'An AuraHandledException should throw if the user is not an admin.');
        System.assertEquals(Label.stgEditPermissionError, auraException.getMessage(), 'The aura handled exception ' +
                'thrown should be an insufficient privileges error.');
    }

    /*********************************************************************************************************
    * @description Verifies that saveFilterGroupAndRules() fails if the user is not an admin
    */
    @isTest
    private static void saveFilterGroupAndRulesShouldFailForNonAdmin() {
        // When
        AuraHandledException auraException;
        System.runAs(standardUser) {
            try {
                CRLP_RollupUI_SVC.saveFilterGroupAndRules(null);
            } catch (AuraHandledException ex) {
                auraException = ex;
            }
        }
        // Then
        System.assert(auraException != null, 'An AuraHandledException should throw if the user is not an admin.');
        System.assertEquals(Label.stgEditPermissionError, auraException.getMessage(), 'The aura handled exception ' +
                'thrown should be an insufficient privileges error.');
    }

    /*********************************************************************************************************
    * @description Verifies that getDeploymentStatus() fails if the user is not an admin
    */
    @isTest
    private static void getDeploymentStatusShouldFailForNonAdmin() {
        // When
        AuraHandledException auraException;
        System.runAs(standardUser) {
            try {
                CRLP_RollupUI_SVC.getDeploymentStatus(null, null, null, null);
            } catch (AuraHandledException ex) {
                auraException = ex;
            }
        }
        // Then
        System.assert(auraException != null, 'An AuraHandledException should throw if the user is not an admin.');
        System.assertEquals(Label.stgEditPermissionError, auraException.getMessage(), 'The aura handled exception ' +
                'thrown should be an insufficient privileges error.');
    }

    /*********************************************************************************************************
    * @description Verifies that getFilterRuleConstantPicklistOptions() fails if the user is not an admin
    */
    @isTest
    private static void getFilterRuleConstantPicklistOptionsShouldFailForNonAdmin() {
        // When
        AuraHandledException auraException;
        System.runAs(standardUser) {
            try {
                CRLP_RollupUI_SVC.getFilterRuleConstantPicklistOptions(null, null);
            } catch (AuraHandledException ex) {
                auraException = ex;
            }
        }
        // Then
        System.assert(auraException != null, 'An AuraHandledException should throw if the user is not an admin.');
        System.assertEquals(Label.stgEditPermissionError, auraException.getMessage(), 'The aura handled exception ' +
                'thrown should be an insufficient privileges error.');
    }

    /********************************************************************************************************
    * Helper Functions
    */

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