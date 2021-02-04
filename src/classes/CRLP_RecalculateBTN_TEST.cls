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
    private static final TEST_SObjectGateway.RecurringDonationGateway rdGateway = new TEST_SObjectGateway.RecurringDonationGateway();

    /**
     * @description Test Setup: Insert a dummy contact and let it create an Account. The Opportunity data has to
     * be created in the actual unit test to allow for the trigger test to run
     */
    @TestSetup
    private static void setupBaseTestData() {

        Contact c = UTIL_UnitTestData_TEST.getContact();
        insert c;

        insert new General_Accounting_Unit__c(Name = 'UNITTEST');

        insert new TEST_RecurringDonationBuilder()
            .withPlannedInstallments(2)
            .withContact(c.Id)
            .withAmount(1)
            .withInstallmentPeriodYearly()
            .withDateEstablished(Date.newInstance(1970,6,12))
            .withScheduleTypeMultiplyValue()
            .withOpenEndedStatusNone()
            .build();
    }

    /**
     * @description Validate that a User with no update permissions to the Contact object gets a pageMessage
     * error when the recalculate controller constructor is executed.
     */
    @isTest
    private static void test_nopermissions() {
        // Get a user with ReadOnly profile (a Salesforce standard profile)
        User readOnlyUser = UTIL_UnitTestData_TEST.createUserWithoutInsert(UTIL_Profile.PROFILE_READ_ONLY);

        // Verify that controller detects the User doesn't have update permissions on the Contact object
        Test.startTest();
        System.runAs(readOnlyUser) {
            CRLP_RecalculateBTN_CTRL ctlr = new CRLP_RecalculateBTN_CTRL(new ApexPages.StandardController(getContact()));

            System.assertEquals(true, ctlr.hasError, 'The controller constructor should have generated an error ' +
                'because the Read Only user does not have update permissions to the Contact object');
        }
        Test.stopTest();
    }

    /**
     * @description Simple validation of clicking the button when legacy rollups are enabled.
     */
    @isTest
    private static void test_legacy_rollups() {

        // Ensure that Customizable Rollups are disabled
        disableCustomizableRollups();

        Contact c = getContact();
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
        rd = rdGateway.getRecord(rd.Id);
        System.assert(rd.npe03__Paid_Amount__c == null);

        Test.startTest();

        clickRecalculateRollupsFor(c);

        clickRecalculateRollupsFor(gau);

        clickRecalculateRollupsFor(rd);

        Test.stopTest();

        // Confirm that the legacy rollup logic updates the value of the Total Gift and
        // Soft Credit to a value different than the original value (100);
        c = getContact();
        System.assert(c.npo02__TotalOppAmount__c != 100);
        System.assert(c.npo02__Soft_Credit_Total__c != 100);

        // Confirm that the legacy rollup logic updates the value of the RD rollup field Paid Amount.
        // to a value different than the original value (null).
        rd = rdGateway.getRecord(rd.Id);
        System.assert(rd.npe03__Paid_Amount__c != null);
    }

    /**
     * @description Simple validation of clicking the button when the new customizable rollups are enabled
     */
    @isTest
    private static void test_new_rollups() {

        // Start by enabling Customizable Rollups (which disables all legacy rollup operations)
        enableCustomizableRollups();

        Contact c = getContact();
        Account a = c.Account;
        General_Accounting_Unit__c gau = [SELECT Id FROM General_Accounting_Unit__c LIMIT 1];
        npe03__Recurring_Donation__c rd = rdGateway.getRecords()[0];

        Test.startTest();

        Integer expectedJobCount = 0;
        assertCRLPBatchSubmitted(expectedJobCount);

        clickRecalculateRollupsFor(c);

        expectedJobCount++;
        if (CRLP_Rollup_SVC.hasActivePartialSoftCreditRollupsForSObject(Contact.SObjectType)) {
            expectedJobCount++;
        }        
        assertCRLPBatchSubmitted(expectedJobCount);

        clickRecalculateRollupsFor(a);

        expectedJobCount++;
        if (CRLP_Rollup_SVC.hasActivePartialSoftCreditRollupsForSObject(Account.SObjectType)) {
            expectedJobCount++;
        }
        if (CRLP_Rollup_SVC.hasActiveAccountSoftCreditRollupsForSObject(Account.SObjectType)) {
            expectedJobCount++;
        }        
        assertCRLPBatchSubmitted(expectedJobCount);

        clickRecalculateRollupsFor(gau);
        expectedJobCount++;

        clickRecalculateRollupsFor(rd);
        expectedJobCount++;

        assertCRLPBatchSubmitted(expectedJobCount);

        Test.stopTest();
    }

    /**
     * @description Verifies a Customizable Rollup batch is submitted when button is clicked on 
     * and Customizable Rollups are enabled and enhanced RDs are enabled
     */
    @isTest
    private static void shouldSubmitCRLPBatchWhenCRLPAndEhancedRDsAreEnabled() {

        enableCustomizableRollups();
        RD2_EnablementService_TEST.setRecurringDonations2Enabled();

        npe03__Recurring_Donation__c rd = TEST_RecurringDonationBuilder.constructEnhancedBuilder()
            .withDefaultValues()
            .withContact(getContact().Id)
            .withAmount(100)
            .build();
        insert rd;

        Test.startTest();
        
        clickRecalculateRollupsFor(rd);

        assertCRLPBatchSubmitted(1);

        Test.stopTest();
    }

    /**
     * @description Verifies legacy rollups do not modify Recurring Donation rollup fields when button is clicked on 
     * and Customizable Rollups are not enabled and enhanced RDs are enabled
     */
    @isTest
    private static void shouldNotUpdateRollupFieldsOnRDWhenCRLPIsDisabledAndEhancedRDsAreEnabled() {

        disableCustomizableRollups();
        RD2_EnablementService_TEST.setRecurringDonations2Enabled();

        npe03__Recurring_Donation__c rd = TEST_RecurringDonationBuilder.constructEnhancedBuilder()
            .withDefaultValues()
            .withContact(getContact().Id)
            .withAmount(100)
            .build();
        insert rd;

        rd = rdGateway.getRecord(rd.Id);
        System.assertEquals(null, rd.npe03__Paid_Amount__c, 'Paid Amount on RD should not be set initially');

        Test.startTest();        
        clickRecalculateRollupsFor(rd);
        Test.stopTest();

        // Confirm that the legacy rollup logic does not update the value of the RD rollup field Paid Amount
        rd = rdGateway.getRecord(rd.Id);
        System.assertEquals(null, rd.npe03__Paid_Amount__c, 'Paid Amount on RD should not be updated by legacy rollups');
    }



    // Helpers
    //////////////////


    /****
    * @description Simulates Recalculate Rollups button click
    * @param sObj Record to recalculate rollups for
    * @return void
    */
    private static void clickRecalculateRollupsFor(SObject sObj) {
        CRLP_RecalculateBTN_CTRL ctrl = new CRLP_RecalculateBTN_CTRL(new ApexPages.StandardController(sObj));
        System.assertEquals(false, ctrl.hasError, 'The controller constructor should have not generated an error');
        
        ctrl.buttonClick();
    }

    /****
    * @description Disables Customizable Rollups
    * @return void
    */
    private static void disableCustomizableRollups() {
        UTIL_CustomSettingsFacade.getRollupSettingsForTests(new Customizable_Rollup_Settings__c (
            Customizable_Rollups_Enabled__c = false
        ));
    }

    /****
    * @description Enables Customizable Rollups (which disables all legacy rollup operations)
    * @return void
    */
    private static void enableCustomizableRollups() {
        UTIL_CustomSettingsFacade.getRollupSettingsForTests(new Customizable_Rollup_Settings__c(
            Customizable_Rollups_Enabled__c = true,
            Rollups_Limit_on_Attached_Opps_for_Skew__c = 200,
            Rollups_Account_SkewMode_Batch_Size__c = 200,
            Rollups_Contact_SkewMode_Batch_Size__c = 200,
            Rollups_Contact_Soft_Credit_Batch_Size__c = 200,
            Rollups_Account_Soft_Credit_Batch_Size__c = 200,
            Rollups_AcctContactSoftCredit_Batch_Size__c = 200,
            Rollups_Account_Batch_Size__c = 20,
            Rollups_Contact_Batch_Size__c = 20,
            Rollups_GAU_Batch_Size__c = 400
        ));
    }

    /****
    * @description Asserts CRLP batch jobs are submitted
    * @return void
    */
    private static void assertCRLPBatchSubmitted(Integer expectedJobCount) {
        System.assertEquals(expectedJobCount, [SELECT Count() FROM AsyncApexJob WHERE ApexClass.Name LIKE 'CRLP%'],
            expectedJobCount + ' jobs should been queued');
    }

    /****
    * @description Returns contact record
    * @return Contact
    */
    private static Contact getContact() {
        return [
            SELECT FirstName, LastName, 
                AccountId, Account.Id,
                npo02__TotalOppAmount__c, npo02__Soft_Credit_Total__c
            FROM Contact
            LIMIT 1
        ];
    }
}
