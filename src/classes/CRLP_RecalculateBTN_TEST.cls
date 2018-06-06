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
     * @description Test Setup: Insert a dummy contact and let it create an Account. The Opportunity data has to
     * be created in the actual unit test to allow for the trigger test to run
     */
    @TestSetup
    private static void setupBaseTestData() {

        Contact c = UTIL_UnitTestData_TEST.getContact();
        insert c;

        General_Accounting_Unit__c gau = new General_Accounting_Unit__c(Name = 'UNITTEST');
        insert gau;

        npe03__Recurring_Donation__c rd = new npe03__Recurring_Donation__c();
        rd.Name = 'test';
        rd.npe03__Installments__c = 2;
        rd.npe03__Contact__c = c.Id;
        rd.npe03__Amount__c = 1;
        rd.npe03__Installment_Period__c = system.label.npe03.RecurringDonationInstallmentPeriodYearly;
        rd.npe03__Date_Established__c = date.newinstance(1970,6,12);
        rd.npe03__Schedule_Type__c = system.label.npe03.RecurringDonationMultiplyValue;
        rd.npe03__Open_Ended_Status__c = 'None'; 
        insert rd;
    }

    /**
     * @description Validate that a User with no update permissions to the Contact object gets a pageMessage
     * error when the recalculate controller constructor is executed.
     */
    static testMethod void test_nopermissions() {
        // Retrieve the dummy Contact
        Contact c = [SELECT Id, FirstName, LastName, AccountId FROM Contact LIMIT 1];

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

        // Retrieve the dummy Contact
        Contact c = [SELECT Id, FirstName, LastName, AccountId FROM Contact LIMIT 1];
        // Set a random Total Gift and Soft Credit.
        c.npo02__TotalOppAmount__c = 100;
        c.npo02__Soft_Credit_Total__c = 100;
        update c;
        
        General_Accounting_Unit__c gau = [SELECT Id FROM General_Accounting_Unit__c LIMIT 1];

        npe03__Recurring_Donation__c rd = [SELECT npe03__Paid_Amount__c, (SELECT StageName FROM npe03__Donations__r) FROM npe03__Recurring_Donation__c LIMIT 1];
        rd.npe03__Paid_Amount__c = null;
        rd.npe03__Donations__r[0].StageName = UTIL_UnitTestData_TEST.getClosedWonStage();

        TDTM_TriggerHandler.disableTDTM = true;
        update rd.npe03__Donations__r[0];
        update rd;
        TDTM_TriggerHandler.disableTDTM = false;

        // Confirm that the initial value of the next payment is null.
        rd = [SELECT npe03__Paid_Amount__c FROM npe03__Recurring_Donation__c LIMIT 1];
        System.assert(rd.npe03__Paid_Amount__c == null);

        Test.startTest();

        CRLP_RecalculateBTN_CTRL ctlr = new CRLP_RecalculateBTN_CTRL(new ApexPages.StandardController(c));
        System.assertEquals(false, ctlr.hasError, 'The controller constructor should have not generated an error');
        ctlr.buttonClick();

        ctlr = new CRLP_RecalculateBTN_CTRL(new ApexPages.StandardController(gau));
        System.assertEquals(false, ctlr.hasError, 'The controller constructor should have not generated an error');
        ctlr.buttonClick();

        ctlr = new CRLP_RecalculateBTN_CTRL(new ApexPages.StandardController(rd));
        System.assertEquals(false, ctlr.hasError, 'The controller constructor should have not generated an error');
        ctlr.buttonClick();

        Test.stopTest();

        // Confirm that the legacy rollup logic updates the value of the Total Gift and
        // Soft Credit to a value different than the original value (100);
        c = [SELECT npo02__TotalOppAmount__c, npo02__Soft_Credit_Total__c FROM Contact LIMIT 1];
        System.assert(c.npo02__TotalOppAmount__c != 100);
        System.assert(c.npo02__Soft_Credit_Total__c != 100);

        // Confirm that the legacy rollup logic updates the value of the RD rollup field Paid Amount.
        // to a value different than the original value (null).
        rd = [SELECT npe03__Paid_Amount__c FROM npe03__Recurring_Donation__c LIMIT 1];
        System.assert(rd.npe03__Paid_Amount__c != null);
    }

    /**
     * @description Simple validation of clicking the button when the new customizable rollups are enabled
     */
    static testMethod void test_new_rollups() {

        // Start by enabling Customizable Rollups (which disables all legacy rollup operations)
        UTIL_CustomSettingsFacade.getRollupSettingsForTests(new Customizable_Rollup_Settings__c(
                        Customizable_Rollups_Enabled__c = true,
                        Rollups_Limit_on_Attached_Opps_for_Skew__c = 200,
                        Rollups_Account_SkewMode_Batch_Size__c = 200,
                        Rollups_Contact_SkewMode_Batch_Size__c = 200,
                        Rollups_Contact_Soft_Credit_Batch_Size__c = 200,
                        Rollups_Account_Soft_Credit_Batch_Size__c = 200,
                        Rollups_Account_Batch_Size__c = 20,
                        Rollups_Contact_Batch_Size__c = 20,
                        Rollups_GAU_Batch_Size__c = 400
                ));

        // Retrieve the dummy Contact
        Contact c = [SELECT Id, FirstName, LastName, AccountId, Account.Id FROM Contact LIMIT 1];
        Account a = c.Account;
        General_Accounting_Unit__c gau = [SELECT Id FROM General_Accounting_Unit__c LIMIT 1];
        npe03__Recurring_Donation__c rd = [SELECT Id FROM npe03__Recurring_Donation__c LIMIT 1];

        System.assertEquals(0, [SELECT Count() FROM AsyncApexJob WHERE ApexClass.Name LIKE 'CRLP%'],
                'Zero jobs should be currently scheduled');

        Test.startTest();

        Integer expectedJobCount = 0;

        CRLP_RecalculateBTN_CTRL ctlr = new CRLP_RecalculateBTN_CTRL(new ApexPages.StandardController(c));
        System.assertEquals(false, ctlr.hasError, 'The controller constructor should have not generated an error');

        ctlr.buttonClick();

        expectedJobCount++;
        if (CRLP_Rollup_SVC.hasActivePartialSoftCreditRollupsForSObject(Contact.SObjectType)) {
            expectedJobCount++;
        }
        System.assertEquals(expectedJobCount, [SELECT Count() FROM AsyncApexJob WHERE ApexClass.Name LIKE 'CRLP%'],
                expectedJobCount + ' jobs should been queued');

        ctlr = new CRLP_RecalculateBTN_CTRL(new ApexPages.StandardController(a));
        System.assertEquals(false, ctlr.hasError, 'The controller constructor should have not generated an error');
        ctlr.buttonClick();

        expectedJobCount++;
        if (CRLP_Rollup_SVC.hasActivePartialSoftCreditRollupsForSObject(Account.SObjectType)) {
            expectedJobCount++;
        }
        if (CRLP_Rollup_SVC.hasActiveAccountSoftCreditRollupsForSObject(Account.SObjectType)) {
            expectedJobCount++;
        }
        System.assertEquals(expectedJobCount, [SELECT Count() FROM AsyncApexJob WHERE ApexClass.Name LIKE 'CRLP%'],
                expectedJobCount + ' jobs should been queued');

        ctlr = new CRLP_RecalculateBTN_CTRL(new ApexPages.StandardController(gau));
        System.assertEquals(false, ctlr.hasError, 'The controller constructor should have not generated an error');
        ctlr.buttonClick();
        expectedJobCount++;

        ctlr = new CRLP_RecalculateBTN_CTRL(new ApexPages.StandardController(rd));
        System.assertEquals(false, ctlr.hasError, 'The controller constructor should have not generated an error');
        ctlr.buttonClick();
        expectedJobCount++;

        // validate that the jobs were submitted
        System.assertEquals(expectedJobCount, [SELECT Count() FROM AsyncApexJob WHERE ApexClass.Name LIKE 'CRLP%'],
                expectedJobCount + ' jobs should been queued');

        Test.stopTest();
    }
}
