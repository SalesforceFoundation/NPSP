/*
    Copyright (c) 2020 Salesforce.org
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
* @date 2020
* @group Recurring Donations
* @description Unit tests for the Refresh Opportunities button
*
*/
@isTest
private with sharing class RD_AddDonationsBTN_TEST {

    private static final Date DATE_ESTABLISHED = Date.newInstance(2019, 10, 1);

    private static final TEST_SObjectGateway.OpportunityGateway oppGateway = new TEST_SObjectGateway.OpportunityGateway();

    /***
    * @description Verifies Opportunities are recreated when the button is clicked on
    */
    @isTest
    private static void shouldRefreshOppsWhenButtonClick() {
        Account acc = UTIL_UnitTestData_TEST.buildOrganizationAccount();
        insert acc;

        npe03__Recurring_Donation__c rd = getLegacyRDBuilder()
            .withAccount(acc.Id)
            .withNextDonationDate(System.today())
            .build();

        Test.startTest();
        insert rd;
        Test.stopTest();

        delete oppGateway.getRecords(rd);

        createCustomFieldMapping();

        RD_AddDonationsBTN_CTRL ctrl = new RD_AddDonationsBTN_CTRL(
            new ApexPages.StandardController(rd)
        );
        System.assertEquals(rd.Id, ctrl.sc.getId());

        PageReference returnPage = ctrl.buttonClick();
        System.assertNotEquals(null, returnPage, 'Page should be redirected on the button click');
        System.assertNotEquals('/' + rd.Id, returnPage.getUrl(),
            'The button should redirect to the Recurring Donation detail page on successful Opp refresh');

        System.assertEquals(false, oppGateway.getRecords(rd).isEmpty(), 'Opportunities should be recreated');
    }

    /***
    * @description Ensures proper message is displayed when navigating to Visualforce page
    * without a Recurring Donation Id
    */
    @isTest
    private static void shouldDisplayErrorMessageWhenMissingId() {
        npe03__Recurring_Donation__c rd = getLegacyRDBuilder()
            .withAccount(UTIL_UnitTestData_TEST.mockId(Account.SObjectType))
            .build();

        Test.startTest();
        RD_AddDonationsBTN_CTRL ctrl = new RD_AddDonationsBTN_CTRL(
            new ApexPages.StandardController(rd)
        );

        //No redirect should occur on the error message display
        System.assertEquals(null, ctrl.buttonClick());

        UTIL_UnitTestData_TEST.assertPageHasMessage(System.Label.RD_ErrorAddDonationMissingId, ApexPages.Severity.ERROR);

        System.assertEquals(false, ctrl.showContinueBtn, 'The continue button should be hidden');

        String expectedPageUrl = '/' + npe03__Recurring_Donation__c.SObjectType.getDescribe().getKeyPrefix();
        System.assertEquals(expectedPageUrl, ctrl.redirectToRecurringDonationsPage().getUrl(),
            'The Cancel should redirect to the Recurring Donation list view tab'
        );

        Test.stopTest();
    }

    /***
    * @description Ensures proper message is displayed when enhanced Recurring Donation mode is enabled
    */
    @isTest
    private static void shouldDisplayErrorMessageWhenEnhancedRDIsEnabled() {
        RD2_EnablementService_TEST.setRecurringDonations2Enabled();

        Contact contact = UTIL_UnitTestData_TEST.getContact();
        insert contact;

        npe03__Recurring_Donation__c rd = TEST_RecurringDonationBuilder.constructEnhancedBuilder()
            .withDefaultValues()
            .withContact(contact.Id)
            .withAmount(100)
            .build();
        insert rd;

        Test.startTest();
        RD_AddDonationsBTN_CTRL ctrl = new RD_AddDonationsBTN_CTRL(
            new ApexPages.StandardController(rd)
        );

        // The error should be generated and rendered by the constructor
        UTIL_UnitTestData_TEST.assertPageHasMessage(System.Label.RD_ErrorAddDonationLimitedToLegacyMode, ApexPages.Severity.ERROR);

        // No redirect should occur on this, even though it should be unreachable
        System.assertEquals(null, ctrl.buttonClick());

        System.assertEquals(false, ctrl.showContinueBtn, 'The continue button should be hidden');

        // Validate that the cancel operation redirects to the correct RD
        System.assertEquals('/' + String.valueOf(rd.Id).left(15), ctrl.redirectToRecurringDonationsPage().getUrl(),
            'The Cancel should redirect to the Recurring Donation detail page'
        );

        Test.stopTest();
    }

    /***
    * @description Verifies if it displays error message when the user has no create permission
    * on the Opportunity SObject
    */
    @isTest
    private static void shouldDisplayErrorMessageWhenUserHasNoCreatePermission() {

        UTIL_Permissions_TEST.Stub permissionStub = new UTIL_Permissions_TEST.Stub();
        permissionStub.hasCreate = false;

        testAndAssertUserDoesNotHavePermissions(permissionStub);
    }

    /***
    * @description Verifies if it displays error message when the user has no edit permission
    * on the Opportunity SObject
    */
    @isTest
    private static void shouldDisplayErrorMessageWhenUserHasNoEditPermission() {

        UTIL_Permissions_TEST.Stub permissionStub = new UTIL_Permissions_TEST.Stub();
        permissionStub.hasUpdate = false;

        testAndAssertUserDoesNotHavePermissions(permissionStub);
    }

    /***
    * @description Verifies if it displays error message when the uer has no delete permission
    * on the Opportunity SObject
    */
    @isTest
    private static void shouldDisplayErrorMessageWhenUserHasNoDeletePermission() {

        UTIL_Permissions_TEST.Stub permissionStub = new UTIL_Permissions_TEST.Stub();
        permissionStub.hasDelete = false;

        testAndAssertUserDoesNotHavePermissions(permissionStub);
    }

    // Helpers
    /////////////

    /***
    * @description Builds a recurring donation with default values and weekly installment period
    * @return TEST_RecurringDonationBuilder Recurring Donation record builder
    */
    private static TEST_RecurringDonationBuilder getLegacyRDBuilder() {
        return TEST_RecurringDonationBuilder.constructLegacyBuilder()
            .withAmount(100)
            .withPlannedInstallments(2)
            .withInstallmentPeriodWeekly()
            .withDateEstablished(DATE_ESTABLISHED)
            .withScheduleTypeMultiplyValue()
            .withOpenEndedStatusNone();
    }

    /***
    * @description Removes current Custom Field Mappings and create a new one
    * in order to avoid reaching debug log size limit
    * @return void
    */
    private static void createCustomFieldMapping() {
        delete [SELECT Id FROM npe03__Custom_Field_Mapping__c];

        insert new npe03__Custom_Field_Mapping__c(
            Name = 'CFM-' + System.now(),
            npe03__Opportunity_Field__c = 'closedate',
            npe03__Recurring_Donation_Field__c = 'Name'
        );
    }


    /***
    * @description builds test data for account and recurring donations and verifies if it generates
    * error message if the user do not have required permissions on the opportunity SObject.
    */
    private static void testAndAssertUserDoesNotHavePermissions(UTIL_Permissions_TEST.Stub permissionStub) {
        Account acc = UTIL_UnitTestData_TEST.buildOrganizationAccount();
        insert acc;

        npe03__Recurring_Donation__c rd = getLegacyRDBuilder()
            .withAccount(acc.Id)
            .withNextDonationDate(System.today())
            .build();
        insert rd;

        RD_AddDonationsBTN_CTRL.permissions = (UTIL_Permissions) Test.createStub(UTIL_Permissions.class, permissionStub);

        RD_AddDonationsBTN_CTRL ctrl = new RD_AddDonationsBTN_CTRL(
            new ApexPages.StandardController(rd)
        );

        UTIL_UnitTestData_TEST.assertPageHasError(System.Label.RD_ErrorAddDonationPermissionDenied);
        System.assertEquals(false, ctrl.showContinueBtn, 'The continue button should be hidden');

    }

}
