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
* @description Enhanced Recurring Donations Entry Form LWC Controller Tests
*
*/
@IsTest
private with sharing class RD2_EntryFormController_TEST {

    private static final Date START_DATE = Date.newInstance(2019, 3, 1);
    private static final String COMMITMENT_ID = RD2_ElevateIntegrationService_TEST.COMMITMENT_ID;
    private static final String PAYMENT_METHOD_TOKEN = 'token-abcd-efgh-ijkl-mnop-qrst';
    private static final String CARD_LAST_4 = '1234';
    private static final String CARD_EXPIRATION_MONTH = '11';
    private static final String CARD_EXPIRATION_YEAR = '2019';
    private static final String EVENT_VERSION = '1';
    private static final String NO_CREATE_PERMISSION = 'NoCreate';

    private static final TEST_SObjectGateway.RecurringDonationGateway rdGateway = new TEST_SObjectGateway.RecurringDonationGateway();
    private static final TEST_SObjectGateway.ErrorGateway errorGateway = new TEST_SObjectGateway.ErrorGateway();

    private static OrgConfig orgConfig = new OrgConfig();

    /****
    * @description Creates data required for unit tests
    */
    @TestSetup
    private static void setUp() {
        RD2_EnablementService_TEST.setRecurringDonations2Enabled();

        Contact c = UTIL_UnitTestData_TEST.getContact();
        insert c;

        npe03__Recurring_Donation__c rd = TEST_RecurringDonationBuilder.constructEnhancedBuilder()
            .withContact(c.Id)
            .withAmount(25)
            .withDefaultValues()
            .withInstallmentPeriodWeekly()
            .withDayOfMonth('1')
            .withInstallmentFrequency(2)
            .build();
        insert rd;
    }

    /***
    * @description Verifies that Entry Form Controller gathers the correct org setting
    */
    @IsTest
    private static void shouldReturnSettings() {
        Id accountId = UTIL_UnitTestData_TEST.mockId(Account.SObjectType);

        Test.startTest();
        RD2_AppView initialView = RD2_EntryFormController.getInitialView(accountId, null);
        Test.stopTest();

        System.assertEquals(RD2_NamingService.isAutomaticNamingEnabled, initialView.isAutoNamingEnabled,
            'Recurring Donation Auto Naming setting should be returned accordingly');
        System.assertEquals(UserInfo.isMultiCurrencyOrganization(), initialView.isMultiCurrencyEnabled,
            'Multi Currency Org should be detected in the configuration.');
        System.assertEquals(String.valueOf(Account.SObjectType), initialView.parentSObjectType,
            'Parent Sobject type should be correctly identified when value is not null');

        System.assertEquals(true, initialView.InstallmentPeriodPermissions.get('Createable'),
            'Installment_Period__c.IsCreatable should return true');
    }

    /***
    * @description Verifies whether the org is the Elevate customer
    * in order to display the Elevate credit card widget if so.
    */
    @IsTest
    private static void newRecordShouldDefaultStartDate() {
        Test.startTest();
        RD2_AppView initialView = RD2_EntryFormController.getInitialView(null, null);
        Test.stopTest();

        System.assertEquals(initialView.record.dateEstablished, Date.today(), 'Date established should default to today.');
    }

    /***
    * @description Verifies whether the org is the Elevate customer
    * in order to display the Elevate credit card widget if so.
    */
    @IsTest
    private static void newRecordShouldDefaultDateEstablished() {
        Test.startTest();
        RD2_AppView initialView = RD2_EntryFormController.getInitialView(null, null);
        Test.stopTest();

        System.assertEquals(initialView.record.startDate, Date.today(), 'Start date should default to today.');
    }

    /***
    * @description Verifies whether the org is the Elevate customer
    * in order to display the Elevate credit card widget if so.
    */
    @IsTest
    private static void shouldDisplayElevateWidgetWhenElevateEnabledIsTrue() {
        Id accountId = UTIL_UnitTestData_TEST.mockId(Account.SObjectType);

        RD2_ElevateIntegrationService_TEST.enableElevateUserPermissions();

        Test.startTest();
        RD2_AppView initialView = RD2_EntryFormController.getInitialView(accountId, null);
        Test.stopTest();

        System.assertEquals(true, initialView.isElevateCustomer,
            'The org should be Elevate customer');
    }

    /***
    * @description Verifies that Entry Form Controller returns the expected results for Account for Donor Type
    */
    @IsTest
    private static void shouldReturnAccountDonorType() {
        RD2_EnablementService_TEST.setRecurringDonations2Enabled();

        Account a = UTIL_UnitTestData_TEST.buildOrganizationAccount();
        insert a;

        npe03__Recurring_Donation__c rd = TEST_RecurringDonationBuilder.constructEnhancedBuilder()
            .withAccount(a.Id)
            .withAmount(25)
            .withDefaultValues()
            .withInstallmentPeriodMonthly()
            .withDayOfMonth('1')
            .build();
        insert rd;

        Test.startTest();
        RD2_AppView view = RD2_EntryFormController.getInitialView(a.Id, rd.Id);
        String donorType = view.record.donorType;
        String period = view.record.recurringPeriod;
        Test.stopTest();

        System.assertEquals('Account', donorType);
        System.assertEquals('Monthly', period);
    }

    /***
    * @description Verifies that Entry Form Controller returns the expected results for Contact for Donor Type
    */
    @IsTest
    private static void shouldReturnContactDonorType() {
        //skip the test if Advancement is installed
        if(ADV_PackageInfo_SVC.useAdv()) return;
        
        RD2_EnablementService_TEST.setRecurringDonations2Enabled();

        npe03__Recurring_Donation__c rd = rdGateway.getRecords()[0];

        Test.startTest();
        RD2_AppView view = RD2_EntryFormController.getInitialView(null, rd.Id);
        String donorType = view.record.donorType;
        String period = view.record.recurringPeriod;
        Integer frequency = view.record.recurringFrequency;
        Test.stopTest();

        System.assertEquals('Contact', donorType);
        System.assertEquals('Weekly', period);
        System.assertEquals(2, frequency);
    }

    /**
     * @description Validate that the System Admin User reports that they have the required field permissions
     */
    @IsTest
    private static void shouldReturnTrueWhenUserHasPermissions() {
        Boolean hasPerms = RD2_EntryFormController.hasRequiredFieldPermissions();
        System.assertEquals(true, hasPerms, 'The Admin User should have permissions');
    }

    /**
     * @description Validate that a Standard User w/o Read permission on a single RD  field reports that they
     * are missing the required field permissions
     */
    @IsTest
    private static void shouldReturnFalseWhenUserIsMissingPermissions() {
        User stdUser = UTIL_UnitTestData_TEST.createStandardProfileUser();

        Id stdProfileId = [SELECT Id FROM Profile WHERE Name = :UTIL_Profile.PROFILE_STANDARD_USER LIMIT 1].Id;

        FieldPermissions fldPerm = [
            SELECT Id, PermissionsRead, PermissionsEdit
            FROM FieldPermissions
            WHERE Parent.ProfileId = :stdProfileId
            AND Field = 'npe03__Recurring_Donation__c.npe03__Installment_Period__c'
        ];
        fldPerm.PermissionsRead = false;
        fldPerm.PermissionsEdit = false;
        update fldPerm;

        Test.startTest();
        System.runAs(stdUser) {
            Boolean hasPerms = RD2_EntryFormController.hasRequiredFieldPermissions();
            System.assertEquals(false, hasPerms, 'The Standard User should be missing permissions');
        }
        Test.stopTest();
    }

    /***
    * @description Verifies that Entry Form Controller excluded all NPSP packaged field and predefined excluded fields
    */
    @IsTest
    private static void shouldReturnRD2CustomFieldsWithoutNPSPNameSpaceAndExcludedFields() {
        Test.startTest();
        List<InputFieldView> customFields = RD2_EntryFormController.getCustomFieldSectionFields();
        Test.stopTest();

        Set<String> excludedCustomFields = RD2_Settings.getExcludedCustomFields();

        for (InputFieldView field : customFields) {
            System.assert(!excludedCustomFields.contains(field.apiName),
                'Excluded fields should not be return:' + field.apiName);
            System.assert(!field.apiName.startsWith('npsp__'),
                'NPSP package field should not be return:' + field.apiName);
            System.assert(!field.apiName.startsWith('npe03__'),
                'NPSP package field should not be return:' + field.apiName);
        }
    }

    /***
    * @description Verifies Commitment record created response is returned upon successful creation
    */
    @IsTest
    private static void shouldReturnCreatedResponseWhenCreateCommitmentSucceeds() {
        RD2_EnablementService_TEST.setRecurringDonations2Enabled();
        PS_IntegrationService.setConfiguration(PS_IntegrationServiceConfig_TEST.testConfig);

        npe03__Recurring_Donation__c rd = buildRecurringDonation();

        Test.startTest();
        mockRecordCreatedCalloutResponse();

        RD2_CommitmentService service = new RD2_CommitmentService();

        UTIL_Http.Response response = service.handleCommitment(rd, null, PAYMENT_METHOD_TOKEN);
        Test.stopTest();

        System.assertNotEquals(null, response, 'The Commitment response should be returned');
        System.assertEquals(UTIL_Http.STATUS_CODE_CREATED, response.statusCode,
            'The response status code should match: ' + response);
        System.assert(response.body.contains('"version":"'+EVENT_VERSION+'"'),
            'The response should include the version: ' + response);
    }

    /**
    * @description Verifies an error record will be created when an error response is received from the Elevate API.
    */
    @IsTest
    private static void shouldCreateErrorRecordWhenElevateReturnsErrorResponse() {
        RD2_EnablementService_TEST.setRecurringDonations2Enabled();
        PS_IntegrationService.setConfiguration(PS_IntegrationServiceConfig_TEST.testConfig);

        npe03__Recurring_Donation__c rd = buildRecurringDonation();

        RD2_QueryService selectorStub = (RD2_QueryService)Test.createStub(
                RD2_QueryService.class,
                new RD2_QueryServiceMock(rd.clone())
        );
        RD2_EntryFormController.selector = selectorStub;

        Test.startTest();
        UTIL_Http_TEST.mockBadRequestCalloutResponse();

        RD2_EntryFormController.handleCommitment(JSON.serialize(rd), PAYMENT_METHOD_TOKEN);
        Test.stopTest();

        List<Error__c> errors = errorGateway.getRecords();
        System.assertEquals(1, errors.size(),
            'An error record should be created for an error response.');
        System.assertEquals(rd.npe03__Contact__c, errors[0].Related_Record_Id__c,
            'The error record should contain donor Contact Id.');
        System.assertEquals(ERR_Handler_API.Context.Elevate.name(),errors[0].Context_Type__c,
            'The error record context type should match with Elevate context.');
        System.assert(errors[0].Full_Message__c.contains(UTIL_Http_TEST.BAD_REQUEST_MESSAGE),
            'The error record should contain error response message.');
    }
    
    /**
    * @description Verifies an error record will be created when update paymnet commitment fail.
    */
    @IsTest
    private static void shouldCreateErrorRecordWhenUpdatePaymentInfoReturnsErrorResponse() {
        RD2_EnablementService_TEST.setRecurringDonations2Enabled();
        PS_IntegrationService.setConfiguration(PS_IntegrationServiceConfig_TEST.testConfig);

        npe03__Recurring_Donation__c rd = buildRecurringDonation();
        insert rd;

        Test.startTest();
        UTIL_Http_TEST.mockBadRequestCalloutResponse();

        RD2_EntryFormController.handleUpdatePaymentCommitment(JSON.serialize(rd), PAYMENT_METHOD_TOKEN);
        Test.stopTest();

        List<Error__c> errors = errorGateway.getRecords();
        System.assertEquals(1, errors.size(),
            'An error record should be created for an error response.');
        System.assertEquals(rd.Id, errors[0].Related_Record_Id__c,
            'The error record should contain donor Contact Id.');
        System.assertEquals(ERR_Handler_API.Context.Elevate.name(),errors[0].Context_Type__c,
            'The error record context type should match with Elevate context.');
        System.assert(errors[0].Full_Message__c.contains(UTIL_Http_TEST.BAD_REQUEST_MESSAGE),
            'The error record should contain error response message.');
    }

    /**
    * @description Verifies commitment success response is returned upon successful update 
    */
    @IsTest
    private static void shouldReturnSuccessResponseWhenUpdatePaymentInfoIsSuccess() {
        RD2_EnablementService_TEST.setRecurringDonations2Enabled();
        PS_IntegrationService.setConfiguration(PS_IntegrationServiceConfig_TEST.testConfig);

        npe03__Recurring_Donation__c rd = buildRecurringDonation();
        insert rd;

        npe03__Recurring_Donation__c updateRequestRd = new npe03__Recurring_Donation__c(
                Id = rd.Id,
                CommitmentId__c = COMMITMENT_ID,
                npe03__Contact__c = rd.npe03__Contact__c
        );

        Test.startTest();
        UTIL_Http_TEST.mockRecordUpdateCalloutResponse(mockSuccessResponseBody());

        String response = 
            RD2_EntryFormController.handleUpdatePaymentCommitment(JSON.serialize(updateRequestRd), PAYMENT_METHOD_TOKEN);
        Test.stopTest();

        Integer statusCode;
        String status;
        JSONParser parser = JSON.createParser(response);

        while (parser.nextToken() != null) {
            if(parser.getCurrentToken() == JSONToken.FIELD_NAME) {
                if (parser.getText() == 'statusCode') {
                    parser.nextToken();
                    statusCode = parser.getIntegerValue();

                } else if (parser.getText() == 'status') {
                    parser.nextToken();
                    status = parser.getText();
                }
            } 
        }

        System.assertNotEquals(null, response, 'The Commitment response should be returned');
        System.assertEquals(UTIL_Http.STATUS_CODE_OK, statusCode,
            'The response status code should match: ' + response);
            System.assertEquals(UTIL_Http.STATUS_OK, status,
            'The response status should match: ' + response);
    }

    /**
    * @description Verifies commitment success response is returned upon successful schedule update 
    */
    @IsTest
    private static void shouldReturnSuccessResponseWhenUpdateElevateScheduleAmount() {
        RD2_EnablementService_TEST.setRecurringDonations2Enabled();
        PS_IntegrationService.setConfiguration(PS_IntegrationServiceConfig_TEST.testConfig);

        npe03__Recurring_Donation__c rd = buildRecurringDonation();
        insert rd;

        npe03__Recurring_Donation__c updateRequestRd = new npe03__Recurring_Donation__c(
            Id = rd.Id,
            CommitmentId__c = COMMITMENT_ID,
            npe03__Amount__c = rd.npe03__Amount__c + 10,
            npe03__Contact__c = rd.npe03__Contact__c
        );

        Test.startTest();
        UTIL_Http_TEST.mockRecordUpdateCalloutResponse(mockSuccessResponseBody());

        String response = 
            RD2_EntryFormController.handleUpdatePaymentCommitment(JSON.serialize(updateRequestRd), PAYMENT_METHOD_TOKEN);
        Test.stopTest();

        Integer statusCode;
        String status;
        JSONParser parser = JSON.createParser(response);

        while (parser.nextToken() != null) {
            if(parser.getCurrentToken() == JSONToken.FIELD_NAME) {
                if (parser.getText() == 'statusCode') {
                    parser.nextToken();
                    statusCode = parser.getIntegerValue();

                } else if (parser.getText() == 'status') {
                    parser.nextToken();
                    status = parser.getText();
                }
            } 
        }

        System.assertNotEquals(null, response, 'The Commitment response should be returned');
        System.assertEquals(UTIL_Http.STATUS_CODE_OK, statusCode,
            'The response status code should match: ' + response);
        System.assertEquals(UTIL_Http.STATUS_OK, status,
            'The response status should match: ' + response);
    }

    /**
    * @description Verifies commitment success response is returned upon successful schedule update 
    */
    @IsTest
    private static void shouldReturnSuccessResponseWhenUpdateElevateSchedulePeriod() {
        RD2_EnablementService_TEST.setRecurringDonations2Enabled();
        PS_IntegrationService.setConfiguration(PS_IntegrationServiceConfig_TEST.testConfig);

        npe03__Recurring_Donation__c rd = buildRecurringDonation();
        insert rd;

        npe03__Recurring_Donation__c updateRequestRd = new npe03__Recurring_Donation__c(
            Id = rd.Id,
            CommitmentId__c = COMMITMENT_ID,
            npe03__Installment_Period__c = RD_Constants.INSTALLMENT_PERIOD_YEARLY,
            npe03__Contact__c = rd.npe03__Contact__c
        );

        Test.startTest();
        UTIL_Http_TEST.mockRecordUpdateCalloutResponse(mockSuccessResponseBody());

        String response = 
            RD2_EntryFormController.handleUpdatePaymentCommitment(JSON.serialize(updateRequestRd), PAYMENT_METHOD_TOKEN);
        Test.stopTest();

        Integer statusCode;
        String status;
        JSONParser parser = JSON.createParser(response);

        while (parser.nextToken() != null) {
            if(parser.getCurrentToken() == JSONToken.FIELD_NAME) {
                if (parser.getText() == 'statusCode') {
                    parser.nextToken();
                    statusCode = parser.getIntegerValue();

                } else if (parser.getText() == 'status') {
                    parser.nextToken();
                    status = parser.getText();
                }
            } 
        }

        System.assertNotEquals(null, response, 'The Commitment response should be returned');
        System.assertEquals(UTIL_Http.STATUS_CODE_OK, statusCode,
            'The response status code should match: ' + response);
        System.assertEquals(UTIL_Http.STATUS_OK, status,
            'The response status should match: ' + response);
    }

    /**
    * @description Verifies commitment success response is returned upon successful schedule update 
    */
    @IsTest
    private static void shouldReturnSuccessResponseWhenUpdateElevateScheduleFrequency() {
        RD2_EnablementService_TEST.setRecurringDonations2Enabled();
        PS_IntegrationService.setConfiguration(PS_IntegrationServiceConfig_TEST.testConfig);

        npe03__Recurring_Donation__c rd = buildRecurringDonation();
        insert rd;

        npe03__Recurring_Donation__c updateRequestRd = new npe03__Recurring_Donation__c(
            Id = rd.Id,
            CommitmentId__c = COMMITMENT_ID,
            InstallmentFrequency__c = rd.InstallmentFrequency__c + 1,
            npe03__Contact__c = rd.npe03__Contact__c
        );

        Test.startTest();
        UTIL_Http_TEST.mockRecordUpdateCalloutResponse(mockSuccessResponseBody());

        String response = 
            RD2_EntryFormController.handleUpdatePaymentCommitment(JSON.serialize(updateRequestRd), PAYMENT_METHOD_TOKEN);
        Test.stopTest();

        Integer statusCode;
        String status;
        JSONParser parser = JSON.createParser(response);

        while (parser.nextToken() != null) {
            if(parser.getCurrentToken() == JSONToken.FIELD_NAME) {
                if (parser.getText() == 'statusCode') {
                    parser.nextToken();
                    statusCode = parser.getIntegerValue();

                } else if (parser.getText() == 'status') {
                    parser.nextToken();
                    status = parser.getText();
                }
            } 
        }

        System.assertNotEquals(null, response, 'The Commitment response should be returned');
        System.assertEquals(UTIL_Http.STATUS_CODE_OK, statusCode,
            'The response status code should match: ' + response);
        System.assertEquals(UTIL_Http.STATUS_OK, status,
            'The response status should match: ' + response);
    }

    /***
    * @description Verifies Recurring Donation should be validate and handle any error before calling Elevate API
    */
    @IsTest
    private static void shouldThrowExceptionWhenRDFieldValueIsInvalid() {
        RD2_EnablementService_TEST.setRecurringDonations2Enabled();

        PS_IntegrationServiceConfig_TEST.enableElevateIntegrationService();

        npe03__Recurring_Donation__c rd = buildRecurringDonation();
        RD2_QueryService selectorStub = (RD2_QueryService)Test.createStub(
                RD2_QueryService.class,
                new RD2_QueryServiceMock(rd.clone())
        );
        RD2_EntryFormController.selector = selectorStub;

        rd.CommitmentId__c = COMMITMENT_ID;
        rd.npe03__Amount__c = 0.9;

        String errorMessage;

        Test.startTest();

        try {
            RD2_EntryFormController.handleCommitment(JSON.serialize(rd), PAYMENT_METHOD_TOKEN);
    
        } catch(Exception ex) {
            errorMessage = ex.getMessage();
        }
        Test.stopTest();

        System.assertEquals(System.Label.RD2_ElevateRDAmountMustBeValid, errorMessage,
            'RD should be pre-validate before the Elevate Commitment API is called');
    }

    /***
    * @description Verifies Recurring Donation should be validate and handle any error before calling Elevate API
    */
    @IsTest
    private static void shouldReturnSuccessWhenUpdatingRdFromController() {
        RD2_EnablementService_TEST.setRecurringDonations2Enabled();
        PS_IntegrationService.setConfiguration(PS_IntegrationServiceConfig_TEST.testConfig);

        npe03__Recurring_Donation__c rd = buildRecurringDonation();

        rd.CommitmentId__c = COMMITMENT_ID;
        rd.npe03__Amount__c = 1;

        insert rd;

        rd.npe03__Amount__c = 2;

        String response;

        Test.startTest();

        try {
            UTIL_Http_TEST.mockRecordUpdateCalloutResponse(mockSuccessResponseBody());
            response = RD2_EntryFormController.handleCommitment(JSON.serialize(rd), PAYMENT_METHOD_TOKEN);

        } catch(Exception ex) {

        }

        Integer statusCode;
        String status;
        JSONParser parser = JSON.createParser(response);

        while (parser.nextToken() != null) {
            if(parser.getCurrentToken() == JSONToken.FIELD_NAME) {
                if (parser.getText() == 'statusCode') {
                    parser.nextToken();
                    statusCode = parser.getIntegerValue();

                } else if (parser.getText() == 'status') {
                    parser.nextToken();
                    status = parser.getText();
                }
            }
        }

        Test.stopTest();

        System.assertNotEquals(null, response, 'Expected to receive a response from handleCommitment');
        System.assertEquals(UTIL_Http.STATUS_CODE_OK, statusCode,
                'The response status code should match: ' + response);
        System.assertEquals(UTIL_Http.STATUS_OK, status,
                'The response status should match: ' + response);
    }

    /**
    * @description Verifies commitment success response is returned upon successful campaign update
    */
    @IsTest
    private static void shouldReturnSuccessResponseWhenUpdateElevateCamapaign() {
        RD2_EnablementService_TEST.setRecurringDonations2Enabled();
        PS_IntegrationService.setConfiguration(PS_IntegrationServiceConfig_TEST.testConfig);

        Campaign rdCampaign = new Campaign(name = 'Annual Campaign');
        insert rdCampaign;

        Campaign anotherRdCampaign = new Campaign(name = 'Annual Campaign');
        insert anotherRdCampaign;

        npe03__Recurring_Donation__c rd = buildRecurringDonation();
        rd.npe03__Recurring_Donation_Campaign__c = rdCampaign.Id;
        insert rd;

        rd.npe03__Recurring_Donation_Campaign__c = anotherRdCampaign.Id;

        Test.startTest();
        UTIL_Http_TEST.mockRecordUpdateCalloutResponse(mockSuccessResponseBody());

        String response = 
            RD2_EntryFormController.handleUpdatePaymentCommitment(JSON.serialize(rd), PAYMENT_METHOD_TOKEN);
        Test.stopTest();

        Integer statusCode;
        String status;
        JSONParser parser = JSON.createParser(response);

        while (parser.nextToken() != null) {
            if(parser.getCurrentToken() == JSONToken.FIELD_NAME) {
                if (parser.getText() == 'statusCode') {
                    parser.nextToken();
                    statusCode = parser.getIntegerValue();

                } else if (parser.getText() == 'status') {
                    parser.nextToken();
                    status = parser.getText();
                }
            } 
        }

        System.assertNotEquals(null, response, 'The Commitment response should be returned');
        System.assertEquals(UTIL_Http.STATUS_CODE_OK, statusCode,
            'The response status code should match: ' + response);
        System.assertEquals(UTIL_Http.STATUS_OK, status,
            'The response status should match: ' + response);
    }

    @IsTest
    private static void canSaveRecurringDonation() {
        RD2_EnablementService_TEST.setRecurringDonations2Enabled();
        Contact donorContact = getContact();

        RD2_SaveRequest req = new RD2_SaveRequest();

        req.dayOfMonth = '15';
        req.startDate = Date.newInstance(2022, 1, 15);
        req.dateEstablished = Date.newInstance(2022, 1, 15);
        req.recurringFrequency = 1;
        req.contactId = donorContact.Id;
        req.recurringStatus = 'Active';
        req.donationValue = 5;
        req.recurringType = 'Open';
        req.recurringPeriod = 'Monthly';
        req.paymentMethod = 'Credit Card';

        SaveResultView result = RD2_EntryFormController.saveRecurringDonation(req);

        System.assert(result.success, 'RD not inserted successfully');
        System.assertNotEquals(result.recordId, null, 'Save result should have an Id');
    }

    @IsTest
    private static void canSaveRDWithCustomFieldsNotCreateable() {
        RD2_EnablementService_TEST.setRecurringDonations2Enabled();
        Contact donorContact = getContact();

        UTIL_PermissionsMock utilPermissionsMockInstance = new UTIL_PermissionsMock().canUpdate();
        UTIL_Permissions utilPermissionsMock = (UTIL_Permissions) Test.createStub(UTIL_Permissions.class,
                utilPermissionsMockInstance);
        UTIL_Permissions.setInstance(utilPermissionsMock);

        RD2_SaveRequest req = new RD2_SaveRequest();
        req.dayOfMonth = '15';
        req.startDate = Date.newInstance(2022, 1, 15);
        req.dateEstablished = Date.newInstance(2022, 1, 15);
        req.recurringFrequency = 1;
        req.contactId = donorContact.Id;
        req.recurringStatus = 'Active';
        req.donationValue = 5;
        req.recurringType = 'Open';
        req.recurringPeriod = 'Monthly';
        req.paymentMethod = 'Credit Card';
        req.customFieldValues = new Map<String, Object> {
            NO_CREATE_PERMISSION => 'TestNoCreateValue1',
            NO_CREATE_PERMISSION + '_1' => 'TestNoCreateValue2'
        };

        SaveResultView result = RD2_EntryFormController.saveRecurringDonation(req);

        for (String fieldName : req.customFieldValues.keySet()) {
            System.assertNotEquals(NO_CREATE_PERMISSION, fieldName.substringBefore('_'), 'All fields that are not' +
                ' createable should be removed from the save request.');
        }

        System.assert(result.success, 'RD not inserted successfully');
        System.assertNotEquals(result.recordId, null, 'Save result should have an Id');
    }

    @IsTest
    private static void rdCustomFieldsMapToCorrectFieldType() {

        RD2_SaveRequest saveRequest = new RD2_SaveRequest();
        saveRequest.customFieldValues = new Map<String, Object> {
            'TestField' => 'TestFieldValue'
        };

        RD2_SaveRequestHelperMock saveRequestHelperMockInstance = new RD2_SaveRequestHelperMock();
        RD2_SaveRequestHelper saveRequestHelperMock = (RD2_SaveRequestHelper)
            Test.createStub(RD2_SaveRequestHelper.class, saveRequestHelperMockInstance);
        saveRequest.requestHelper = saveRequestHelperMock;

        UTIL_DescribeMock describeMock = getDescribeMock();

        testMapToBoolean(describeMock, saveRequest, saveRequestHelperMockInstance);
        testMapToDate(describeMock, saveRequest, saveRequestHelperMockInstance);
        testMapToDateTime(describeMock, saveRequest, saveRequestHelperMockInstance);
        testMapToTime(describeMock, saveRequest, saveRequestHelperMockInstance);
        testMapToCurrency(describeMock, saveRequest, saveRequestHelperMockInstance);
        testMapToDouble(describeMock, saveRequest, saveRequestHelperMockInstance);
        testMapToInteger(describeMock, saveRequest, saveRequestHelperMockInstance);
    }

    @IsTest
    private static void rdCustomFieldsMapToCorrectFieldTypeWithNullValue() {

        RD2_SaveRequest saveRequest = new RD2_SaveRequest();
        saveRequest.customFieldValues = new Map<String, Object> {
            'TestField' => null
        };

        RD2_SaveRequestHelperMock saveRequestHelperMockInstance = new RD2_SaveRequestHelperMock();
        RD2_SaveRequestHelper saveRequestHelperMock = (RD2_SaveRequestHelper)
                Test.createStub(RD2_SaveRequestHelper.class, saveRequestHelperMockInstance);
        saveRequest.requestHelper = saveRequestHelperMock;

        UTIL_DescribeMock describeMock = getDescribeMock();

        testMapToBoolean(describeMock, saveRequest, saveRequestHelperMockInstance);
        testMapToDate(describeMock, saveRequest, saveRequestHelperMockInstance);
        testMapToDateTime(describeMock, saveRequest, saveRequestHelperMockInstance);
        testMapToTime(describeMock, saveRequest, saveRequestHelperMockInstance);
        testMapToCurrency(describeMock, saveRequest, saveRequestHelperMockInstance);
        testMapToDouble(describeMock, saveRequest, saveRequestHelperMockInstance);
        testMapToInteger(describeMock, saveRequest, saveRequestHelperMockInstance);
    }

    @IsTest
    private static void saveRequestMapsFieldsToRecurringDonation() {
        RD2_SaveRequest req = new RD2_SaveRequest();

        Id fakeCampaignId = UTIL_UnitTestData_TEST.mockId(Campaign.SObjectType);
        Id fakeContactId = UTIL_UnitTestData_TEST.mockId(Contact.SObjectType);
        Id fakeRdId = UTIL_UnitTestData_TEST.mockId(npe03__Recurring_Donation__c.SObjectType);

        Date fakeDate =  Date.newInstance(2022, 1, 15);
        Date fakeDate2 =  Date.newInstance(2022, 1, 14);
        req.dayOfMonth = '15';
        req.recurringStatus = 'Active';
        req.startDate = fakeDate;
        req.dateEstablished = fakeDate2;
        req.recurringFrequency = 1;
        req.contactId = fakeContactId;
        req.recurringStatus = 'Active';
        req.donationValue = 5;
        req.recurringType = 'Open';
        req.recurringPeriod = 'Monthly';
        req.paymentMethod = 'Credit Card';
        req.campaignId = fakeCampaignId;
        req.customFieldValues = new Map<String, Object>{
                // utilizing this field as a fake custom field
                UTIL_Namespace.StrTokenNSPrefix('CommitmentId__c') => '123-456-789'
        };
        req.cardExpirationYear = '2025';
        req.cardExpirationMonth = '2';
        req.recordId = fakeRdId;

        npe03__Recurring_Donation__c rd = req.toRecord();

        System.assertEquals('15', rd.Day_of_Month__c);
        System.assertEquals(fakeDate, rd.StartDate__c);
        System.assertEquals(fakeDate2, rd.npe03__Date_Established__c);
        System.assertEquals(1, rd.InstallmentFrequency__c);
        System.assertEquals('123-456-789', rd.CommitmentId__c);
        System.assertEquals(fakeCampaignId, rd.npe03__Recurring_Donation_Campaign__c);
        System.assertEquals('Credit Card', rd.PaymentMethod__c);
        System.assertEquals(5, rd.npe03__Amount__c);
        System.assertEquals('2025', rd.CardExpirationYear__c);
        System.assertEquals('2', rd.CardExpirationMonth__c);
        System.assertEquals('Active', rd.Status__c);
        System.assertEquals(fakeRdId, rd.Id);
    }


    @IsTest
    private static void saveResponseIncludesErrorInformation() {
        RD2_EnablementService_TEST.setRecurringDonations2Enabled();
        Contact donorContact = getContact();

        RD2_SaveRequest req = new RD2_SaveRequest();

        req.dayOfMonth = '15';
        req.startDate = Date.newInstance(2022, 1, 15);
        req.dateEstablished = Date.newInstance(2022, 1, 15);
        req.recurringFrequency = 1;
        req.contactId = donorContact.Id;
        req.recurringStatus = 'Active';
        req.donationValue = -1;
        req.recurringType = 'Open';
        req.recurringPeriod = 'Monthly';
        req.paymentMethod = 'Credit Card';

        SaveResultView result = RD2_EntryFormController.saveRecurringDonation(req);

        System.assertEquals(false, result.success, 'Expected RD2SaveResult success to be false');
        System.assertEquals(null, result.recordId, 'Expected empty record Id');
        System.assertEquals(Label.RD2_AmountMustBeValid, result.errors[0].message, 'Wrong error message');
    }

    // Helpers
    ////////////////

    /****
    * @description Simulates a successful commitment creation callout
    * @return String
    */
    private static void mockRecordCreatedCalloutResponse() {
        UTIL_Http_TEST.mockRecordCreatedCalloutResponse(mockSuccessResponseBody());
    }

    /****
    * @description Returns a mock response body that mimics response body returned from Elevate
    * when a commitment is created
    * @return String
    */
    private static String mockSuccessResponseBody() {
        return '{"id":"' + COMMITMENT_ID
            + '","status":"ACTIVE","statusReason":"COMMITMENT_CREATED"'
            + ',"version":"' + EVENT_VERSION +'"'
            + ',"cardData":{"last4":"' + CARD_LAST_4
            + '","expirationMonth":"' + CARD_EXPIRATION_MONTH
            + '","expirationYear":"' + CARD_EXPIRATION_YEAR
            + '"}}';
    }

    /****
    * @description Returns contact record
    * @return Contact
    */
    private static Contact getContact() {
        return [
            SELECT FirstName, LastName, AccountId, Account.Name
            FROM Contact
            LIMIT 1
        ];
    }

    /****
    * @description Returns a new Recurring Donation record
    * @return npe03__Recurring_Donation__c
    */
    private static npe03__Recurring_Donation__c buildRecurringDonation() {
        return TEST_RecurringDonationBuilder.constructEnhancedBuilder()
            .withDefaultValues()
            .withContact(getContact().Id)
            .withAmount(100)
            .withDateEstablished(START_DATE)
            .withStartDate(START_DATE)
            .withDayOfMonth('1')
            .withPaymentMethod(RD2_Constants.PAYMENT_PICKLIST_VALUE_CARD)
            .build();
    }

    private static void testMapToBoolean(UTIL_DescribeMock describeMock,
            RD2_SaveRequest saveRequest,
            RD2_SaveRequestHelperMock saveRequestHelperMockInstance) {

        describeMock.setFieldType(DisplayType.BOOLEAN);
        saveRequest.toRecord();
        System.assert(saveRequestHelperMockInstance.setRecurringDonationFieldCalled, 'The setRecurringDonationField ' +
                'method should be called.');
        System.assert(saveRequestHelperMockInstance.paramValues()[2] instanceof Boolean ||
                saveRequestHelperMockInstance.paramValues()[2] == null, 'The boolean value should correctly map to ' +
                'the boolean field type.');
    }

    private static void testMapToDate(UTIL_DescribeMock describeMock,
            RD2_SaveRequest saveRequest,
            RD2_SaveRequestHelperMock saveRequestHelperMockInstance) {

        saveRequest.customFieldValues = new Map<String, Object> {
                'TestDate' => String.valueOf(Date.today())
        };

        describeMock.setFieldType(DisplayType.DATE);
        saveRequest.toRecord();
        System.assert(saveRequestHelperMockInstance.setRecurringDonationFieldCalled);
        System.assert(saveRequestHelperMockInstance.paramValues()[2] instanceof Date ||
                saveRequestHelperMockInstance.paramValues()[2] == null);
    }

    private static void testMapToDateTime(UTIL_DescribeMock describeMock,
            RD2_SaveRequest saveRequest,
            RD2_SaveRequestHelperMock saveRequestHelperMockInstance) {

        saveRequest.customFieldValues = new Map<String, Object> {
            'TestDatetime' => String.valueOf(Datetime.newInstance(
                Date.today().year(),
                Date.today().month(),
                Date.today().day()
            ))
        };

        describeMock.setFieldType(DisplayType.DATETIME);
        saveRequest.toRecord();
        System.assert(saveRequestHelperMockInstance.setRecurringDonationFieldCalled, 'The setRecurringDonationField ' +
                'method should be called.');
        System.assert(saveRequestHelperMockInstance.paramValues()[2] instanceof Datetime ||
            saveRequestHelperMockInstance.paramValues()[2] == null, 'The datetime value should correctly map to ' +
                'the datetime field type.');
    }

    private static void testMapToTime(UTIL_DescribeMock describeMock,
            RD2_SaveRequest saveRequest,
            RD2_SaveRequestHelperMock saveRequestHelperMockInstance) {

        saveRequest.customFieldValues = new Map<String, Object> {
            'TestTime' => String.valueOf(Time.newInstance(
                18, 30, 2, 20
            ))
        };

        describeMock.setFieldType(DisplayType.TIME);
        saveRequest.toRecord();
        System.assert(saveRequestHelperMockInstance.setRecurringDonationFieldCalled, 'The setRecurringDonationField ' +
                'method should be called.');
        System.assert(saveRequestHelperMockInstance.paramValues()[2] instanceof Time ||
            saveRequestHelperMockInstance.paramValues()[2] == null, 'The time value should correctly map to ' +
                'the time field type.');
    }

    private static void testMapToCurrency(UTIL_DescribeMock describeMock,
            RD2_SaveRequest saveRequest,
            RD2_SaveRequestHelperMock saveRequestHelperMockInstance) {

        saveRequest.customFieldValues = new Map<String, Object> {
            'TestCurrency' => 5.00
        };

        describeMock.setFieldType(DisplayType.CURRENCY);
        saveRequest.toRecord();
        System.assert(saveRequestHelperMockInstance.setRecurringDonationFieldCalled, 'The setRecurringDonationField ' +
                'method should be called.');
        System.assert(saveRequestHelperMockInstance.paramValues()[2] instanceof Double ||
            saveRequestHelperMockInstance.paramValues()[2] == null, 'The currency value should correctly map to ' +
                'the double field type.');
    }

    private static void testMapToDouble(UTIL_DescribeMock describeMock,
            RD2_SaveRequest saveRequest,
            RD2_SaveRequestHelperMock saveRequestHelperMockInstance) {

        saveRequest.customFieldValues = new Map<String, Object> {
            'TestDouble' => String.valueOf(15.1524)
        };

        describeMock.setFieldType(DisplayType.DOUBLE);
        saveRequest.toRecord();
        System.assert(saveRequestHelperMockInstance.setRecurringDonationFieldCalled, 'The setRecurringDonationField ' +
                'method should be called.');
        System.assert(saveRequestHelperMockInstance.paramValues()[2] instanceof Double ||
            saveRequestHelperMockInstance.paramValues()[2] == null, 'The double value should correctly map to ' +
                'the double field type.');
    }

    private static void testMapToInteger(UTIL_DescribeMock describeMock,
            RD2_SaveRequest saveRequest,
            RD2_SaveRequestHelperMock saveRequestHelperMockInstance) {

        saveRequest.customFieldValues = new Map<String, Object> {
            'TestInteger' => 15
        };

        describeMock.setFieldType(DisplayType.INTEGER);
        saveRequest.toRecord();
        System.assert(saveRequestHelperMockInstance.setRecurringDonationFieldCalled, 'The setRecurringDonationField ' +
                'method should be called.');
        System.assert(saveRequestHelperMockInstance.paramValues()[2] instanceof Integer ||
            saveRequestHelperMockInstance.paramValues()[2] == null, 'The integer value should correctly map to ' +
                'the integer field type.');
    }

    private static UTIL_DescribeMock getDescribeMock() {
        UTIL_DescribeMock utilDescribeMockInstance = new UTIL_DescribeMock();
        UTIL_Describe utilDescribeMock = (UTIL_Describe) Test.createStub(UTIL_Describe.class,
                utilDescribeMockInstance);
        UTIL_Describe.setInstance(utilDescribeMock);

        return utilDescribeMockInstance;
    }

    public class RD2_QueryServiceMock implements StubProvider {

        npe03__Recurring_Donation__c rd;

        public RD2_QueryServiceMock(npe03__Recurring_Donation__c rd) {
            this.rd = rd;
        }

        public Object handleMethodCall(Object stubbedObject,
                String stubbedMethodName,
                Type returnType,
                List<Type> listOfParamTypes,
                List<String> listOfParamNames,
                List<Object> listOfArgs
        ) {
            return this.rd;
        }
    }

    private class UTIL_PermissionsMock implements StubProvider {
        Boolean canUpdate = false;

        public UTIL_PermissionsMock canUpdate() {
            canUpdate = true;

            return this;
        }

        public Object handleMethodCall(Object stubbedObject, String stubbedMethodName,
                Type returnType, List<Type> paramTypes, List<String> listOfParamNames,
                List<Object> args) {

            switch on stubbedMethodName {
                when 'canCreateInstanced' {
                    if (String.valueOf(args[1]).substringBefore('_').equals(NO_CREATE_PERMISSION)) {
                        return false;
                    }
                }
                when 'canUpdate' {
                    return canUpdate;
                }
            }
            return null;
        }
    }

    private class UTIL_DescribeMock implements StubProvider {
        private DisplayType fieldType;

        public UTIL_DescribeMock setFieldType(DisplayType fieldTypeArg) {
            fieldType = fieldTypeArg;

            return this;
        }

        public DisplayType fieldType() {
            return fieldType;
        }

        public Object handleMethodCall(Object stubbedObject, String stubbedMethodName,
                Type returnType, List<Type> paramTypes, List<String> listOfParamNames,
                List<Object> args) {

            switch on stubbedMethodName {
                when 'getFieldTypeInstance' {
                    return fieldType.name().toUpperCase();
                }
                when 'getObjectDescribeInstance' {
                    return UTIL_Describe.getObjectDescribe(npe03__Recurring_Donation__c.SObjectType);
                }
            }
            return null;
        }
    }

    private class RD2_SaveRequestHelperMock implements StubProvider {
        private Boolean setRecurringDonationFieldCalled;
        private List<Object> parameterValues;

        public List<Object> paramValues() {
            return parameterValues;
        }

        public Object handleMethodCall(Object stubbedObject, String stubbedMethodName,
                Type returnType, List<Type> argTypes, List<String> listOfParamNames,
                List<Object> args) {

            switch on stubbedMethodName {
                when 'setRecurringDonationField' {
                    parameterValues = args;
                    setRecurringDonationFieldCalled = true;
                }
            }
            return null;
        }
    }
}