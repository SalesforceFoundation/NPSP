/*
    Copyright (c) 2018 Salesforce.org
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
* @group Settings
* @description Unit tests for STG_PanelMultipleTribute_CTRL class
*/
@isTest
private class STG_PanelMultipleTribute_TEST {

    /*********************************************************************************************************
    * @description Tests basic settings page functionality and confirms expected values and errors when ≈
    *              Multiple Tributes Setting is in Single Tribute Mode
    **********************************************************************************************************/
    @isTest
    static void testPanelPageSingleTributeMode() {
        npe01__Contacts_and_Orgs_Settings__c testSettings = OPP_OpportunityContactRolesTribute_TEST.createContactAndOrgSettingsForOCRTributeTests(TBU_MultipleTributesSettingsFacade.TRIBUTE_SINGLE_VAL);

        Test.setCurrentPage(Page.STG_PanelMultipleTribute);

        STG_PanelMultipleTribute_CTRL ctrl = new STG_PanelMultipleTribute_CTRL();

        System.assertEquals('idPanelMultipleTribute', ctrl.idPanel(), 'ctrl.idPanel()');
        System.assertEquals(true, ctrl.isBatchDisabled, 'ctrl.isBatchDisabled');
        System.assertEquals(Label.stgMultipleTributesSingleOpp, ctrl.getMultipleTributesSettingForDisplay(), 'Multiple Tributes Setting For Display()');

        ctrl.runBatch();

        UTIL_UnitTestData_TEST.assertPageHasError(Label.errMultipleTributesBatchInvalid); 
    }

    /*********************************************************************************************************
    * @description Tests basic settings page functionality and confirms expected values and errors when ≈
    *              Multiple Tributes Setting is in Mixed Tribute Mode
    **********************************************************************************************************/ 
    @isTest
    static void testPanelPageMixedTributeMode() {
        npe01__Contacts_and_Orgs_Settings__c testSettings = OPP_OpportunityContactRolesTribute_TEST.createContactAndOrgSettingsForOCRTributeTests(TBU_MultipleTributesSettingsFacade.TRIBUTE_MIXED_VAL);

        Test.setCurrentPage(Page.STG_PanelMultipleTribute);

        STG_PanelMultipleTribute_CTRL ctrl = new STG_PanelMultipleTribute_CTRL();

        System.assertEquals('idPanelMultipleTribute', ctrl.idPanel(), 'ctrl.idPanel()');
        System.assertEquals(false, ctrl.isBatchDisabled, 'ctrl.isBatchDisabled');
        System.assertEquals(Label.stgMultipleTributesFlexible, ctrl.getMultipleTributesSettingForDisplay(), 'Multiple Tributes Setting For Display()');

        ctrl.runBatch();

        UTIL_UnitTestData_TEST.assertPageHasError(Label.errMultipleTributesBatchInvalid); 
    }

    /*********************************************************************************************************
    * @description Tests basic settings page functionality and confirms expected values and behavior when ≈
    *              Multiple Tributes Setting is in Multiple Tribute Mode
    **********************************************************************************************************/ 
    @isTest
    static void testPanelPageMultipleTributeMode() {
        npe01__Contacts_and_Orgs_Settings__c testSettings = OPP_OpportunityContactRolesTribute_TEST.createContactAndOrgSettingsForOCRTributeTests(TBU_MultipleTributesSettingsFacade.TRIBUTE_MULTIPLE_VAL);

        Test.setCurrentPage(Page.STG_PanelMultipleTribute);

        STG_PanelMultipleTribute_CTRL ctrl = new STG_PanelMultipleTribute_CTRL();

        System.assertEquals('idPanelMultipleTribute', ctrl.idPanel(), 'ctrl.idPanel()');
        System.assertEquals(false, ctrl.isBatchDisabled, 'ctrl.isBatchDisabled');
        System.assertEquals(Label.stgMultipleTributesLimited, ctrl.getMultipleTributesSettingForDisplay(), 'Multiple Tributes Setting For Display()');

        //Make sure there is no Tribute record in the org
        List<Tribute__c> tributeList = [Select Id from Tribute__c];
        System.assertEquals(true, tributeList.isEmpty(), 'No Tributes Expected');

        //Create and Insert Opportunity
        Account acc = new Account(Name = 'TestPanelPageMultipleTributeMode');
        insert acc;

        String closeWonStageName = UTIL_UnitTestData_TEST.getClosedWonStage();

        List<Opportunity> oppsToInsert = new List<Opportunity>();
        for (Integer i = 0; i < 10; i++) {
            Opportunity opp = new Opportunity(
                AccountId = acc.Id, 
                StageName = closeWonStageName,
                Name='Donation' + i,
                Amount= i,
                CloseDate = Date.newInstance(2018, 1, 2),
                Honoree_Name__c = 'John Smith' + i,
                Notification_Recipient_Name__c = 'Mark Smith'
            );
            oppsToInsert.add(opp);
        }
        insert oppsToInsert;

        Map<String, Id> honNmToOppIdMap = new Map<String, Id>();

        for (Opportunity opp : oppsToInsert) {
            honNmToOppIdMap.put (opp.Honoree_Name__c, opp.Id);
        }

        Test.startTest();

        // Execute Batch Job
        ctrl.runBatch();

        Test.stopTest();

        //System should create the Tribute record for the Opportunity
        tributeList = [SELECT       Id,
                                    Opportunity__c,
                                    Honoree_Name__c
                       FROM Tribute__c 
                       ORDER BY     Honoree_Name__c ASC];

        System.assertEquals(10, tributeList.size(), '10 Tributes Expected');

        for (Integer i=0; i < 10; i++) {
            System.assertEquals('John Smith' + i, tributeList[i].Honoree_Name__c, 'Honoree Name #' + i);
            System.assertEquals(honNmToOppIdMap.get(tributeList[i].Honoree_Name__c), tributeList[i].Opportunity__c, 'Opportunity Id, #' + i);
        }

        //System should clear the Tribute fields on the Opportunity
        List<Opportunity> oppList = [SELECT     Id 
                                     FROM Opportunity
                                     WHERE      Honoree_Name__c != null OR
                                                Tribute_Type__c != null OR
                                                Honoree_Contact__c != null];
        System.assertEquals(true, oppList.isEmpty(), 'Opps should not have Tribute Info');
    }

    /*********************************************************************************************************
    * @description Confirms list of SelectOptions are returned as possible SelectOption settings.
    **********************************************************************************************************/ 
    @isTest
    static void testPanelPageMultipleTributesOptions() {

        STG_PanelMultipleTribute_CTRL ctrl = new STG_PanelMultipleTribute_CTRL();

        List<SelectOption> selectOptions = ctrl.getMultipleTributesOptions();
        // Confirming at least some items are returned.  Didn't want to code to a specific number in case additional
        // option added later.
        System.assertEquals(true, !selectOptions.isEmpty(), 'Multiple Tributes Options List Size');
    }
}