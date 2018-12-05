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
@isTest
public with sharing class ADDR_Validator_TEST {
    private static final String SMARTY_STREETS_VALIDATOR_CLASS = 'ADDR_SmartyStreets_Validator';
    private static final String SMARTY_STREETS_VERIFICATION_ENDPOINT = 'https://api.smartystreets.com/street-address';
    private static final String SETTINGS_NAME = Schema.SObjectType.Addr_Verification_Settings__c.getLabel();
    
    @isTest
    private static void testContactAddress() {
        //skip the test if Advancement is installed
        if (ADV_PackageInfo_SVC.useAdv()) return;

        // address validation is async, so no way to successfully test if other related triggers are already async!
        if (hasAsyncAddrTriggers()) return;
        
        createDefaultSettings();
        Test.setMock(HttpCalloutMock.class, new ADDR_MockHttpRespGenerator_TEST());
              
        Contact contact = new Contact(FirstName = 'Test', LastName = 'Person'); 
        contact.MailingStreet = 'single-address';
        contact.MailingCity = 'Cupertino';
        contact.MailingState = 'California';
        contact.MailingPostalCode = '95014';
        contact.MailingCountry = 'United States';
        
        Test.StartTest();
        insert contact;
        Test.StopTest();
        
        //check household got created for contact
        contact = getContact(contact.Id);
        Id accountId = contact.Account.Id;
        System.assertNotEquals(null, accountId);
        
        Address__c[] av = getAddressesForHousehold(accountId);
        System.assertEquals(1, av.size());
        System.assertEquals('1 Infinite Loop', av[0].MailingStreet__c);
        System.assertEquals('CA', av[0].MailingState__c);
        System.assertEquals('95014-2083', av[0].MailingPostalCode__c);
        System.assertEquals(true, av[0].Verified__c);
        System.assertEquals(Label.Addr_Verified, av[0].Verification_Status__c);
        
        contact = getContact(contact.Id);
        System.assertEquals('1 Infinite Loop', contact.MailingStreet);
        System.assertEquals('Cupertino', contact.MailingCity);
        System.assertEquals('95014-2083', contact.MailingPostalCode);
        if (ADDR_Addresses_TDTM.isStateCountryPicklistsEnabled)            
            System.assertEquals('California', contact.MailingState);
        else
            System.assertEquals('CA', contact.MailingState);
    }

    @isTest
    private static void testContactInvalidAddress() {
        //skip the test if Advancement is installed
        if (ADV_PackageInfo_SVC.useAdv()) return;

        // address validation is async, so no way to successfully test if other related triggers are already async!
        if (hasAsyncAddrTriggers()) return;
        
        createDefaultSettings();
        Test.setMock(HttpCalloutMock.class, new ADDR_MockHttpRespGenerator_TEST());
              
        Contact contact = new Contact(FirstName = 'Test', LastName = 'Person'); 
        contact.MailingStreet = 'invalid-address';
        contact.MailingCity = 'chicago';
        contact.MailingState = 'Illinois';
        contact.MailingPostalCode = '60606';
        contact.MailingCountry = 'United States';
        
        Test.StartTest();
        insert contact;
        Test.StopTest();
        
        //check household got created for contact
        contact = getContact(contact.Id);
        Id accountId = contact.Account.Id;
        System.assertNotEquals(null, accountId);

        Address__c[] av = getAddressesForHousehold(contact.AccountId);      
        System.assertEquals(1, av.size());
        System.assertEquals(true, av[0].Verified__c);
        System.assertEquals(Label.Address_Not_Found, av[0].Verification_Status__c);
    }
    
    @isTest
    private static void test400() {
        //skip the test if Advancement is installed
        if (ADV_PackageInfo_SVC.useAdv()) return;

        // address validation is async, so no way to successfully test if other related triggers are already async!
        if (hasAsyncAddrTriggers()) return;
        
        Addr_Verification_Settings__c settings = createDefaultSettings();
        Test.setMock(HttpCalloutMock.class, new ADDR_MockHttpRespGenerator_TEST());
              
        Contact contact = new Contact(FirstName = 'Test', LastName = 'Person'); 
        contact.MailingStreet = '400 error';
        contact.MailingCity = 'chicago';
        contact.MailingState = 'Illinois';
        contact.MailingPostalCode = '60606';
        contact.MailingCountry = 'United States';
        
        Test.StartTest();
        insert contact;
        Test.StopTest();
        
        //check household got created for contact
        contact = getContact(contact.Id);
        Id accountId = contact.Account.Id;
        System.assertNotEquals(null, accountId);

        Address__c[] av = getAddressesForHousehold(contact.AccountId);      
        System.assertEquals(1, av.size());
        System.assertEquals(false, av[0].Verified__c);
        System.assertEquals('Bad input. Required fields missing from input or are malformed.', av[0].Verification_Status__c);
    }
    
    @isTest
    private static void test401() {
        //skip the test if Advancement is installed
        if (ADV_PackageInfo_SVC.useAdv()) return;

        // address validation is async, so no way to successfully test if other related triggers are already async!
        if (hasAsyncAddrTriggers()) return;
        
        Addr_Verification_Settings__c settings = createDefaultSettings();
        Test.setMock(HttpCalloutMock.class, new ADDR_MockHttpRespGenerator_TEST());
              
        Contact contact = new Contact(FirstName = 'Test', LastName = 'Person'); 
        contact.MailingStreet = '401 error';
        contact.MailingCity = 'chicago';
        contact.MailingState = 'Illinois';
        contact.MailingPostalCode = '60606';
        contact.MailingCountry = 'United States';
        
        Test.StartTest();
        insert contact;
        Test.StopTest();
        
        //check household got created for contact
        contact = getContact(contact.Id);
        Id accountId = contact.Account.Id;
        System.assertNotEquals(null, accountId);

        Address__c[] av = getAddressesForHousehold(contact.AccountId);
        System.assertEquals(1, av.size());
        System.assertEquals(false, av[0].Verified__c);
        System.assertEquals('Unauthorized. Authentication failure; invalid credentials.', av[0].Verification_Status__c);
    }
    
    @isTest
    private static void test402() {
        //skip the test if Advancement is installed
        if (ADV_PackageInfo_SVC.useAdv()) return;

        // address validation is async, so no way to successfully test if other related triggers are already async!
        if (hasAsyncAddrTriggers()) return;
        
        Addr_Verification_Settings__c settings = createDefaultSettings();
        Test.setMock(HttpCalloutMock.class, new ADDR_MockHttpRespGenerator_TEST());
              
        Contact contact = new Contact(FirstName = 'Test', LastName = 'Person'); 
        contact.MailingStreet = '402 error';
        contact.MailingCity = 'chicago';
        contact.MailingState = 'Illinois';
        contact.MailingPostalCode = '60606';
        contact.MailingCountry = 'United States';
        
        Test.StartTest();
        insert contact;
        Test.StopTest();
        
        //check household got created for contact
        contact = getContact(contact.Id);
        Id accountId = contact.Account.Id;
        System.assertNotEquals(null, accountId);

        Address__c[] av = getAddressesForHousehold(contact.AccountId);      
        System.assertEquals(1, av.size());
        System.assertEquals(false, av[0].Verified__c);
        System.assertEquals('Payment required. No active subscription found.', av[0].Verification_Status__c);
    }
    
    @isTest
    private static void test500() {
        //skip the test if Advancement is installed
        if (ADV_PackageInfo_SVC.useAdv()) return;

        // address validation is async, so no way to successfully test if other related triggers are already async!
        if (hasAsyncAddrTriggers()) return;
        
        Addr_Verification_Settings__c settings = createDefaultSettings();
        Test.setMock(HttpCalloutMock.class, new ADDR_MockHttpRespGenerator_TEST());
              
        Contact contact = new Contact(FirstName = 'Test', LastName = 'Person'); 
        contact.MailingStreet = '500 error';
        contact.MailingCity = 'chicago';
        contact.MailingState = 'Illinois';
        contact.MailingPostalCode = '60606';
        contact.MailingCountry = 'United States';
        
        Test.StartTest();
        insert contact;
        Test.StopTest();
        
        //check household got created for contact
        contact = getContact(contact.Id);
        Id accountId = contact.Account.Id;
        System.assertNotEquals(null, accountId);

        Address__c[] av = getAddressesForHousehold(contact.AccountId);       
        System.assertEquals(1, av.size());
        System.assertEquals(false, av[0].Verified__c);
        System.assertEquals('Internal server error. General service failure; retry request.', av[0].Verification_Status__c);
    }
    
    @isTest
    private static void testContactAmbiguousAddress() {
        //skip the test if Advancement is installed
        if (ADV_PackageInfo_SVC.useAdv()) return;

        // address validation is async, so no way to successfully test if other related triggers are already async!
        if (hasAsyncAddrTriggers()) return;
        
        createDefaultSettings();
        Test.setMock(HttpCalloutMock.class, new ADDR_MockHttpRespGenerator_TEST());
              
        Contact contact = new Contact(FirstName = 'Test', LastName = 'Person'); 
        contact.MailingStreet = 'ambiguous-address';
        contact.MailingCity = 'chicago';
        contact.MailingState = 'Illinois';
        contact.MailingPostalCode = '60606';
        contact.MailingCountry = 'United States';
        
        Test.StartTest();
        insert contact;
        Test.StopTest();
        
        //check household got created for contact
        contact = getContact(contact.Id);
        Id accountId = contact.Account.Id;
        System.assertNotEquals(null, accountId);

        Address__c[] av = getAddressesForHousehold(accountId);
        System.assertEquals(1, av.size());
        System.assertEquals(true, av[0].Verified__c);
        System.assertEquals(true, av[0].Ambiguous__c);
        System.assertEquals(Label.Addr_Verified, av[0].Verification_Status__c);
    }

    @isTest
    private static void testContactZipOnly() {
        //skip the test if Advancement is installed
        if (ADV_PackageInfo_SVC.useAdv()) return;

        // address validation is async, so no way to successfully test if other related triggers are already async!
        if (hasAsyncAddrTriggers()) return;
        
        createDefaultSettings();
        Test.setMock(HttpCalloutMock.class, new ADDR_MockHttpRespGenerator_TEST());
        
        Contact contact = new Contact(FirstName = 'Test', LastName = 'Person'); 
        contact.MailingPostalCode = '94105';
        contact.MailingCity = 'single-zip';
        contact.MailingCountry = 'United States';
        
        Test.StartTest();
        insert contact;
        Test.StopTest();
        
        //check household got created for contact
        contact = getContact(contact.Id);
        Id accountId = contact.Account.Id;
        System.assertNotEquals(null, accountId);
   
        Address__c[] av = getAddressesForHousehold(accountId);  
        System.assertEquals('98236', av[0].MailingPostalCode__c);
        System.assertEquals('Clinton', av[0].MailingCity__c);
        System.assertEquals(true, av[0].Verified__c);
        System.assertEquals(Label.Addr_Verified, av[0].Verification_Status__c);
            
        contact c1 = getContact(contact.Id);
        System.assertEquals(null, c1.MailingStreet);
        System.assertEquals('Clinton', c1.MailingCity);
        System.assertEquals('98236', c1.MailingPostalCode);
    }

    @isTest
    private static void testContactCityAndStateOnly() {
        //skip the test if Advancement is installed
        if (ADV_PackageInfo_SVC.useAdv()) return;

        // address validation is async, so no way to successfully test if other related triggers are already async!
        if (hasAsyncAddrTriggers()) return;
        
        createDefaultSettings();
        Test.setMock(HttpCalloutMock.class, new ADDR_MockHttpRespGenerator_TEST());
        
        Contact contact = new Contact(FirstName = 'Test', LastName = 'Person'); 
        contact.MailingCity = 'single-zip';
        contact.MailingState = 'Illinois';
        contact.MailingCountry = 'United States';
        
        Test.startTest();
        insert contact;
        Test.StopTest();
        
        //check household got created for contact
        contact = getContact(contact.Id);
        Id accountId = contact.Account.Id;
        System.assertNotEquals(null, accountId); 

        Address__c[] av = getAddressesForHousehold(contact.AccountId);     
        System.assertEquals('98236', av[0].MailingPostalCode__c);
        System.assertEquals('Clinton', av[0].MailingCity__c);
        System.assertEquals(true, av[0].Verified__c);
        System.assertEquals(Label.Addr_Verified, av[0].Verification_Status__c);
        
        contact c1 = getContact(contact.Id);
        System.assertEquals(null, c1.MailingStreet);
        System.assertEquals('Clinton', c1.MailingCity);
        System.assertEquals('98236', c1.MailingPostalCode);
    }

    @isTest
    private static void testController() {
        STG_PanelADDRVerification_CTRL sc = new STG_PanelADDRVerification_CTRL();
        sc.initDynamicFields(); //this will also set the settings property
        
        sc.addrVerifSettings.Auth_ID__c = 'testID';
        sc.addrVerifSettings.Auth_Token__c = 'testToken';
        sc.addrVerifSettings.Address_Verification_Endpoint__c = SMARTY_STREETS_VERIFICATION_ENDPOINT;
        sc.addrVerifSettings.Class__c = SMARTY_STREETS_VALIDATOR_CLASS;
        sc.saveSettings();
        System.assertEquals('Saved.\n', sc.apiSettingsSaveMessage);

        sc.apiTestEntry = '98236';
        sc.testApi();
        System.assertNotEquals(null, sc.apiTestResult);

        Test.startTest();
        sc.batchVerify();
        Test.stopTest();
        
        //The batch has its own test. This basically tests that no exception was thrown
        //since it got to set the status variable.
        System.assertEquals(true, sc.isRunningBatch);
    }

    @isTest
    private static void testBlankService() {
        STG_PanelADDRVerification_CTRL sc = new STG_PanelADDRVerification_CTRL();
        sc.initDynamicFields(); //this will also set the settings property
        
        sc.addrVerifSettings.Auth_ID__c = 'testID';
        sc.addrVerifSettings.Auth_Token__c = 'testToken';
        sc.addrVerifSettings.Address_Verification_Endpoint__c = SMARTY_STREETS_VERIFICATION_ENDPOINT;
        sc.addrVerifSettings.Class__c = '';
        sc.saveSettings();
        System.assertEquals('Saved.\n', sc.apiSettingsSaveMessage);

    }

    @isTest
    private static void testControllerMissingSetting() {
        STG_PanelADDRVerification_CTRL sc = new STG_PanelADDRVerification_CTRL();
        sc.initDynamicFields(); //this will also set the settings property
        
        sc.addrVerifSettings.Class__c = SMARTY_STREETS_VALIDATOR_CLASS;
        
        Test.startTest();
        sc.saveSettings();
        Test.stopTest();
        
        System.assertEquals(null, sc.apiSettingsSaveMessage, 'Save message should be empty: ' + sc.apiSettingsSaveMessage);
        System.assert(sc.apiSettingsErrorMessage.contains('You must provide an Auth ID'), 'Error message should contain "You must provide an Auth ID": ' + sc.apiSettingsErrorMessage);
        System.assert(sc.apiSettingsErrorMessage.contains('You must provide an Auth Token'), 'Error message should contain "You must provide an Auth Token": ' + sc.apiSettingsErrorMessage);
    }

    @isTest
    private static void dontValidatePreviouslyValidatedAddresses() {
        //skip the test if Advancement is installed
        if (ADV_PackageInfo_SVC.useAdv()) return;

        // address validation is async, so no way to successfully test if other related triggers are already async!
        if (hasAsyncAddrTriggers()) return;
        
        Contact contact = new Contact(FirstName = 'Test', LastName = 'Person'); 
        contact.MailingStreet = 'single-address';
        contact.MailingCity = 'Cupertino';
        contact.MailingState = 'California';
        contact.MailingPostalCode = '95014';
        contact.MailingCountry = 'United States';
        
        insert contact;
        
        //check household got created for contact
        contact = getContact(contact.Id);
        Id accountId = contact.Account.Id;
        System.assertNotEquals(null, accountId);
        
        Address__c[] av = getAddressesForHousehold(accountId);
        System.assertEquals(1, av.size());
        System.assertEquals(false, av[0].Verified__c);
        System.assertEquals(null, av[0].Verification_Status__c);
        
        createDefaultSettings();
        Test.setMock(HttpCalloutMock.class, new ADDR_MockHttpRespGenerator_TEST());        
        av[0].Verified__c = true;
        
        Test.StartTest();
        update av[0];
        Test.StopTest();
        
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
    * @description Verify the page displays a message when the user has no permission to view the page
    */
    @isTest
    private static void shouldDisplayMessageWhenUserHasNoAccess() {
        User readOnlyUser = UTIL_UnitTestData_TEST.createUser(UTIL_UnitTestData_TEST.PROFILE_READONLY_USER);

        System.runAs(readOnlyUser) {
            Test.setCurrentPage(Page.STG_PanelAddrVerification);
            STG_PanelAddrVerification_CTRL ctrl = new STG_PanelAddrVerification_CTRL();

            UTIL_UnitTestData_TEST.assertPageHasMessage(System.Label.stgAddrPermissionDenied, ApexPages.Severity.INFO);
            assertAuthIdAndTokenAreNull(ctrl);
        }
    }

    /*******************************************************************************************************
    * @description Verify the page does not display API key and other address verification settings
    * when user has no permission to view the page
    */
    @isTest
    private static void shouldNotRetrieveApiSettingsWhenUserHasNoAccess() {        
        createDefaultSettings();

        User readOnlyUser = UTIL_UnitTestData_TEST.createUser(UTIL_UnitTestData_TEST.PROFILE_READONLY_USER);

        System.runAs(readOnlyUser) {
            Test.setCurrentPage(Page.STG_PanelAddrVerification);
            STG_PanelAddrVerification_CTRL ctrl = new STG_PanelAddrVerification_CTRL();

            ctrl.initDynamicFields();
            assertAuthIdAndTokenAreNull(ctrl);

            ctrl.testApi();
            System.assertEquals(System.Label.stgAddrPermissionDenied, ctrl.apiTestResult);
            assertAuthIdAndTokenAreNull(ctrl);
        }
    }

    /*******************************************************************************************************
    * @description Verify permission denied message is displayed on health check panel
    * when address read only user verifies address
    */
    @isTest
    private static void healthCheckShouldDisplayPermissionDeniedMessageWhenUserHasNoAccess() { 
        Addr_Verification_Settings__c addrSettings = createDefaultSettings();
        System.assertEquals(SMARTY_STREETS_VALIDATOR_CLASS, addrSettings.Class__c, 
            'Address Verification Settings should have SmartyStreets validator class set');

        User readOnlyUser = UTIL_UnitTestData_TEST.createUser(UTIL_UnitTestData_TEST.PROFILE_READONLY_USER);
        System.runAs(readOnlyUser) {  
            STG_PanelHealthCheck_CTRL healthCheckPanel = new STG_PanelHealthCheck_CTRL();
            STG_PanelAddrVerification_CTRL ctrl = new STG_PanelAddrVerification_CTRL();
            ctrl.verifyAddressVerificationService(healthCheckPanel);

            System.assertEquals(1, healthCheckPanel.listDR.size(), 
                'One defect result should be returned: ' + healthCheckPanel.listDR);
            System.assertEquals(System.Label.stgAddrPermissionDenied, healthCheckPanel.listDR[0].strDetails);
            System.assertEquals(SETTINGS_NAME, healthCheckPanel.listDR[0].strName);
            System.assertEquals(null, healthCheckPanel.listDR[0].strSolution);
        }
    }

    /*******************************************************************************************************
    * @description Verify no message is displayed when address validator is not Smarty Streets validator
    */
    @isTest
    private static void healthCheckShouldNotReturnAnyMessageWhenValidatorIsNotSmartyStreets() { 
        Addr_Verification_Settings__c addrSettings = createDefaultSettings();
        addrSettings.Class__c = 'ADDR_Foo_Validator';

        User readOnlyUser = UTIL_UnitTestData_TEST.createUser(UTIL_UnitTestData_TEST.PROFILE_READONLY_USER);
        System.runAs(readOnlyUser) {
            STG_PanelHealthCheck_CTRL healthCheckPanel = new STG_PanelHealthCheck_CTRL();
            STG_PanelAddrVerification_CTRL ctrl = new STG_PanelAddrVerification_CTRL();
            ctrl.verifyAddressVerificationService(healthCheckPanel);
            System.assertEquals(0, healthCheckPanel.listDR.size(), 
                'No defect result should be returned: ' + healthCheckPanel.listDR);
        }
    }

    /*******************************************************************************************************
    * @description Verify address verification is attempted on health check panel
    * when system admin verifies address
    */
    @isTest
    private static void healthCheckShouldVerifyAddressWhenUserHasAccess() { 
        final String expectedMessage = 'Methods defined as TestMethod do not support Web service callouts';
        final String expectedSolution = String.format(
            System.Label.healthSolutionEditSetting, 
            new String[]{ SETTINGS_NAME, System.Label.stgNavHouseholds, System.Label.stgNavAddressVerification }
        );

        Addr_Verification_Settings__c addrSettings = createDefaultSettings();
        System.assertEquals(SMARTY_STREETS_VALIDATOR_CLASS, addrSettings.Class__c, 
            'Address Verification Settings should have SmartyStreets validator class set');

        STG_PanelHealthCheck_CTRL healthCheckPanel = new STG_PanelHealthCheck_CTRL();
        STG_PanelAddrVerification_CTRL ctrl = new STG_PanelAddrVerification_CTRL();
        ctrl.verifyAddressVerificationService(healthCheckPanel);

        System.assertEquals(1, healthCheckPanel.listDR.size(), 
            'One defect result should be returned: ' + healthCheckPanel.listDR);
        System.assertEquals(expectedMessage, healthCheckPanel.listDR[0].strDetails);
        System.assertEquals(SETTINGS_NAME, healthCheckPanel.listDR[0].strName);
        System.assertEquals(expectedSolution, healthCheckPanel.listDR[0].strSolution);
    }


    // Helpers
    //////////////

    /*******************************************************************************************************
    * @description Returns true if address triggers are async
    */
    private static Boolean hasAsyncAddrTriggers() {
        return TDTM_DefaultConfig.ADDR_Address_TDTM_TestAsync ||
            TDTM_DefaultConfig.ADDR_Contact_TDTM_TestAsync ||
            TDTM_DefaultConfig.ADDR_Account_TDTM_TestAsync; 
    }
    
    /*******************************************************************************************************
    * @description Creates Address Verification Settings
    */
    public static Addr_Verification_Settings__c createDefaultSettings() {
        // use the household account model
        UTIL_CustomSettingsFacade.getContactsSettings();

        // create the basic api settings
        Addr_Verification_Settings__c settings = UTIL_CustomSettingsFacade.getAddressVerificationSettings();
        settings.Auth_ID__c = 'hey';
        settings.Auth_Token__c = 'there';
        settings.Class__c = SMARTY_STREETS_VALIDATOR_CLASS;
        settings.Enable_Automatic_Verification__c = true;
        settings.Reject_Ambiguous_Addresses__c = true;
        
        return settings;
    }

    /*******************************************************************************************************
    * @description Retrieves the Address details
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
    * @description Assert Address Verification Settings Authorization ID and Token are not retrieved
    */
    private static void assertAuthIdAndTokenAreNull(STG_PanelAddrVerification_CTRL ctrl) {
        System.assertEquals(null, ctrl.addrVerifSettings.Auth_ID__c, 'Auth Id should not be displayed on Settings');
        System.assertEquals(null, ctrl.addrVerifSettings.Auth_Token__c, 'Auth Token should not be displayed on Settings');
    }
}
