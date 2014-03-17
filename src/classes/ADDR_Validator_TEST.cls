@isTest
public with sharing class ADDR_Validator_TEST {

    // if you only want to run one test in this class, fill in its name here.
    // if you want to run all tests, then use '*'
    private static string strTestOnly = '*';
    
    public static void createDefaultSettings() {
        // use the household account model
        CAO_Constants.getContactsSettingsForTests(
            new npe01__Contacts_and_Orgs_Settings__c (npe01__Account_Processor__c = CAO_Constants.HH_ACCOUNT_PROCESSOR));

        // create the basic api authentication settings
        Address_Authentication_Settings__c authSettings = Address_Authentication_Settings__c.getOrgDefaults();
        authSettings.Auth_ID__c = 'hey';
        authSettings.Auth_Token__c = 'there';
        insert authSettings;

        // set the verification settings
        Address_Verification_Settings__c settings = Address_Verification_Settings__c.getOrgDefaults();
        settings.Auto_Update_Addresses__c = true;
        settings.Clear_Invalid_Addresses__c = true;
        settings.Enable_Automatic_Verification__c = true;
        settings.Reject_Ambiguous_Addresses__c = true;
        insert settings;
    }
    
    static testMethod void testContactAddress() {
    	if (strTestOnly != '*' && strTestOnly != 'testContactAddress') return;
    	
        createDefaultSettings();
        Test.setMock(HttpCalloutMock.class, new ADDR_MockHttpRespGenerator_TEST());
              
        Contact contact = new contact(firstname='Test', lastname='Person'); 
        insert contact;
        
        //check household got created for contact
        contact = [select Account.Id from Contact where Id = :contact.Id];
        Id accountId = contact.Account.Id;
        System.assertNotEquals(null, accountId);
         
        // update contact with address to get the Address__c record created
        contact.MailingStreet = 'single-address-response';
        contact.MailingCity = 'Cupertino';
        contact.MailingState = 'CA';
        contact.MailingPostalCode = '95014';
        Test.StartTest();
        update contact;
        Test.StopTest();
        
        Address__c[] av = [select MailingStreet__c, MailingState__c, MailingPostalCode__c, Verified__c 
                from Address__c where Household_Account__c = :accountId];
        System.assertEquals(1, av.size());
        System.assertEquals('1 Infinite Loop', av[0].MailingStreet__c);
        System.assertEquals('CA', av[0].MailingState__c);
        System.assertEquals('95014-2083', av[0].MailingPostalCode__c);
        System.assertEquals(true, av[0].Verified__c);
    }

    static testMethod void testContactBadAddress() {
    	if (strTestOnly != '*' && strTestOnly != 'testContactBadAddress') return;
    	
        createDefaultSettings();
        Test.setMock(HttpCalloutMock.class, new ADDR_MockHttpRespGenerator_TEST());
              
        Contact contact = new contact(firstname='Test', lastname='Person'); 
        insert contact;
        
        //check household got created for contact
        contact = [select Account.Id from Contact where Id = :contact.Id];
        Id accountId = contact.Account.Id;
        System.assertNotEquals(null, accountId);
         
        // update contact with address to get the Address__c record created
        contact.MailingStreet = 'bogus-address-for-test';
        contact.MailingCity = 'chicago';
        contact.MailingState = 'il';
        contact.MailingPostalCode = '60606';
        Test.StartTest();
        update contact;
        Test.StopTest();

        Address__c[] av = [select Verified__c from Address__c where Household_Account__c = :contact.AccountId];       
        System.assertEquals(1, av.size());
        System.assertEquals(false, av[0].Verified__c);
    }
    
    static testMethod void testContactAmbiguousAddress() {
        if (strTestOnly != '*' && strTestOnly != 'testContactAmbiguousAddress') return;
        
        createDefaultSettings();
        Test.setMock(HttpCalloutMock.class, new ADDR_MockHttpRespGenerator_TEST());
              
        Contact contact = new contact(firstname='Test', lastname='Person'); 
        insert contact;
        
        //check household got created for contact
        contact = [select Account.Id from Contact where Id = :contact.Id];
        Id accountId = contact.Account.Id;
        System.assertNotEquals(null, accountId);
         
        // update contact with address to get the Address__c record created
        contact.MailingStreet = 'ambiguous-address-for-test';
        contact.MailingCity = 'chicago';
        contact.MailingState = 'il';
        contact.MailingPostalCode = '60606';
        Test.StartTest();
        update contact;
        Test.StopTest();

        Address__c[] av = [select Verified__c, Ambiguous__c from Address__c 
                            where Household_Account__c = :accountId];       
        System.assertEquals(1, av.size());
        System.assertEquals(false, av[0].Verified__c);
        System.assertEquals(true, av[0].Ambiguous__c);
    }

    static testMethod void testContactZipOnly() {
    	if (strTestOnly != '*' && strTestOnly != 'testContactZipOnly') return;
    	
    	createDefaultSettings();
        Test.setMock(HttpCalloutMock.class, new ADDR_MockHttpRespGenerator_TEST());
        
        Contact contact = new contact(firstname='Test', lastname='Person'); 
        insert contact;
        
        //check household got created for contact
        contact = [select Account.Id from Contact where Id = :contact.Id];
        Id accountId = contact.Account.Id;
        System.assertNotEquals(null, accountId);
         
        // update contact with postal code to get the Address__c record created
        contact.MailingPostalCode = '60606';
        Test.StartTest();
        update contact;
        Test.StopTest();
                        
        Address__c[] av = [select MailingCity__c, MailingPostalCode__c, Verified__c 
                            from Address__c where Household_Account__c = :accountId];      
        System.assertEquals('98236', av[0].MailingPostalCode__c);
        System.assertEquals('Clinton', av[0].MailingCity__c);
        /*
        contact[] c1 = [select id, MailingStreet, MailingCity from contact where id = :contact.id];
        System.assertEquals(null, c1[0].MailingStreet);
        System.assertEquals('98236', c1[0].MailingPostalCode__c);
        System.assertEquals('Clinton', c1[0].MailingCity);*/
    }

    static testMethod void testContactCityAndStateOnly() {
    	if (strTestOnly != '*' && strTestOnly != 'testContactCityAndStateOnly') return;
    	
        createDefaultSettings();
        Test.setMock(HttpCalloutMock.class, new ADDR_MockHttpRespGenerator_TEST());
        
        Contact contact = new contact(firstname='Test', lastname='Person'); 
        insert contact;
        
        //check household got created for contact
        contact = [select Account.Id from Contact where Id = :contact.Id];
        Id accountId = contact.Account.Id;
        System.assertNotEquals(null, accountId);
         
        // update contact with to get the Address__c record created
        contact.MailingCity = 'Clinton';
        contact.MailingState = 'WA';
        Test.StartTest();
        update contact;
        Test.StopTest();

        Address__c[] av = [select id, MailingCity__c, MailingPostalCode__c from Address__c 
                            where Household_Account__c = :contact.AccountId];        
        System.assertEquals('98236', av[0].MailingPostalCode__c);
        System.assertEquals('Clinton', av[0].MailingCity__c);
        /*
        contact[] c1 = [select id, MailingStreet, MailingPostalCode from contact where id = :contact.id];
        System.assertEquals(null, c1[0].MailingStreet)
        System.assertEquals('Clinton', c1[0].MailingCity__c);
        System.assertEquals('98236', c1[0].MailingPostalCode);*/
    }

    static testMethod void testBatch() {
    	if (strTestOnly != '*' && strTestOnly != 'testBatch') return;
    	
        createDefaultSettings();
        Test.setMock(HttpCalloutMock.class, new ADDR_MockHttpRespGenerator_TEST());
        
        Test.StartTest();
        ADDR_Validator_Batch.verifyAllAddresses();
        Test.StopTest();
    }

    static testMethod void testController() {
    	if (strTestOnly != '*' && strTestOnly != 'testController') return;
    	
        STG_PanelADDRVerification_CTRL sc = new STG_PanelADDRVerification_CTRL();
        
        sc.apiSettings.HTML_Key__c = 'skldjflsdkfj';
        sc.saveApiSettings();
        System.assertEquals('Saved.', sc.apiSettingsSaveMessage);

        sc.saveVerificationSettings();

        sc.apiTestEntry = '98236';
        sc.testApi();
        system.assertNotEquals(null, sc.apiTestResult);

        Test.startTest();
        sc.bulkVerify();
        Test.stopTest();
    }
}