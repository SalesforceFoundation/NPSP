/*
    Copyright (c) 2017, Salesforce.org
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
 * @date 2017
 * @group TDTM
 * @group-content ../../ApexDocContent/TDTM.htm
 * @description Test class for TDTM_Config_API Class and enabling TDTM control for SI's
 *
***/
@isTest
private class TDTM_Config_API_Test {

    /*********************************************************************************************************
    * @description Test that an individual trigger can be disabled in the current code execution context
    */
    @isTest
    static void triggersAreDisabledForSpecificContext() {
        //skip the test if Advancement is installed
        if (ADV_PackageInfo_SVC.useAdv()) return;
        
        TDTM_DefaultConfig.startTestDataInit();
        Test.startTest();

        Contact contactWithAccount = UTIL_UnitTestData_TEST.getContact();
        insert contactWithAccount;
        contactWithAccount = [SELECT AccountId FROM Contact WHERE Id = :contactWithAccount.Id LIMIT 1];
        System.assertNotEquals(null, contactWithAccount.AccountId, 'there should be an account id associated with this new contact');

        // disable the trigger that creates a new Household Account for the Contact
        List<Trigger_Handler__c> handlers = TDTM_Config_API.getCachedRecords();
        for (Trigger_Handler__c th : handlers) {
            if (th.Object__c == 'Contact' && th.Class__c == 'ACCT_IndividualAccounts_TDTM') {
                th.Active__c = false;
            }
        }

        Contact contactWithoutAccount = UTIL_UnitTestData_TEST.getContact();
        insert contactWithoutAccount;
        contactWithoutAccount = [SELECT AccountId FROM Contact WHERE Id = :contactWithoutAccount.Id LIMIT 1];
        System.assertEquals(null, contactWithoutAccount.AccountId, 'there should NOT be an account id associated with this new contact');

        Test.stopTest();
    }

    /*********************************************************************************************************
    * @description Test that an individual trigger can be disabled permanently for a specified Username. 
    * Also tests case-insensitivity of username
    */
    @isTest
    static void triggersAreDisabledForSpecificUser() {
        //skip the test if Advancement is installed
        if (ADV_PackageInfo_SVC.useAdv()) return;

        // disable this one trigger
        List<Trigger_Handler__c> handlers = TDTM_Config_API.getDefaultRecords();
        for (Trigger_Handler__c th : handlers) {
            if (th.Object__c == 'Contact' && th.Class__c == 'ACCT_IndividualAccounts_TDTM') {
                th.Usernames_to_Exclude__c = UserInfo.getUserName().toUpperCase();
            }
        }
        insert handlers;

        Contact contactWithoutAccount = UTIL_UnitTestData_TEST.getContact();
        insert contactWithoutAccount;
        contactWithoutAccount = [SELECT AccountId FROM Contact WHERE Id = :contactWithoutAccount.Id LIMIT 1];
        System.assertEquals(null, contactWithoutAccount.AccountId, 'there should not be an account id associated with this new contact');
    }


    /*******************************************************************************************************
    * @description verify the TDTM Callable Action modifies the TDTM Triggers globally 
    ********************************************************************************************************/
    @IsTest
    private static void triggersAreDisabledForCurrentContext() {
        // skip the test if Advancement is installed
        if (ADV_PackageInfo_SVC.useAdv()) {
            return;
        }

        Integer accountCountBefore = Database.countQuery('SELECT COUNT() FROM Account');
        TDTM_Config_Api.disableAllTriggers();
        
        Contact contactWithoutAccount = UTIL_UnitTestData_TEST.getContact();
        insert contactWithoutAccount;

        Integer accountCountAfter = Database.countQuery('SELECT COUNT() FROM Account');

        System.assertEquals(accountCountBefore, accountCountAfter, 'Account record was not created');
        System.assertEquals(null, contactWithoutAccount.AccountId, 'Contact Triggers were turned off');

    }

    /*******************************************************************************************************
    * @description Insert a new Account and then verify that there are still zero records in the 
        Trigger_Handler__c object
    */
    @IsTest
    private static void testCachedRecordsCreateNoTriggerRecords() {
        // Test the below scenario only if it is not customer org
        // Create a account to trigger the TDTM Triggerhandler
        if (UTIL_Namespace.isCustomerOrg()) {
            return;
        }
        Account acct = UTIL_UnitTestData_TEST.createMultipleTestAccounts(1,null)[0];
        insert acct;
        List<Trigger_Handler__c> handlers = [select id, name from Trigger_Handler__c];
        System.assertEquals(0, handlers.size());    
    }

}