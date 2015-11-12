/*
    Copyright (c) 2014 Salesforce.org
    All rights reserved.
    
    Redistribution and use in source and binary forms, with or without
    modification, are permitted provided that the following conditions are met:
    
    * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution.
    * Neither the name of the Salesforce.org nor the names of
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
* @date 2014 
* @description test Class which holds test methods for common utilities, 
* such as detecting whether we are in a managed package, and some string helpers.
*/
@isTest
public with sharing class RLLP_OppRollup_TEST2 {

    // if you only want to run one test in this class, fill in its name here.
    // if you want to run all tests, then use '*'
    private static String strTestOnly = '*';
    
    static String giftRecordTypeNameForTests = UTIL_RecordTypes.getRecordTypeNameForGiftsTests('Opportunity');
    
    static testMethod void testOpportunityUtilityErrorHandlingOne2One() {
    	if (strTestOnly != '*' && strTestOnly != 'testOpportunityUtilityErrorHandlingOne2One') return;
        testOpportunityUtilityErrorHandling(CAO_Constants.ONE_TO_ONE_PROCESSOR);
    }
    static testMethod void testOpportunityUtilityErrorHandlingHHAccount() {
    	if (strTestOnly != '*' && strTestOnly != 'testOpportunityUtilityErrorHandlingHHAccount') return;
        testOpportunityUtilityErrorHandling(CAO_Constants.HH_ACCOUNT_PROCESSOR);
    }
    static void testOpportunityUtilityErrorHandling(string strProcessor) {
    	
    	Error_Settings__c errorSettings = UTIL_CustomSettingsFacade.getErrorSettings();
    	errorSettings.Error_Notifications_On__c = false;
		if(!Test.isRunningTest())
		    upsert errorSettings;

        npe01__Contacts_and_Orgs_Settings__c contactSettingsForTests = UTIL_CustomSettingsFacade.getContactsSettingsForTests(
            new npe01__Contacts_and_Orgs_Settings__c (
            npe01__Account_Processor__c = strProcessor,
            npe01__Enable_Opportunity_Contact_Role_Trigger__c = true,
            npe01__Opportunity_Contact_Role_Default_role__c = 'Donor'
        ));

        npo02__Households_Settings__c householdSettingsForTests = UTIL_CustomSettingsFacade.getHouseholdsSettingsForTests(
            new npo02__Households_Settings__c (
            npo02__Household_Rules__c = HH_Households.ALL_PROCESSOR,
            npo02__Always_Rollup_to_Primary_Contact__c = false,
            npo02__Enable_Opp_Rollup_Triggers__c = false,
            npo02__Excluded_Account_Opp_Rectypes__c = null,
            npo02__Excluded_Account_Opp_Types__c = null,
            npo02__Excluded_Contact_Opp_Rectypes__c = null,
            npo02__Excluded_Contact_Opp_Types__c = null,
            npo02__Membership_Record_Types__c = null,
            npo02__Enable_Soft_Credit_Rollups__c = true,
            npo02__Soft_Credit_Roles__c = 'TestOCR',
            npo02__Advanced_Household_Naming__c = false
        ));

        // create & insert contact(s)
        Contact[] TestCons = UTIL_UnitTestData_TEST.CreateMultipleTestContacts(10);
        insert TestCons;
        system.assert(TestCons[0].id != null);

        //create new opp with a missing required field (close date)
        Opportunity[] newOpps = UTIL_UnitTestData_TEST.OppsForContactList (TestCons, null, 
            UTIL_UnitTestData_TEST.getClosedWonStage(), null, 1000 , giftRecordTypeNameForTests ,null);

        Test.startTest();
        List<Database.Saveresult> sr = Database.insert(newOpps, false);
        Test.stopTest();
        
        //Verify no opps were inserted
        Integer oppsInserted = [select Count() from Opportunity];
        System.assertEquals(0, oppsInserted);

        /*Error records don't get created because the first time Database.insert runs all records fail to insert,
        and thus everything gets rolled back. We cannot control the validation failure, as this is controlled by the 
        platform. 
        List<Error__c> errors = [select Error_Type__c, Record_URL__c, Object_Type__c from Error__c];
        system.assertEquals(1, errors.size());
        Error__c ore = errors[0];
        system.assert(ore != null);
        system.assertEquals('Required Field Missing', ore.Error_Type__c);
        system.assert(ore.Record_URL__c.endsWith(TestCons[0].id));
        system.assertEquals('Opportunity', ore.Object_Type__c);*/
    }
}
