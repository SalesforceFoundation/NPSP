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

    // if you only want to run one test in this class, fill in its name here.
    // if you want to run all tests, then use '*'
    private static string strTestOnly = '*';

    private static boolean hasAsyncAddrTriggers() {
        return TDTM_DefaultConfig.ADDR_Address_TDTM_TestAsync ||
            TDTM_DefaultConfig.ADDR_Contact_TDTM_TestAsync ||
            TDTM_DefaultConfig.ADDR_Account_TDTM_TestAsync; 
    }
    
    public static Addr_Verification_Settings__c createDefaultSettings() {
        // use the household account model
        UTIL_CustomSettingsFacade.getContactsSettings();

        // create the basic api settings
        Addr_Verification_Settings__c settings = UTIL_CustomSettingsFacade.getAddressVerificationSettings();
        settings.Auth_ID__c = 'hey';
        settings.Auth_Token__c = 'there';
        settings.Class__c = 'ADDR_SmartyStreets_Validator';
        settings.Enable_Automatic_Verification__c = true;
        settings.Reject_Ambiguous_Addresses__c = true;
        
        return settings;
    }
    
    static testMethod void testContactAddress() {
        //skip the test if Advancement is installed
        if(ADV_PackageInfo_SVC.useAdv()) return;

        if (strTestOnly != '*' && strTestOnly != 'testContactAddress') return;
        
        // address validation is async, so no way to successfully test if other related triggers are already async!
        if (hasAsyncAddrTriggers()) return;
        
        createDefaultSettings();
        Test.setMock(HttpCalloutMock.class, new ADDR_MockHttpRespGenerator_TEST());
              
        Contact contact = new contact(firstname='Test', lastname='Person'); 
        contact.MailingStreet = 'single-address';
        contact.MailingCity = 'Cupertino';
        contact.MailingState = 'California';
        contact.MailingPostalCode = '95014';
        contact.MailingCountry = 'United States';
        
        Test.StartTest();
        insert contact;
        Test.StopTest();
        
        //check household got created for contact
        contact = [select Account.Id from Contact where Id = :contact.Id];
        Id accountId = contact.Account.Id;
        System.assertNotEquals(null, accountId);
        
        Address__c[] av = [select MailingStreet__c, MailingState__c, MailingPostalCode__c, Verified__c, 
                Verification_Status__c from Address__c where Household_Account__c = :accountId];
        System.assertEquals(1, av.size());
        System.assertEquals('1 Infinite Loop', av[0].MailingStreet__c);
        System.assertEquals('CA', av[0].MailingState__c);
        System.assertEquals('95014-2083', av[0].MailingPostalCode__c);
        System.assertEquals(true, av[0].Verified__c);
        System.assertEquals(Label.Addr_Verified, av[0].Verification_Status__c);
        
        contact = [select id, MailingStreet, MailingCity, MailingPostalCode, MailingState
                         from contact where id = :contact.id];
        System.assertEquals('1 Infinite Loop', contact.MailingStreet);
        System.assertEquals('Cupertino', contact.MailingCity);
        System.assertEquals('95014-2083', contact.MailingPostalCode);
        if (ADDR_Addresses_TDTM.isStateCountryPicklistsEnabled)            
            System.assertEquals('California', contact.MailingState);
        else
            System.assertEquals('CA', contact.MailingState);
    }

    static testMethod void testContactInvalidAddress() {
        //skip the test if Advancement is installed
        if(ADV_PackageInfo_SVC.useAdv()) return;

        if (strTestOnly != '*' && strTestOnly != 'testContactInvalidAddress') return;
        
        // address validation is async, so no way to successfully test if other related triggers are already async!
        if (hasAsyncAddrTriggers()) return;
        
        createDefaultSettings();
        Test.setMock(HttpCalloutMock.class, new ADDR_MockHttpRespGenerator_TEST());
              
        Contact contact = new contact(firstname='Test', lastname='Person'); 
        contact.MailingStreet = 'invalid-address';
        contact.MailingCity = 'chicago';
        contact.MailingState = 'Illinois';
        contact.MailingPostalCode = '60606';
        contact.MailingCountry = 'United States';
        
        Test.StartTest();
        insert contact;
        Test.StopTest();
        
        //check household got created for contact
        contact = [select Account.Id from Contact where Id = :contact.Id];
        Id accountId = contact.Account.Id;
        System.assertNotEquals(null, accountId);

        Address__c[] av = [select Verified__c, Verification_Status__c from Address__c where Household_Account__c = :contact.AccountId];       
        System.assertEquals(1, av.size());
        System.assertEquals(true, av[0].Verified__c);
        System.assertEquals(Label.Address_Not_Found, av[0].Verification_Status__c);
    }
    
    static testMethod void test400() {
        //skip the test if Advancement is installed
        if(ADV_PackageInfo_SVC.useAdv()) return;

        if (strTestOnly != '*' && strTestOnly != 'test400') return;
        
        // address validation is async, so no way to successfully test if other related triggers are already async!
        if (hasAsyncAddrTriggers()) return;
        
        Addr_Verification_Settings__c settings = createDefaultSettings();
        Test.setMock(HttpCalloutMock.class, new ADDR_MockHttpRespGenerator_TEST());
              
        Contact contact = new contact(firstname='Test', lastname='Person'); 
        contact.MailingStreet = '400 error';
        contact.MailingCity = 'chicago';
        contact.MailingState = 'Illinois';
        contact.MailingPostalCode = '60606';
        contact.MailingCountry = 'United States';
        
        Test.StartTest();
        insert contact;
        Test.StopTest();
        
        //check household got created for contact
        contact = [select Account.Id from Contact where Id = :contact.Id];
        Id accountId = contact.Account.Id;
        System.assertNotEquals(null, accountId);

        Address__c[] av = [select Verified__c, Verification_Status__c from Address__c where Household_Account__c = :contact.AccountId];       
        System.assertEquals(1, av.size());
        System.assertEquals(false, av[0].Verified__c);
        System.assertEquals('Bad input. Required fields missing from input or are malformed.', av[0].Verification_Status__c);
    }
    
    static testMethod void test401() {
        //skip the test if Advancement is installed
        if(ADV_PackageInfo_SVC.useAdv()) return;

        if (strTestOnly != '*' && strTestOnly != 'test401') return;
        
        // address validation is async, so no way to successfully test if other related triggers are already async!
        if (hasAsyncAddrTriggers()) return;
        
        Addr_Verification_Settings__c settings = createDefaultSettings();
        Test.setMock(HttpCalloutMock.class, new ADDR_MockHttpRespGenerator_TEST());
              
        Contact contact = new contact(firstname='Test', lastname='Person'); 
        contact.MailingStreet = '401 error';
        contact.MailingCity = 'chicago';
        contact.MailingState = 'Illinois';
        contact.MailingPostalCode = '60606';
        contact.MailingCountry = 'United States';
        
        Test.StartTest();
        insert contact;
        Test.StopTest();
        
        //check household got created for contact
        contact = [select Account.Id from Contact where Id = :contact.Id];
        Id accountId = contact.Account.Id;
        System.assertNotEquals(null, accountId);

        Address__c[] av = [select Verified__c, Verification_Status__c from Address__c where Household_Account__c = :contact.AccountId];       
        System.assertEquals(1, av.size());
        System.assertEquals(false, av[0].Verified__c);
        System.assertEquals('Unauthorized. Authentication failure; invalid credentials.', av[0].Verification_Status__c);
    }
    
    static testMethod void test402() {
        //skip the test if Advancement is installed
        if(ADV_PackageInfo_SVC.useAdv()) return;

        if (strTestOnly != '*' && strTestOnly != 'test402') return;
        
        // address validation is async, so no way to successfully test if other related triggers are already async!
        if (hasAsyncAddrTriggers()) return;
        
        Addr_Verification_Settings__c settings = createDefaultSettings();
        Test.setMock(HttpCalloutMock.class, new ADDR_MockHttpRespGenerator_TEST());
              
        Contact contact = new contact(firstname='Test', lastname='Person'); 
        contact.MailingStreet = '402 error';
        contact.MailingCity = 'chicago';
        contact.MailingState = 'Illinois';
        contact.MailingPostalCode = '60606';
        contact.MailingCountry = 'United States';
        
        Test.StartTest();
        insert contact;
        Test.StopTest();
        
        //check household got created for contact
        contact = [select Account.Id from Contact where Id = :contact.Id];
        Id accountId = contact.Account.Id;
        System.assertNotEquals(null, accountId);

        Address__c[] av = [select Verified__c, Verification_Status__c from Address__c where Household_Account__c = :contact.AccountId];       
        System.assertEquals(1, av.size());
        System.assertEquals(false, av[0].Verified__c);
        System.assertEquals('Payment required. No active subscription found.', av[0].Verification_Status__c);
    }
    
    static testMethod void test500() {
        //skip the test if Advancement is installed
        if(ADV_PackageInfo_SVC.useAdv()) return;

        if (strTestOnly != '*' && strTestOnly != 'test500') return;
        
        // address validation is async, so no way to successfully test if other related triggers are already async!
        if (hasAsyncAddrTriggers()) return;
        
        Addr_Verification_Settings__c settings = createDefaultSettings();
        Test.setMock(HttpCalloutMock.class, new ADDR_MockHttpRespGenerator_TEST());
              
        Contact contact = new contact(firstname='Test', lastname='Person'); 
        contact.MailingStreet = '500 error';
        contact.MailingCity = 'chicago';
        contact.MailingState = 'Illinois';
        contact.MailingPostalCode = '60606';
        contact.MailingCountry = 'United States';
        
        Test.StartTest();
        insert contact;
        Test.StopTest();
        
        //check household got created for contact
        contact = [select Account.Id from Contact where Id = :contact.Id];
        Id accountId = contact.Account.Id;
        System.assertNotEquals(null, accountId);

        Address__c[] av = [select Verified__c, Verification_Status__c from Address__c where Household_Account__c = :contact.AccountId];       
        System.assertEquals(1, av.size());
        System.assertEquals(false, av[0].Verified__c);
        System.assertEquals('Internal server error. General service failure; retry request.', av[0].Verification_Status__c);
    }
    
    static testMethod void testContactAmbiguousAddress() {
        //skip the test if Advancement is installed
        if(ADV_PackageInfo_SVC.useAdv()) return;

        if (strTestOnly != '*' && strTestOnly != 'testContactAmbiguousAddress') return;
        
        // address validation is async, so no way to successfully test if other related triggers are already async!
        if (hasAsyncAddrTriggers()) return;
        
        createDefaultSettings();
        Test.setMock(HttpCalloutMock.class, new ADDR_MockHttpRespGenerator_TEST());
              
        Contact contact = new contact(firstname='Test', lastname='Person'); 
        contact.MailingStreet = 'ambiguous-address';
        contact.MailingCity = 'chicago';
        contact.MailingState = 'Illinois';
        contact.MailingPostalCode = '60606';
        contact.MailingCountry = 'United States';
        
        Test.StartTest();
        insert contact;
        Test.StopTest();
        
        //check household got created for contact
        contact = [select Account.Id from Contact where Id = :contact.Id];
        Id accountId = contact.Account.Id;
        System.assertNotEquals(null, accountId);

        Address__c[] av = [select Verified__c, Ambiguous__c, Verification_Status__c from Address__c 
                            where Household_Account__c = :accountId];       
        System.assertEquals(1, av.size());
        System.assertEquals(true, av[0].Verified__c);
        System.assertEquals(true, av[0].Ambiguous__c);
        System.assertEquals(Label.Addr_Verified, av[0].Verification_Status__c);
    }

    static testMethod void testContactZipOnly() {
        //skip the test if Advancement is installed
        if(ADV_PackageInfo_SVC.useAdv()) return;

        if (strTestOnly != '*' && strTestOnly != 'testContactZipOnly') return;
        
        // address validation is async, so no way to successfully test if other related triggers are already async!
        if (hasAsyncAddrTriggers()) return;
        
        createDefaultSettings();
        Test.setMock(HttpCalloutMock.class, new ADDR_MockHttpRespGenerator_TEST());
        
        Contact contact = new contact(firstname='Test', lastname='Person'); 
        contact.MailingPostalCode = '94105';
        contact.MailingCity = 'single-zip';
        contact.MailingCountry = 'United States';
        
        Test.StartTest();
        insert contact;
        Test.StopTest();
        
        //check household got created for contact
        contact = [select Account.Id from Contact where Id = :contact.Id];
        Id accountId = contact.Account.Id;
        System.assertNotEquals(null, accountId);
   
        Address__c[] av = [select MailingCity__c, MailingPostalCode__c, Verified__c, Verification_Status__c
                           from Address__c where Household_Account__c = :accountId];      
        System.assertEquals('98236', av[0].MailingPostalCode__c);
        System.assertEquals('Clinton', av[0].MailingCity__c);
        System.assertEquals(true, av[0].Verified__c);
        System.assertEquals(Label.Addr_Verified, av[0].Verification_Status__c);
            
        contact[] c1 = [select id, MailingStreet, MailingCity, MailingPostalCode from contact where id = :contact.id];
        System.assertEquals(null, c1[0].MailingStreet);
        System.assertEquals('Clinton', c1[0].MailingCity);
        System.assertEquals('98236', c1[0].MailingPostalCode);
    }

    static testMethod void testContactCityAndStateOnly() {
        //skip the test if Advancement is installed
        if(ADV_PackageInfo_SVC.useAdv()) return;

        if (strTestOnly != '*' && strTestOnly != 'testContactCityAndStateOnly') return;
        
        // address validation is async, so no way to successfully test if other related triggers are already async!
        if (hasAsyncAddrTriggers()) return;
        
        createDefaultSettings();
        Test.setMock(HttpCalloutMock.class, new ADDR_MockHttpRespGenerator_TEST());
        
        Contact contact = new contact(firstname='Test', lastname='Person'); 
        contact.MailingCity = 'single-zip';
        contact.MailingState = 'Illinois';
        contact.MailingCountry = 'United States';
        
        Test.startTest();
        insert contact;
        Test.StopTest();
        
        //check household got created for contact
        contact = [select Account.Id from Contact where Id = :contact.Id];
        Id accountId = contact.Account.Id;
        System.assertNotEquals(null, accountId); 

        Address__c[] av = [select id, MailingCity__c, MailingPostalCode__c, Verified__c, 
                            Verification_Status__c from Address__c 
                            where Household_Account__c = :contact.AccountId];        
        System.assertEquals('98236', av[0].MailingPostalCode__c);
        System.assertEquals('Clinton', av[0].MailingCity__c);
        System.assertEquals(true, av[0].Verified__c);
        System.assertEquals(Label.Addr_Verified, av[0].Verification_Status__c);
        
        contact[] c1 = [select id, MailingStreet, MailingCity, MailingPostalCode from contact where id = :contact.id];
        System.assertEquals(null, c1[0].MailingStreet);
        System.assertEquals('Clinton', c1[0].MailingCity);
        System.assertEquals('98236', c1[0].MailingPostalCode);
    }

    static testMethod void testController() {
        if (strTestOnly != '*' && strTestOnly != 'testController') return;
        
        STG_PanelADDRVerification_CTRL sc = new STG_PanelADDRVerification_CTRL();
        sc.initDynamicFields(); //this will also set the settings property
        
        sc.addrVerifSettings.Auth_ID__c = 'testID';
        sc.addrVerifSettings.Auth_Token__c = 'testToken';
        sc.addrVerifSettings.Address_Verification_Endpoint__c = 'https://api.smartystreets.com/street-address';
        sc.addrVerifSettings.Class__c = 'ADDR_SmartyStreets_Validator';
        sc.saveSettings();
        System.assertEquals('Saved.\n', sc.apiSettingsSaveMessage);

        sc.apiTestEntry = '98236';
        sc.testApi();
        system.assertNotEquals(null, sc.apiTestResult);

        Test.startTest();
        sc.batchVerify();
        Test.stopTest();
        
        //The batch has its own test. This basically tests that no exception was thrown
        //since it got to set the status variable.
        System.assertEquals(true, sc.isRunningBatch);
    }

    static testMethod void testBlankService() {
        if (strTestOnly != '*' && strTestOnly != 'testBlankService') return;
        
        STG_PanelADDRVerification_CTRL sc = new STG_PanelADDRVerification_CTRL();
        sc.initDynamicFields(); //this will also set the settings property
        
        sc.addrVerifSettings.Auth_ID__c = 'testID';
        sc.addrVerifSettings.Auth_Token__c = 'testToken';
        sc.addrVerifSettings.Address_Verification_Endpoint__c = 'https://api.smartystreets.com/street-address';
        sc.addrVerifSettings.Class__c = '';
        sc.saveSettings();
        System.assertEquals('Saved.\n', sc.apiSettingsSaveMessage);

    }

    static testMethod void testControllerMissingSetting() {
        if (strTestOnly != '*' && strTestOnly != 'testControllerMissingSetting') return;
        
        STG_PanelADDRVerification_CTRL sc = new STG_PanelADDRVerification_CTRL();
        sc.initDynamicFields(); //this will also set the settings property
        
        sc.addrVerifSettings.Class__c = 'ADDR_SmartyStreets_Validator';
        
        Test.startTest();
        sc.saveSettings();
        Test.stopTest();
        
        System.assertEquals(null, sc.apiSettingsSaveMessage, 'Save message should be empty: ' + sc.apiSettingsSaveMessage);
        System.assert(sc.apiSettingsErrorMessage.contains('You must provide an Auth ID'), 'Error message should contain "You must provide an Auth ID": ' + sc.apiSettingsErrorMessage);
        System.assert(sc.apiSettingsErrorMessage.contains('You must provide an Auth Token'), 'Error message should contain "You must provide an Auth Token": ' + sc.apiSettingsErrorMessage);
    }


    static testMethod void dontValidatePreviouslyValidatedAddresses() {
        //skip the test if Advancement is installed
        if(ADV_PackageInfo_SVC.useAdv()) return;

        if (strTestOnly != '*' && strTestOnly != 'dontValidatePreviouslyValidatedAddresses') return;
        
        // address validation is async, so no way to successfully test if other related triggers are already async!
        if (hasAsyncAddrTriggers()) return;
        
        Contact contact = new contact(firstname='Test', lastname='Person'); 
        contact.MailingStreet = 'single-address';
        contact.MailingCity = 'Cupertino';
        contact.MailingState = 'California';
        contact.MailingPostalCode = '95014';
        contact.MailingCountry = 'United States';
        
        insert contact;
        
        //check household got created for contact
        contact = [select Account.Id from Contact where Id = :contact.Id];
        Id accountId = contact.Account.Id;
        System.assertNotEquals(null, accountId);
        
        Address__c[] av = [select Id, MailingStreet__c, MailingState__c, MailingPostalCode__c, Verified__c, 
                Verification_Status__c from Address__c where Household_Account__c = :accountId];
        System.assertEquals(1, av.size());
        System.assertEquals(false, av[0].Verified__c);
        System.assertEquals(null, av[0].Verification_Status__c);
        
        createDefaultSettings();
        Test.setMock(HttpCalloutMock.class, new ADDR_MockHttpRespGenerator_TEST());        
        av[0].Verified__c = true;
        
        Test.StartTest();
        update av[0];
        Test.StopTest();
        
        Address__c updatedAddress = [SELECT Id, MailingStreet__c, Verified__c, Verification_Status__c FROM Address__c WHERE Id = :av[0].Id];
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

        updatedAddress = [SELECT Id, MailingStreet__c, Verified__c, Verification_Status__c FROM Address__c WHERE Id = :av[0].Id];
        System.assertEquals(true, updatedAddress.Verified__c);
        System.assertEquals(Label.Addr_Verified, updatedAddress.Verification_Status__c, 'Address should have been verified');
        System.assertEquals('1 Infinite Loop', updatedAddress.MailingStreet__c);
    }
}
