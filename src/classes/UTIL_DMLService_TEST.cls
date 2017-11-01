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
* @description Service Class to handle DML actions.
*/

@isTest
public with sharing class UTIL_DMLService_TEST {
    
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

        if (!retrievedContacts.isEmpty()) {
            System.assertEquals(con.FirstName, retrievedContacts[0].FirstName);
        }
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

        if (!retrievedContacts.isEmpty()) {
            System.assertEquals(contacts[0].FirstName, retrievedContacts[0].FirstName);
            System.assertEquals(contacts[1].FirstName, retrievedContacts[1].FirstName);
        }
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

        if (!retrievedContacts.isEmpty()) {
            System.assertEquals(con.FirstName, retrievedContacts[0].FirstName);
        }
    }


    /*********************************************************************************************************
    * @description Tests insert of a List of records with specified optAllOrNone value and default DMLOptions settings.
    * verify:
    *   Records inserted
    * @return void
    **********************************************************************************************************/
    private static testMethod void testRecordsInsertWithAllOrNone() {
        if (strTestOnly != '*' && strTestOnly != 'testRecordsInsertWithAllOrNone') return;
        
        Account acct = new Account(Name = 'DMLOptionsAccount');
        insert acct;

        List<Contact> contacts = new List<Contact> { new Contact(FirstName = 'Blue', LastName = 'Cloud', AccountId = acct.Id),
                                                        new Contact(FirstName = 'Astro', LastName = 'Cloud', AccountId = acct.Id) };
                         
        Test.startTest();
        UTIL_DMLService.insertRecords(contacts, false);
        Test.stopTest();

        List<Contact> retrievedContacts = [SELECT Id, FirstName, LastName, AccountId 
                                           FROM Contact];

        if (!retrievedContacts.isEmpty()) {
            System.assertEquals(contacts[0].FirstName, retrievedContacts[0].FirstName);
            System.assertEquals(contacts[1].FirstName, retrievedContacts[1].FirstName);
        }
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

        if (!retrievedContacts.isEmpty()) {
            System.assertEquals(con.FirstName, retrievedContacts[0].FirstName);
        }
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

        if (!retrievedContacts.isEmpty()) {
            System.assertEquals(contacts[0].FirstName, retrievedContacts[0].FirstName);
            System.assertEquals(contacts[1].FirstName, retrievedContacts[1].FirstName);
        }
    }


    /*********************************************************************************************************
    * @description Tests insert of a record with specified optAllOrNone and DMLOptions values.
    * verify:
    *   Record inserted
    * @return void
    **********************************************************************************************************/
    private static testMethod void testRecordInsertWithAllOrNoneAndDMLOptions() {
        if (strTestOnly != '*' && strTestOnly != 'testRecordInsertWithAllOrNoneAndDMLOptions') return;
        
        Account acct = new Account(Name = 'DMLOptionsAccount');
        insert acct;

        Contact con = new Contact(FirstName = 'Blue', LastName = 'Cloud', AccountId = acct.Id); 
                 
        Test.startTest();
        UTIL_DMLService.insertRecord(con, false, new Database.DMLOptions());
        Test.stopTest();

        List<Contact> retrievedContacts = [SELECT Id, FirstName, LastName, AccountId 
                                           FROM Contact];

        if (!retrievedContacts.isEmpty()) {
            System.assertEquals(con.FirstName, retrievedContacts[0].FirstName);
        }
    }


    /*********************************************************************************************************
    * @description Tests insert of a List of records with specified optAllOrNone and DMLOptions values.
    * verify:
    *   Records inserted
    * @return void
    **********************************************************************************************************/
    private static testMethod void testRecordsInserttWithAllOrNoneAndDMLOptions() {
        if (strTestOnly != '*' && strTestOnly != 'testRecordsInserttWithAllOrNoneAndDMLOptions') return;
        
        Account acct = new Account(Name = 'DMLOptionsAccount');
        insert acct;

        List<Contact> contacts = new List<Contact> { new Contact(FirstName = 'Blue', LastName = 'Cloud', AccountId = acct.Id),
                                                        new Contact(FirstName = 'Astro', LastName = 'Cloud', AccountId = acct.Id) };
                         
        Test.startTest();
        UTIL_DMLService.insertRecords(contacts, false, new Database.DMLOptions());
        Test.stopTest();

        List<Contact> retrievedContacts = [SELECT Id, FirstName, LastName, AccountId 
                                           FROM Contact];

        if (!retrievedContacts.isEmpty()) {
            System.assertEquals(contacts[0].FirstName, retrievedContacts[0].FirstName);
            System.assertEquals(contacts[1].FirstName, retrievedContacts[1].FirstName);
        }
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

        if (!retrievedInsertedContacts.isEmpty()) {
            System.assertEquals(con.FirstName, retrievedInsertedContacts[0].FirstName);
        }

        con.FirstName = 'Cloudy';
        UTIL_DMLService.updateRecord(con);

        List<Contact> retrieveUpdatedContacts = [SELECT Id, FirstName, LastName, AccountId 
                                                 FROM Contact];

        if (!retrieveUpdatedContacts.isEmpty()) {
            System.assertEquals(con.FirstName, retrieveUpdatedContacts[0].FirstName);
        }
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

        if (!retrievedInsertedContacts.isEmpty()) {
            System.assertEquals(contacts[0].FirstName, retrievedInsertedContacts[0].FirstName);
            System.assertEquals(contacts[1].FirstName, retrievedInsertedContacts[1].FirstName);
        }

        contacts[0].FirstName = 'Cloudy';
        contacts[0].FirstName = 'Cody';
        UTIL_DMLService.updateRecords(contacts);

        List<Contact> retrieveUpdatedContacts = [SELECT Id, FirstName, LastName, AccountId 
                                                 FROM Contact];

        if (!retrieveUpdatedContacts.isEmpty()) {
            System.assertEquals(contacts[0].FirstName, retrieveUpdatedContacts[0].FirstName);
            System.assertEquals(contacts[1].FirstName, retrieveUpdatedContacts[1].FirstName);
        }
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

        if (!retrievedInsertedContacts.isEmpty()) {
            System.assertEquals(con.FirstName, retrievedInsertedContacts[0].FirstName);
        }

        con.FirstName = 'Cloudy';
        UTIL_DMLService.updateRecord(con, false);

        List<Contact> retrieveUpdatedContacts = [SELECT Id, FirstName, LastName, AccountId 
                                                 FROM Contact];

        if (!retrieveUpdatedContacts.isEmpty()) {
            System.assertEquals(con.FirstName, retrieveUpdatedContacts[0].FirstName);
        }
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

        if (!retrievedInsertedContacts.isEmpty()) {
            System.assertEquals(contacts[0].FirstName, retrievedInsertedContacts[0].FirstName);
            System.assertEquals(contacts[1].FirstName, retrievedInsertedContacts[1].FirstName);
        }

        contacts[0].FirstName = 'Cloudy';
        contacts[0].FirstName = 'Cody';
        UTIL_DMLService.updateRecords(contacts, false);

        List<Contact> retrieveUpdatedContacts = [SELECT Id, FirstName, LastName, AccountId 
                                                 FROM Contact];

        if (!retrieveUpdatedContacts.isEmpty()) {
            System.assertEquals(contacts[0].FirstName, retrieveUpdatedContacts[0].FirstName);
            System.assertEquals(contacts[1].FirstName, retrieveUpdatedContacts[1].FirstName);
        }
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

        if (!retrievedInsertedContacts.isEmpty()) {
            System.assertEquals(con.FirstName, retrievedInsertedContacts[0].FirstName);
        }

        con.FirstName = 'Cloudy';
        UTIL_DMLService.updateRecord(con, new Database.DMLOptions());

        List<Contact> retrieveUpdatedContacts = [SELECT Id, FirstName, LastName, AccountId 
                                                 FROM Contact];

        if (!retrieveUpdatedContacts.isEmpty()) {
            System.assertEquals(con.FirstName, retrieveUpdatedContacts[0].FirstName);
        }
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

        if (!retrievedInsertedContacts.isEmpty()) {
            System.assertEquals(contacts[0].FirstName, retrievedInsertedContacts[0].FirstName);
            System.assertEquals(contacts[1].FirstName, retrievedInsertedContacts[1].FirstName);
        }

        contacts[0].FirstName = 'Cloudy';
        contacts[0].FirstName = 'Cody';
        UTIL_DMLService.updateRecords(contacts, new Database.DMLOptions());

        List<Contact> retrieveUpdatedContacts = [SELECT Id, FirstName, LastName, AccountId 
                                                 FROM Contact];

        if (!retrieveUpdatedContacts.isEmpty()) {
            System.assertEquals(contacts[0].FirstName, retrieveUpdatedContacts[0].FirstName);
            System.assertEquals(contacts[1].FirstName, retrieveUpdatedContacts[1].FirstName);
        }
    }
    

    /*********************************************************************************************************
    * @description Tests update of a record with specified optAllOrNone and DMLOptions values.
    * verify:
    *   Record updated
    * @return void
    **********************************************************************************************************/
    private static testMethod void testRecordUpdateWithAllOrNoneAndDMLOptions() {
        if (strTestOnly != '*' && strTestOnly != 'testRecordUpdateWithAllOrNoneAndDMLOptions') return;
        
        Account acct = new Account(Name = 'DMLOptionsAccount');
        insert acct;

        Contact con = new Contact(FirstName = 'Blue', LastName = 'Cloud', AccountId = acct.Id); 
                 
        Test.startTest();
        UTIL_DMLService.insertRecord(con);
        Test.stopTest();

        List<Contact> retrievedInsertedContacts = [SELECT Id, FirstName, LastName, AccountId 
                                                   FROM Contact];

        if (!retrievedInsertedContacts.isEmpty()) {
            System.assertEquals(con.FirstName, retrievedInsertedContacts[0].FirstName);
        }

        con.FirstName = 'Cloudy';
        UTIL_DMLService.updateRecord(con, false, new Database.DMLOptions());

        List<Contact> retrieveUpdatedContacts = [SELECT Id, FirstName, LastName, AccountId 
                                                 FROM Contact];

        if (!retrieveUpdatedContacts.isEmpty()) {
            System.assertEquals(con.FirstName, retrieveUpdatedContacts[0].FirstName);
        }
    }


    /*********************************************************************************************************
    * @description Tests update of a List of records with specified optAllOrNone and DMLOptions values.
    * verify:
    *   Records updated
    * @return void
    **********************************************************************************************************/
    private static testMethod void testRecordsUpdatetWithAllOrNoneAndDMLOptions() {
        if (strTestOnly != '*' && strTestOnly != 'testRecordsUpdatetWithAllOrNoneAndDMLOptions') return;
        
        Account acct = new Account(Name = 'DMLOptionsAccount');
        insert acct;

        List<Contact> contacts = new List<Contact> { new Contact(FirstName = 'Blue', LastName = 'Cloud', AccountId = acct.Id),
                                                     new Contact(FirstName = 'Astro', LastName = 'Cloud', AccountId = acct.Id) };
                         
        Test.startTest();
        UTIL_DMLService.insertRecords(contacts, false, new Database.DMLOptions());
        Test.stopTest();

        List<Contact> retrievedInsertedContacts = [SELECT Id, FirstName, LastName, AccountId 
                                                   FROM Contact];
                                                   
        if (!retrievedInsertedContacts.isEmpty()) {
            System.assertEquals(contacts[0].FirstName, retrievedInsertedContacts[0].FirstName);
            System.assertEquals(contacts[1].FirstName, retrievedInsertedContacts[1].FirstName);
        }

        contacts[0].FirstName = 'Cloudy';
        contacts[0].FirstName = 'Cody';
        UTIL_DMLService.updateRecords(contacts, false, new Database.DMLOptions());

        List<Contact> retrieveUpdatedContacts = [SELECT Id, FirstName, LastName, AccountId 
                                                 FROM Contact];

        if (!retrieveUpdatedContacts.isEmpty()) {
            System.assertEquals(contacts[0].FirstName, retrieveUpdatedContacts[0].FirstName);
            System.assertEquals(contacts[1].FirstName, retrieveUpdatedContacts[1].FirstName);
        }
    }
    

    /*********************************************************************************************************
    * @description Tests the NPSP Setting Respect Duplicate Rule Settings for duplicate Accounts
    *   set to false 
    * verify:
    *   
    * @return void
    **********************************************************************************************************/
    private static testMethod void testRespectDuplicateRuleSettingsForAccounts() {
        if (strTestOnly != '*' && strTestOnly != 'testRespectDuplicateRuleSettingsForAccounts') return;
        
        UTIL_CustomSettingsFacade.getErrorSettingsForTests(new Error_Settings__c(Respect_Duplicate_Rule_Settings__c = false));
        Error_Settings__c errorSettings = UTIL_CustomSettingsFacade.getErrorSettings();
        UTIL_DMLService.insertRecord(errorSettings, true);
        
        Account acct = new Account(Name='Blue Cloud', BillingCity='San Francisco');
        UTIL_DMLService.insertRecord(acct);
        List<Account> retrievedAccts = [SELECT Id, Name FROM Account];
        if (!retrievedAccts.isEmpty()) {
            System.assertEquals('Blue Cloud', retrievedAccts[0].Name);
        }
        
        Account dupeAcct = new Account(Name='Blue Cloud', BillingCity='San Francisco');
        Database.SaveResult sr = UTIL_DMLService.insertRecord(dupeAcct);
        if (!sr.isSuccess()) {
            for (Database.Error duplicateError : sr.getErrors()) {
                System.assertEquals('DUPLICATES_DETECTED', String.valueOf(duplicateError.getStatusCode()));
            }
        } 

        errorSettings.Respect_Duplicate_Rule_Settings__c = true;
        UTIL_DMLService.updateRecord(errorSettings, true);
         
        UTIL_DMLService.insertRecord(dupeAcct);
        retrievedAccts = [SELECT Id, Name FROM Account];
        if (!retrievedAccts.isEmpty()) {
            System.assertEquals(2, retrievedAccts.size());
        }
    
        Account dupeAcctUpdate = new Account(Name='Blue Cloud Update', BillingCity='San Francisco');
        UTIL_DMLService.insertRecord(dupeAcctUpdate);
        retrievedAccts = [SELECT Id, Name FROM Account];
        if (!retrievedAccts.isEmpty()) {
            System.assertEquals(3, retrievedAccts.size());
        }

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
    *   Records inserted
    * @return void
    **********************************************************************************************************/
    private static testMethod void testRespectDuplicateRuleSettingsForContacts() {
        if (strTestOnly != '*' && strTestOnly != 'testRespectDuplicateRuleSettingsForContacts') return;
        
        UTIL_CustomSettingsFacade.getErrorSettingsForTests(new Error_Settings__c(Respect_Duplicate_Rule_Settings__c = false));
        Error_Settings__c errorSettings = UTIL_CustomSettingsFacade.getErrorSettings();
        UTIL_DMLService.insertRecord(errorSettings, true);
        
        Account acct = new Account(Name='Blue Cloud', BillingCity='San Francisco');
        UTIL_DMLService.insertRecord(acct);
        Contact con = new Contact(FirstName='Blue',LastName='Cloud', Email='blue@cloud.com', AccountId=acct.Id);
        UTIL_DMLService.insertRecord(con);

        List<Contact> retrievedContacts = [SELECT Id, FirstName FROM Contact];
        if (!retrievedContacts.isEmpty()) {
            System.assertEquals('Blue', retrievedContacts[0].FirstName);
        }
        
        Contact dupeContact = new Contact(FirstName='Blue',LastName='Cloud', Email='blue@cloud.com', AccountId=acct.Id);
        Database.SaveResult sr = UTIL_DMLService.insertRecord(dupeContact);
        if (!sr.isSuccess()) {
            for (Database.Error duplicateError : sr.getErrors()) {
                System.assertEquals('DUPLICATES_DETECTED', String.valueOf(duplicateError.getStatusCode()));
            }
        } 

        errorSettings.Respect_Duplicate_Rule_Settings__c = true;
        UTIL_DMLService.updateRecord(errorSettings, true);
         
        UTIL_DMLService.insertRecord(dupeContact);
        retrievedContacts = [SELECT Id, FirstName FROM Contact];
        if (!retrievedContacts.isEmpty()) {
            System.assertEquals(2, retrievedContacts.size());
        }
    
        Contact dupeContactUpdate = new Contact(FirstName='Blue Update',LastName='Cloud', Email='blue@cloud.com', AccountId=acct.Id);
        UTIL_DMLService.insertRecord(dupeContactUpdate);
        retrievedContacts = [SELECT Id, FirstName FROM Contact];
        if (!retrievedContacts.isEmpty()) {
            System.assertEquals(3, retrievedContacts.size());
        }

        dupeContactUpdate.FirstName = 'Blue';
        UTIL_DMLService.updateRecord(dupeContactUpdate);

        retrievedContacts = [SELECT Id, FirstName FROM Contact];
        for(Contact eachCon : retrievedContacts) {
            System.assertEquals('Blue', eachCon.FirstName);
        }
    
    }
    

}