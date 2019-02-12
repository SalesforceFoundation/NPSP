/*
    Copyright (c) 2015 Salesforce.org
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
* @date 2015
* @group Settings
* @description tests for the Health Check wizard
*/
@isTest

private with sharing class STG_PanelHealthCheck_TEST {
    
    /*******************************************************************************************************
    * @description verify that the health check test for verifying no missing payments succeeds when we
    * have an opp with payments.
    */ 
    @isTest
    private static void verifyNoMissingOppPaymentsSuccess() {
        UTIL_CustomSettingsFacade.getContactsSettingsForTests(
            new npe01__Contacts_And_Orgs_Settings__c(npe01__Payments_Enabled__c= true));
        
        Account acc = new Account(Name = 'my account');
        insert acc;
        Opportunity opp = buildOpportunity(acc.Id);
        insert opp;
        System.assertEquals(1, [select count() from npe01__OppPayment__c]);
        
        STG_PanelHealthCheck_CTRL hc = new STG_PanelHealthCheck_CTRL();
        System.assertEquals(0, hc.listDR.size());
        
        Test.startTest();
        hc.verifyNoMissingOppPayments();
        Test.stopTest();
        
        System.assertEquals(1, hc.listDR.size());
        System.assertEquals(STG_PanelHealthCheck_CTRL.statusSuccess, hc.listDR[0].strStatus);
    }

    /*******************************************************************************************************
    * @description verify that the health check test for verifying no missing payments gives a warning when we
    * have an opp without payments.
    */ 
    @isTest
    private static void verifyNoMissingOppPaymentsFail() {
        UTIL_CustomSettingsFacade.getContactsSettingsForTests(
            new npe01__Contacts_And_Orgs_Settings__c (npe01__Payments_Enabled__c= true));
        
        Account acc = new Account(Name = 'my account');
        insert acc;
        Opportunity opp = buildOpportunity(acc.Id);
        insert opp;
        System.assertEquals(1, [select count() from npe01__OppPayment__c]);
        delete [select Id from npe01__OppPayment__c];
        
        STG_PanelHealthCheck_CTRL hc = new STG_PanelHealthCheck_CTRL();
        System.assertEquals(0, hc.listDR.size());
        
        Test.startTest();
        hc.verifyNoMissingOppPayments();
        Test.stopTest();
        
        System.assertEquals(1, hc.listDR.size());
        System.assertEquals(STG_PanelHealthCheck_CTRL.statusWarning, hc.listDR[0].strStatus);
    }


    /*******************************************************************************************************
    * @description verify that the health check test for verifying Level fields exist works
    */ 
    @isTest
    private static void verifyLevelFieldsExist() {
        Level__c lvl1 = new Level__c(
            Name = 'new',
            Target__c = 'Contact',
            Source_Field__c = 'npo02__OppsClosedThisYear__c', 
            Level_Field__c = 'Does_not_exist__c', 
            Previous_Level_Field__c = null, 
            Active__c = true, 
            Minimum_Amount__c = 10, 
            Maximum_Amount__c = 100);
        insert lvl1;

        STG_PanelHealthCheck_CTRL hc = new STG_PanelHealthCheck_CTRL();
        System.assertEquals(0, hc.listDR.size());
        
        Test.startTest();
        hc.verifyLevels();
        Test.stopTest();
        
        System.assertEquals(1, hc.listDR.size());
        System.assertEquals(STG_PanelHealthCheck_CTRL.statusError, hc.listDR[0].strStatus);
    }

    /*******************************************************************************************************
    * @description verify that the health check test for verifying Level source fields are numeric
    */ 
    @isTest
    private static void verifyLevelSourceFieldNumeric() {
        Level__c lvl1 = new Level__c(
            Name = 'new',
            Target__c = 'Contact',
            Source_Field__c = 'Name', 
            Level_Field__c = 'Does_not_exist__c', 
            Previous_Level_Field__c = null, 
            Active__c = true, 
            Minimum_Amount__c = 10, 
            Maximum_Amount__c = 100);
        insert lvl1;

        STG_PanelHealthCheck_CTRL hc = new STG_PanelHealthCheck_CTRL();
        System.assertEquals(0, hc.listDR.size());
        
        Test.startTest();
        hc.verifyLevels();
        Test.stopTest();
        
        System.assertEquals(2, hc.listDR.size());
        System.assertEquals(STG_PanelHealthCheck_CTRL.statusError, hc.listDR[0].strStatus);
    }

    /*******************************************************************************************************
    * @description verify that the health check test for verifying OCR settings fails when we have bad values
    */ 
    @isTest
    private static void verifyOCRSettingsCheck() {
        //adding this to verify regression where one role value was contained within another; this should not cause a second health check error
        STG_Panel.stgService.stgHH.npo02__Soft_Credit_Roles__c = 'Matched Donor;foo';

        STG_Panel.stgService.stgCon.npe01__Opportunity_Contact_Role_Default_role__c = 'Donor';
        STG_Panel.stgService.stgCon.Honoree_Opportunity_Contact_Role__c = 'Donor';

        STG_PanelHealthCheck_CTRL hc = new STG_PanelHealthCheck_CTRL();
        System.assertEquals(0, hc.listDR.size());
        
        Test.startTest();
        hc.verifyOppContactRolesSettings();
        Test.stopTest();
        
        System.assertEquals(1, hc.listDR.size());
        //count number of line breaks to ensure only one health check failed
        System.assertEquals(1,  hc.listDR[0].strDetails.countMatches('<br/>'));
        System.assertEquals(STG_PanelHealthCheck_CTRL.statusError, hc.listDR[0].strStatus);
    }

    /*******************************************************************************************************
    * @description verify trigger handler action comparisons work as expected if case & sequence are not an exact match
    */
    @isTest
    private static void verifyTriggerHandlers_succeed() {
        List<Trigger_Handler__c> listHandlersDefault = TDTM_DefaultConfig.getDefaultRecords();
        for (Trigger_Handler__c th : listHandlersDefault) {
            if (th.Trigger_Action__c == 'BeforeUpdate;AfterUpdate') {
                // Change the order of these in the list to verify that the logic ignores sequence & caes
                th.Trigger_Action__c = 'AfterUpdate;Beforeupdate';
                break;
            }
        }
        insert listHandlersDefault;

        Test.startTest();

        STG_PanelHealthCheck_CTRL hc = new STG_PanelHealthCheck_CTRL();
        hc.verifyTriggerHandlers();

        System.assertEquals(STG_PanelHealthCheck_CTRL.statusSuccess, hc.listDR[0].strStatus,
                'The result status should be Success\n' + hc.listDR[0]);
    }

    /*******************************************************************************************************
    * @description verify that the trigger handler check picks up a missing trigger and a load order change
    */
    @isTest
    private static void verifyTriggerHandlers_fail() {
        List<Trigger_Handler__c> listHandlersDefault = TDTM_DefaultConfig.getDefaultRecords();
        listHandlersDefault[1].Load_Order__c = 10;
        insert listHandlersDefault;
        delete listHandlersDefault[0];  // delete one record

        Test.startTest();

        STG_PanelHealthCheck_CTRL hc = new STG_PanelHealthCheck_CTRL();
        hc.verifyTriggerHandlers();

        System.assertEquals(STG_PanelHealthCheck_CTRL.statusWarning, hc.listDR[0].strStatus,
                'The result status should be Warning\n' + hc.listDR[0]);
        System.assertEquals(2, hc.listDR[0].strDetails.countMatches('<li>'),
                'There should be two warning messages generated for this\n' + hc.listDR[0]);
    }

    /*******************************************************************************************************
    * @description In this test scenario, we set a non default Household Record Type in the Contact And Orgs Settings.
    * This should create a Success Detect Result.
    */ 
    @isTest
    private static void test_VerifyAccountModelRecordType_NonDefaultRT_In_SettingsHHRT() {
        //Run the test for the Household Record Type
        verifyAccountModelRecordType_NonDefaultRT_In_Settings(true);
    }

    /*******************************************************************************************************
    * @description In this test scenario, we set a non default One To One Record Type in the Contact And Orgs Settings.
    * This should create a Success Detect Result.
    */
    @isTest
    private static void test_VerifyAccountModelRecordType_NonDefaultRT_In_SettingsOneToOneRT() {
        //Run the test for the One To One Record Type
        verifyAccountModelRecordType_NonDefaultRT_In_Settings(false);
    }

    /*******************************************************************************************************
    * @description method that checks the Non Default Record Type
    * @param parameter to check if we are testing a Household Record type or One To One. 
    * True if it is a household and false if it is One To One
    */
    private static void verifyAccountModelRecordType_NonDefaultRT_In_Settings(Boolean isHouseHold) {
        //Check if the Org has more than 1 Record Type for Account.
        //In case there is only one RecordType, it will be the default, therefore we should not run this test.
        if (UTIL_Describe.getObjectDescribe('Account').getRecordTypeInfos().size() < 2) {
            return;
        }

        Schema.RecordTypeInfo accountNonDefaultRecordTypeInfo;
        //Get the non default Account RecordType for the current user.
        for (Schema.RecordTypeInfo accountRecordTypeInfo : UTIL_Describe.getObjectDescribe('Account').getRecordTypeInfos()) {
            if (accountRecordTypeInfo.isDefaultRecordTypeMapping() == false) {
                accountNonDefaultRecordTypeInfo = accountRecordTypeInfo;
                break;
            }
        }

        //Set the non default Account Record in the Household or One To One Model Custom Settings
        npe01__Contacts_And_Orgs_Settings__c settings;
        if (isHouseHold) {
            settings = UTIL_CustomSettingsFacade.getContactsSettingsForTests(
                new npe01__Contacts_And_Orgs_Settings__c (npe01__HH_Account_RecordTypeID__c = accountNonDefaultRecordTypeInfo.getRecordTypeId())
            );
        } else {
            settings = UTIL_CustomSettingsFacade.getContactsSettingsForTests(
                new npe01__Contacts_And_Orgs_Settings__c (npe01__One_to_One_RecordTypeID__c = accountNonDefaultRecordTypeInfo.getRecordTypeId())
            );
        }

        Test.startTest();
        //Run the Health Check.
        STG_PanelHealthCheck_CTRL panelHealthCheckController = new STG_PanelHealthCheck_CTRL();
        panelHealthCheckController.verifyAccountModelRecordType();
        Test.stopTest();

        //Confirm there is a Success Detect Result
        System.assertEquals(1, panelHealthCheckController.listDR.size(), 'We should have 1 Detect Result');
        System.assertEquals(System.Label.healthLabelAccountDefaultRT, panelHealthCheckController.listDR[0].strName);
        System.assertEquals(STG_PanelHealthCheck_CTRL.statusSuccess, panelHealthCheckController.listDR[0].strStatus);
        System.assertEquals(null, panelHealthCheckController.listDR[0].strDetails);
        System.assertEquals(null, panelHealthCheckController.listDR[0].strSolution);
    }

    /*******************************************************************************************************
    * @description In this test scenario, we set the Default Household Record Type in the Contact And Orgs Settings.
    * This should create a Failed Detect Result.
    */ 
    @isTest
    private static void test_VerifyAccountModelRecordType_DefaultRT_In_SettingsHHRT() {
        //Run the test for the Household Record Type
        verifyAccountModelRecordType_DefaultRT_In_Settings(true);
    }

    /*******************************************************************************************************
    * @description In this test scenario, we set the Default One To One Record Type in the Contact And Orgs Settings.
    * This should create a Failed Detect Result.
    */ 
    @isTest
    private static void test_VerifyAccountModelRecordType_DefaultRT_In_SettingsOneToOneRT() {
        //Run the test for the One To One Record Type
        verifyAccountModelRecordType_DefaultRT_In_Settings(false);
    }

    /*******************************************************************************************************
    * @description method that checks Default Record Type in the Contact And Orgs Settings.
    * @param parameter to check if we are testing a Household Record type or One To One. 
    * True if it is a household and false if it is One To One
    */ 
    private static void verifyAccountModelRecordType_DefaultRT_In_Settings(Boolean isHouseHold) {
        //Get the Default Account RecordType for the current user.
        Schema.RecordTypeInfo accountDefaultRecordTypeInfo;
        for (Schema.RecordTypeInfo accountRecordTypeInfo : UTIL_Describe.getObjectDescribe('Account').getRecordTypeInfos()) {
            if (accountRecordTypeInfo.isDefaultRecordTypeMapping()) {
                accountDefaultRecordTypeInfo = accountRecordTypeInfo;
                break;
            }
        }

        //Set the default Account Record in the Household or One To One Model Custom Settings
        npe01__Contacts_And_Orgs_Settings__c settings;
        if (isHouseHold) {
            settings = UTIL_CustomSettingsFacade.getContactsSettingsForTests(
                new npe01__Contacts_And_Orgs_Settings__c (npe01__HH_Account_RecordTypeID__c = accountDefaultRecordTypeInfo.getRecordTypeId())
            );
        } else {
            settings = UTIL_CustomSettingsFacade.getContactsSettingsForTests(
                new npe01__Contacts_And_Orgs_Settings__c (npe01__One_to_One_RecordTypeID__c = accountDefaultRecordTypeInfo.getRecordTypeId())
            );
        }

        Test.startTest();
        //Run the Health Check.
        STG_PanelHealthCheck_CTRL panelHealthCheckController = new STG_PanelHealthCheck_CTRL();
        panelHealthCheckController.verifyAccountModelRecordType();
        Test.stopTest();

        //Confirm there is a Failed Detect Result
        System.assertEquals(1, panelHealthCheckController.listDR.size(), 'We should have 1 Detect Result');
        System.assertEquals(System.Label.healthLabelAccountDefaultRT, panelHealthCheckController.listDR[0].strName);
        System.assertEquals(STG_PanelHealthCheck_CTRL.statusError, panelHealthCheckController.listDR[0].strStatus);
        System.assertEquals(
            String.format(System.Label.healthDetailsAccountDefaultRTIssue, new List<String>{accountDefaultRecordTypeInfo.getName()}),
            panelHealthCheckController.listDR[0].strDetails
        );
        System.assertEquals(
            System.Label.healthSolutionAccountDefaultRTIssue,
            panelHealthCheckController.listDR[0].strSolution
        );
    }

    /*******************************************************************************************************
    * @description In this test scenario, we set an Invalid value (Opportunity Record type) in the Household Contact And Orgs Settings.
    * In this case, we use a Opportunity Record Type as an invalid value for the Household Record Type.
    * This should create a Failed Detect Result.
    */ 
    @isTest
    private static void test_VerifyAccountModelRecordType_InvalidRT_In_SettingsHHRT() {
        //Run the test for the Household Record Type
        verifyAccountModelRecordType_InvalidRT_In_Settings(true);
    }

    /*******************************************************************************************************
    * @description In this test scenario, we set an Invalid value (Opportunity Record type) in the One To One Contact And Orgs Settings.
    * In this case, we use a Opportunity Record Type as an invalid value for the One to One Record Type.
    * This should create a Failed Detect Result.
    */ 
    @isTest
    private static void test_VerifyAccountModelRecordType_InvalidRT_In_SettingsOneToOneRT() {
        //Run the test for the One To One Record Type
        verifyAccountModelRecordType_InvalidRT_In_Settings(false);
    }

    /*******************************************************************************************************
    * @description method that sets an Invalid value Record Type (Opportunity Record type) in the Contact And Orgs Settings.
    * @param parameter to check if we are testing a Household Record type or One To One. 
    * True if it is a household and false if it is One To One
    */ 
    private static void verifyAccountModelRecordType_InvalidRT_In_Settings(Boolean isHouseHold) {
        //Get a random Opportunity RecordType for the current user.
        Schema.RecordTypeInfo opportunityRecordTypeInfo = UTIL_Describe.getObjectDescribe('Opportunity').getRecordTypeInfos()[0];

        //Set the Opportunity Record Type in the Household or One To One Model Custom Settings.
        //The goal is test an invalid Account Record Type.
        npe01__Contacts_And_Orgs_Settings__c settings;
        if (isHouseHold) {
            settings = UTIL_CustomSettingsFacade.getContactsSettingsForTests(
                new npe01__Contacts_And_Orgs_Settings__c (npe01__HH_Account_RecordTypeID__c = opportunityRecordTypeInfo.getRecordTypeId())
            );
        } else {
            settings = UTIL_CustomSettingsFacade.getContactsSettingsForTests(
                new npe01__Contacts_And_Orgs_Settings__c (npe01__One_to_One_RecordTypeID__c = opportunityRecordTypeInfo.getRecordTypeId())
            );
        }

        Test.startTest();
        //Run the Health Check.
        STG_PanelHealthCheck_CTRL panelHealthCheckController = new STG_PanelHealthCheck_CTRL();
        panelHealthCheckController.verifyAccountModelRecordType();
        Test.stopTest();

        //Confirm there is a Failed Detect Result
        System.assertEquals(1, panelHealthCheckController.listDR.size(), 'We should have 1 Detect Result');
        System.assertEquals(System.Label.healthLabelAccountDefaultRT, panelHealthCheckController.listDR[0].strName);
        System.assertEquals(STG_PanelHealthCheck_CTRL.statusError, panelHealthCheckController.listDR[0].strStatus);
        System.assertEquals(System.Label.healthDetailsAccountDefaultRTInvalid, panelHealthCheckController.listDR[0].strDetails);
        System.assertEquals(System.Label.healthSolutionAccountDefaultRTInvalid, panelHealthCheckController.listDR[0].strSolution);
    }

    /*******************************************************************************************************
    * @description In this test scenario, we set an Invalid ID of Household Record Type in the Contact And Orgs Settings.
    * This should create a Failed Detect Result.
    */ 
    @isTest
    private static void test_VerifyAccountModelRecordType_InvalidIDRT_In_SettingsHHRT() {
        //Run the test for the Household Record Type
        verifyAccountModelRecordType_InvalidIDRT_In_Settings(true);
    }

    /*******************************************************************************************************
    * @description In this test scenario, we set an Invalid ID of One To One Record Type in the Contact And Orgs Settings.
    * This should create a Failed Detect Result.
    */ 
    @isTest
    private static void test_VerifyAccountModelRecordType_InvalidIDRT_In_SettingsOneToOneRT() {
        //Run the test for the One To One Record Type
        verifyAccountModelRecordType_InvalidIDRT_In_Settings(false);
    }

    /*******************************************************************************************************
    * @description method that sets an Invalid ID of Household Household or One To One Record Type in the Contact And Orgs Settings.
    * @param parameter to check if we are testing a Household Record type or One To One. 
    * True if it is a household and false if it is One To One
    */ 
    private static void verifyAccountModelRecordType_InvalidIDRT_In_Settings(Boolean isHouseHold) {
        //Set an invalid Account Record ID in the Household or One To One Model Custom Settings
        npe01__Contacts_And_Orgs_Settings__c settings;
        if (isHouseHold) {
            settings = UTIL_CustomSettingsFacade.getContactsSettingsForTests(
                new npe01__Contacts_And_Orgs_Settings__c (npe01__HH_Account_RecordTypeID__c = 'NOT_AN_ID')
            );

        } else {
            settings = UTIL_CustomSettingsFacade.getContactsSettingsForTests(
                new npe01__Contacts_And_Orgs_Settings__c (npe01__One_to_One_RecordTypeID__c = 'NOT_AN_ID')
            );
        }

        Test.startTest();
        STG_PanelHealthCheck_CTRL panelHealthCheckController = new STG_PanelHealthCheck_CTRL();
        panelHealthCheckController.verifyAccountModelRecordType();
        Test.stopTest();

        //Confirm there is a Failed Detect Result, because of the invalid ID
        System.assertEquals(1, panelHealthCheckController.listDR.size(), 'We should have 1 Detect Result');
        System.assertEquals(STG_PanelHealthCheck_CTRL.statusError, panelHealthCheckController.listDR[0].strStatus);
        System.assertEquals(true, String.isNotBlank(panelHealthCheckController.listDR[0].strDetails), 'A System.Exception should be thrown');
        System.assertEquals(null, panelHealthCheckController.listDR[0].strSolution);
    }

    /*********************************************************************************************************
    @description 
        Test invalid record types settings are displayed on the Health Check run
    verify:
        Each invalid record type setting field has a Defect Result logged
    **********************************************************************************************************/ 
    @isTest
    private static void shouldCreateDefectResultForEachInvalidRecordType() {
        STG_PanelHealthCheck_CTRL healthCheck = new STG_PanelHealthCheck_CTRL();

        STG_Panel.stgService.stgAllo.Excluded_Opp_RecTypes__c = 'InvalidRTId1';
        STG_Panel.stgService.stgCon.npe01__HH_Account_RecordTypeID__c = 'InvalidRTId2';
        STG_Panel.stgService.stgCon.npe01__One_to_One_RecordTypeID__c = 'InvalidRTId3';
        STG_Panel.stgService.stgCon.Opp_RecTypes_Excluded_for_Payments__c = 'InvalidRTId4'; 
        STG_Panel.stgService.stgRD.npe03__Record_Type__c = 'InvalidRTId5'; 
        STG_Panel.stgService.stgHH.npo02__Household_Creation_Excluded_Recordtypes__c = 'InvalidRTId6'; 
        STG_Panel.stgService.stgHH.npo02__Household_OCR_Excluded_Recordtypes__c = 'InvalidRTId7'; 
        STG_Panel.stgService.stgHH.npo02__Excluded_Account_Opp_Rectypes__c = 'InvalidRTId8'; 
        STG_Panel.stgService.stgHH.npo02__Excluded_Contact_Opp_Rectypes__c = 'InvalidRTId9'; 
        STG_Panel.stgService.stgHH.npo02__Membership_Record_Types__c = 'InvalidRTId10';

        healthCheck.verifyRecordTypes();

        System.assertEquals(10, healthCheck.listDR.size(), 'A Detect Result should be created for each invalid record type: ' + healthCheck.listDR);  
    }

    /*********************************************************************************************************
    * @description Verifies success defect result is created when Opportunity has duplicate primary OCRs
    * and "Disable Contact Role Automation" checked and there is no Opportunity with duplicate primary OCRS
    * and "Disable Contact Role Automation" unchecked.
    **********************************************************************************************************/ 
    @isTest
    private static void shouldCreateSuccessDefectResultWhenOppDisableContactRoleAutomationIsChecked() {
        STG_PanelHealthCheck_CTRL healthCheck = new STG_PanelHealthCheck_CTRL();

        Account acc = new Account(Name = 'No Defect Result for Disable Contact Role Automation');
        insert acc;
        Opportunity opp = buildOpportunity(acc.Id);
        opp.DisableContactRoleAutomation__c = true;
        insert opp;
        Contact contact = UTIL_UnitTestData_TEST.getContact();
        insert contact;
        
        List<OpportunityContactRole> primaryOCRs = new List<OpportunityContactRole>();
        for (Integer i = 0; i < 2; i++) {
            primaryOCRs.add(new OpportunityContactRole(
                OpportunityId = opp.Id,
                ContactId = contact.Id,
                IsPrimary = true,
                Role = 'Donor'
            ));
        }
        insert primaryOCRs;

        healthCheck.verifyOppContactRoles();

        System.assertEquals(1, healthCheck.listDR.size(), 'One Detect Result should be created: ' + healthCheck.listDR);  
        System.assertEquals(STG_PanelHealthCheck_CTRL.statusSuccess, healthCheck.listDR[0].strStatus);
        System.assertEquals(System.Label.healthDetailsOCRDupPrimaryValid, healthCheck.listDR[0].strSolution);
    }

    /*********************************************************************************************************
    * @description Verifies error defect result is created when at least one Opportunity exists
    * with duplicate primary OCRs and "Disable Contact Role Automation" unchecked
    **********************************************************************************************************/ 
    @isTest
    private static void shouldCreateErrorDefectResultWhenOppDisableContactRoleAutomationIsUnchecked() {
        STG_PanelHealthCheck_CTRL healthCheck = new STG_PanelHealthCheck_CTRL();

        Account acc = new Account(Name = 'No Defect Result for Disable Contact Role Automation');
        insert acc;
        List<Opportunity> opps = new List<Opportunity>{
            buildOpportunity(acc.Id),
            buildOpportunity(acc.Id)
        };
        opps[1].DisableContactRoleAutomation__c = true;
        insert opps;
        Contact contact = UTIL_UnitTestData_TEST.getContact();
        insert contact;
        
        List<OpportunityContactRole> primaryOCRs = new List<OpportunityContactRole>();
        for (Opportunity opp : opps) {
            for (Integer i = 0; i < 2; i++) {
                primaryOCRs.add(new OpportunityContactRole(
                    OpportunityId = opps[i].Id,
                    ContactId = contact.Id,
                    IsPrimary = true,
                    Role = 'Donor'
                ));
            }
        }
        insert primaryOCRs;

        healthCheck.verifyOppContactRoles();

        System.assertEquals(1, healthCheck.listDR.size(), 'One Detect Result should be created: ' + healthCheck.listDR);  
        System.assertEquals(STG_PanelHealthCheck_CTRL.statusError, healthCheck.listDR[0].strStatus);
        System.assertEquals(System.Label.healthSolutionOCRDupPrimary, healthCheck.listDR[0].strSolution);
    }

    // Helpers
    //////////////

    /*******************************************************************************************************
    * @description Builds a closed won Opportunity
    * @param accountId Account Id
    * @return Opportunity
    ********************************************************************************************************/
    private static Opportunity buildOpportunity(Id accountId) {
        return new Opportunity(
            Name = 'Test Health Check Opp', 
            StageName = UTIL_UnitTestData_TEST.getClosedWonStage(), 
            CloseDate = System.today(), 
            Amount = 100, 
            AccountId = accountId
        );
    }

    /*******************************************************************************************************
    * @description Get the Opportunity with the related OCRs.
    * @param oppId The Id of the Opportunity to load.
    * @return Opportunity. The Opportunity with the related OCRs.
    ********************************************************************************************************/
    private static Opportunity loadOpportunityWithOCRs(Id oppId) {
        return [
            SELECT Name, (
                SELECT OpportunityId, ContactId, IsPrimary, Role
                FROM OpportunityContactRoles
            )
            FROM Opportunity
            WHERE Id = :oppId
        ];
    }

}