/*
    Copyright (c) 2017, Salesforce.org
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
* @date 2017
* @group Utilities
* @description Test class for the UTIL_DMLService class.
*/

@isTest
public with sharing class UTIL_DMLService_TEST {
    
    private static final Integer NUMBER_OF_RECORDS_ZERO = 0;
    private static final Integer NUMBER_OF_RECORDS_ONE = 1;
    private static final Integer NUMBER_OF_RECORDS_TWO = 2;
    private static final Integer NUMBER_OF_RECORDS_THREE = 3;
    private static final String ERROR_STATUS_CODE_DUPLICATES_DETECTED = 'DUPLICATES_DETECTED';


    /*********************************************************************************************************
    * @description If you only want to run a single test in this class, fill in its name here.
    * If you want to run all tests, then use '*'
    */
    private static string strTestOnly = '*';
    

    /*********************************************************************************************************
    * @description Tests insert of a record with default DMLOption settings.
    * verify:
    *   Record inserted
    * @return void
    **********************************************************************************************************/
    private static testMethod void testRecordInsertWithDefaults() {
        if (strTestOnly != '*' && strTestOnly != 'testRecordInsertWithDefaults') return;
        
        Account acct = new Account(Name = 'DMLOptionsAccount');
        insert acct;

        Contact con = new Contact(FirstName = 'Blue', LastName = 'Cloud', AccountId = acct.Id); 
                 
        Test.startTest();
        UTIL_DMLService.insertRecord(con);
        Test.stopTest();

        List<Contact> retrievedContacts = [SELECT Id, FirstName, LastName, AccountId 
                                           FROM Contact];

        System.assertEquals(false, retrievedContacts.isEmpty());
    }


    /*********************************************************************************************************
    * @description Tests insert of a List of records with default DMLOptions settings.
    * verify:
    *   Records inserted
    * @return void
    **********************************************************************************************************/
    private static testMethod void testRecordsInsertWithDefaults() {
        if (strTestOnly != '*' && strTestOnly != 'testRecordsInsertWithDefaults') return;
        
        Account acct = new Account(Name = 'DMLOptionsAccount');
        insert acct;

        List<Contact> contacts = new List<Contact> { new Contact(FirstName = 'Blue', LastName = 'Cloud', AccountId = acct.Id),
                                                        new Contact(FirstName = 'Astro', LastName = 'Cloud', AccountId = acct.Id) };
                         
        Test.startTest();
        UTIL_DMLService.insertRecords(contacts);
        Test.stopTest();

        List<Contact> retrievedContacts = [SELECT Id, FirstName, LastName, AccountId 
                                           FROM Contact];

        System.assertEquals(NUMBER_OF_RECORDS_TWO, retrievedContacts.size());
    }


    /*********************************************************************************************************
    * @description Tests insert of a record with specified optAllOrNone value and default DMLOptions settings.
    * verify:
    *   Record inserted
    * @return void
    **********************************************************************************************************/
    private static testMethod void testRecordInsertWithAllOrNone() {
        if (strTestOnly != '*' && strTestOnly != 'testRecordInsertWithAllOrNone') return;
        
        Account acct = new Account(Name = 'DMLOptionsAccount');
        insert acct;

        Contact con = new Contact(FirstName = 'Blue', LastName = 'Cloud', AccountId = acct.Id); 
                 
        Test.startTest();
        UTIL_DMLService.insertRecord(con, false);
        Test.stopTest();

        List<Contact> retrievedContacts = [SELECT Id, FirstName, LastName, AccountId 
                                           FROM Contact];

        System.assertEquals(false, retrievedContacts.isEmpty());
    }


    /*********************************************************************************************************
    * @description Tests insert of a List of records with specified optAllOrNone value and default DMLOptions settings.
    * verify:
    *   Records not inserted
    * @return void
    **********************************************************************************************************/
    private static testMethod void testRecordsInsertWithAllOrNoneTrue() {
        if (strTestOnly != '*' && strTestOnly != 'testRecordsInsertWithAllOrNone') return;
        
        Account acct = new Account(Name = 'DMLOptionsAccount');
        insert acct;

        List<Contact> contacts = new List<Contact> { new Contact(FirstName = 'Blue', LastName = 'Cloud', AccountId = acct.Id),
                                                        new Contact(FirstName = 'Astro', AccountId = acct.Id) };
                         
        try {
            Test.startTest();
            UTIL_DMLService.insertRecords(contacts, true);
            Test.stopTest();
        } catch (DmlException e) {}
        
        List<Contact> retrievedContacts = [SELECT Id, FirstName, LastName, AccountId 
                                           FROM Contact];

        System.assertEquals(NUMBER_OF_RECORDS_ZERO, retrievedContacts.size());
    }


    /*********************************************************************************************************
    * @description Tests insert of a List of records with specified optAllOrNone value and default DMLOptions settings.
    * verify:
    *   One record inserted
    * @return void
    **********************************************************************************************************/
    private static testMethod void testRecordsInsertWithAllOrNoneFalse() {
        if (strTestOnly != '*' && strTestOnly != 'testRecordsInsertWithAllOrNone') return;
        
        Account acct = new Account(Name = 'DMLOptionsAccount');
        insert acct;

        List<Contact> contacts = new List<Contact> { new Contact(FirstName = 'Blue', LastName = 'Cloud', AccountId = acct.Id),
                                                        new Contact(FirstName = 'Astro', AccountId = acct.Id) };
                         
        Test.startTest();
        UTIL_DMLService.insertRecords(contacts, false);
        Test.stopTest();

        List<Contact> retrievedContacts = [SELECT Id, FirstName, LastName, AccountId 
                                           FROM Contact];

        System.assertEquals(NUMBER_OF_RECORDS_ONE, retrievedContacts.size());
    }


    /*********************************************************************************************************
    * @description Tests insert of a record with default DMLOptions settings.
    * verify:
    *   Record inserted
    * @return void
    **********************************************************************************************************/
    private static testMethod void testRecordInsertDMLOptions() {
        if (strTestOnly != '*' && strTestOnly != 'testRecordInsertDMLOptions') return;
        
        Account acct = new Account(Name = 'DMLOptionsAccount');
        insert acct;

        Contact con = new Contact(FirstName = 'Blue', LastName = 'Cloud', AccountId = acct.Id); 
                 
        Test.startTest();
        UTIL_DMLService.insertRecord(con, new Database.DMLOptions());
        Test.stopTest();

        List<Contact> retrievedContacts = [SELECT Id, FirstName, LastName, AccountId 
                                           FROM Contact];

        System.assertEquals(false, retrievedContacts.isEmpty());
    }


    /*********************************************************************************************************
    * @description Tests insert of a List of records with default DMLOptions settings.
    * verify:
    *   Records inserted
    * @return void
    **********************************************************************************************************/
    private static testMethod void testRecordsInsertWithDMLOptions() {
        if (strTestOnly != '*' && strTestOnly != 'testRecordsInsertWithDMLOptions') return;
        
        Account acct = new Account(Name = 'DMLOptionsAccount');
        insert acct;

        List<Contact> contacts = new List<Contact> { new Contact(FirstName = 'Blue', LastName = 'Cloud', AccountId = acct.Id),
                                                        new Contact(FirstName = 'Astro', LastName = 'Cloud', AccountId = acct.Id) };
                         
        Test.startTest();
        UTIL_DMLService.insertRecords(contacts, new Database.DMLOptions());
        Test.stopTest();

        List<Contact> retrievedContacts = [SELECT Id, FirstName, LastName, AccountId 
                                           FROM Contact];

        System.assertEquals(NUMBER_OF_RECORDS_TWO, retrievedContacts.size());
    }


    /*********************************************************************************************************
    * @description Tests update of a record with default DMLOption settings.
    * verify:
    *   Record updated
    * @return void
    **********************************************************************************************************/
    private static testMethod void testRecordUpdateWithDefaults() {
        if (strTestOnly != '*' && strTestOnly != 'testRecordUpdateWithDefaults') return;
        
        Account acct = new Account(Name = 'DMLOptionsAccount');
        insert acct;

        Contact con = new Contact(FirstName = 'Blue', LastName = 'Cloud', AccountId = acct.Id); 
                 
        Test.startTest();
        UTIL_DMLService.insertRecord(con);
        Test.stopTest();

        List<Contact> retrievedInsertedContacts = [SELECT Id, FirstName, LastName, AccountId 
                                                   FROM Contact];

        System.assertEquals(false, retrievedInsertedContacts.isEmpty());

        con.FirstName = 'Cloudy';
        UTIL_DMLService.updateRecord(con);

        List<Contact> retrieveUpdatedContacts = [SELECT Id, FirstName, LastName, AccountId 
                                                 FROM Contact];

        System.assertEquals(false, retrieveUpdatedContacts.isEmpty());
        System.assertEquals(con.FirstName, retrieveUpdatedContacts[0].FirstName);
    }


    /*********************************************************************************************************
    * @description Tests update of a List of records with default DMLOptions settings.
    * verify:
    *   Records updated
    * @return void
    **********************************************************************************************************/
    private static testMethod void testRecordsUpdateWithDefaults() {
        if (strTestOnly != '*' && strTestOnly != 'testRecordsUpdateWithDefaults') return;
        
        Account acct = new Account(Name = 'DMLOptionsAccount');
        insert acct;

        List<Contact> contacts = new List<Contact> { new Contact(FirstName = 'Blue', LastName = 'Cloud', AccountId = acct.Id),
                                                     new Contact(FirstName = 'Astro', LastName = 'Cloud', AccountId = acct.Id) };
                         
        Test.startTest();
        UTIL_DMLService.insertRecords(contacts);
        Test.stopTest();

        List<Contact> retrievedInsertedContacts = [SELECT Id, FirstName, LastName, AccountId 
                                                   FROM Contact];

        System.assertEquals(false, retrievedInsertedContacts.isEmpty());

        contacts[0].FirstName = 'Cloudy';
        contacts[0].FirstName = 'Cody';
        UTIL_DMLService.updateRecords(contacts);

        List<Contact> retrieveUpdatedContacts = [SELECT Id, FirstName, LastName, AccountId 
                                                 FROM Contact];

        System.assertEquals(false, retrieveUpdatedContacts.isEmpty());
        System.assertEquals(contacts[0].FirstName, retrieveUpdatedContacts[0].FirstName);
        System.assertEquals(contacts[1].FirstName, retrieveUpdatedContacts[1].FirstName);
    }


    /*********************************************************************************************************
    * @description Tests update of a record with specified optAllOrNone value and default DMLOptions settings.
    * verify:
    *   Record updated
    * @return void
    **********************************************************************************************************/
    private static testMethod void testRecordUpdateWithAllOrNone() {
        if (strTestOnly != '*' && strTestOnly != 'testRecordUpdateWithAllOrNone') return;
        
        Account acct = new Account(Name = 'DMLOptionsAccount');
        insert acct;

        Contact con = new Contact(FirstName = 'Blue', LastName = 'Cloud', AccountId = acct.Id); 
                 
        Test.startTest();
        UTIL_DMLService.insertRecord(con, false);
        Test.stopTest();

        List<Contact> retrievedInsertedContacts = [SELECT Id, FirstName, LastName, AccountId 
                                                   FROM Contact];

        System.assertEquals(false, retrievedInsertedContacts.isEmpty());

        con.FirstName = 'Cloudy';
        UTIL_DMLService.updateRecord(con, false);

        List<Contact> retrieveUpdatedContacts = [SELECT Id, FirstName, LastName, AccountId 
                                                 FROM Contact];

        System.assertEquals(false, retrieveUpdatedContacts.isEmpty());
        System.assertEquals(con.FirstName, retrieveUpdatedContacts[0].FirstName);
    }


    /*********************************************************************************************************
    * @description Tests update of a List of records with specified optAllOrNone value and default DMLOptions settings.
    * verify:
    *   Records updated
    * @return void
    **********************************************************************************************************/
    private static testMethod void testRecordsUpdateWithAllOrNone() {
        if (strTestOnly != '*' && strTestOnly != 'testRecordsUpdateWithAllOrNone') return;
        
        Account acct = new Account(Name = 'DMLOptionsAccount');
        insert acct;

        List<Contact> contacts = new List<Contact> { new Contact(FirstName = 'Blue', LastName = 'Cloud', AccountId = acct.Id),
                                                     new Contact(FirstName = 'Astro', LastName = 'Cloud', AccountId = acct.Id) };
                         
        Test.startTest();
        UTIL_DMLService.insertRecords(contacts, false);
        Test.stopTest();

        List<Contact> retrievedInsertedContacts = [SELECT Id, FirstName, LastName, AccountId 
                                                   FROM Contact];

        System.assertEquals(false, retrievedInsertedContacts.isEmpty());

        contacts[0].FirstName = 'Cloudy';
        contacts[0].FirstName = 'Cody';
        UTIL_DMLService.updateRecords(contacts, false);

        List<Contact> retrieveUpdatedContacts = [SELECT Id, FirstName, LastName, AccountId 
                                                 FROM Contact];

        System.assertEquals(false, retrieveUpdatedContacts.isEmpty());
        System.assertEquals(contacts[0].FirstName, retrieveUpdatedContacts[0].FirstName);
        System.assertEquals(contacts[1].FirstName, retrieveUpdatedContacts[1].FirstName);
    }


    /*********************************************************************************************************
    * @description Tests update of a record with specified default DMLOptions settings.
    * verify:
    *   Record updated
    * @return void
    **********************************************************************************************************/
    private static testMethod void testRecordUpdateWithDMLOptions() {
        if (strTestOnly != '*' && strTestOnly != 'testRecordUpdateWithDMLOptions') return;
        
        Account acct = new Account(Name = 'DMLOptionsAccount');
        insert acct;

        Contact con = new Contact(FirstName = 'Blue', LastName = 'Cloud', AccountId = acct.Id); 
                 
        Test.startTest();
        UTIL_DMLService.insertRecord(con, false);
        Test.stopTest();

        List<Contact> retrievedInsertedContacts = [SELECT Id, FirstName, LastName, AccountId 
                                                   FROM Contact];

        System.assertEquals(false, retrievedInsertedContacts.isEmpty());

        con.FirstName = 'Cloudy';
        UTIL_DMLService.updateRecord(con, new Database.DMLOptions());

        List<Contact> retrieveUpdatedContacts = [SELECT Id, FirstName, LastName, AccountId 
                                                 FROM Contact];

        System.assertEquals(false, retrieveUpdatedContacts.isEmpty());
        System.assertEquals(con.FirstName, retrieveUpdatedContacts[0].FirstName);
    }


    /*********************************************************************************************************
    * @description Tests update of a List of records with default DMLOptions settings.
    * verify:
    *   Records updated
    * @return void
    **********************************************************************************************************/
    private static testMethod void testRecordsUpdateWithDMLOptions() {
        if (strTestOnly != '*' && strTestOnly != 'testRecordsUpdateWithDMLOptions') return;
        
        Account acct = new Account(Name = 'DMLOptionsAccount');
        insert acct;

        List<Contact> contacts = new List<Contact> { new Contact(FirstName = 'Blue', LastName = 'Cloud', AccountId = acct.Id),
                                                     new Contact(FirstName = 'Astro', LastName = 'Cloud', AccountId = acct.Id) };
                         
        Test.startTest();
        UTIL_DMLService.insertRecords(contacts, false);
        Test.stopTest();

        List<Contact> retrievedInsertedContacts = [SELECT Id, FirstName, LastName, AccountId 
                                                   FROM Contact];

        System.assertEquals(false, retrievedInsertedContacts.isEmpty());

        contacts[0].FirstName = 'Cloudy';
        contacts[0].FirstName = 'Cody';
        UTIL_DMLService.updateRecords(contacts, new Database.DMLOptions());

        List<Contact> retrieveUpdatedContacts = [SELECT Id, FirstName, LastName, AccountId 
                                                 FROM Contact];

        System.assertEquals(false, retrieveUpdatedContacts.isEmpty());
        System.assertEquals(contacts[0].FirstName, retrieveUpdatedContacts[0].FirstName);
        System.assertEquals(contacts[1].FirstName, retrieveUpdatedContacts[1].FirstName);
    }


    /*********************************************************************************************************
    * @description Tests upsert of a record by wrapping Database.upsert(...).
    * verify:
    *   Record upserted
    * @return void
    **********************************************************************************************************/
    private static testMethod void testRecordUpsertWithDefaults() {
        if (strTestOnly != '*' && strTestOnly != 'testRecordUpsertWithDefaults') return;

        Account acct = new Account(Name = 'UpsertedAccount');
        Test.startTest();
        UTIL_DMLService.upsertRecord(acct);
        Test.stopTest();

        List<Account> retrievedUpsertedAccount = [SELECT Id, Name
                                                  FROM Account];

        System.assertEquals(false, retrievedUpsertedAccount.isEmpty());

        acct.Name = 'Cloudy';
        UTIL_DMLService.upsertRecord(acct);

        retrievedUpsertedAccount = [SELECT Id, Name
                                    FROM Account];

        System.assertEquals(acct.Name, retrievedUpsertedAccount[0].Name);
    }


    /*********************************************************************************************************
    * @description Tests upsert of a List of records by wrapping Database.upsert(...).
    * verify:
    *   Records upserted
    * @return void
    **********************************************************************************************************/
    private static testMethod void testRecordsUpsertWithDefaults() {
        if (strTestOnly != '*' && strTestOnly != 'testRecordsUpsertWithDefaults') return;

        Account acct = new Account(Name = 'UpsertedAccount');
        insert acct;

        List<Contact> contacts = new List<Contact> { new Contact(FirstName = 'Blue', LastName = 'Cloud', AccountId = acct.Id),
                                                     new Contact(FirstName = 'Astro', LastName = 'Cloud', AccountId = acct.Id) };

        Test.startTest();
        UTIL_DMLService.upsertRecords(contacts);
        Test.stopTest();

        List<Contact> retrievedUpsertedContacts = [SELECT Id, FirstName, LastName, AccountId
                                                   FROM Contact];

        System.assertEquals(false, retrievedUpsertedContacts.isEmpty());

        contacts[0].FirstName = 'Cloudy';
        contacts[0].FirstName = 'Cody';
        UTIL_DMLService.upsertRecords(contacts);

        retrievedUpsertedContacts = [SELECT Id, FirstName, LastName, AccountId
                                     FROM Contact];

        System.assertEquals(contacts[0].FirstName, retrievedUpsertedContacts[0].FirstName);
        System.assertEquals(contacts[1].FirstName, retrievedUpsertedContacts[1].FirstName);
    }


    /*********************************************************************************************************
    * @description Tests upsert of a record with specified allOrNone value.
    * verify:
    *   Record upserted
    * @return void
    **********************************************************************************************************/
    private static testMethod void testRecordUpsertWithAllOrNone() {
        if (strTestOnly != '*' && strTestOnly != 'testRecordUpsertWithAllOrNone') return;

        Account acct = new Account(Name = 'UpsertedAccount');
        insert acct;

        Contact con = new Contact(FirstName = 'Blue', LastName = 'Cloud', AccountId = acct.Id);

        Test.startTest();
        UTIL_DMLService.upsertRecord(con, false);
        Test.stopTest();

        List<Contact> retrievedUpsertedContacts = [SELECT Id, FirstName, LastName, AccountId
                                                   FROM Contact];

        System.assertEquals(false, retrievedUpsertedContacts.isEmpty());

        con.FirstName = 'Cloudy';
        UTIL_DMLService.upsertRecord(con, false);

        retrievedUpsertedContacts = [SELECT Id, FirstName, LastName, AccountId
                                     FROM Contact];

        System.assertEquals(con.FirstName, retrievedUpsertedContacts[0].FirstName);
    }


    /*********************************************************************************************************
    * @description Tests upsert of a List of records with specified allOrNone value.
    * verify:
    *   Records upserted
    * @return void
    **********************************************************************************************************/
    private static testMethod void testRecordsUpsertWithAllOrNone() {
        if (strTestOnly != '*' && strTestOnly != 'testRecordsUpsertWithAllOrNone') return;

        Account acct = new Account(Name = 'UpsertedAccount');
        insert acct;

        List<Contact> contacts = new List<Contact> { new Contact(FirstName = 'Blue', LastName = 'Cloud', AccountId = acct.Id),
                                                     new Contact(FirstName = 'Astro', LastName = 'Cloud', AccountId = acct.Id) };

        Test.startTest();
        UTIL_DMLService.upsertRecords(contacts, false);
        Test.stopTest();

        List<Contact> retrievedUpsertedContacts = [SELECT Id, FirstName, LastName, AccountId
                                                   FROM Contact];

        System.assertEquals(false, retrievedUpsertedContacts.isEmpty());

        contacts[0].FirstName = 'Cloudy';
        contacts[0].FirstName = 'Cody';
        UTIL_DMLService.upsertRecords(contacts, false);

        retrievedUpsertedContacts = [SELECT Id, FirstName, LastName, AccountId
                                     FROM Contact];

        System.assertEquals(contacts[0].FirstName, retrievedUpsertedContacts[0].FirstName);
        System.assertEquals(contacts[1].FirstName, retrievedUpsertedContacts[1].FirstName);
    }


    /*********************************************************************************************************
    * @description Tests the NPSP Setting Respect Duplicate Rule Settings for duplicate Accounts
    *   set to false 
    * verify:
    *   Duplicate Accounts detected and allowed when the Respect Duplicate Rule Setting set to true.
    * @return void
    **********************************************************************************************************/
    private static testMethod void testRespectDuplicateRuleSettingsForAccounts() {
        if (strTestOnly != '*' && strTestOnly != 'testRespectDuplicateRuleSettingsForAccounts') return;

        UTIL_CustomSettingsFacade.getErrorSettingsForTests(new Error_Settings__c(Respect_Duplicate_Rule_Settings__c = false));
        Error_Settings__c errorSettings = UTIL_CustomSettingsFacade.getErrorSettings();
        UTIL_DMLService.insertRecord(errorSettings);

        Account acct = new Account(Name='Blue Cloud', BillingCity='San Francisco');
        UTIL_DMLService.insertRecord(acct);
        List<Account> retrievedAccts = [SELECT Id, Name FROM Account];
        System.assertEquals('Blue Cloud', retrievedAccts[0].Name);

        Account dupeAcct = new Account(Name='Blue Cloud', BillingCity='San Francisco');
        Database.SaveResult sr = UTIL_DMLService.insertRecord(dupeAcct, false); // AllOrNone flag set to false to check if the Duplicate Rule's Action is set to Block. 
        if (!sr.isSuccess()) {
            for (Database.Error duplicateError : sr.getErrors()) {
                System.assertEquals(ERROR_STATUS_CODE_DUPLICATES_DETECTED, String.valueOf(duplicateError.getStatusCode()));
                Datacloud.DuplicateResult duplicateResult = ((Database.DuplicateError)duplicateError).getDuplicateResult();
                // If isAllowSave is false, the running Org has the Duplicate Rule's Action set to Block so end test.
                if (!duplicateResult.isAllowSave()) return;
            }
        } else {
            // If the dupeAcct was successfully saved, the running Org may have Duplicate Rules deactivated so end test.
            retrievedAccts = [SELECT Id, Name FROM Account];
            if (retrievedAccts.size() == NUMBER_OF_RECORDS_TWO) return;
        }

        errorSettings.Respect_Duplicate_Rule_Settings__c = true;
        UTIL_DMLService.updateRecord(errorSettings);

        UTIL_DMLService.insertRecord(dupeAcct);

        retrievedAccts = [SELECT Id, Name FROM Account];
        System.assertEquals(NUMBER_OF_RECORDS_TWO, retrievedAccts.size());

        Account dupeAcctUpdate = new Account(Name='Blue Cloud Update', BillingCity='San Francisco');
        UTIL_DMLService.insertRecord(dupeAcctUpdate);
        retrievedAccts = [SELECT Id, Name FROM Account];
        System.assertEquals(NUMBER_OF_RECORDS_THREE, retrievedAccts.size());

        dupeAcctUpdate.Name = 'Blue Cloud';
        UTIL_DMLService.updateRecord(dupeAcctUpdate);

        retrievedAccts = [SELECT Id, Name FROM Account];
        for(Account eachAcct : retrievedAccts) {
            System.assertEquals('Blue Cloud', eachAcct.Name);
        }
    }


    /*********************************************************************************************************
    * @description Tests the NPSP Setting Respect Duplicate Rule Settings for duplicate Contacts
    *   Records To Be Saved set to true 
    * verify:
    *    Duplicate Contacts detected and allowed when the Respect Duplicate Rule Setting set to true
    * @return void
    **********************************************************************************************************/
    private static testMethod void testRespectDuplicateRuleSettingsForContacts() {
        if (strTestOnly != '*' && strTestOnly != 'testRespectDuplicateRuleSettingsForContacts') return;

        UTIL_CustomSettingsFacade.getErrorSettingsForTests(new Error_Settings__c(Respect_Duplicate_Rule_Settings__c = false));
        Error_Settings__c errorSettings = UTIL_CustomSettingsFacade.getErrorSettings();
        UTIL_DMLService.insertRecord(errorSettings);

        Account acct = new Account(Name='Blue Cloud', BillingCity='San Francisco');
        UTIL_DMLService.insertRecord(acct);
        Contact con = new Contact(FirstName='Blue',LastName='Cloud', Email='blue@cloud.com', AccountId=acct.Id);
        UTIL_DMLService.insertRecord(con);

        List<Contact> retrievedContacts = [SELECT Id, FirstName FROM Contact];
        System.assertEquals('Blue', retrievedContacts[0].FirstName);

        Contact dupeContact = new Contact(FirstName='Blue',LastName='Cloud', Email='blue@cloud.com', AccountId=acct.Id);
        Database.SaveResult sr = UTIL_DMLService.insertRecord(dupeContact, false); // AllOrNone flag set to false to check if the Duplicate Rule's Action is set to Block. 
        if (!sr.isSuccess()) {
            for (Database.Error duplicateError : sr.getErrors()) {
                System.assertEquals(ERROR_STATUS_CODE_DUPLICATES_DETECTED, String.valueOf(duplicateError.getStatusCode()));
                Datacloud.DuplicateResult duplicateResult = ((Database.DuplicateError)duplicateError).getDuplicateResult();
                // If isAllowSave is false, the running Org has the Duplicate Rule Action set to Block so end test.
                if (!duplicateResult.isAllowSave()) return;
            }
        } else {
            // If the dupeContact was successfully saved, the running Org may have Duplicate Rules deactivated so end test.
            retrievedContacts = [SELECT Id, FirstName FROM Contact];
            if (retrievedContacts.size() == NUMBER_OF_RECORDS_TWO) return;
        }

        errorSettings.Respect_Duplicate_Rule_Settings__c = true;
        UTIL_DMLService.updateRecord(errorSettings);

        UTIL_DMLService.insertRecord(dupeContact);
        retrievedContacts = [SELECT Id, FirstName FROM Contact];
        System.assertEquals(NUMBER_OF_RECORDS_TWO, retrievedContacts.size());

        Contact dupeContactUpdate = new Contact(FirstName='Blue Update',LastName='Cloud', Email='blue@cloud.com', AccountId=acct.Id);
        UTIL_DMLService.insertRecord(dupeContactUpdate);
        retrievedContacts = [SELECT Id, FirstName FROM Contact];
        System.assertEquals(NUMBER_OF_RECORDS_THREE, retrievedContacts.size());

        dupeContactUpdate.FirstName = 'Blue';
        UTIL_DMLService.updateRecord(dupeContactUpdate);

        retrievedContacts = [SELECT Id, FirstName FROM Contact];
        for(Contact eachCon : retrievedContacts) {
            System.assertEquals('Blue', eachCon.FirstName);
        }
    }


}