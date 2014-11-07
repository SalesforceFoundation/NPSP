/*
Copyright (c) 2014 salesforce.com foundation, Inc.
All rights reserved.

Redistribution and use in source and binary forms, with or without modification, 
are permitted provided that the following conditions are met:

    * Redistributions of source code must retain the above copyright notice, 
    this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright notice, 
    this list of conditions and the following disclaimer in the documentation 
    and/or other materials provided with the distribution.
    * Neither the name of the salesforce.com foundation. nor the names of its contributors 
    may be used to endorse or promote products derived from this software 
    without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND 
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED 
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. 
IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, 
INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, 
BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, 
DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF 
LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE 
OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED 
OF THE POSSIBILITY OF SUCH DAMAGE.

*/
/**
* @author Salesforce Foundation
* @date 01/13/2014
* @description test code for all of Settings
*/
@isTest
public with sharing class STG_SettingsManager_TEST {

    // if you only want to run one test in this class, fill in its name here.
    // if you want to run all tests, then use '*'
    private static string strTestOnly = '*';
    
    public static testMethod void testSettingsManager() {
        if (strTestOnly != '*' && strTestOnly != 'testSettingsManager') return;
        STG_SettingsManager_CTRL ctrl = new STG_SettingsManager_CTRL(); 
        system.assertEquals('idPanelHome', STG_SettingsManager_CTRL.idPanelCurrent);
        system.assertEquals(null, ctrl.setPanelCurrent());
    }
    
    public static testMethod void testSetTriggerSchedConfig() {
        if (strTestOnly != '*' && strTestOnly != 'testSetTriggerSchedConfig') return;
        STG_SettingsManager_CTRL ctrl = new STG_SettingsManager_CTRL(); 
        
        Test.startTest();
        ctrl.setTriggerSchedConfig();
        Test.stopTest();
        
        List<Schedulable__c> scheduledJobs = [select Class_Name__c from Schedulable__c];
        System.assertEquals(6, scheduledJobs.size());
        
        List<CronTrigger> masterJobs = [select Id, CronJobDetail.Id from CronTrigger where CronJobDetail.Name IN 
        :UTIL_MasterSchedulableHelper.scheduledJobs and CronJobDetail.JobType = '7'];
        System.assertEquals(3, masterJobs.size());
    }
     
    public static testMethod void testDataBoundMultiSelect() {
        if (strTestOnly != '*' && strTestOnly != 'testDataBoundMultiSelect') return;
        STG_DataBoundMultiSelect_CTRL ctrl = new STG_DataBoundMultiSelect_CTRL();
        Contact con = new Contact();
        con.npo02__Naming_Exclusions__c = 'a;b;c';
        ctrl.sobjBinding = con;
        ctrl.strField = 'npo02__Naming_Exclusions__c';
        system.assertNotEquals(null, ctrl.listStrValues);
        system.assertEquals(3, ctrl.listStrValues.size());
        system.assertEquals('a;b;c', ctrl.strValues);
        list<string> listStr = new list<string>{'x', 'y', 'z'};
        ctrl.listStrValues = listStr;
        system.assertEquals('x;y;z', ctrl.strValues);        
    }

    public static testMethod void testPanel() {
        if (strTestOnly != '*' && strTestOnly != 'testPanel') return;
        STG_Panel ctrl = new STG_Panel();
        system.assertEquals(null, ctrl.idPanel());
        ctrl.isEditMode = true;
        system.assertEquals(true, ctrl.isEditMode);
        system.assertEquals(false, ctrl.isReadOnlyMode);
        system.assertNotEquals(null, STG_Panel.stgService);
        system.assertEquals(null, ctrl.saveSettings());
        system.assertEquals(false, ctrl.isEditMode);
        system.assertEquals(null, ctrl.editSettings());
        system.assertEquals(true, ctrl.isEditMode);
        system.assertEquals(null, ctrl.cancelEdit());
        system.assertEquals(false, ctrl.isEditMode);
        system.assertEquals(3, STG_Panel.listSOAccountModels.size());
        system.assertNotEquals(null, STG_Panel.listSOContactRoles);
        system.assertNotEquals(null, STG_Panel.listSOHHRules);
        system.assertNotEquals(null, STG_Panel.listSOContactRecTypes);
        system.assertNotEquals(null, STG_Panel.listSOAccountRecTypeIds);
        system.assertNotEquals(null, STG_Panel.listSOOppRecTypes);
        system.assertNotEquals(null, STG_Panel.listSOOppRecTypesIds);
        system.assertNotEquals(null, STG_Panel.listSOOppContactRoles);
        system.assertNotEquals(null, STG_Panel.listSOOppTypes);
        system.assertNotEquals(null, STG_Panel.listSORelTypes);
        system.assertNotEquals(null, STG_Panel.listSOCampaignTypes);
        system.assertNotEquals(null, STG_Panel.listSOMailingReportIds);
        string str = STG_Panel.strHHAccountRecordTypeLabel;
        string str2 = STG_Panel.strOneToOneRecordTypeLabel;        
    }
    
    public static testMethod void testSettingsService() {
        if (strTestOnly != '*' && strTestOnly != 'testSettingsService') return;
    	STG_SettingsService svc = STG_SettingsService.stgService;
    	system.assertNotEquals(null, svc);
    	system.assertNotEquals(null, svc.stgCon);
        system.assertNotEquals(null, svc.stgHH);
        system.assertNotEquals(null, svc.stgRD);
        system.assertNotEquals(null, svc.stgRel);
        system.assertNotEquals(null, svc.stgAffl);
        system.assertNotEquals(null, svc.stgBDE);
        system.assertNotEquals(null, svc.mapRDCustomField);
        system.assertNotEquals(null, svc.listRDCustomInstallment);
        system.assertNotEquals(null, svc.listRDCustomFieldMapping);
        system.assertNotEquals(null, svc.listPMTFieldMapping);
        svc.saveAll();
    }
    
    public static testMethod void testPanelAffl() {
        if (strTestOnly != '*' && strTestOnly != 'testPanelAffl') return;
    	STG_PanelAffiliations_CTRL panel = new STG_PanelAffiliations_CTRL();
    	system.assertEquals('idPanelAffl', panel.idPanel());
    	STG_Panel.stgService.stgAffl.npe5__Automatic_Affiliation_Creation_Turned_On__c = true;
    	panel.saveSettings();
    	system.assertEquals(true, UTIL_CustomSettingsFacade.getOrgAffiliationsSettings().npe5__Automatic_Affiliation_Creation_Turned_On__c);
        STG_Panel.stgService.stgAffl.npe5__Automatic_Affiliation_Creation_Turned_On__c = false;
        panel.saveSettings();
        system.assertEquals(false, UTIL_CustomSettingsFacade.getOrgAffiliationsSettings().npe5__Automatic_Affiliation_Creation_Turned_On__c);
    }

    public static testMethod void testPanelAllo() {
        if (strTestOnly != '*' && strTestOnly != 'testPanelAllo') return;
        STG_PanelAllocations_CTRL panel = new STG_PanelAllocations_CTRL();
        system.assertEquals('idPanelAllocations', panel.idPanel());
        STG_Panel.stgService.stgAllo.Default_Allocations_Enabled__c = true;
        //this call creates a General fund when one doesn't exist
        panel.enableDefaultAllocations();
        //set the default accounting unit. this is normally selected automatically through the picklist in the UI.
        STG_Panel.stgService.stgAllo.Default__c = STG_PanelAllocations_CTRL.listSOGeneralAccountingUnitIds[0].getValue();
        panel.saveSettings();
        system.assertEquals(true, Allocations_Settings__c.getOrgDefaults().Default_Allocations_Enabled__c, 'Settings should save successfully.');
        system.assertNotEquals(null,Allocations_Settings__c.getOrgDefaults().Default__c, 'Default should be filled with the Id of the created General Accounting Unit.');
        STG_Panel.stgService.stgAllo.Default_Allocations_Enabled__c = false;
        panel.saveSettings();
        system.assertEquals(false, Allocations_Settings__c.getOrgDefaults().Default_Allocations_Enabled__c);
    }

    public static testMethod void testPanelBDE() {
        if (strTestOnly != '*' && strTestOnly != 'testPanelBDE') return;
        STG_PanelBDE_CTRL panel = new STG_PanelBDE_CTRL();
        system.assertEquals('idPanelBDE', panel.idPanel());
        STG_Panel.stgService.stgBDE.Opportunity_Naming__c = true;
        panel.saveSettings();
        system.assertEquals(true, UTIL_CustomSettingsFacade.getOrgBDESettings().Opportunity_Naming__c);
        STG_Panel.stgService.stgBDE.Opportunity_Naming__c = false;
        panel.saveSettings();
        system.assertEquals(false, UTIL_CustomSettingsFacade.getOrgBDESettings().Opportunity_Naming__c);
    }

    public static testMethod void testPanelContactRoles() {
        if (strTestOnly != '*' && strTestOnly != 'testPanelContactRoles') return;
        STG_PanelContactRoles_CTRL panel = new STG_PanelContactRoles_CTRL();
        system.assertEquals('idPanelConRoles', panel.idPanel());
        STG_Panel.stgService.stgCon.npe01__Enable_Opportunity_Contact_Role_Trigger__c = true;
        panel.saveSettings();
        system.assertEquals(true, UTIL_CustomSettingsFacade.getOrgContactsSettings().npe01__Enable_Opportunity_Contact_Role_Trigger__c);
        STG_Panel.stgService.stgCon.npe01__Enable_Opportunity_Contact_Role_Trigger__c = false;
        panel.saveSettings();
        system.assertEquals(false, UTIL_CustomSettingsFacade.getOrgContactsSettings().npe01__Enable_Opportunity_Contact_Role_Trigger__c);
    }

    public static testMethod void testPanelContacts() {
        if (strTestOnly != '*' && strTestOnly != 'testPanelContacts') return;
        STG_PanelContacts_CTRL panel = new STG_PanelContacts_CTRL();
        system.assertEquals('idPanelCon', panel.idPanel());
        STG_Panel.stgService.stgCon.npe01__Account_Processor__c = CAO_Constants.HH_ACCOUNT_PROCESSOR;
        panel.saveSettings();
        system.assertEquals('Household Account', UTIL_CustomSettingsFacade.getOrgContactsSettings().npe01__Account_Processor__c);
        STG_Panel.stgService.stgCon.npe01__Account_Processor__c = CAO_Constants.ONE_TO_ONE_PROCESSOR;
        panel.saveSettings();
        system.assertEquals('One-to-One', UTIL_CustomSettingsFacade.getOrgContactsSettings().npe01__Account_Processor__c);
    }

    public static testMethod void testPanelHouseholds() {
        if (strTestOnly != '*' && strTestOnly != 'testPanelHouseholds') return;
        STG_PanelHouseholds_CTRL panel = new STG_PanelHouseholds_CTRL();
        system.assertEquals('idPanelHH', panel.idPanel());
        system.assertEquals(false, panel.isRunningBatch);
        STG_Panel.stgService.stgHH.npo02__Advanced_Household_Naming__c = false;
        panel.saveSettings();
        system.assertEquals(false, UTIL_CustomSettingsFacade.getOrgHouseholdsSettings().npo02__Advanced_Household_Naming__c);        
        panel.activateHouseholdNaming();
        system.assertEquals(true, UTIL_CustomSettingsFacade.getOrgHouseholdsSettings().npo02__Advanced_Household_Naming__c);
    }

    public static testMethod void testPanelLeads() {
        if (strTestOnly != '*' && strTestOnly != 'testPanelLeads') return;
        STG_PanelLeads_CTRL panel = new STG_PanelLeads_CTRL();
        system.assertEquals('idPanelLeads', panel.idPanel());
        STG_Panel.stgService.stgCon.npe01__Default_Opp_on_Convert__c = true;
        panel.saveSettings();
        system.assertEquals(true, UTIL_CustomSettingsFacade.getOrgContactsSettings().npe01__Default_Opp_on_Convert__c);
        STG_Panel.stgService.stgCon.npe01__Default_Opp_on_Convert__c = false;
        panel.saveSettings();
        system.assertEquals(false, UTIL_CustomSettingsFacade.getOrgContactsSettings().npe01__Default_Opp_on_Convert__c);
    }

    public static testMethod void testPanelMembership() {
        if (strTestOnly != '*' && strTestOnly != 'testPanelMembership') return;
        STG_PanelMembership_CTRL panel = new STG_PanelMembership_CTRL();
        system.assertEquals('idPanelMembership', panel.idPanel());
        STG_Panel.stgService.stgHH.npo02__Membership_Grace_Period__c = 10;
        panel.saveSettings();
        system.assertEquals(10, UTIL_CustomSettingsFacade.getOrgHouseholdsSettings().npo02__Membership_Grace_Period__c);        
        STG_Panel.stgService.stgHH.npo02__Membership_Grace_Period__c = 20;
        panel.saveSettings();
        system.assertEquals(20, UTIL_CustomSettingsFacade.getOrgHouseholdsSettings().npo02__Membership_Grace_Period__c);
    }

    public static testMethod void testPanelOppBatch() {
        if (strTestOnly != '*' && strTestOnly != 'testPanelOppBatch') return;
        STG_PanelOppBatch_CTRL panel = new STG_PanelOppBatch_CTRL();
        system.assertEquals('idPanelOppBatch', panel.idPanel());
        system.assertEquals(false, panel.isRunningBatch);
        panel.runBatch();
        system.assertEquals(true, panel.isRunningBatch);
    }

    public static testMethod void testPanelOppRollups() {
        if (strTestOnly != '*' && strTestOnly != 'testPanelOppRollups') return;
        STG_PanelOppRollups_CTRL panel = new STG_PanelOppRollups_CTRL();
        system.assertEquals('idPanelOppRollup', panel.idPanel());
        STG_Panel.stgService.stgHH.npo02__Batch_Size__c = 10;
        panel.saveSettings();
        system.assertEquals(10, UTIL_CustomSettingsFacade.getOrgHouseholdsSettings().npo02__Batch_Size__c);        
        STG_Panel.stgService.stgHH.npo02__Batch_Size__c = 20;
        panel.saveSettings();
        system.assertEquals(20, UTIL_CustomSettingsFacade.getOrgHouseholdsSettings().npo02__Batch_Size__c);
    }

    public static testMethod void testPanelOpps() {
        if (strTestOnly != '*' && strTestOnly != 'testPanelOpps') return;
        STG_PanelOpps_CTRL panel = new STG_PanelOpps_CTRL();
        system.assertEquals('idPanelOpp', panel.idPanel());
        STG_Panel.stgService.stgCon.npe01__Payments_Enabled__c = true;
        panel.saveSettings();
        system.assertEquals(true, UTIL_CustomSettingsFacade.getOrgContactsSettings().npe01__Payments_Enabled__c);
        STG_Panel.stgService.stgCon.npe01__Payments_Enabled__c = false;
        panel.saveSettings();
        system.assertEquals(false, UTIL_CustomSettingsFacade.getOrgContactsSettings().npe01__Payments_Enabled__c);
    }

    public static testMethod void testPanelPaymentMapping() {
        if (strTestOnly != '*' && strTestOnly != 'testPanelPaymentMapping') return;
        STG_PanelPaymentMapping_CTRL panel = new STG_PanelPaymentMapping_CTRL();
        system.assertEquals('idPanelPaymentMapping', panel.idPanel());
        system.assertEquals(false, ApexPages.hasMessages());               
        system.assertNotEquals(null, panel.getSourceFields());
        system.assertNotEquals(null, panel.getTargetFields());
        system.assertEquals(null, panel.newPfm());        
        system.assertNotEquals(null, panel.pfmNew);
        system.assertEquals(true, panel.isEditMode);
        system.assertEquals(null, panel.cancelPfmEdit());
        system.assertEquals(false, panel.isEditMode);
        system.assertEquals(null, panel.newPfm());        
        system.assertNotEquals(null, panel.pfmNew);
        system.assertEquals(true, panel.isEditMode);
        panel.pfmNew.npe01__Opportunity_Field__c = null;        
        panel.pfmNew.npe01__Payment_Field__c = null;
        system.assertEquals(null, panel.savePfm());
        system.assertEquals(true, panel.isEditMode);
        panel.pfmNew.npe01__Opportunity_Field__c = 'Amount';  
        system.assertEquals(null, panel.onSelectSourceField());      
        panel.pfmNew.npe01__Payment_Field__c = 'npe01__Payment_Amount__c';
        system.assertEquals(true, panel.isPfmNewValid);
        system.assertEquals(null, panel.savePfm());
        system.assertEquals(false, panel.isEditMode);
        system.assertNotEquals(null, panel.listPMTFieldMapping);
        system.assertEquals(1, panel.listPMTFieldMapping.size());
        panel.pfmIdDelete = panel.listPMTFieldMapping[0].Id;
        system.assertEquals(null, panel.deletePfm());
        system.assertNotEquals(null, panel.listPMTFieldMapping);
        system.assertEquals(0, panel.listPMTFieldMapping.size());  

        // save a bogus mapping, and verify our check complains
        panel.pfmNew.npe01__Opportunity_Field__c = 'NoExist';        
        panel.pfmNew.npe01__Payment_Field__c = 'NoExist';
        system.assertEquals(true, panel.isPfmNewValid);
        system.assertEquals(null, panel.savePfm());
        system.assertEquals(false, panel.isEditMode);
        system.assertNotEquals(null, panel.listPMTFieldMapping);
        system.assertEquals(1, panel.listPMTFieldMapping.size());
             
    }

    public static testMethod void testPanelRD() {
        if (strTestOnly != '*' && strTestOnly != 'testPanelRD') return;
    	insert new Schedulable__c(Name = 'Recurring Donation Updates', 
            Class_Name__c = 'RD_RecurringDonations_SCHED', Active__c = true, Frequency__c = 'Daily');
        STG_PanelRD_CTRL panel = new STG_PanelRD_CTRL();
        system.assertEquals('idPanelRD', panel.idPanel());
        panel.init();
        system.assertEquals(true, panel.rdSched.Active__c);
        system.assertNotEquals(null, panel.listSORDCloseOptions);
        system.assertNotEquals(null, panel.listSORDCloseOptions);
        STG_Panel.stgService.stgRD.npe03__Opportunity_Forecast_Months__c = 10;
        panel.isRDScheduleDisabled = true;
        system.assertEquals(null, panel.saveSettings());
        system.assertEquals(10, STG_Panel.stgService.stgRD.npe03__Opportunity_Forecast_Months__c);
        system.assertEquals(false, [select Active__c from Schedulable__c
            where Class_Name__c = 'RD_RecurringDonations_SCHED'][0].Active__c);
        STG_Panel.stgService.stgRD.npe03__Opportunity_Forecast_Months__c = 5;
        system.assertEquals(null, panel.saveSettings());
        system.assertEquals(5, STG_Panel.stgService.stgRD.npe03__Opportunity_Forecast_Months__c);
        STG_Panel.stgService.stgRD.npe03__Opportunity_Forecast_Months__c = 15;
        system.assertEquals(null, panel.saveSettings());
        system.assertEquals(15, STG_Panel.stgService.stgRD.npe03__Opportunity_Forecast_Months__c);
    }

    public static testMethod void testPanelRDBatch() {
        if (strTestOnly != '*' && strTestOnly != 'testPanelRDBatch') return;
        STG_PanelRDBatch_CTRL panel = new STG_PanelRDBatch_CTRL();
        system.assertEquals('idPanelRDBatch', panel.idPanel());
        system.assertEquals(false, panel.isRunningBatch);
        panel.runBatch();
        system.assertEquals(true, panel.isRunningBatch);
    }

    public static testMethod void testPanelRDCustomFieldMapping() {
        if (strTestOnly != '*' && strTestOnly != 'testPanelRDCustomFieldMapping') return;
        STG_PanelRDCustomFieldMapping_CTRL panel = new STG_PanelRDCustomFieldMapping_CTRL();
        system.assertEquals('idPanelRDFieldMap', panel.idPanel());
        system.assertEquals(false, ApexPages.hasMessages());               
        system.assertNotEquals(null, STG_PanelRDCustomFieldMapping_CTRL.listSORDFields);
        system.assertNotEquals(null, STG_PanelRDCustomFieldMapping_CTRL.listSOOppFields);
        system.assertEquals(null, panel.newCustomFieldMapping());        
        system.assertNotEquals(null, panel.fmNew);
        system.assertEquals(true, panel.isEditMode);
        system.assertEquals(null, panel.cancelCustomFieldMapping());
        system.assertEquals(false, panel.isEditMode);
        system.assertEquals(null, panel.newCustomFieldMapping());        
        system.assertNotEquals(null, panel.fmNew);
        system.assertEquals(true, panel.isEditMode);
        panel.fmNew.npe03__Recurring_Donation_Field__c = null;        
        panel.fmNew.npe03__Opportunity_Field__c = null;
        system.assertEquals(null, panel.createCustomFieldMapping());
        system.assertEquals(true, panel.isEditMode);
        panel.fmNew.npe03__Opportunity_Field__c = 'Amount';  
        panel.fmNew.npe03__Recurring_Donation_Field__c = 'npe03__Amount__c';
        system.assertEquals(null, panel.createCustomFieldMapping());
        system.assertEquals(false, panel.isEditMode);
        system.assertNotEquals(null, panel.listRDCustomFieldMapping);
        system.assertEquals(1, panel.listRDCustomFieldMapping.size());
        panel.fmIdDelete = 'not a valid id';
        system.assertEquals(null, panel.deleteFm());
        panel.fmIdDelete = panel.listRDCustomFieldMapping[0].Id;
        system.assertEquals(null, panel.deleteFm());
        system.assertNotEquals(null, panel.listRDCustomFieldMapping);
        system.assertEquals(0, panel.listRDCustomFieldMapping.size());  
    }

    public static testMethod void testPanelRDCustomInstallment() {
        if (strTestOnly != '*' && strTestOnly != 'testPanelRDCustomInstallment') return;
        STG_PanelRDCustomInstallment_CTRL panel = new STG_PanelRDCustomInstallment_CTRL();
        system.assertEquals('idPanelRDInstPd', panel.idPanel());
        system.assertEquals(false, ApexPages.hasMessages());               
        system.assertNotEquals(null, STG_PanelRDCustomInstallment_CTRL.listSORDCustomPeriod);
        system.assertEquals(null, panel.newCustomInstallment());        
        system.assertNotEquals(null, panel.ciNew);
        system.assertEquals(true, panel.isEditMode);
        system.assertEquals(null, panel.cancelCustomInstallment());
        system.assertEquals(false, panel.isEditMode);
        system.assertEquals(null, panel.newCustomInstallment());        
        system.assertNotEquals(null, panel.ciNew);
        system.assertEquals(true, panel.isEditMode);
        panel.ciNew.Name = null;        
        panel.ciNew.npe03__Value__c = null;        
        panel.ciNew.npe03__Increment__c = null;
        system.assertEquals(null, panel.createCustomInstallment());
        system.assertEquals(true, panel.isEditMode);
        panel.ciNew.Name = 'TestInstallment';        
        panel.ciNew.npe03__Value__c = 10;        
        panel.ciNew.npe03__Increment__c = 'Days';
        system.assertEquals(null, panel.createCustomInstallment());
        system.assertEquals(false, panel.isEditMode);
        system.assertNotEquals(null, STG_Panel.stgService.listRDCustomInstallment);
        system.assertEquals(1, STG_Panel.stgService.listRDCustomInstallment.size());
        //system.assertEquals(null, panel.getSettingsFirstTime());
        panel.ciIdDelete = 'not a valid id';
        system.assertEquals(null, panel.deleteCi());
        panel.ciIdDelete = STG_Panel.stgService.listRDCustomInstallment[0].Id;
        system.assertEquals(null, panel.deleteCi());
        system.assertNotEquals(null, STG_Panel.stgService.listRDCustomInstallment);
        system.assertEquals(0, STG_Panel.stgService.listRDCustomInstallment.size());  
    }

    public static testMethod void testPanelRel() { 
        if (strTestOnly != '*' && strTestOnly != 'testPanelRel') return;
        STG_PanelRel_CTRL panel = new STG_PanelRel_CTRL();
        system.assertEquals('idPanelRel', panel.idPanel());
        STG_Panel.stgService.stgRel.npe4__Allow_AutoCreated_Duplicates__c = true;
        panel.saveSettings();
        system.assertEquals(true, UTIL_CustomSettingsFacade.getOrgRelationshipSettings().npe4__Allow_AutoCreated_Duplicates__c);
        STG_Panel.stgService.stgRel.npe4__Allow_AutoCreated_Duplicates__c = false;
        panel.saveSettings();
        system.assertEquals(false, UTIL_CustomSettingsFacade.getOrgRelationshipSettings().npe4__Allow_AutoCreated_Duplicates__c);
        system.assertNotEquals(null, panel.listSOGenderFieldOptions);
    }

    public static testMethod void testPanelRelAuto() {
        if (strTestOnly != '*' && strTestOnly != 'testPanelRelAuto') return;
        STG_PanelRelAuto_CTRL panel = new STG_PanelRelAuto_CTRL();
        system.assertEquals('idPanelRelAuto', panel.idPanel());
        system.assertEquals(false, ApexPages.hasMessages());               
        system.assertEquals(null, panel.newRelAutoCreate());        
        system.assertNotEquals(null, panel.acNew);
        system.assertEquals(true, panel.isEditMode);
        system.assertEquals(null, panel.cancelRelAutoCreate());
        system.assertEquals(false, panel.isEditMode);
        system.assertEquals(null, panel.newRelAutoCreate());        
        system.assertNotEquals(null, panel.acNew);
        system.assertEquals(true, panel.isEditMode);
        panel.acNew.npe4__Object__c = null;        
        panel.acNew.npe4__Field__c = null;        
        panel.acNew.npe4__Relationship_Type__c = null;
        panel.acNew.npe4__Campaign_Types__c = null;
        system.assertEquals(null, panel.createRelAutoCreate());
        system.assertEquals(true, panel.isEditMode);
        panel.acNew.npe4__Object__c = 'Contact';        
        panel.acNew.npe4__Field__c = 'ReportsToId';        
        panel.acNew.npe4__Relationship_Type__c = 'coworker';
        panel.acNew.npe4__Campaign_Types__c = null;
        system.assertEquals(null, panel.createRelAutoCreate());
        system.assertEquals(false, panel.isEditMode);
        system.assertNotEquals(null, panel.listRelAutoCreate);
        system.assertEquals(1, panel.listRelAutoCreate.size());
        panel.acIdDelete = 'not a valid id';
        system.assertEquals(null, panel.deleteAc());
        panel.acIdDelete = panel.listRelAutoCreate[0].Id;
        system.assertEquals(null, panel.deleteAc());
        system.assertNotEquals(null, panel.listRelAutoCreate);
        system.assertEquals(0, panel.listRelAutoCreate.size());  
        panel.acNew.npe4__Object__c = 'Contact';        
        system.assertNotEquals(null, panel.listSOACfield);
        panel.acNew.npe4__Object__c = 'CampaignMember';
        system.assertNotEquals(null, panel.listSOACfield);
    }

    public static testMethod void testPanelRelReciprocal() {
        if (strTestOnly != '*' && strTestOnly != 'testPanelRelReciprocal') return;
        STG_PanelRelReciprocal_CTRL panel = new STG_PanelRelReciprocal_CTRL();
        system.assertEquals('idPanelRelReciprocal', panel.idPanel());
        system.assertEquals(false, ApexPages.hasMessages());               
        system.assertEquals(null, panel.newRelLookup());        
        system.assertNotEquals(null, panel.rlNew);
        system.assertEquals(true, panel.isEditMode);
        system.assertEquals(null, panel.cancelRelLookup());
        system.assertEquals(false, panel.isEditMode);
        system.assertEquals(null, panel.newRelLookup());        
        system.assertNotEquals(null, panel.rlNew);
        system.assertEquals(true, panel.isEditMode);
        panel.rlNew.Name = null;        
        panel.rlNew.npe4__Male__c = null;        
        panel.rlNew.npe4__Female__c = null;        
        panel.rlNew.npe4__Neutral__c = null;        
        system.assertEquals(null, panel.createRelLookup());
        system.assertEquals(true, panel.isEditMode);
        panel.rlNew.Name = 'foo';        
        panel.rlNew.npe4__Male__c = 'bar';        
        panel.rlNew.npe4__Female__c = 'baz';        
        panel.rlNew.npe4__Neutral__c = 'buz';        
        system.assertEquals(null, panel.createRelLookup());
        system.assertEquals(false, panel.isEditMode);
        system.assertNotEquals(null, panel.listRelLookup);
        system.assertEquals(1, panel.listRelLookup.size());
        panel.rlIdDelete = 'not a valid id';
        system.assertEquals(null, panel.deleteRl());
        panel.rlIdDelete = panel.listRelLookup[0].Id;
        system.assertEquals(null, panel.deleteRl());
        system.assertNotEquals(null, panel.listRelLookup);
        system.assertEquals(0, panel.listRelLookup.size());  
    }

    public static testMethod void testPanelUserRollup() {
        if (strTestOnly != '*' && strTestOnly != 'testPanelUserRollup') return;
        STG_PanelUserRollup_CTRL panel = new STG_PanelUserRollup_CTRL();
        system.assertEquals('idPanelUserRollup', panel.idPanel());
        system.assertEquals(false, ApexPages.hasMessages());               
        panel.startBuild();        
        system.assertNotEquals(null, panel.activeUDR);
        system.assertEquals(true, panel.isEditMode);
        system.assertNotEquals(null, panel.getSourceFields());
        system.assertNotEquals(null, panel.getTargetFields());
        system.assertNotEquals(null, panel.getTargetObjects());
        system.assertNotEquals(null, panel.getValidOperators());
        panel.clearForSourceField();
        panel.clearForOperation();
        panel.clearForTargetObject();
        panel.cancel();
        system.assertEquals(false, panel.isEditMode);
        panel.startBuild();        
        system.assertNotEquals(null, panel.activeUDR);
        system.assertEquals(true, panel.isEditMode);
        panel.activeUDR.SourceField = null;         
        panel.activeUDR.Operation = null;        
        panel.activeUDR.TargetObject = null;        
        panel.activeUDR.TargetField = null;    
        system.assertEquals(false, panel.activeUDR.getisValid());    
        panel.activeUDR.save();
        system.assertEquals(true, panel.isEditMode);
        panel.activeUDR.SourceField = 'Amount';        
        panel.activeUDR.Operation = 'SUM';        
        panel.activeUDR.TargetObject = 'Contact';        
        panel.activeUDR.TargetField = 'Description'; 
        system.assertEquals(true, panel.activeUDR.getisValid());    
        system.assertNotEquals(null, panel.getSourceFields());
        system.assertNotEquals(null, panel.getTargetFields());
        system.assertNotEquals(null, panel.getTargetObjects());
        system.assertNotEquals(null, panel.getValidOperators());
        system.assertNotEquals(null, panel.udrList);
        panel.activeUDR.TargetObject = 'Account';        
        system.assertNotEquals(null, panel.getTargetFields());
        panel.activeUDR.TargetObject = 'npo02__Household__c';        
        system.assertNotEquals(null, panel.getTargetFields());
        panel.activeUDR.TargetObject = 'Contact';        
        panel.activeUDR.save();
        system.assertEquals(false, panel.isEditMode);
        system.assertNotEquals(null, panel.udrlist);
        system.assertEquals(1, panel.udrlist.size());
        panel.startBuild();
        system.assertNotEquals(null, panel.getTargetFields());
        panel.activeUDR = panel.udrlist[0];
        panel.activeUDR.deleteMe();
        system.assertNotEquals(null, panel.udrlist);
        system.assertEquals(0, panel.udrlist.size());  
        
    }

    // tests from the original user rollup settings page
    public static testMethod void TEST_userRollupSettings() {
        if (strTestOnly != '*' && strTestOnly != 'TEST_userRollupSettings') return;
        
        Test.setCurrentPageReference(new PageReference('Page.STG_SettingsManager'));
        
        //pass the controller into the extension
        STG_PanelUserRollup_CTRL controller = new STG_PanelUserRollup_CTRL();
  
        //kickoff a new rollup
        controller.startBuild();
        
        //call the major getter methods
        list<SelectOption> oppyList = controller.getSourceFields();
        controller.activeUDR.SourceField = 'Amount';
        
        list<SelectOption> operatorList = controller.getValidOperators();
        system.assert(operatorList.size() == 4);
        
        controller.activeUDR.SourceField = 'CloseDate';
        operatorList = controller.getValidOperators();
        system.assert(operatorList.size() == 2);
        
        controller.activeUDR.Operation = 'MAX';
                
        list<SelectOption> targetObjectList = controller.getTargetObjects();
        system.assertEquals(targetObjectList.size(), 3);
        
        controller.activeUDR.TargetObject = 'Account';
        
        list<SelectOption> targetFieldList = controller.getTargetFields();
               
        //change target object to test other options        
        controller.activeUDR.TargetObject = 'npo02__Household__c';
        targetFieldList = controller.getTargetFields();
        
        controller.activeUDR.TargetObject = 'Contact';
        targetFieldList = controller.getTargetFields();
        controller.activeUDR.TargetField = 'Birthdate';
        STG_PanelUserRollup_CTRL.UDR udr = controller.activeUDR;
        controller.activeUDR.save();
        //load a UDR
        udr.loadMe();        
        
        //run through the loop with a newly inserted UDR
        targetFieldList = controller.getTargetFields();
        
        //existing invalid rollups will cause test failure
        system.assertEquals(controller.activeUDR.getisValid(), true);
        list<STG_PanelUserRollup_CTRL.UDR> udrlist = controller.udrList;
        system.assert(udrList.size() > 0);        
        
        //test clearing the three different lists
        controller.clearForTargetObject();
        system.assert(controller.activeUDR.TargetField == null);
        controller.clearForOperation();
        system.assert(controller.activeUDR.TargetObject != null);
        controller.clearForSourceField();
        system.assert(controller.activeUDR.Operation == null);
        
        controller.cancel();
        system.assertEquals(null, controller.activeUDR);
        
        //generate a new one so we can call its delete sequence
        controller.startBuild();
        //delete it
        controller.activeUDR.deleteMe();
        
        //call the other UDR contructor
        STG_PanelUserRollup_CTRL.UDR u = new STG_PanelUserRollup_CTRL.UDR('', '', '', '', controller);
                
        //insert invalid rollup to test error handling methods
        npo02__User_Rollup_Field_Settings__c badurfs = new npo02__User_Rollup_Field_Settings__c(
        Name = 'Invalid Test Rollup',
        npo02__Target_Field__c = 'InvalidTargetField__test',
        npo02__Source_Field__c = 'InvalidSourceField__test',
        npo02__Object_Name__c = 'Account',
        npo02__Field_Action__c = 'TEST'         
        );        
        insert badurfs;
        
        //exercise household code
        npo02__User_Rollup_Field_Settings__c HHurfs = new npo02__User_Rollup_Field_Settings__c(
        Name = 'Household Test Rollup',
        npo02__Target_Field__c = 'lastoppamount__c',
        npo02__Source_Field__c = 'Amount',
        npo02__Object_Name__c = 'npo02__Household__c',
        npo02__Field_Action__c = 'MAX'         
        );        
        insert HHurfs; 
                
        npo02__User_Rollup_Field_Settings__c badobject = new npo02__User_Rollup_Field_Settings__c(
        Name = 'Invalid Object Rollup',
        npo02__Target_Field__c = 'InvalidTargetField__test',
        npo02__Source_Field__c = 'InvalidSourceField__test',
        npo02__Object_Name__c = 'BadAccount',
        npo02__Field_Action__c = 'TEST'
        );        
        insert badobject;
        
        
    }
    
    public static testMethod void testPanelTDTM() {
        if (strTestOnly != '*' && strTestOnly != 'testPanelTDTM') return;
        STG_PanelTDTM_CTRL panel = new STG_PanelTDTM_CTRL();
        system.assertEquals('idPanelTDTM', panel.idPanel());
        system.assertEquals(false, ApexPages.hasMessages());               
        system.assertEquals(null, panel.newTh());        
        system.assertNotEquals(null, panel.thNew);
        system.assertEquals(true, panel.isEditMode);
        system.assertEquals(null, panel.cancelTh());
        system.assertEquals(false, panel.isEditMode);
        system.assertEquals(null, panel.newTh());        
        system.assertNotEquals(null, panel.thNew);
        system.assertEquals(true, panel.isEditMode);
        panel.thNew.Object__c = null;        
        panel.thNew.Class__c = null;        
        panel.thNew.Trigger_Action__c = null;        
        panel.thNew.Load_Order__c = null;        
        system.assertEquals(null, panel.createTh());
        system.assertEquals(true, panel.isEditMode);
        panel.thNew.Object__c = 'foo';        
        panel.thNew.Class__c = 'bar';        
        panel.thNew.Trigger_Action__c = 'AfterInsert';        
        panel.thNew.Load_Order__c = 1;
        panel.thNew.Active__c = false;        
        system.assertEquals(null, panel.createTh());
        system.assertEquals(false, panel.isEditMode);
        system.assertNotEquals(null, panel.listTH);
        system.assertEquals(1, panel.listTH.size());
        panel.thIdDelete = 'not a valid id';
        system.assertEquals(null, panel.deleteTh());
        panel.thIdDelete = panel.listTH[0].Id;
        system.assertEquals(null, panel.deleteTh());
        system.assertNotEquals(null, panel.listTH);
        system.assertEquals(0, panel.listTH.size());
        system.assertNotEquals(null, panel.listSOTriggerAction); 
    }

    public static testMethod void testPanelErrorLog() {
        if (strTestOnly != '*' && strTestOnly != 'testPanelErrorLog') return;
        STG_PanelErrorLog_CTRL panel = new STG_PanelErrorLog_CTRL();
        system.assertEquals('idPanelErrorLog', panel.idPanel());
        UTIL_SoqlListView_CTRL slv = new UTIL_SoqlListView_CTRL();
        panel.setComponentController(slv);
        slv.pageController = panel;
        system.assertNotEquals(null, panel.getStrSoql());
        system.assertNotEquals(null, panel.getstrFields());
        system.assertNotEquals(null, panel.getstrNameField());
        system.assertNotEquals(null, panel.getstrObjectType());
        system.assertEquals(null, panel.NewItem());
        system.assertNotEquals(null, panel.EditItem(null));
        system.assertNotEquals(null, panel.getslvConsumer());
        system.assertEquals(null, panel.clearErrorLog());
        system.assertNotEquals(null, slv.setCon);
        system.assertNotEquals(null, slv.cRecordsPerPage);
        system.assertEquals(null, slv.showMoreRecordsPerPage());
        system.assertNotEquals(null, slv.NumberOfPages);
        system.assertNotEquals(null, slv.NumberOfItems);
        system.assertNotEquals(null, slv.listSLVObj);
        system.assertNotEquals(null, slv.listSLVObjCurrent);
        slv.strAlphaFilter = '%';
        system.assertNotEquals(null, slv.strAlphaFilter);
        system.assertEquals(null, slv.AlphaFilter());
        system.assertNotEquals(null, slv.listAlphaFilters);
        system.assertNotEquals(null, slv.SortItemField);
        system.assertNotEquals(null, slv.SortItemAsc);
        system.assertEquals(null, slv.SortItem());
        system.assertNotEquals(null, slv.showCheckboxes);
        
    }

    public static testMethod void testPanelHealthCheck() {
        if (strTestOnly != '*' && strTestOnly != 'testPanelHealthCheck') return;
        STG_PanelHealthCheck_CTRL panel = new STG_PanelHealthCheck_CTRL();
        system.assertEquals('idPanelHealthCheck', panel.idPanel());
        system.assertEquals(null, panel.runDetector());
    }
    
}