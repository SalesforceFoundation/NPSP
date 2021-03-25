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
* @description Unit tests for the Elevate Information widget controller
*
*/
@IsTest(IsParallel=false)
private with sharing class RD2_ElevateInformation_TEST {


    /****
    * @description Verifies required data is returned to the Elevate widget
    */
    @isTest
    private static void shouldReturnDataWhenElevateIsEnabled() {
        RD2_EnablementService_TEST.setRecurringDonations2Enabled();
        enableElevate();

        Id recordId = UTIL_UnitTestData_TEST.mockId(npe03__Recurring_Donation__c.getSObjectType());

        Map<String, Object> data = RD2_ElevateInformation_CTRL.getPermissionData(recordId);

        System.assertEquals(true, ((Boolean) data.get('isElevateCustomer')),
            'The org should be Elevate customer');
        System.assertEquals(null, ((String) data.get('alert')),
            'No alert should be returned for the RD record');
        System.assertEquals(true, ((Boolean) data.get('hasFieldPermissions')),
            'User should have required field permissions');
        System.assertEquals(true, ((Boolean) data.get('showLastFourDigits')),
            'User should have perms to show the last 4 of credit card');
        System.assertEquals(true, ((Boolean) data.get('showExpirationDate')),
            'User should have perms to show expiration date');
        System.assertEquals(null, ((String) data.get('errorMessage')),
            'No error should be returned for the RD record');
        System.assertEquals(true, (Boolean) data.get('hasFieldUpdatePermission'),
            'The user should have RD field update permission');
        System.assertEquals(true, (Boolean) data.get('hasRDSObjectUpdatePermission'),
            'The user should have RD record update permission');
    }

    /****
    * @description Verifies read only user does not have the permission to modify elevate RD
    */
    @isTest
    private static void shouldReturnFalseWhenUserCannotModifyRD() {
        RD2_EnablementService_TEST.setRecurringDonations2Enabled();
        enableElevate();
        User standardUser = UTIL_UnitTestData_TEST.createUserWithoutInsert(UTIL_Profile.PROFILE_READ_ONLY);

        System.runAs(standardUser) {
            Id recordId = UTIL_UnitTestData_TEST.mockId(npe03__Recurring_Donation__c.getSObjectType());

            Map<String, Object> data = RD2_ElevateInformation_CTRL.getPermissionData(recordId);

            System.assertEquals(false, (Boolean) data.get('hasFieldUpdatePermission'),
                'The user should not have RD fields update permission');
            System.assertEquals(false, (Boolean) data.get('hasRDSObjectUpdatePermission'),
            '   The user should not have RD record update permission');
        }
    }

    /****
    * @description Verifies data indicates Elevate is not connected
    * when Elevate is not enabled
    */
    @isTest
    private static void shouldNotDisplayElevateWidgetWhenElevateIsNotEnabled() {
        RD2_EnablementService_TEST.setRecurringDonations2Enabled();

        PS_IntegrationServiceConfig_TEST.Stub configStub = new PS_IntegrationServiceConfig_TEST.Stub()
            .withIsIntegrationEnabled(false);
        RD2_ElevateIntegrationService.config = (PS_IntegrationServiceConfig) Test.createStub(
            PS_IntegrationServiceConfig.class,
            configStub
        );

        Id recordId = UTIL_UnitTestData_TEST.mockId(npe03__Recurring_Donation__c.getSObjectType());

        Map<String, Object> data = RD2_ElevateInformation_CTRL.getPermissionData(recordId);

        System.assertEquals(false, ((Boolean) data.get('isElevateCustomer')),
            'The org should not be connected to Elevate');
    }

    /****
    * @description Verifies data returns an alert
    * when Enhanced Recurring Donations are not enabled
    */
    @isTest
    private static void shouldReturnAlertWhenRD2IsNotEnabled() {
        enableElevate();

        Id recordId = UTIL_UnitTestData_TEST.mockId(npe03__Recurring_Donation__c.getSObjectType());

        Map<String, Object> data = RD2_ElevateInformation_CTRL.getPermissionData(recordId);

        System.assertNotEquals(null, ((String) data.get('alert')),
            'An alert should be returned when Enhanced Recurring Donations are not enabled');
    }

    /****
    * @description Verifies data returns an alert
    * when Enhanced Recurring Donations are not enabled
    */
    @isTest
    private static void shouldReturnAlertWhenIdIsNotRecurringDonationId() {
        RD2_EnablementService_TEST.setRecurringDonations2Enabled();
        enableElevate();

        Id recordId = UTIL_UnitTestData_TEST.mockId(Account.getSObjectType());

        Map<String, Object> data = RD2_ElevateInformation_CTRL.getPermissionData(recordId);

        System.assertNotEquals(null, ((String) data.get('alert')),
            'An alert should be returned when the widget is added to a non-RD record page');
    }

    /****
    * @description Verifies data returns an error message
    * when an error record is created for the Recurring Donation
    */
    @isTest
    private static void shouldReturnErrorMessageWhenRecurringDonationHasAnError() {
        RD2_EnablementService_TEST.setRecurringDonations2Enabled();
        enableElevate();

        Id recordId = UTIL_UnitTestData_TEST.mockId(npe03__Recurring_Donation__c.getSObjectType());

        Error__c error = new Error__c(
            Datetime__c = System.now(),
            Related_Record_ID__c = recordId,
            Full_Message__c = 'test error message'
        );
        insert error;

        String errorString = RD2_ElevateInformation_CTRL.getLatestErrorMessage(recordId);

        String expectedMessage = String.format(
            System.Label.commonErrorPrefix,
            new String[]{ error.Full_Message__c }
        );
        System.assertEquals(expectedMessage, errorString,
            'An error message should match');
    }

    /****
    * @description Verifies that the show date/last4 perms are accurate for a user without access to these fields
    */
    @isTest
    private static void shouldReturnCorrectPermsForLimitedAccessUser() {
        RD2_EnablementService_TEST.setRecurringDonations2Enabled();
        enableElevate();
        Id recordId = UTIL_UnitTestData_TEST.mockId(npe03__Recurring_Donation__c.getSObjectType());

        User standardUser = UTIL_UnitTestData_TEST.createUserWithoutInsert(UTIL_Profile.PROFILE_READ_ONLY);

        System.runAs(standardUser) {

            Map<String, Object> data = RD2_ElevateInformation_CTRL.getPermissionData(recordId);

            System.assertEquals(true, ((Boolean) data.get('isElevateCustomer')),
                'The org should be Elevate customer');
            System.assertEquals(null, ((String) data.get('alert')),
                'No alert should be returned for the RD record');
            System.assertEquals(false, ((Boolean) data.get('hasFieldPermissions')),
                'User should not have required field permissions');
            System.assertEquals(false, ((Boolean) data.get('showLastFourDigits')),
                'User should not have perms to show the last 4 of credit card');
            System.assertEquals(false, ((Boolean) data.get('showExpirationDate')),
                'User should not have perms to show expiration date');
        }
    }


    // Helpers
    ////////////////


    /****
    * @description Enables Elevate integration and allows Create Commitment functionality
    */
    private static void enableElevate() {
        RD2_ElevateIntegrationService_TEST.enableElevateUserPermissions();
        PS_IntegrationService.setConfiguration(PS_IntegrationServiceConfig_TEST.testConfig);
    }

}
