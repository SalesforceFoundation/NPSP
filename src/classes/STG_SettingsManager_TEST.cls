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

    public static testMethod void testSettingsManager() {
        STG_SettingsManager_CTRL ctrl = new STG_SettingsManager_CTRL(); 
        system.assertEquals('idPanelHome', STG_SettingsManager_CTRL.idPanelCurrent);
        system.assertEquals(null, ctrl.setPanelCurrent());
    }
     
    public static testMethod void testPanel() {
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
    	STG_PanelAffiliations_CTRL panel = new STG_PanelAffiliations_CTRL();
    	system.assertEquals('idPanelAffl', panel.idPanel());
    	STG_Panel.stgService.stgAffl.npe5__Automatic_Affiliation_Creation_Turned_On__c = true;
    	panel.saveSettings();
    	system.assertEquals(true, npe5__Affiliations_Settings__c.getOrgDefaults().npe5__Automatic_Affiliation_Creation_Turned_On__c);
        STG_Panel.stgService.stgAffl.npe5__Automatic_Affiliation_Creation_Turned_On__c = false;
        panel.saveSettings();
        system.assertEquals(false, npe5__Affiliations_Settings__c.getOrgDefaults().npe5__Automatic_Affiliation_Creation_Turned_On__c);
    }

    public static testMethod void testPanelBDE() {
        STG_PanelBDE_CTRL panel = new STG_PanelBDE_CTRL();
        system.assertEquals('idPanelBDE', panel.idPanel());
        STG_Panel.stgService.stgBDE.Opportunity_Naming__c = true;
        panel.saveSettings();
        system.assertEquals(true, Batch_Data_Entry_Settings__c.getOrgDefaults().Opportunity_Naming__c);
        STG_Panel.stgService.stgBDE.Opportunity_Naming__c = false;
        panel.saveSettings();
        system.assertEquals(false, Batch_Data_Entry_Settings__c.getOrgDefaults().Opportunity_Naming__c);
    }

    public static testMethod void testPanelContactRoles() {
        STG_PanelContactRoles_CTRL panel = new STG_PanelContactRoles_CTRL();
        system.assertEquals('idPanelConRoles', panel.idPanel());
        STG_Panel.stgService.stgCon.npe01__Enable_Opportunity_Contact_Role_Trigger__c = true;
        panel.saveSettings();
        system.assertEquals(true, npe01__Contacts_And_Orgs_Settings__c.getOrgDefaults().npe01__Enable_Opportunity_Contact_Role_Trigger__c);
        STG_Panel.stgService.stgCon.npe01__Enable_Opportunity_Contact_Role_Trigger__c = false;
        panel.saveSettings();
        system.assertEquals(false, npe01__Contacts_And_Orgs_Settings__c.getOrgDefaults().npe01__Enable_Opportunity_Contact_Role_Trigger__c);
    }

    public static testMethod void testPanelContacts() {
        STG_PanelContacts_CTRL panel = new STG_PanelContacts_CTRL();
        system.assertEquals('idPanelCon', panel.idPanel());
        STG_Panel.stgService.stgCon.npe01__Account_Processor__c = 'HH Account';
        panel.saveSettings();
        system.assertEquals('HH Account', npe01__Contacts_And_Orgs_Settings__c.getOrgDefaults().npe01__Account_Processor__c);
        STG_Panel.stgService.stgCon.npe01__Account_Processor__c = 'One-to-One';
        panel.saveSettings();
        system.assertEquals('One-to-One', npe01__Contacts_And_Orgs_Settings__c.getOrgDefaults().npe01__Account_Processor__c);
    }

    public static testMethod void testPanelHouseholds() {
        STG_PanelHouseholds_CTRL panel = new STG_PanelHouseholds_CTRL();
        system.assertEquals('idPanelHH', panel.idPanel());
        system.assertEquals(false, panel.isRunningBatch);
        STG_Panel.stgService.stgHH.npo02__Advanced_Household_Naming__c = false;
        panel.saveSettings();
        system.assertEquals(false, npo02__Households_Settings__c.getOrgDefaults().npo02__Advanced_Household_Naming__c);        
        panel.activateHouseholdNaming();
        system.assertEquals(true, npo02__Households_Settings__c.getOrgDefaults().npo02__Advanced_Household_Naming__c);
    }
}