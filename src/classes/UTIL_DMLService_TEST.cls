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
private with sharing class UTIL_DMLService_TEST {
    
    private static final Integer NUMBER_OF_RECORDS_ZERO = 0;
    private static final Integer NUMBER_OF_RECORDS_ONE = 1;
    private static final Integer NUMBER_OF_RECORDS_TWO = 2;
    private static final Integer NUMBER_OF_RECORDS_THREE = 3;
    private static final String ERROR_STATUS_CODE_DUPLICATES_DETECTED = 'DUPLICATES_DETECTED';

    private static final TEST_SobjectGateway.ErrorGateway errorGateway = new TEST_SobjectGateway.ErrorGateway();


    /***
    * @description Tests insert of a record with default DMLOption settings.
    * verify: Record inserted
    */
    @isTest
    private static void testRecordInsertWithDefaults() {
        Account acct = new Account(Name = 'DMLOptionsAccount');
        insert acct;

        Contact con = new Contact(FirstName = 'Blue', LastName = 'Cloud', AccountId = acct.Id); 
                 
        Test.startTest();
        UTIL_DMLService.insertRecord(con);
        Test.stopTest();

        List<Contact> retrievedContacts = getContacts();

        System.assertEquals(false, retrievedContacts.isEmpty());
    }


    /***
    * @description Tests insert of a List of records with default DMLOptions settings.
    * verify: Records inserted
    */
    @isTest
    private static void testRecordsInsertWithDefaults() {
        Account acct = new Account(Name = 'DMLOptionsAccount');
        insert acct;

        List<Contact> contacts = new List<Contact> { new Contact(FirstName = 'Blue', LastName = 'Cloud', AccountId = acct.Id),
                                                        new Contact(FirstName = 'Astro', LastName = 'Cloud', AccountId = acct.Id) };
                         
        Test.startTest();
        UTIL_DMLService.insertRecords(contacts);
        Test.stopTest();

        List<Contact> retrievedContacts = getContacts();

        System.assertEquals(NUMBER_OF_RECORDS_TWO, retrievedContacts.size());
    }


    /***
    * @description Tests insert of a record with specified optAllOrNone value and default DMLOptions settings.
    * verify: Record inserted
    */
    @isTest
    private static void testRecordInsertWithAllOrNone() {
        Account acct = new Account(Name = 'DMLOptionsAccount');
        insert acct;

        Contact con = new Contact(FirstName = 'Blue', LastName = 'Cloud', AccountId = acct.Id); 
                 
        Test.startTest();
        UTIL_DMLService.insertRecord(con, false);
        Test.stopTest();

        List<Contact> retrievedContacts = getContacts();

        System.assertEquals(false, retrievedContacts.isEmpty());
    }


    /***
    * @description Tests insert of a List of records with specified optAllOrNone value and default DMLOptions settings.
    * verify: Records not inserted
    */
    @isTest
    private static void testRecordsInsertWithAllOrNoneTrue() {
        Account acct = new Account(Name = 'DMLOptionsAccount');
        insert acct;

        List<Contact> contacts = new List<Contact> { new Contact(FirstName = 'Blue', LastName = 'Cloud', AccountId = acct.Id),
                                                        new Contact(FirstName = 'Astro', AccountId = acct.Id) };
                         
        try {
            Test.startTest();
            UTIL_DMLService.insertRecords(contacts, true);
            Test.stopTest();
        } catch (DmlException e) {}
        
        List<Contact> retrievedContacts = getContacts();

        System.assertEquals(NUMBER_OF_RECORDS_ZERO, retrievedContacts.size());
    }


    /***
    * @description Tests insert of a List of records with specified optAllOrNone value and default DMLOptions settings.
    * verify: One record inserted
    */
    @isTest
    private static void testRecordsInsertWithAllOrNoneFalse() {
        Account acct = new Account(Name = 'DMLOptionsAccount');
        insert acct;

        List<Contact> contacts = new List<Contact> { new Contact(FirstName = 'Blue', LastName = 'Cloud', AccountId = acct.Id),
                                                        new Contact(FirstName = 'Astro', AccountId = acct.Id) };
                         
        Test.startTest();
        UTIL_DMLService.insertRecords(contacts, false);
        Test.stopTest();

        List<Contact> retrievedContacts = getContacts();

        System.assertEquals(NUMBER_OF_RECORDS_ONE, retrievedContacts.size());
    }


    /***
    * @description Tests insert of a record with default DMLOptions settings.
    * verify: Record inserted
    */
    @isTest
    private static void testRecordInsertDMLOptions() {
        Account acct = new Account(Name = 'DMLOptionsAccount');
        insert acct;

        Contact con = new Contact(FirstName = 'Blue', LastName = 'Cloud', AccountId = acct.Id); 
                 
        Test.startTest();
        UTIL_DMLService.insertRecord(con, new Database.DMLOptions());
        Test.stopTest();

        List<Contact> retrievedContacts = getContacts();

        System.assertEquals(false, retrievedContacts.isEmpty());
    }


    /***
    * @description Tests insert of a List of records with default DMLOptions settings.
    * verify: Records inserted
    */
    @isTest
    private static void testRecordsInsertWithDMLOptions() {
        Account acct = new Account(Name = 'DMLOptionsAccount');
        insert acct;

        List<Contact> contacts = new List<Contact> { new Contact(FirstName = 'Blue', LastName = 'Cloud', AccountId = acct.Id),
                                                        new Contact(FirstName = 'Astro', LastName = 'Cloud', AccountId = acct.Id) };
                         
        Test.startTest();
        UTIL_DMLService.insertRecords(contacts, new Database.DMLOptions());
        Test.stopTest();

        List<Contact> retrievedContacts = getContacts();

        System.assertEquals(NUMBER_OF_RECORDS_TWO, retrievedContacts.size());
    }


    /***
    * @description Tests update of a record with default DMLOption settings.
    * verify: Record updated
    */
    @isTest
    private static void testRecordUpdateWithDefaults() {
        Account acct = new Account(Name = 'DMLOptionsAccount');
        insert acct;

        Contact con = new Contact(FirstName = 'Blue', LastName = 'Cloud', AccountId = acct.Id); 
                 
        Test.startTest();
        UTIL_DMLService.insertRecord(con);
        Test.stopTest();

        List<Contact> retrievedInsertedContacts = getContacts();

        System.assertEquals(false, retrievedInsertedContacts.isEmpty());

        con.FirstName = 'Cloudy';
        UTIL_DMLService.updateRecord(con);

        List<Contact> retrieveUpdatedContacts = getContacts();

        System.assertEquals(false, retrieveUpdatedContacts.isEmpty());
        System.assertEquals(con.FirstName, retrieveUpdatedContacts[0].FirstName);
    }


    /***
    * @description Tests update of a List of records with default DMLOptions settings.
    * verify: Records updated
    */
    @isTest
    private static void testRecordsUpdateWithDefaults() {
        Account acct = new Account(Name = 'DMLOptionsAccount');
        insert acct;

        List<Contact> contacts = new List<Contact> { new Contact(FirstName = 'Blue', LastName = 'Cloud', AccountId = acct.Id),
                                                     new Contact(FirstName = 'Astro', LastName = 'Cloud', AccountId = acct.Id) };
                         
        Test.startTest();
        UTIL_DMLService.insertRecords(contacts);
        Test.stopTest();

        List<Contact> retrievedInsertedContacts = getContacts();

        System.assertEquals(false, retrievedInsertedContacts.isEmpty());

        contacts[0].FirstName = 'Cloudy';
        contacts[0].FirstName = 'Cody';
        UTIL_DMLService.updateRecords(contacts);

        List<Contact> retrieveUpdatedContacts = getContacts();

        System.assertEquals(false, retrieveUpdatedContacts.isEmpty());
        System.assertEquals(contacts[0].FirstName, retrieveUpdatedContacts[0].FirstName);
        System.assertEquals(contacts[1].FirstName, retrieveUpdatedContacts[1].FirstName);
    }


    /***
    * @description Tests update of a record with specified optAllOrNone value and default DMLOptions settings.
    * verify: Record updated
    */
    @isTest
    private static void testRecordUpdateWithAllOrNone() {
        Account acct = new Account(Name = 'DMLOptionsAccount');
        insert acct;

        Contact con = new Contact(FirstName = 'Blue', LastName = 'Cloud', AccountId = acct.Id); 
                 
        Test.startTest();
        UTIL_DMLService.insertRecord(con, false);
        Test.stopTest();

        List<Contact> retrievedInsertedContacts = getContacts();

        System.assertEquals(false, retrievedInsertedContacts.isEmpty());

        con.FirstName = 'Cloudy';
        UTIL_DMLService.updateRecord(con, false);

        List<Contact> retrieveUpdatedContacts = getContacts();

        System.assertEquals(false, retrieveUpdatedContacts.isEmpty());
        System.assertEquals(con.FirstName, retrieveUpdatedContacts[0].FirstName);
    }


    /***
    * @description Tests update of a List of records with specified optAllOrNone value and default DMLOptions settings.
    * verify: Records updated
    */
    @isTest
    private static void testRecordsUpdateWithAllOrNone() {
        Account acct = new Account(Name = 'DMLOptionsAccount');
        insert acct;

        List<Contact> contacts = new List<Contact> { new Contact(FirstName = 'Blue', LastName = 'Cloud', AccountId = acct.Id),
                                                     new Contact(FirstName = 'Astro', LastName = 'Cloud', AccountId = acct.Id) };
                         
        Test.startTest();
        UTIL_DMLService.insertRecords(contacts, false);
        Test.stopTest();

        List<Contact> retrievedInsertedContacts = getContacts();

        System.assertEquals(false, retrievedInsertedContacts.isEmpty());

        contacts[0].FirstName = 'Cloudy';
        contacts[0].FirstName = 'Cody';
        UTIL_DMLService.updateRecords(contacts, false);

        List<Contact> retrieveUpdatedContacts = getContacts();

        System.assertEquals(false, retrieveUpdatedContacts.isEmpty());
        System.assertEquals(contacts[0].FirstName, retrieveUpdatedContacts[0].FirstName);
        System.assertEquals(contacts[1].FirstName, retrieveUpdatedContacts[1].FirstName);
    }


    /***
    * @description Tests update of a record with specified default DMLOptions settings.
    * verify: Record updated
    */
    @isTest
    private static void testRecordUpdateWithDMLOptions() {
        Account acct = new Account(Name = 'DMLOptionsAccount');
        insert acct;

        Contact con = new Contact(FirstName = 'Blue', LastName = 'Cloud', AccountId = acct.Id); 
                 
        Test.startTest();
        UTIL_DMLService.insertRecord(con, false);
        Test.stopTest();

        List<Contact> retrievedInsertedContacts = getContacts();

        System.assertEquals(false, retrievedInsertedContacts.isEmpty());

        con.FirstName = 'Cloudy';
        UTIL_DMLService.updateRecord(con, new Database.DMLOptions());

        List<Contact> retrieveUpdatedContacts = getContacts();

        System.assertEquals(false, retrieveUpdatedContacts.isEmpty());
        System.assertEquals(con.FirstName, retrieveUpdatedContacts[0].FirstName);
    }


    /***
    * @description Tests update of a List of records with default DMLOptions settings.
    * verify: Records updated
    */
    @isTest
    private static void testRecordsUpdateWithDMLOptions() {
        Account acct = new Account(Name = 'DMLOptionsAccount');
        insert acct;

        List<Contact> contacts = new List<Contact> { new Contact(FirstName = 'Blue', LastName = 'Cloud', AccountId = acct.Id),
                                                     new Contact(FirstName = 'Astro', LastName = 'Cloud', AccountId = acct.Id) };
                         
        Test.startTest();
        UTIL_DMLService.insertRecords(contacts, false);
        Test.stopTest();

        List<Contact> retrievedInsertedContacts = getContacts();

        System.assertEquals(false, retrievedInsertedContacts.isEmpty());

        contacts[0].FirstName = 'Cloudy';
        contacts[0].FirstName = 'Cody';
        UTIL_DMLService.updateRecords(contacts, new Database.DMLOptions());

        List<Contact> retrieveUpdatedContacts = getContacts();

        System.assertEquals(false, retrieveUpdatedContacts.isEmpty());
        System.assertEquals(contacts[0].FirstName, retrieveUpdatedContacts[0].FirstName);
        System.assertEquals(contacts[1].FirstName, retrieveUpdatedContacts[1].FirstName);
    }
    /***
    * @description Verifies records are updated and no error is generated
    */
    @isTest
    private static void shouldUpdateRecordsAndLogNoError() {
        List<Contact> contacts = new List<Contact>{
            UTIL_UnitTestData_TEST.getContact(),
            UTIL_UnitTestData_TEST.getContact()
        };
        insert contacts;

        for (Contact c : contacts) {
            c.LastName += ' Updated';
        }

        Test.startTest();
        UTIL_DMLService.updateRecordBatchAndLogErrors(contacts, 'TestContext');
        Test.stopTest();

        List<Error__c> errors = errorGateway.getRecords();
        System.assertEquals(0, errors.size(), 'No Error should be generated: ' + errors);

        List<Contact> actualContacts = getContacts();
        System.assertEquals(contacts.size(), actualContacts.size(), 'Number of records should match');

        for (Contact c : contacts) {
            System.assert(c.LastName.endsWith(' Updated'), 'The record should be updated: ' + c);
        }
    }

    /***
    * @description Verifies error is created when the update fails
    */
    @isTest
    private static void shouldLogErrorOnUpdateFailure() {
        List<Contact> contacts = new List<Contact>{
            UTIL_UnitTestData_TEST.getContact(),
            UTIL_UnitTestData_TEST.getContact()
        };
        insert contacts;
        contacts = getContacts();

        //mock invalid record
        contacts[0].Id = UTIL_UnitTestData_TEST.mockId(Contact.SObjectType);

        for (Contact c : contacts) {
            c.LastName += ' Updated';
        }

        Test.startTest();
        UTIL_DMLService.updateRecordBatchAndLogErrors(contacts, 'TestContext');
        Test.stopTest();

        List<Error__c> errors = errorGateway.getRecords();
        System.assertEquals(1, errors.size(), 'An Error should be generated: ' + errors);

        Map<Id, Contact> actualContactById = new Map<Id, Contact>(getContacts());

        System.assert(actualContactById.get(contacts[1].Id).LastName.endsWith(' Updated'), 
            'Valid record should be updated: ' + actualContactById.get(contacts[1].Id));
    }

    /***
    * @description Tests upsert of a record by wrapping Database.upsert(...).
    * verify: Record upserted
    */
    @isTest
    private static void testRecordUpsertWithDefaults() {
        Account acct = new Account(Name = 'UpsertedAccount');
        Test.startTest();
        UTIL_DMLService.upsertRecord(acct);
        Test.stopTest();

        List<Account> retrievedUpsertedAccount = getAccounts();

        System.assertEquals(false, retrievedUpsertedAccount.isEmpty());

        acct.Name = 'Cloudy';
        UTIL_DMLService.upsertRecord(acct);

        retrievedUpsertedAccount = getAccounts();

        System.assertEquals(acct.Name, retrievedUpsertedAccount[0].Name);
    }


    /***
    * @description Tests upsert of a List of records by wrapping Database.upsert(...).
    * verify: Records upserted
    */
    @isTest
    private static void testRecordsUpsertWithDefaults() {
        Account acct = new Account(Name = 'UpsertedAccount');
        insert acct;

        List<Contact> contacts = new List<Contact> { new Contact(FirstName = 'Blue', LastName = 'Cloud', AccountId = acct.Id),
                                                     new Contact(FirstName = 'Astro', LastName = 'Cloud', AccountId = acct.Id) };

        Test.startTest();
        UTIL_DMLService.upsertRecords(contacts);
        Test.stopTest();

        List<Contact> retrievedUpsertedContacts = getContacts();

        System.assertEquals(false, retrievedUpsertedContacts.isEmpty());

        contacts[0].FirstName = 'Cloudy';
        contacts[0].FirstName = 'Cody';
        UTIL_DMLService.upsertRecords(contacts);

        retrievedUpsertedContacts = getContacts();

        System.assertEquals(contacts[0].FirstName, retrievedUpsertedContacts[0].FirstName);
        System.assertEquals(contacts[1].FirstName, retrievedUpsertedContacts[1].FirstName);
    }


    /***
    * @description Tests upsert of a record with specified allOrNone value.
    * verify: Record upserted
    */
    @isTest
    private static void testRecordUpsertWithAllOrNone() {
        Account acct = new Account(Name = 'UpsertedAccount');
        insert acct;

        Contact con = new Contact(FirstName = 'Blue', LastName = 'Cloud', AccountId = acct.Id);

        Test.startTest();
        UTIL_DMLService.upsertRecord(con, false);
        Test.stopTest();

        List<Contact> retrievedUpsertedContacts = getContacts();

        System.assertEquals(false, retrievedUpsertedContacts.isEmpty());

        con.FirstName = 'Cloudy';
        UTIL_DMLService.upsertRecord(con, false);

        retrievedUpsertedContacts = getContacts();

        System.assertEquals(con.FirstName, retrievedUpsertedContacts[0].FirstName);
    }


    /***
    * @description Tests upsert of a List of records with specified allOrNone value.
    * verify: Records upserted
    */
    @isTest
    private static void testRecordsUpsertWithAllOrNone() {
        Account acct = new Account(Name = 'UpsertedAccount');
        insert acct;

        List<Contact> contacts = new List<Contact> { new Contact(FirstName = 'Blue', LastName = 'Cloud', AccountId = acct.Id),
                                                     new Contact(FirstName = 'Astro', LastName = 'Cloud', AccountId = acct.Id) };

        Test.startTest();
        UTIL_DMLService.upsertRecords(contacts, false);
        Test.stopTest();

        List<Contact> retrievedUpsertedContacts = getContacts();

        System.assertEquals(false, retrievedUpsertedContacts.isEmpty());

        contacts[0].FirstName = 'Cloudy';
        contacts[0].FirstName = 'Cody';
        UTIL_DMLService.upsertRecords(contacts, false);

        retrievedUpsertedContacts = getContacts();

        System.assertEquals(contacts[0].FirstName, retrievedUpsertedContacts[0].FirstName);
        System.assertEquals(contacts[1].FirstName, retrievedUpsertedContacts[1].FirstName);
    }

    /***
    * @description Verifies records are deleted and no error is generated
    */
    @isTest
    private static void shouldDeleteRecordsAndLogNoError() {
        List<Contact> contacts = new List<Contact>{
            UTIL_UnitTestData_TEST.getContact(),
            UTIL_UnitTestData_TEST.getContact()
        };
        insert contacts;

        Test.startTest();
        UTIL_DMLService.deleteRecordsAndLogErrors(contacts, 'TestContext');
        Test.stopTest();

        List<Error__c> errors = errorGateway.getRecords();
        System.assertEquals(0, errors.size(), 'No Error should be generated: ' + errors);

        System.assertEquals(0, getContacts().size(), 'Records should be deleted');
    }

    /***
    * @description Verifies error is created when deletion fails
    */
    @isTest
    private static void shouldLogErrorOnDeletionFailure() {
        List<Contact> contacts = new List<Contact>{
            UTIL_UnitTestData_TEST.getContact(),
            UTIL_UnitTestData_TEST.getContact()
        };
        insert contacts;
        contacts = getContacts();

        //mock invalid record
        Id validContactId = contacts[0].Id;
        contacts[0].Id = UTIL_UnitTestData_TEST.mockId(Contact.SObjectType);

        Test.startTest();
        UTIL_DMLService.deleteRecordsAndLogErrors(contacts, 'TestContext');
        Test.stopTest();

        List<Error__c> errors = errorGateway.getRecords();
        System.assertEquals(1, errors.size(), 'An Error should be generated: ' + errors);

        List<Contact> actualContacts = getContacts();
        System.assertEquals(1, actualContacts.size(), 'A record should be deleted');
        System.assertEquals(validContactId, actualContacts[0].Id, 'Records not being in list should not be deleted');
    }

    /***
    * @description Tests the NPSP Setting Respect Duplicate Rule Settings for duplicate Accounts
    *   set to false 
    * verify:
    *   Duplicate Accounts detected and allowed when the Respect Duplicate Rule Setting set to true.
    */
    @isTest
    private static void testRespectDuplicateRuleSettingsForAccounts() {
        UTIL_CustomSettingsFacade.getErrorSettingsForTests(new Error_Settings__c(Respect_Duplicate_Rule_Settings__c = false));
        Error_Settings__c errorSettings = UTIL_CustomSettingsFacade.getErrorSettings();
        UTIL_DMLService.insertRecord(errorSettings);

        Account acct = new Account(Name='Blue Cloud', BillingCity='San Francisco');
        UTIL_DMLService.insertRecord(acct);
        List<Account> retrievedAccts = getAccounts();
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
            retrievedAccts = getAccounts();
            if (retrievedAccts.size() == NUMBER_OF_RECORDS_TWO) return;
        }

        errorSettings.Respect_Duplicate_Rule_Settings__c = true;
        UTIL_DMLService.updateRecord(errorSettings);

        UTIL_DMLService.insertRecord(dupeAcct);

        retrievedAccts = getAccounts();
        System.assertEquals(NUMBER_OF_RECORDS_TWO, retrievedAccts.size());

        Account dupeAcctUpdate = new Account(Name='Blue Cloud Update', BillingCity='San Francisco');
        UTIL_DMLService.insertRecord(dupeAcctUpdate);
        retrievedAccts = getAccounts();
        System.assertEquals(NUMBER_OF_RECORDS_THREE, retrievedAccts.size());

        dupeAcctUpdate.Name = 'Blue Cloud';
        UTIL_DMLService.updateRecord(dupeAcctUpdate);

        retrievedAccts = getAccounts();
        for(Account eachAcct : retrievedAccts) {
            System.assertEquals('Blue Cloud', eachAcct.Name);
        }
    }


    /***
    * @description Tests the NPSP Setting Respect Duplicate Rule Settings for duplicate Contacts
    *   Records To Be Saved set to true 
    * verify:
    *    Duplicate Contacts detected and allowed when the Respect Duplicate Rule Setting set to true
    */
    @isTest
    private static void testRespectDuplicateRuleSettingsForContacts() {
        UTIL_CustomSettingsFacade.getErrorSettingsForTests(new Error_Settings__c(Respect_Duplicate_Rule_Settings__c = false));
        Error_Settings__c errorSettings = UTIL_CustomSettingsFacade.getErrorSettings();
        UTIL_DMLService.insertRecord(errorSettings);

        Account acct = new Account(Name='Blue Cloud', BillingCity='San Francisco');
        UTIL_DMLService.insertRecord(acct);
        Contact con = new Contact(FirstName='Blue',LastName='Cloud', Email='blue@cloud.com', AccountId=acct.Id);
        UTIL_DMLService.insertRecord(con);

        List<Contact> retrievedContacts = getContacts();
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
            retrievedContacts = getContacts();
            if (retrievedContacts.size() == NUMBER_OF_RECORDS_TWO) return;
        }

        errorSettings.Respect_Duplicate_Rule_Settings__c = true;
        UTIL_DMLService.updateRecord(errorSettings);

        UTIL_DMLService.insertRecord(dupeContact);
        retrievedContacts = getContacts();
        System.assertEquals(NUMBER_OF_RECORDS_TWO, retrievedContacts.size());

        Contact dupeContactUpdate = new Contact(FirstName='Blue Update',LastName='Cloud', Email='blue@cloud.com', AccountId=acct.Id);
        UTIL_DMLService.insertRecord(dupeContactUpdate);
        retrievedContacts = getContacts();
        System.assertEquals(NUMBER_OF_RECORDS_THREE, retrievedContacts.size());

        dupeContactUpdate.FirstName = 'Blue';
        UTIL_DMLService.updateRecord(dupeContactUpdate);

        retrievedContacts = getContacts();
        for(Contact eachCon : retrievedContacts) {
            System.assertEquals('Blue', eachCon.FirstName);
        }
    }


    // Helper Methods
    /////////////////////

    /***
     * @description Retrieves Contacts
     * @return List<Contact>
     */
    private static List<Contact> getContacts() {
        return [
            SELECT Id, FirstName, LastName, AccountId, Account.Name
            FROM Contact
        ];
    }

    /***
     * @description Retrieves Accounts
     * @return List<Account>
     */
    private static List<Account> getAccounts() {
        return [
            SELECT Id, Name
            FROM Account
        ];
    }

}