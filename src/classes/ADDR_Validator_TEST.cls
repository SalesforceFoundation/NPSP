/*
    Copyright (c) 2014, Salesforce.org
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
* @date 2013
* @group Address Management
* @description Tests for the ADDR_Validator class.
*/
@IsTest
public with sharing class ADDR_Validator_TEST {
    private static final String SMARTY_STREETS_VALIDATOR_CLASS = 'ADDR_SmartyStreets_Validator';
    private static final String SMARTY_STREETS_VERIFICATION_ENDPOINT = 'https://api.smartystreets.com/street-address';
    private static final String SETTINGS_NAME = Schema.SObjectType.Addr_Verification_Settings__c.getLabel();
    private static final String ZIP_CODE = '94105';
    private static final String STATUS_ERROR = STG_PanelHealthCheck_CTRL.statusError;
    private static final String STATUS_SUCCESS = STG_PanelHealthCheck_CTRL.statusSuccess;
    private static final String SAVE_SETTINGS_SUCCESS_MESSAGE = System.Label.Saved + '\n';
    private static OrgConfig orgConfig = new OrgConfig();

    @IsTest
    private static void testContactAddress() {
        //skip the test if Advancement is installed
        if (ADV_PackageInfo_SVC.useAdv()) return;

        // address validation is async, so no way to successfully test if other related triggers are already async!
        if (hasAsyncAddrTriggers()) return;

        createDefaultSettings();
        Test.setMock(HttpCalloutMock.class, new ADDR_MockHttpRespGenerator_TEST());

        Contact contact = new Contact(FirstName = 'Test', LastName = getContactLastName());
        contact.MailingStreet = 'single-address';
        contact.MailingCity = 'Cupertino';
        contact.MailingState = 'California';
        contact.MailingPostalCode = '95014';
        contact.MailingCountry = 'United States';

        Test.startTest();
        insert contact;
        Test.stopTest();

        //check household got created for contact
        contact = getContact(contact.Id);

        Address__c[] av = getAddressesForHousehold(contact.AccountId);
        System.assertEquals(1, av.size());
        System.assertEquals('1 Infinite Loop', av[0].MailingStreet__c);
        System.assertEquals('CA', av[0].MailingState__c);
        System.assertEquals('95014-2083', av[0].MailingPostalCode__c);
        System.assertEquals(true, av[0].Verified__c);
        System.assertEquals(Label.Addr_Verified, av[0].Verification_Status__c);

        System.assertEquals('1 Infinite Loop', contact.MailingStreet);
        System.assertEquals('Cupertino', contact.MailingCity);
        System.assertEquals('95014-2083', contact.MailingPostalCode);
        if (orgConfig.isStateCountryPicklistsEnabled()) {
            System.assertEquals('California', contact.MailingState);
        } else {
            System.assertEquals('CA', contact.MailingState);
        }
    }

    /*******************************************************************************************************
    * @description Verify invalid address is verified with expected not found status
    */
    @IsTest
    private static void testContactInvalidAddress() {
        //skip the test if Advancement is installed
        if (ADV_PackageInfo_SVC.useAdv()) return;

        // address validation is async, so no way to successfully test if other related triggers are already async!
        if (hasAsyncAddrTriggers()) return;

        createDefaultSettings();
        Test.setMock(HttpCalloutMock.class, new ADDR_MockHttpRespGenerator_TEST());

        Contact contact = buildContactOnStreet('invalid-address');

        Test.startTest();
        insert contact;
        Test.stopTest();

        assertVerifiedAddressWithStatus(Label.Address_Not_Found, contact.Id);
    }

    /*******************************************************************************************************
    * @description Verify bad input address verification
    */
    @IsTest
    private static void testAddressVerificationResponse400() {
        //skip the test if Advancement is installed
        if (ADV_PackageInfo_SVC.useAdv()) return;

        // address validation is async, so no way to successfully test if other related triggers are already async!
        if (hasAsyncAddrTriggers()) return;

        createDefaultSettings();
        Test.setMock(HttpCalloutMock.class, new ADDR_MockHttpRespGenerator_TEST());

        Contact contact = buildContactOnStreet('400 error');

        Test.startTest();
        insert contact;
        Test.stopTest();

        assertUnverifiedAddressWithStatus('Bad input. Required fields missing from input or are malformed.', contact.Id);
    }

    /*******************************************************************************************************
    * @description Verify unauthorized access on address verification
    */
    @IsTest
    private static void testAddressVerificationResponse401() {
        //skip the test if Advancement is installed
        if (ADV_PackageInfo_SVC.useAdv()) return;

        // address validation is async, so no way to successfully test if other related triggers are already async!
        if (hasAsyncAddrTriggers()) return;

        createDefaultSettings();
        Test.setMock(HttpCalloutMock.class, new ADDR_MockHttpRespGenerator_TEST());

        Contact contact = buildContactOnStreet('401 error');

        Test.startTest();
        insert contact;
        Test.stopTest();

        assertUnverifiedAddressWithStatus('Unauthorized. Authentication failure; invalid credentials.', contact.Id);
    }

    /*******************************************************************************************************
    * @description Verify inactive subscription on address verification
    */
    @IsTest
    private static void testAddressVerificationResponse402() {
        //skip the test if Advancement is installed
        if (ADV_PackageInfo_SVC.useAdv()) return;

        // address validation is async, so no way to successfully test if other related triggers are already async!
        if (hasAsyncAddrTriggers()) return;

        createDefaultSettings();
        Test.setMock(HttpCalloutMock.class, new ADDR_MockHttpRespGenerator_TEST());

        Contact contact = buildContactOnStreet('402 error');

        Test.startTest();
        insert contact;
        Test.stopTest();

        assertUnverifiedAddressWithStatus('Payment required. No active subscription found.', contact.Id);
    }

    /*******************************************************************************************************
    * @description Verify iternal server error on address verification
    */
    @IsTest
    private static void testAddressVerificationResponse500() {
        //skip the test if Advancement is installed
        if (ADV_PackageInfo_SVC.useAdv()) return;

        // address validation is async, so no way to successfully test if other related triggers are already async!
        if (hasAsyncAddrTriggers()) return;

        createDefaultSettings();
        Test.setMock(HttpCalloutMock.class, new ADDR_MockHttpRespGenerator_TEST());

        Contact contact = buildContactOnStreet('500 error');

        Test.startTest();
        insert contact;
        Test.stopTest();

        assertUnverifiedAddressWithStatus('Internal server error. General service failure; retry request.', contact.Id);
    }

    /*******************************************************************************************************
    * @description Verify ambiguous result on address verification
    */
    @IsTest
    private static void testContactAmbiguousAddress() {
        //skip the test if Advancement is installed
        if (ADV_PackageInfo_SVC.useAdv()) return;

        // address validation is async, so no way to successfully test if other related triggers are already async!
        if (hasAsyncAddrTriggers()) return;

        createDefaultSettings();
        Test.setMock(HttpCalloutMock.class, new ADDR_MockHttpRespGenerator_TEST());

        Contact contact = buildContactOnStreet('ambiguous-address');

        Test.startTest();
        insert contact;
        Test.stopTest();

        //check household got created for contact
        contact = getContact(contact.Id);

        Address__c[] av = getAddressesForHousehold(contact.AccountId);
        System.assertEquals(1, av.size());
        System.assertEquals(true, av[0].Verified__c);
        System.assertEquals(true, av[0].Ambiguous__c);
        System.assertEquals(Label.Addr_Verified, av[0].Verification_Status__c);
    }

    /*******************************************************************************************************
    * @description Verify zip code address verification
    */
    @IsTest
    private static void testContactZipOnly() {
        //skip the test if Advancement is installed
        if (ADV_PackageInfo_SVC.useAdv()) return;

        // address validation is async, so no way to successfully test if other related triggers are already async!
        if (hasAsyncAddrTriggers()) return;

        createDefaultSettings();
        Test.setMock(HttpCalloutMock.class, new ADDR_MockHttpRespGenerator_TEST());

        Contact contact = new Contact(FirstName = 'Test', LastName = getContactLastName());
        contact.MailingPostalCode = '94105';
        contact.MailingCity = 'single-zip';
        contact.MailingCountry = 'United States';

        Test.startTest();
        insert contact;
        Test.stopTest();

        //check household got created for contact
        contact = getContact(contact.Id);

        Address__c[] av = getAddressesForHousehold(contact.AccountId);
        System.assertEquals('98236', av[0].MailingPostalCode__c);
        System.assertEquals('Clinton', av[0].MailingCity__c);
        System.assertEquals(true, av[0].Verified__c);
        System.assertEquals(Label.Addr_Verified, av[0].Verification_Status__c);

        System.assertEquals(null, contact.MailingStreet);
        System.assertEquals('Clinton', contact.MailingCity);
        System.assertEquals('98236', contact.MailingPostalCode);
    }

    /*******************************************************************************************************
    * @description Verify city and state address verification
    */
    @IsTest
    private static void testContactCityAndStateOnly() {
        //skip the test if Advancement is installed
        if (ADV_PackageInfo_SVC.useAdv()) return;

        // address validation is async, so no way to successfully test if other related triggers are already async!
        if (hasAsyncAddrTriggers()) return;

        createDefaultSettings();
        Test.setMock(HttpCalloutMock.class, new ADDR_MockHttpRespGenerator_TEST());

        Contact contact = new Contact(FirstName = 'Test', LastName = getContactLastName());
        contact.MailingCity = 'single-zip';
        contact.MailingState = 'Illinois';
        contact.MailingCountry = 'United States';

        Test.startTest();
        insert contact;
        Test.stopTest();

        //check household got created for contact
        contact = getContact(contact.Id);

        Address__c[] av = getAddressesForHousehold(contact.AccountId);
        System.assertEquals('98236', av[0].MailingPostalCode__c);
        System.assertEquals('Clinton', av[0].MailingCity__c);
        System.assertEquals(true, av[0].Verified__c);
        System.assertEquals(Label.Addr_Verified, av[0].Verification_Status__c);

        System.assertEquals(null, contact.MailingStreet);
        System.assertEquals('Clinton', contact.MailingCity);
        System.assertEquals('98236', contact.MailingPostalCode);
    }

    /*******************************************************************************************************
    * @description Verify methods on the controller
    */
    @IsTest
    private static void testController() {
        STG_PanelADDRVerification_CTRL sc = new STG_PanelADDRVerification_CTRL();
        sc.initDynamicFields(); //this will also set the settings property

        sc.addrVerifSettings.Auth_ID__c = 'testID';
        sc.addrVerifSettings.Auth_Token__c = 'testToken';
        sc.addrVerifSettings.Address_Verification_Endpoint__c = SMARTY_STREETS_VERIFICATION_ENDPOINT;
        sc.addrVerifSettings.Class__c = SMARTY_STREETS_VALIDATOR_CLASS;
        sc.saveSettings();
        System.assertEquals(SAVE_SETTINGS_SUCCESS_MESSAGE, sc.apiSettingsSaveMessage);

        sc.apiTestEntry = ZIP_CODE;
        sc.testApi();
        System.assertNotEquals(null, sc.apiTestResult);

        Test.startTest();
        sc.batchVerify();
        Test.stopTest();

        //The batch has its own test. This basically tests that no exception was thrown
        //since it got to set the status variable.
        System.assertEquals(true, sc.isRunningBatch);
    }

    /*******************************************************************************************************
    * @description Verify no error is generated when validation class is not set when settings are saved
    */
    @IsTest
    private static void testBlankService() {
        STG_PanelADDRVerification_CTRL sc = new STG_PanelADDRVerification_CTRL();
        sc.initDynamicFields(); //this will also set the settings property

        sc.addrVerifSettings.Auth_ID__c = 'testID';
        sc.addrVerifSettings.Auth_Token__c = 'testToken';
        sc.addrVerifSettings.Address_Verification_Endpoint__c = SMARTY_STREETS_VERIFICATION_ENDPOINT;
        sc.addrVerifSettings.Class__c = '';
        sc.saveSettings();
        System.assertEquals(SAVE_SETTINGS_SUCCESS_MESSAGE, sc.apiSettingsSaveMessage);
    }

    /*******************************************************************************************************
    * @description Verify API token and ID are required when validation class is Smarty Streets validation
    */
    @IsTest
    private static void testControllerMissingSetting() {
        STG_PanelADDRVerification_CTRL sc = new STG_PanelADDRVerification_CTRL();
        sc.initDynamicFields(); //this will also set the settings property

        sc.addrVerifSettings.Class__c = SMARTY_STREETS_VALIDATOR_CLASS;

        Test.startTest();
        sc.saveSettings();
        Test.stopTest();

        System.assertEquals(null, sc.apiSettingsSaveMessage,
            'Save message should be empty: ' + sc.apiSettingsSaveMessage);
        System.assert(sc.apiSettingsErrorMessage.contains(System.Label.Addr_Id_Error),
            'Error message should contain "' + System.Label.Addr_Id_Error + '": ' + sc.apiSettingsErrorMessage);
        System.assert(sc.apiSettingsErrorMessage.contains(System.Label.Addr_Token_Error),
            'Error message should contain "' + System.Label.Addr_Token_Error + '": ' + sc.apiSettingsErrorMessage);
    }

    /*******************************************************************************************************
    * @description Verify previously validated address is not validated again
    */
    @IsTest
    private static void dontValidatePreviouslyValidatedAddresses() {
        //skip the test if Advancement is installed
        if (ADV_PackageInfo_SVC.useAdv()) return;

        // address validation is async, so no way to successfully test if other related triggers are already async!
        if (hasAsyncAddrTriggers()) return;

        Contact contact = new Contact(FirstName = 'Test', LastName = getContactLastName());
        contact.MailingStreet = 'single-address';
        contact.MailingCity = 'Cupertino';
        contact.MailingState = 'California';
        contact.MailingPostalCode = '95014';
        contact.MailingCountry = 'United States';

        insert contact;

        //check household got created for contact
        contact = getContact(contact.Id);

        Address__c[] av = getAddressesForHousehold(contact.AccountId);
        System.assertEquals(1, av.size());
        System.assertEquals(false, av[0].Verified__c);
        System.assertEquals(null, av[0].Verification_Status__c);

        createDefaultSettings();
        Test.setMock(HttpCalloutMock.class, new ADDR_MockHttpRespGenerator_TEST());
        av[0].Verified__c = true;

        Test.startTest();
        update av[0];
        Test.stopTest();

        Address__c updatedAddress = getAddress(av[0].Id);
        System.assertEquals(true, updatedAddress.Verified__c);
        System.assertEquals(null, updatedAddress.Verification_Status__c, 'Address should not have been verified');
        System.assertEquals('single-address', updatedAddress.MailingStreet__c);

        //now, use the button and make sure the address verification happens, despite the fact that Verified is already checked.
        PageReference pageRef = Page.ADDR_ValidatorBTN;
        pageRef.getParameters().put('id', av[0].Id);
        Test.setCurrentPage(pageRef);

        ApexPages.StandardController standardController = new ApexPages.StandardController(av[0]);
        ADDR_Validator ctrl = new ADDR_Validator(standardController);

        ctrl.verifyAddressButton();

        updatedAddress = getAddress(av[0].Id);
        System.assertEquals(true, updatedAddress.Verified__c);
        System.assertEquals(Label.Addr_Verified, updatedAddress.Verification_Status__c, 'Address should have been verified');
        System.assertEquals('1 Infinite Loop', updatedAddress.MailingStreet__c);
    }

    /*******************************************************************************************************
    * @description Verify the page does not display API key and other address verification settings
    * when user has no permission to view the page
    */
    @IsTest
    private static void shouldNotRetrieveApiSettingsWhenUserHasNoAccess() {
        createDefaultSettings();

        Test.setCurrentPage(Page.STG_PanelAddrVerification);
        AddressVerifierExtension addrVerifier = new AddressVerifierExtension().returnHasAccess(false);
        STG_PanelADDRVerification_CTRL.addrVerifier = addrVerifier;
        STG_PanelADDRVerification_CTRL ctrl = new STG_PanelADDRVerification_CTRL();

        assertAuthIdAndTokenAreNull(ctrl);

        ctrl.initDynamicFields();
        assertAuthIdAndTokenAreNull(ctrl);

        ctrl.apiTestEntry = ZIP_CODE;
        ctrl.testApi();
        System.assertEquals(System.Label.stgAddrPermissionDenied, ctrl.apiTestResult);
        assertAuthIdAndTokenAreNull(ctrl);
    }

    /*******************************************************************************************************
    * @description Verify permission denied message is displayed on health check panel
    * when read only user verifies address
    */
    @IsTest
    private static void healthCheckShouldDisplayPermissionDeniedMessageWhenUserHasNoAccess() {
        createDefaultSettings();

        STG_PanelHealthCheck_CTRL healthCheckPanel = new STG_PanelHealthCheck_CTRL();
        AddressVerifierExtension addrVerifier = new AddressVerifierExtension().returnHasAccess(false);
        STG_PanelADDRVerification_CTRL.addrVerifier = addrVerifier;
        STG_PanelADDRVerification_CTRL ctrl = new STG_PanelADDRVerification_CTRL();

        ctrl.verifyAddressVerificationService(healthCheckPanel);

        System.assertEquals(1, healthCheckPanel.listDR.size(), 'Expecting one defect result: ' + healthCheckPanel.listDR);
        System.assertEquals(System.Label.stgAddrPermissionDenied, healthCheckPanel.listDR[0].strDetails);
        System.assertEquals(SETTINGS_NAME, healthCheckPanel.listDR[0].strName);
        System.assertEquals(STATUS_ERROR, healthCheckPanel.listDR[0].strStatus);
        System.assertEquals(null, healthCheckPanel.listDR[0].strSolution);
    }

    /*******************************************************************************************************
    * @description Verify no message is displayed when address validator is not Smarty Streets validator
    */
    @IsTest
    private static void healthCheckShouldNotReturnAnyMessageWhenValidatorIsNotSmartyStreets() {
        Addr_Verification_Settings__c settings = createDefaultSettings();
        settings.Class__c = 'ADDR_Foo_Validator';

        STG_PanelHealthCheck_CTRL healthCheckPanel = new STG_PanelHealthCheck_CTRL();
        AddressVerifierExtension addrVerifier = new AddressVerifierExtension().returnHasAccess(false);
        STG_PanelADDRVerification_CTRL.addrVerifier = addrVerifier;
        STG_PanelADDRVerification_CTRL ctrl = new STG_PanelADDRVerification_CTRL();

        ctrl.verifyAddressVerificationService(healthCheckPanel);
        System.assertEquals(0, healthCheckPanel.listDR.size(), 'Expecting no defect result: ' + healthCheckPanel.listDR);
    }

    /*******************************************************************************************************
    * @description Verify address verification is done on health check panel and message displayed
    * when system admin verifies address that is not valid.
    */
    @IsTest
    private static void healthCheckShouldDisplayMessageOnAddressVerificationError() {
        final String expectedMessage = 'Test Smarty Streets: Not valid';
        final String expectedSolution = String.format(
            System.Label.healthSolutionEditSetting,
            new String[]{ SETTINGS_NAME, System.Label.stgNavHouseholds, System.Label.stgNavAddressVerification }
        );

        createDefaultSettings();
        MockAddressVerifier addrVerifier = new MockAddressVerifier()
            .returnHasAccess(true)
            .returnVerifyServiceResult(expectedMessage);
        STG_PanelADDRVerification_CTRL.addrVerifier = addrVerifier;

        STG_PanelHealthCheck_CTRL healthCheckPanel = new STG_PanelHealthCheck_CTRL();
        STG_PanelADDRVerification_CTRL ctrl = new STG_PanelADDRVerification_CTRL();
        ctrl.verifyAddressVerificationService(healthCheckPanel);

        System.assertEquals(1, healthCheckPanel.listDR.size(), 'Expecting one defect result: ' + healthCheckPanel.listDR);
        System.assertEquals(expectedMessage, healthCheckPanel.listDR[0].strDetails);
        System.assertEquals(SETTINGS_NAME, healthCheckPanel.listDR[0].strName);
        System.assertEquals(STATUS_ERROR, healthCheckPanel.listDR[0].strStatus);
        System.assertEquals(expectedSolution, healthCheckPanel.listDR[0].strSolution);
    }

    /*******************************************************************************************************
    * @description Verify address verification is done on health check panel and message displayed
    * when system admin verifies address that is valid.
    */
    @IsTest
    private static void healthCheckShouldDisplaySuccessWhenAddressIsValidated() {
        final String expectedMessage = 'Test Smarty Streets: is valid';

        createDefaultSettings();
        MockAddressVerifier addrVerifier = new MockAddressVerifier()
            .returnHasAccess(true)
            .returnVerifyServiceResult(expectedMessage);
        STG_PanelADDRVerification_CTRL.addrVerifier = addrVerifier;

        STG_PanelHealthCheck_CTRL healthCheckPanel = new STG_PanelHealthCheck_CTRL();
        STG_PanelADDRVerification_CTRL ctrl = new STG_PanelADDRVerification_CTRL();
        ctrl.verifyAddressVerificationService(healthCheckPanel);

        System.assertEquals(1, healthCheckPanel.listDR.size(), 'Expecting one defect result: ' + healthCheckPanel.listDR);
        System.assertEquals(null, healthCheckPanel.listDR[0].strDetails);
        System.assertEquals(SETTINGS_NAME, healthCheckPanel.listDR[0].strName);
        System.assertEquals(STATUS_SUCCESS, healthCheckPanel.listDR[0].strStatus);
        System.assertEquals(expectedMessage, healthCheckPanel.listDR[0].strSolution);
    }

    /*******************************************************************************************************
    * @description Verify unencoded token is encoded when the validator is SmartyStreets
    */
    @IsTest
    private static void shouldEncodeUnencodedSmartyStreetsToken() {
        Addr_Verification_Settings__c settings = createDefaultSettings();
        String token = settings.Auth_Token__c;
        String encodedToken = EncodingUtil.urlEncode(token, 'UTF-8');

        System.assertEquals(SMARTY_STREETS_VALIDATOR_CLASS, settings.Class__c);
        System.assertNotEquals(null, settings.Auth_Token__c);

        AddressVerifierExtension addrVerifier = new AddressVerifierExtension();
        addrVerifier.encodeToken(settings);

        System.assertNotEquals(token, settings.Auth_Token__c, 'Token should be changed');
        System.assertEquals(encodedToken, settings.Auth_Token__c, 'Token should be encoded');
    }

    /*******************************************************************************************************
    * @description Verify already encoded token is not encoded again
    */
    @IsTest
    private static void shouldNotEncodeAlreadyEncodedSmartyStreetsToken() {
        Addr_Verification_Settings__c settings = createDefaultSettings();
        String encodedToken = EncodingUtil.urlEncode(settings.Auth_Token__c, 'UTF-8');
        settings.Auth_Token__c = encodedToken;

        AddressVerifierExtension addrVerifier = new AddressVerifierExtension();
        addrVerifier.encodeToken(settings);

        System.assertEquals(encodedToken, settings.Auth_Token__c, 'Already encoded token should not be encoded again');
    }

    /*******************************************************************************************************
    * @description Verify unencoded token is not encoded when the validator is not SmartyStreets
    */
    @IsTest
    private static void shouldNotEncodeUnencodedTokenWhenValidatorIsNotSmartyStreets() {
        Addr_Verification_Settings__c settings = createDefaultSettings();
        String token = settings.Auth_Token__c;
        String encodedToken = EncodingUtil.urlEncode(token, 'UTF-8');

        settings.Class__c = 'foo';

        AddressVerifierExtension addrVerifier = new AddressVerifierExtension();
        addrVerifier.encodeToken(settings);

        System.assertEquals(token, settings.Auth_Token__c, 'Token should not be changed');
        System.assertNotEquals(encodedToken, settings.Auth_Token__c, 'Token should not be encoded');
    }


    /*******************************************************************************************************
    * @description Verify system admin has access to verify address
    */
    @IsTest
    private static void hasAccessShouldReturnTrueWhenUserIsSystemAdmin() {
        STG_PanelADDRVerification_CTRL ctrl = new STG_PanelADDRVerification_CTRL();

        System.assertEquals(true, ctrl.hasAccess, 'System admin should have access to verify address');
    }

    /*******************************************************************************************************
    * @description Verify read only user does not have access to verify address
    */
    @IsTest
    private static void hasAccessShouldReturnFalseWhenUserHasNoAcceessOnAddress() {
        User readOnlyUser = UTIL_UnitTestData_TEST.createUser(UTIL_UnitTestData_TEST.PROFILE_READONLY_USER);

        System.runAs(readOnlyUser) {
            STG_PanelADDRVerification_CTRL ctrl = new STG_PanelADDRVerification_CTRL();

            System.assertEquals(false, ctrl.hasAccess, 'Read-only user should not have access to verify address');
        }
    }

    /*******************************************************************************************************
    * @description Verify address validation service returns permission denied message when
    * user has no access to verify address
    */
    @IsTest
    private static void verifyServiceShouldReturnPermissionDeniedMessageWhenUserHasNoAccess() {
        Addr_Verification_Settings__c settings = createDefaultSettings();

        AddressVerifierExtension addrVerifier = new AddressVerifierExtension().returnHasAccess(false);

        String result = addrVerifier.verifyService(settings, ZIP_CODE);
        System.assertEquals(System.Label.stgAddrPermissionDenied, result);
    }

    /*******************************************************************************************************
    * @description Verify address validation service returns null when validator is not Smarty Streets
    */
    @IsTest
    private static void verifyServiceShouldReturnNullWhenValidatorIsNotSmartyStreets() {
        Addr_Verification_Settings__c settings = createDefaultSettings();
        settings.Class__c = 'foo';

        AddressVerifierExtension addrVerifier = new AddressVerifierExtension();

        String result = addrVerifier.verifyService(settings, ZIP_CODE);
        System.assertEquals(null, result);
    }

    /*******************************************************************************************************
    * @description Verify address validation service is verified when user has access to verify address and
    * validator is Smarty Streets
    */
    @IsTest
    private static void verifyServiceShouldReturnVerificationMessageWhenAddressIsValidated() {
        Addr_Verification_Settings__c settings = createDefaultSettings();
        AddressVerifierExtension addrVerifier = new AddressVerifierExtension();

        Test.startTest();//required to be called just before Test.setMock();
        Test.setMock(HttpCalloutMock.class, new MockSmartyStreetsService());

        String result = addrVerifier.verifyService(settings, ZIP_CODE);
        System.assertEquals(System.Label.Addr_Valid_Key_Pair, result);
        Test.stopTest();
    }

    /**
     * @description Verify that a "standard" user instantiates the right permissions controller in the addr validation
     * class - specifically not the "escalated" permissions version.
     * Note: It's not possible to simulate a guest site user in an org without sites enabled.
     */
    @IsTest
    private static void shouldUseCorrectPermServiceForNonGuestSiteUser() {
        User stdUser = UTIL_UnitTestData_TEST.createStandardProfileUser();

        System.runAs(stdUser) {
            Boolean isStanderdPerm = (ADDR_Validator.dbActions instanceof ADDR_Validator.StandardPermissions);
            Boolean isEscelatedPerm = (ADDR_Validator.dbActions instanceof ADDR_Validator.EscalatedPermissions);

            System.assertEquals(true, isStanderdPerm, 'The default action should be that the User uses Standard Permissions');
            System.assertEquals(false, isEscelatedPerm, 'The default action should be that the User does NOT uses Escalated Permissions');
        }
    }

    // Helpers
    //////////////

    /*******************************************************************************************************
    * @description Returns true if address triggers are async
    * @return Boolean
    */
    private static Boolean hasAsyncAddrTriggers() {
        return TDTM_DefaultConfig.ADDR_Address_TDTM_TestAsync ||
            TDTM_DefaultConfig.ADDR_Contact_TDTM_TestAsync ||
            TDTM_DefaultConfig.ADDR_Account_TDTM_TestAsync;
    }

    /*******************************************************************************************************
    * @description Creates Address Verification Settings
    * @return Addr_Verification_Settings__c
    */
    public static Addr_Verification_Settings__c createDefaultSettings() {
        // use the household account model
        UTIL_CustomSettingsFacade.getContactsSettings();

        // create the basic api settings
        Addr_Verification_Settings__c settings = UTIL_CustomSettingsFacade.getAddressVerificationSettings();
        settings.Auth_ID__c = 'foo';
        settings.Auth_Token__c = getSmartyStreetsUnencodedToken();
        settings.Class__c = SMARTY_STREETS_VALIDATOR_CLASS;
        settings.Address_Verification_Endpoint__c = SMARTY_STREETS_VERIFICATION_ENDPOINT;
        settings.Enable_Automatic_Verification__c = true;
        settings.Reject_Ambiguous_Addresses__c = true;

        return settings;
    }

    /*******************************************************************************************************
    * @description Returns Smarty Streets unencoded token
    * @return String Token
    */
    private static String getSmartyStreetsUnencodedToken() {
        final Integer unencodedTokenLen = 88;
        Blob key = Crypto.generateAesKey(128);

        return String.valueOf(key).rightPad(unencodedTokenLen, 'ABC123').left(unencodedTokenLen);
    }

    /*******************************************************************************************************
    * @description Builds Contact record
    * @param street Mailing Street
    * @return Contact
    */
    private static Contact buildContactOnStreet(String street) {
        Contact contact = new Contact(FirstName = 'Test', LastName = getContactLastName());
        contact.MailingStreet = street;
        contact.MailingCity = 'chicago';
        contact.MailingState = 'Illinois';
        contact.MailingPostalCode = '60606';
        contact.MailingCountry = 'United States';

        return contact;
    }

    /*******************************************************************************************************
    * @description Builds a random string that can represent a random contact last name
    * @return String
    */
    private static String getContactLastName() {
        final Integer maxLastNameLength = 80;

        Blob key = Crypto.generateAesKey(128);
        String encodedKey = EncodingUtil.base64Encode(key);
        return encodedKey.left(maxLastNameLength);
    }

    /*******************************************************************************************************
    * @description Retrieves the Address details
    * @param addressId Address__c.Id
    * @return Address__c Retrieved Address
    */
    private static Address__c getAddress(Id addressId) {
        Address__c addr = [
            SELECT MailingStreet__c, MailingCity__c,
                MailingState__c, MailingPostalCode__c,
                Verified__c, Verification_Status__c,
                Ambiguous__c
            FROM Address__c
            WHERE Id = :addressId
        ];

        return addr;
    }


    /*******************************************************************************************************
    * @description Retrieves Addresses for a Household
    * @param hhId Household Id
    * @return List<Address__c> List of addresses for the household
    */
    private static List<Address__c> getAddressesForHousehold(Id hhId) {
        return [
            SELECT MailingStreet__c, MailingCity__c,
                MailingState__c, MailingPostalCode__c,
                Verified__c, Verification_Status__c,
                Ambiguous__c
            FROM Address__c
            WHERE Household_Account__c = :hhId
        ];
    }

    /*******************************************************************************************************
    * @description Retrieves the Contact details
    * @param contactId Contact Id
    * @return Contact Retrieved contact
    */
    private static Contact getContact(Id contactId) {
        Contact c = [
            SELECT AccountId, Account.Id,
                MailingStreet, MailingCity, MailingState, MailingPostalCode
            FROM Contact
            WHERE Id = :contactId
        ];

        return c;
    }

    /*******************************************************************************************************
    * @description Asserts verified address
    * @param verificationStatus Verification Status on address
    * @param contactId Contact Id
    */
    private static void assertVerifiedAddressWithStatus(String verificationStatus, Id contactId) {
        assertAddressWithStatus(verificationStatus, contactId, true);
    }

    /*******************************************************************************************************
    * @description Asserts unverified address
    * @param verificationStatus Verification Status on address
    * @param contactId Contact Id
    */
    private static void assertUnverifiedAddressWithStatus(String verificationStatus, Id contactId) {
        assertAddressWithStatus(verificationStatus, contactId, false);
    }

    /*******************************************************************************************************
    * @description Asserts address verification result
    * @param verificationStatus Verification Status on address
    * @param contactId Contact Id
    * @param isVerified Verified flag on address
    */
    private static void assertAddressWithStatus(String verificationStatus, Id contactId, Boolean isVerified) {
        //check household got created for contact
        Contact contact = getContact(contactId);
        System.assertNotEquals(null, contact.AccountId);

        Address__c[] av = getAddressesForHousehold(contact.AccountId);
        System.assertEquals(1, av.size());
        System.assertEquals(isVerified, av[0].Verified__c);
        System.assertEquals(verificationStatus, av[0].Verification_Status__c);
    }

    /*******************************************************************************************************
    * @description Assert Address Verification Settings Authorization ID and Token are not retrieved
    * @param ctrl Address verification controller
    */
    private static void assertAuthIdAndTokenAreNull(STG_PanelADDRVerification_CTRL ctrl) {
        System.assertEquals(null, ctrl.addrVerifSettings.Auth_ID__c, 'Auth Id should not be displayed on Settings');
        System.assertEquals(null, ctrl.addrVerifSettings.Auth_Token__c, 'Auth Token should not be displayed on Settings');
    }

    /*******************************************************************************************************
    * @description Address verifier that stubs hasAccess()
    */
    private class AddressVerifierExtension extends STG_PanelADDRVerification_CTRL.AddressVerifier {
        private Boolean hasAccess = true;

        private AddressVerifierExtension returnHasAccess(Boolean hasAccess) {
            this.hasAccess = hasAccess;
            return this;
        }

        public override Boolean hasAccess() {
            return hasAccess;
        }
    }

    /*******************************************************************************************************
    * @description Address Verifier Mock
    */
    private class MockAddressVerifier implements STG_PanelADDRVerification_CTRL.IAddressVerifier {
        private String result = null;
        private Boolean hasAccess = true;
        private Integer runVerifyService = 0;
        private Integer runHasAccess = 0;
        private Integer runEncodeTokenCount = 0;

        private MockAddressVerifier returnVerifyServiceResult(String result) {
            this.result = result;
            return this;
        }

        private MockAddressVerifier returnHasAccess(Boolean hasAccess) {
            this.hasAccess = hasAccess;
            return this;
        }

        public String verifyService(Addr_Verification_Settings__c settings, String zipCode) {
            runVerifyService++;
            return result;
        }

        public Boolean hasAccess() {
            runHasAccess++;
            return hasAccess;
        }

        public void encodeToken(Addr_Verification_Settings__c settings) {
            runEncodeTokenCount++;
        }
    }

    /*******************************************************************************************************
    * @description Smarty Streets Service Mock
    */
    private class MockSmartyStreetsService implements HttpCalloutMock {
        private Integer statusCode = 201;
        private String status = null;

        private MockSmartyStreetsService returnStatusCode(Integer statusCode) {
            this.statusCode = statusCode;
            return this;
        }

        private MockSmartyStreetsService returnStatus(String status) {
            this.status = status;
            return this;
        }

        public HttpResponse respond(HttpRequest request) {
            HttpResponse response = new HttpResponse();
            response.setHeader('Content-Type', 'application/json');
            response.setStatusCode(statusCode);

            if (String.isNotBlank(status)) {
                response.setStatus(status);
            }

            return response;
        }
    }
}
