@isTest
public with sharing class STTG_InstallScript_TEST {

    // if you only want to run one test in this class, fill in its name here.
    // if you want to run all tests, then use '*'
    private static string strTestOnly = 'runScriptCustomConfigOnInstall';
    
    /** If it's the first time we install Cumulus and there was no custom flag enabled **/
    public testmethod static void runScriptNoCustomConfigOnInstall() {
        if (strTestOnly != '*' && strTestOnly != 'runScriptNoCustomConfigOnInstall') return;
                
        //Run the script. @TODO: we should be reading the version number from a config file
        Test.testInstall(new STTG_InstallScript(), null);
        
        List<Trigger_Handler__c> afterScriptConfig = [select Active__c, Asynchronous__c, Class__c, Load_Order__c, 
            Object__c, Trigger_Action__c from Trigger_Handler__c];
        afterScriptConfig.sort();
        
        List<Trigger_Handler__c> defaultConfig = TDTM_DefaultConfig.getDefaultRecords();
        defaultConfig.sort();
        
        System.assertEquals(afterScriptConfig.size(), defaultConfig.size());
        for(Integer i = 0; i < defaultConfig.size(); i++) {
        	System.assertEquals(afterScriptConfig[i], defaultConfig[i]);
        }
    }
    
    public testmethod static void runScriptCustomConfigOnInstall() {
        if (strTestOnly != '*' && strTestOnly != 'runScriptCustomConfigOnInstall') return;
    	
    	//Set disable flags (pre-Cumulus config)
    	setNpspFlags();

        //Run the script. @TODO: we should be reading the version number from a config file
        Test.testInstall(new STTG_InstallScript(), null);
        
        //Get the TDTM classes that map the NPSP flags
        List<String> tdtmClasses = TDTM_DefaultConfig.getNpspToCumulusMap().values();
        //Remove empty values
        List<String> tdtmClassesWithValues = new List<String>();
        for(String tdtmClass : tdtmClasses) {
        	if(!String.isBlank(tdtmClass))
        	   tdtmClassesWithValues.add(tdtmClass);
        }
        
        List<Trigger_Handler__c> afterScriptConfig = [select Active__c, Asynchronous__c, Class__c, Load_Order__c, 
            Object__c, Trigger_Action__c from Trigger_Handler__c where Class__c IN :tdtmClasses];
        
        System.assertEquals(tdtmClassesWithValues.size(), afterScriptConfig.size());
        
        //Verify that the TDTM flags have been deactivated (since all the NPSP disable flags were on)     
        for(Trigger_Handler__c handler : afterScriptConfig) {
        	System.debug('****Is class ' + handler.Class__c + ' still active: ' + handler.Active__c);
        	System.assertEquals(false, handler.Active__c);
        }
        
        //Assert old flags have been properly disabled
        assertNpspFlagsDeactivated();
    }
    
    public testmethod static void runScriptNoCustomConfigOnPush() {
        if (strTestOnly != '*' && strTestOnly != 'runScriptNoCustomConfigOnPush') return;
        
        Test.testInstall(new STTG_InstallScript(), new Version(1,0), true);
        
    }
    
    public testmethod static void runScriptCustomConfigOnPush() {
    	if (strTestOnly != '*' && strTestOnly != 'runScriptCustomConfigOnPush') return;
    	
    	Test.testInstall(new STTG_InstallScript(), new Version(1,0), true);
    	
    }
    
    private static void setNpspFlags() {
    	List<SObject> settingsToInsert = new List<SObject>();
        npe01__Contacts_And_Orgs_Settings__c npe01Settings = npe01__Contacts_And_Orgs_Settings__c.getOrgDefaults();
        npe01Settings.npe01__DISABLE_IndividualAccounts_trigger__c = true;
        npe01Settings.npe01__DISABLE_OpportunityAccount_trigger__c = true;
        npe01Settings.npe01__DISABLE_OpportunityContactRoles_trigger__c = true;
        npe01Settings.npe01__DISABLE_OpportunityPayments_trigger__c = true;
        settingsToInsert.add(npe01Settings);
        
        npo02__Households_Settings__c npo02Settings = npo02__Households_Settings__c.getOrgDefaults();
        npo02Settings.npo02__DISABLE_Household_Opportunity_trigger__c = true;
        npo02Settings.npo02__DISABLE_Households_trigger__c = true;
        npo02Settings.npo02__DISABLE_OpportunityRollup_trigger__c = true;
        settingsToInsert.add(npo02Settings);
        
        npe03__Recurring_Donations_Settings__c npe03Settings = npe03__Recurring_Donations_Settings__c.getOrgDefaults();
        npe03Settings.npe03__DISABLE_Donations_trigger__c = true;
        npe03Settings.npe03__DISABLE_RecurringDonations_trigger__c = true;
        settingsToInsert.add(npe03Settings);
        
        npe4__Relationship_Settings__c npe04Settings = npe4__Relationship_Settings__c.getOrgDefaults();
        npe04Settings.npe4__DISABLE_RelationshipCM_trigger__c = true;
        npe04Settings.npe4__DISABLE_RelationshipContacts_trigger__c = true;
        npe04Settings.npe4__DISABLE_Relationships_trigger__c = true;
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