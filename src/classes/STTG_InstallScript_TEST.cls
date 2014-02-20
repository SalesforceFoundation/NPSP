@isTest
public with sharing class STTG_InstallScript_TEST {

    // if you only want to run one test in this class, fill in its name here.
    // if you want to run all tests, then use '*'
    private static string strTestOnly = '*';
    
    /** NPSP to TDTM test - to verify no exception is thrown if the custom settings don't exist **/
    public testmethod static void mappingsTest_runScriptNoCustomSettings() {
        if (strTestOnly != '*' && strTestOnly != 'mappingsTest_runScriptNoCustomSettings') return;
               
        //Don't create NPSP custom settings
        
        Test.testInstall(new STTG_InstallScript(), null);
        
        List<Trigger_Handler__c> afterScriptConfig = [select Active__c, Asynchronous__c, Class__c, Load_Order__c, 
            Object__c, Trigger_Action__c from Trigger_Handler__c];
        
        List<Trigger_Handler__c> defaultConfig = TDTM_DefaultConfig.getDefaultRecords();
        
        assertTriggerHandlersEqual(afterScriptConfig, defaultConfig);
    }
    
    /** NPSP to TDTM test - If it's the first time we install Cumulus and there was no custom DISABLE flag enabled **/
    public testmethod static void mappingsTest_runScriptNoCustomConfigOnInstall() {
        if (strTestOnly != '*' && strTestOnly != 'mappingsTest_runScriptNoCustomConfigOnInstall') return;
         
        //Create NPSP custom settings with all disable flags off
        setAllNpspFlags(false);
               
        Test.testInstall(new STTG_InstallScript(), null);
        
        List<Trigger_Handler__c> afterScriptConfig = [select Active__c, Asynchronous__c, Class__c, Load_Order__c, 
            Object__c, Trigger_Action__c from Trigger_Handler__c];
              
        List<Trigger_Handler__c> defaultConfig = TDTM_DefaultConfig.getDefaultRecords();
        
        assertTriggerHandlersEqual(afterScriptConfig, defaultConfig);
    }
    
    private static void assertTriggerHandlersEqual(List<Trigger_Handler__c> afterScriptConfig, List<Trigger_Handler__c> defaultConfig) {
    	afterScriptConfig.sort();
    	defaultConfig.sort();
    	
    	System.assertEquals(afterScriptConfig.size(), defaultConfig.size());
        for(Integer i = 0; i < defaultConfig.size(); i++) {
            System.assertEquals(afterScriptConfig[i].Class__c, defaultConfig[i].Class__c);
            System.assertEquals(afterScriptConfig[i].Load_Order__c, defaultConfig[i].Load_Order__c);
            System.assertEquals(afterScriptConfig[i].Object__c, defaultConfig[i].Object__c);
            System.assertEquals(afterScriptConfig[i].Active__c, defaultConfig[i].Active__c);
            System.assertEquals(afterScriptConfig[i].Asynchronous__c, defaultConfig[i].Asynchronous__c);
            System.assertEquals(afterScriptConfig[i].Trigger_Action__c, defaultConfig[i].Trigger_Action__c);
        }
    }
    
    /** NPSP to TDTM test - If it's the first time we install Cumulus and all the custom DISABLE flag were enabled **/
    public testmethod static void mappingsTest_runScriptCustomConfigOnInstallAllFlags() {
        if (strTestOnly != '*' && strTestOnly != 'mappingsTest_runScriptCustomConfigOnInstallAllFlags') return;
    	
        //Create NPSP custom settings with all disable flags on
    	setAllNpspFlags(true);

        Test.testInstall(new STTG_InstallScript(), null);
        
        //Get the TDTM classes that map to the NPSP flags
        List<String> tdtmClasses = TDTM_DefaultConfig.getNpspToCumulusMap().values();
        //Remove empty values
        List<String> tdtmClassesWithValues = new List<String>();
        for(String tdtmClass : tdtmClasses) {
        	if(!String.isBlank(tdtmClass))
        	   tdtmClassesWithValues.add(tdtmClass);
        }
        
        //Verify that all the TDTM classes have been deactivated (since all the NPSP disable flags were on)
        List<Trigger_Handler__c> afterScriptConfig = [select Active__c, Class__c from Trigger_Handler__c where Class__c IN :tdtmClasses];     
        //The -1 is because there are two NPSP flags (npe01__DISABLE_OpportunityAccount_trigger__c and 
        //npe01__DISABLE_OpportunityContactRoles_trigger__c) that point to the same TDTM class (OPP_OpportunityContactRoles_TDTM)
        System.assertEquals(tdtmClassesWithValues.size() - 1, afterScriptConfig.size());     
        for(Trigger_Handler__c handler : afterScriptConfig) {
        	System.debug('****Is class ' + handler.Class__c + ' still active: ' + handler.Active__c);
        	System.assertEquals(false, handler.Active__c);
        }
        
        //Assert old flags have been properly disabled
        assertNpspFlagsDeactivated();
    }
    
     /** NPSP to TDTM test - If it's the first time we install Cumulus and some the custom DISABLE flag were enabled **/
    public testmethod static void mappingsTest_runScriptCustomConfigOnInstallSomeFlags() {
        if (strTestOnly != '*' && strTestOnly != 'mappingsTest_runScriptCustomConfigOnInstallSomeFlags') return;
        
        //Create NPSP custom settings with some disable flags on
        List<SObject> settingsToInsert = new List<SObject>();
        
        npe01__Contacts_And_Orgs_Settings__c npe01Settings = npe01__Contacts_And_Orgs_Settings__c.getOrgDefaults();
        npe01Settings.npe01__DISABLE_IndividualAccounts_trigger__c = true;
        npe01Settings.npe01__DISABLE_OpportunityAccount_trigger__c = true;
        settingsToInsert.add(npe01Settings);    
        
        npo02__Households_Settings__c npo02Settings = npo02__Households_Settings__c.getOrgDefaults();
        npo02Settings.npo02__DISABLE_Household_Opportunity_trigger__c = true;
        settingsToInsert.add(npo02Settings); 
        insert settingsToInsert;

        Test.testInstall(new STTG_InstallScript(), null);
        
        //Verify that the right TDTM classes have been deactivated
        List<String> mappedTdtmClasses = new String[] {'ACCT_IndividualAccounts_TDTM', 'OPP_OpportunityContactRoles_TDTM', 
                                                               'HH_OppContactRoles_TDTM'};
        List<Trigger_Handler__c> afterScriptConfig = [select Active__c, Class__c from Trigger_Handler__c where Class__c IN :mappedTdtmClasses];
        for(Trigger_Handler__c handler : afterScriptConfig) {
        	System.debug('****Is class ' + handler.Class__c + ' still active: ' + handler.Active__c);
            System.assertEquals(false, handler.Active__c);
        }
        
        //Assert old flags have been properly disabled
        assertNpspFlagsDeactivated();
    }
    
    private static void setAllNpspFlags(Boolean flagValue) {
    	List<SObject> settingsToInsert = new List<SObject>();
        npe01__Contacts_And_Orgs_Settings__c npe01Settings = npe01__Contacts_And_Orgs_Settings__c.getOrgDefaults();
        npe01Settings.npe01__DISABLE_IndividualAccounts_trigger__c = flagValue;
        npe01Settings.npe01__DISABLE_OpportunityAccount_trigger__c = flagValue;
        npe01Settings.npe01__DISABLE_OpportunityContactRoles_trigger__c = flagValue;
        npe01Settings.npe01__DISABLE_OpportunityPayments_trigger__c = flagValue;
        settingsToInsert.add(npe01Settings);
        
        npo02__Households_Settings__c npo02Settings = npo02__Households_Settings__c.getOrgDefaults();
        npo02Settings.npo02__DISABLE_Household_Opportunity_trigger__c = flagValue;
        npo02Settings.npo02__DISABLE_HouseholdAfter_trigger__c = flagValue;
        npo02Settings.npo02__DISABLE_HouseholdBefore_trigger__c = flagValue;
        npo02Settings.npo02__DISABLE_Households_trigger__c = flagValue;
        npo02Settings.npo02__DISABLE_OpportunityRollup_trigger__c = flagValue;
        settingsToInsert.add(npo02Settings);
        
        npe03__Recurring_Donations_Settings__c npe03Settings = npe03__Recurring_Donations_Settings__c.getOrgDefaults();
        npe03Settings.npe03__DISABLE_Donations_trigger__c = flagValue;
        npe03Settings.npe03__DISABLE_RecurringDonations_trigger__c = flagValue;
        settingsToInsert.add(npe03Settings);
        
        npe4__Relationship_Settings__c npe04Settings = npe4__Relationship_Settings__c.getOrgDefaults();
        npe04Settings.npe4__DISABLE_RelationshipCM_trigger__c = flagValue;
        npe04Settings.npe4__DISABLE_RelationshipContacts_trigger__c = flagValue;
        npe04Settings.npe4__DISABLE_Relationships_trigger__c = flagValue;
        settingsToInsert.add(npe04Settings);
        
        insert settingsToInsert;
    }
    
    private static void assertNpspFlagsDeactivated() {
    	npe01__Contacts_And_Orgs_Settings__c npe01Settings = npe01__Contacts_And_Orgs_Settings__c.getOrgDefaults();
        System.assertEquals(false, npe01Settings.npe01__DISABLE_IndividualAccounts_trigger__c);
        System.assertEquals(false, npe01Settings.npe01__DISABLE_OpportunityAccount_trigger__c);
        System.assertEquals(false, npe01Settings.npe01__DISABLE_OpportunityContactRoles_trigger__c);
        System.assertEquals(false, npe01Settings.npe01__DISABLE_OpportunityPayments_trigger__c);
        
        npo02__Households_Settings__c npo02Settings = npo02__Households_Settings__c.getOrgDefaults();
        System.assertEquals(false, npo02Settings.npo02__DISABLE_Household_Opportunity_trigger__c);
        System.assertEquals(false, npo02Settings.npo02__DISABLE_HouseholdAfter_trigger__c);
        System.assertEquals(false, npo02Settings.npo02__DISABLE_HouseholdBefore_trigger__c);
        System.assertEquals(false, npo02Settings.npo02__DISABLE_Households_trigger__c);
        System.assertEquals(false, npo02Settings.npo02__DISABLE_OpportunityRollup_trigger__c);
        
        npe03__Recurring_Donations_Settings__c npe03Settings = npe03__Recurring_Donations_Settings__c.getOrgDefaults();
        System.assertEquals(false, npe03Settings.npe03__DISABLE_Donations_trigger__c);
        System.assertEquals(false, npe03Settings.npe03__DISABLE_RecurringDonations_trigger__c);
        
        npe4__Relationship_Settings__c npe04Settings = npe4__Relationship_Settings__c.getOrgDefaults();
        System.assertEquals(false, npe04Settings.npe4__DISABLE_RelationshipCM_trigger__c);
        System.assertEquals(false, npe04Settings.npe4__DISABLE_RelationshipContacts_trigger__c);
        System.assertEquals(false, npe04Settings.npe4__DISABLE_Relationships_trigger__c);
    }
    
    public static testmethod void defaultSettingsCreated() {
    	if (strTestOnly != '*' && strTestOnly != 'defaultSettingsCreated') return;
        
        //Clear all custom settings
        deleteAllCustomSettings();
                       
        Test.testInstall(new STTG_InstallScript(), null);
        
        npe01__Contacts_And_Orgs_Settings__c npe01Settings = npe01__Contacts_And_Orgs_Settings__c.getOrgDefaults();
        npo02__Households_Settings__c npo02Settings = npo02__Households_Settings__c.getOrgDefaults();
        npe03__Recurring_Donations_Settings__c npe03Settings = npe03__Recurring_Donations_Settings__c.getOrgDefaults();
        npe4__Relationship_Settings__c npe04Settings = npe4__Relationship_Settings__c.getOrgDefaults();
        npe5__Affiliations_Settings__c npe05Settings = npe5__Affiliations_Settings__c.getOrgDefaults(); 
        Error_Settings__c errorSettings = Error_Settings__c.getOrgDefaults();
        
        //If it's a new install we want to set the Household model by default
        System.assertEquals(CAO_Constants.HH_ACCOUNT_PROCESSOR, npe01Settings.npe01__Account_Processor__c);
        System.assertEquals(false, npe01Settings.npe01__Enable_Opportunity_Contact_Role_Trigger__c);
        System.assertEquals(true, npe01Settings.npe01__Payments_Enabled__c);
        
        System.assertEquals(HH_Households.NO_HOUSEHOLDS_PROCESSOR, npo02Settings.npo02__Household_Rules__c);
        System.assertEquals(label.npo02.Household_Member_Contact_Role, npo02Settings.npo02__Household_Member_Contact_Role__c);
        System.assertEquals(false, npo02Settings.npo02__Always_Rollup_to_Primary_Contact__c);
        System.assertEquals(false, npo02Settings.npo02__Enable_Opp_Rollup_Triggers__c);
        System.assertEquals(null, npo02Settings.npo02__Excluded_Account_Opp_Rectypes__c);
        System.assertEquals(null, npo02Settings.npo02__Excluded_Account_Opp_Types__c);
        System.assertEquals(null, npo02Settings.npo02__Excluded_Contact_Opp_Rectypes__c);
        System.assertEquals(null, npo02Settings.npo02__Excluded_Contact_Opp_Types__c);
        System.assertEquals(null, npo02Settings.npo02__Membership_Record_Types__c);
        System.assertEquals(365, npo02Settings.npo02__Rollup_N_Day_Value__c);
        System.assertEquals(30, npo02Settings.npo02__Membership_Grace_Period__c);
        System.assertEquals(false, npo02Settings.npo02__Advanced_Household_Naming__c);
        System.assertEquals(false, npo02Settings.npo02__Async_Household_Naming__c);
        System.assertEquals(UserInfo.getOrganizationId(), npo02Settings.Setupownerid);
        System.assertEquals(25, npo02Settings.npo02__Schedule_Job_Limit__c);
        System.assertEquals(null, npo02Settings.npo02__Household_OCR_Excluded_Recordtypes__c);
        System.assertEquals(null, npo02Settings.npo02__Household_Creation_Excluded_Recordtypes__c);
        System.assertEquals(HH_Households.NO_HOUSEHOLDS_PROCESSOR, npo02Settings.npo02__Household_Rules__c);
        
        System.assertEquals(RD_RecurringDonations.RecurringDonationCloseOptions.Mark_Opportunities_Closed_Lost.name(), npe03Settings.npe03__Open_Opportunity_Behavior__c);
        System.assertEquals(true, npe03Settings.npe03__Add_Campaign_to_All_Opportunites__c);
        System.assertEquals(true, npe03Settings.npe03__Enable_Update_Check__c);
        System.assertEquals(50, npe03Settings.npe03__Maximum_Donations__c);
        System.assertEquals(12, npe03Settings.npe03__Opportunity_Forecast_Months__c);
        System.assertEquals(90, npe03Settings.npe03__Update_Check_Interval__c);
        System.assertEquals([select id from RecordType where sobjecttype = 'Opportunity' limit 1].id, npe03Settings.npe03__Record_Type__c);
        
        System.assertEquals('List Settings', npe04Settings.npe4__Reciprocal_Method__c);
        
        System.assertEquals(true, npe05Settings.npe5__Automatic_Affiliation_Creation_Turned_On__c);
        
        System.assertEquals(true, errorSettings.Store_Errors_On__c);
        System.assertEquals(true, errorSettings.Error_Notifications_On__c);
        System.assertEquals(ERR_Notifier.NotificationOptions.sysAdmins, errorSettings.Error_Notifications_To__c);
    }
    
    public static void deleteAllCustomSettings() {
    	npe01__Contacts_And_Orgs_Settings__c npe01Settings = npe01__Contacts_And_Orgs_Settings__c.getOrgDefaults();
        npo02__Households_Settings__c npo02Settings = npo02__Households_Settings__c.getOrgDefaults();
        npe03__Recurring_Donations_Settings__c npe03Settings = npe03__Recurring_Donations_Settings__c.getOrgDefaults();
        npe4__Relationship_Settings__c npe04Settings = npe4__Relationship_Settings__c.getOrgDefaults();
        npe5__Affiliations_Settings__c npe05Settings = npe5__Affiliations_Settings__c.getOrgDefaults();
        Error_Settings__c errorSettings = Error_Settings__c.getOrgDefaults(); 
        if(npe01Settings.Id != null) delete npe01Settings;               
        if(npo02Settings.Id != null) delete npo02Settings;
        if(npe03Settings.Id != null) delete npe03Settings;
        if(npe04Settings.Id != null) delete npe04Settings;
        if(npe05Settings.Id != null) delete npe05Settings;
        if(errorSettings.Id != null) delete errorSettings;
    }
}