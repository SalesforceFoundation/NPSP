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

    private static final TEST_SObjectGateway.ErrorGateway errorGateway = new TEST_SObjectGateway.ErrorGateway();


    /****
    * @description Verifies required data is returned to the Elevate widget
    */
    @isTest
    private static void shouldReturnDataWhenElevateIsEnabled() {
        RD2_EnablementService_TEST.setRecurringDonations2Enabled();
        enableElevate();

        Id recordId = UTIL_UnitTestData_TEST.mockId(npe03__Recurring_Donation__c.getSObjectType());

        Map<String, Object> data = RD2_ElevateInformation_CTRL.getData(recordId);

        System.assertEquals(true, ((Boolean) data.get('isElevateCustomer')),
            'The org should be Elevate customer');
        System.assertEquals(null, ((String) data.get('alert')),
            'No alert should be returned for the RD record');
        System.assertEquals(true, ((Boolean) data.get('hasFieldPermissions')),
            'User should have field permissions');
        System.assertEquals(null, ((String) data.get('errorMessage')),
            'No error should be returned for the RD record');
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
        UTIL_FeatureEnablement_TEST.setPilotEnabledParameter(true);

        Id recordId = UTIL_UnitTestData_TEST.mockId(npe03__Recurring_Donation__c.getSObjectType());

        Map<String, Object> data = RD2_ElevateInformation_CTRL.getData(recordId);

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

        Map<String, Object> data = RD2_ElevateInformation_CTRL.getData(recordId);

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

        Map<String, Object> data = RD2_ElevateInformation_CTRL.getData(recordId);

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

        Map<String, Object> data = RD2_ElevateInformation_CTRL.getData(recordId);

        System.assertEquals(null, ((String) data.get('alert')),
            'No alert should be returned for the RD record');

        String expectedMessage = String.format(
            System.Label.commonErrorPrefix,
            new String[]{ error.Full_Message__c }
        );
        System.assertEquals(expectedMessage, ((String) data.get('errorMessage')),
            'An error message should match');
    }


    // Helpers
    ////////////////


    /****
    * @description Enables Elevate integration and allows Create Commitment functionality
    */
    private static void enableElevate() {
        RD2_ElevateIntegrationService_TEST.enableElevateUserPermissions();
        UTIL_FeatureEnablement_TEST.setPilotEnabledParameter(true);
    }

}
