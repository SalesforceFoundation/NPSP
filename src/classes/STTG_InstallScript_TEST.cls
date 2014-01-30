@isTest
public with sharing class STTG_InstallScript_TEST {

    // if you only want to run one test in this class, fill in its name here.
    // if you want to run all tests, then use '*'
    private static string strTestOnly = '*';
    
    /** to verify no exception is thrown if the custom settings don't exist **/
    public testmethod static void runScriptNoCustomSettings() {
        if (strTestOnly != '*' && strTestOnly != 'runScriptNoCustomSettings') return;
               
        //Don't create NPSP custom settings
        
        Test.testInstall(new STTG_InstallScript(), null);
        
        List<Trigger_Handler__c> afterScriptConfig = [select Active__c, Asynchronous__c, Class__c, Load_Order__c, 
            Object__c, Trigger_Action__c from Trigger_Handler__c];
        
        List<Trigger_Handler__c> defaultConfig = TDTM_DefaultConfig.getDefaultRecords();
        
        assertTriggerHandlersEqual(afterScriptConfig, defaultConfig);
    }
    
    /** If it's the first time we install Cumulus and there was no custom DISABLE flag enabled **/
    public testmethod static void runScriptNoCustomConfigOnInstall() {
        if (strTestOnly != '*' && strTestOnly != 'runScriptNoCustomConfigOnInstall') return;
         
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
    
    /** If it's the first time we install Cumulus and all the custom DISABLE flag were enabled **/
    public testmethod static void runScriptCustomConfigOnInstallAllFlags() {
        if (strTestOnly != '*' && strTestOnly != 'runScriptCustomConfigOnInstallAllFlags') return;
    	
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
    
     /** If it's the first time we install Cumulus and some the custom DISABLE flag were enabled **/
    public testmethod static void runScriptCustomConfigOnInstallSomeFlags() {
        if (strTestOnly != '*' && strTestOnly != 'runScriptCustomConfigOnInstallSomeFlags') return;
        
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
}