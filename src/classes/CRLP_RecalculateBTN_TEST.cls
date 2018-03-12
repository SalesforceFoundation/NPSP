/*
    Copyright (c) 2018, Salesforce.org
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
* @group Selectors
* @description Unit Test for the Account/Contact Recalculate Rollups button controller
*/
@isTest
private class CRLP_RecalculateBTN_TEST {

    /**
     * @description Validate that a User with no update permissions to the Contact object gets a pageMessage
     * error when the recalculate controller constructor is executed.
     */
    static testMethod void test_nopermissions() {
        // Insert a dummy Contact
        Contact c = UTIL_UnitTestData_TEST.getContact();
        insert c;

        // Find the ReadOnly profile (a Salesforce standard profile) and create a dummy User with that Profile
        Id roProfileId = [SELECT Id FROM Profile WHERE Name = 'Read Only' LIMIT 1].Id;
        User roUser = new User(
                FirstName = 'UNITTEST', LastName = 'UNITTEST', Alias = 'UNITTEST',
                Email = 'UNITTEST@NOWHERE.NET', UserName = 'UNITTEST@NOWHERE.NET',
                ProfileId = roProfileId,  TimeZoneSidKey = 'America/Los_Angeles',
                LocaleSidKey = 'en_US', LanguageLocaleKey = 'en_US',
                EmailEncodingKey = 'ISO-8859-1'
        );

        // Verify that controller detects the User doesn't have update permissions on the Contact object
        Test.startTest();
        System.runAs(roUser) {
            CRLP_RecalculateBTN_CTRL ctlr = new CRLP_RecalculateBTN_CTRL(new ApexPages.StandardController(c));
            System.assertEquals(true, ctlr.hasError, 'The controller constructor should have generated an error ' +
                    'because the Read Only user does not have update permissions to the Contact object');
        }
        Test.stopTest();
    }

    /**
     * @description Simple validation of clicking the button when legacy rollups are enabled.
     */
    static testMethod void test_legacy_rollups() {

        // Ensure that Customizable Rollups are disabled
        UTIL_CustomSettingsFacade.getRollupSettingsForTests(new Customizable_Rollup_Settings__c (
                        Customizable_Rollups_Enabled__c = false
                ));

        // Insert a dummy Contact
        Contact c = new Contact(LastName = 'UNITTEST', FirstName = 'TEST');
        insert c;

        General_Accounting_Unit__c gau = new General_Accounting_Unit__c(Name = 'UNITTEST');
        insert gau;

        Test.startTest();

        CRLP_RecalculateBTN_CTRL ctlr = new CRLP_RecalculateBTN_CTRL(new ApexPages.StandardController(c));
        System.assertEquals(false, ctlr.hasError, 'The controller constructor should have not generated an error');
        ctlr.buttonClick();

        ctlr = new CRLP_RecalculateBTN_CTRL(new ApexPages.StandardController(gau));
        System.assertEquals(false, ctlr.hasError, 'The controller constructor should have not generated an error');
        ctlr.buttonClick();

        Test.stopTest();
        // There's no way to test that an @future method executed other than to look for a change to the record
        // which there won't be here.
    }

    /**
     * @description Simple validation of clicking the button when the new customizable rollups are enabled
     */
    static testMethod void test_new_rollups() {

        // Start by enabling Customizable Rollups (which disables all legacy rollup operations)
        UTIL_CustomSettingsFacade.getRollupSettingsForTests(new Customizable_Rollup_Settings__c(
                        Customizable_Rollups_Enabled__c = true,
                        Rollups_Limit_on_Attached_Opps_for_LDV__c = 200,
                        Rollups_Account_LDV_Batch_Size__c = 200,
                        Rollups_Contact_LDV_Batch_Size__c = 200,
                        Rollups_Soft_Credit_Batch_Size__c = 200,
                        Rollups_Account_Batch_Size__c = 20,
                        Rollups_Contact_Batch_Size__c = 20,
                        Rollups_Allocation_Batch_Size__c = 400
                ));

        // Insert a dummy Contact
        Contact c = new Contact(LastName = 'UNITTEST', FirstName = 'TEST');
        insert c;
        Account a = [SELECT Id FROM Account LIMIT 1];

        General_Accounting_Unit__c gau = new General_Accounting_Unit__c(Name = 'UNITTEST');
        insert gau;

        Test.startTest();
/* TODO Fix This Test
        CRLP_RecalculateBTN_CTRL ctlr = new CRLP_RecalculateBTN_CTRL(new ApexPages.StandardController(c));
        System.assertEquals(false, ctlr.hasError, 'The controller constructor should have not generated an error');
        ctlr.buttonClick();

        ctlr = new CRLP_RecalculateBTN_CTRL(new ApexPages.StandardController(a));
        System.assertEquals(false, ctlr.hasError, 'The controller constructor should have not generated an error');
        ctlr.buttonClick();

        ctlr = new CRLP_RecalculateBTN_CTRL(new ApexPages.StandardController(gau));
        System.assertEquals(false, ctlr.hasError, 'The controller constructor should have not generated an error');
        ctlr.buttonClick();

        Test.stopTest();

        Integer expectedJobCount = 3;
        if (CRLP_Rollup_SVC.hasActiveSoftCreditRollupsForSObject(Contact.SObjectType)) {
            expectedJobCount++;
        }
        if (CRLP_Rollup_SVC.hasActiveSoftCreditRollupsForSObject(Account.SObjectType)) {
            expectedJobCount++;
        }

        // validate that both the standard and the partial soft credit jobs were submitted
        system.assertEquals(expectedJobCount, [SELECT Count() FROM AsyncApexJob],
                expectedJobCount + ' Queueable jobs should been executed');
*/
    }

}