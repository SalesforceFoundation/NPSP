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

public with sharing class STG_PanelHealthCheck_TEST {
    
    /*******************************************************************************************************
    * @description verify that the health check test for verifying no missing payments succeeds when we
    * have an opp with payments.
    */ 
    static testmethod void verifyNoMissingOppPaymentsSuccess() {

        npe01__Contacts_And_Orgs_Settings__c PaymentsSettingsForTests = UTIL_CustomSettingsFacade.getContactsSettingsForTests(
            new npe01__Contacts_And_Orgs_Settings__c (npe01__Payments_Enabled__c= true));
        
        Account acc = new Account(name='my account');
        insert acc;
        Opportunity opp = new Opportunity(Name='my opp', StageName=UTIL_UnitTestData_TEST.getClosedWonStage(), 
            CloseDate=system.Today(), Amount=100, AccountId=acc.Id);
        insert opp;
        system.assertEquals(1, [select count() from npe01__OppPayment__c]);
        
        STG_PanelHealthCheck_CTRL hc = new STG_PanelHealthCheck_CTRL();
        system.assertEquals(0, hc.listDR.size());
        
        Test.startTest();
        hc.verifyNoMissingOppPayments();
        Test.stopTest();
        
        system.assertEquals(1, hc.listDR.size());
        system.assertEquals(STG_PanelHealthCheck_CTRL.statusSuccess, hc.listDR[0].strStatus);
    }

    /*******************************************************************************************************
    * @description verify that the health check test for verifying no missing payments gives a warning when we
    * have an opp without payments.
    */ 
    static testmethod void verifyNoMissingOppPaymentsFail() {

        npe01__Contacts_And_Orgs_Settings__c PaymentsSettingsForTests = UTIL_CustomSettingsFacade.getContactsSettingsForTests(
            new npe01__Contacts_And_Orgs_Settings__c (npe01__Payments_Enabled__c= true));
        
        Account acc = new Account(name='my account');
        insert acc;
        Opportunity opp = new Opportunity(Name='my opp', StageName=UTIL_UnitTestData_TEST.getClosedWonStage(), 
            CloseDate=system.Today(), Amount=100, AccountId=acc.Id);
        insert opp;
        system.assertEquals(1, [select count() from npe01__OppPayment__c]);
        delete [select Id from npe01__OppPayment__c];
        
        STG_PanelHealthCheck_CTRL hc = new STG_PanelHealthCheck_CTRL();
        system.assertEquals(0, hc.listDR.size());
        
        Test.startTest();
        hc.verifyNoMissingOppPayments();
        Test.stopTest();
        
        system.assertEquals(1, hc.listDR.size());
        system.assertEquals(STG_PanelHealthCheck_CTRL.statusWarning, hc.listDR[0].strStatus);
    }


    /*******************************************************************************************************
    * @description verify that the health check test for verifying Level fields exist works
    */ 
    static testmethod void verifyLevelFieldsExist() {

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
        system.assertEquals(0, hc.listDR.size());
        
        Test.startTest();
        hc.verifyLevels();
        Test.stopTest();
        
        system.assertEquals(1, hc.listDR.size());
        system.assertEquals(STG_PanelHealthCheck_CTRL.statusError, hc.listDR[0].strStatus);
    }

    /*******************************************************************************************************
    * @description verify that the health check test for verifying Level source fields are numeric
    */ 
    static testmethod void verifyLevelSourceFieldNumeric() {

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
        system.assertEquals(0, hc.listDR.size());
        
        Test.startTest();
        hc.verifyLevels();
        Test.stopTest();
        
        system.assertEquals(2, hc.listDR.size());
        system.assertEquals(STG_PanelHealthCheck_CTRL.statusError, hc.listDR[0].strStatus);
    }

    /*******************************************************************************************************
    * @description verify that the health check test for verifying OCR settings fails when we have bad values
    */ 
    static testmethod void verifyOCRSettingsCheck() {

        //adding this to verify regression where one role value was contained within another; this should not cause a second health check error
        STG_Panel.stgService.stgHH.npo02__Soft_Credit_Roles__c = 'Matched Donor;foo';

        STG_Panel.stgService.stgCon.npe01__Opportunity_Contact_Role_Default_role__c = 'Donor';
        STG_Panel.stgService.stgCon.Honoree_Opportunity_Contact_Role__c = 'Donor';

        STG_PanelHealthCheck_CTRL hc = new STG_PanelHealthCheck_CTRL();
        system.assertEquals(0, hc.listDR.size());
        
        Test.startTest();
        hc.verifyOppContactRolesSettings();
        Test.stopTest();
        
        system.assertEquals(1, hc.listDR.size());
        //count number of line breaks to ensure only one health check failed
        system.assertEquals(1,  hc.listDR[0].strDetails.countMatches('<br/>'));
        system.assertEquals(STG_PanelHealthCheck_CTRL.statusError, hc.listDR[0].strStatus);
    }

    /*******************************************************************************************************
    * @description verify trigger handler action comparisons work as expected if case & sequence are not an exact match
    */
    static testMethod void verifyTriggerHandlers_succeed() {
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
    static testMethod void verifyTriggerHandlers_fail() {
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
}