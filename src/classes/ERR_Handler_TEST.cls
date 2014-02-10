/*
    Copyright (c) 2013, Salesforce.com Foundation
    All rights reserved.
    
    Redistribution and use in source and binary forms, with or without
    modification, are permitted provided that the following conditions are met:
    
    * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution.
    * Neither the name of the Salesforce.com Foundation nor the names of
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
@isTest
public with sharing class ERR_Handler_TEST {

    // if you only want to run one test in this class, fill in its name here.
    // if you want to run all tests, then use '*'
    private static string strTestOnly = '*';
    
    private static void setup() {
    	insert new Error_Settings__c(Store_Errors__c = true);
    }
    
    /*** We need to use Database.insert because otherwise the code does not pass the contacts insert
         in the test itself. A record gets inserted just because the name field for accounts was not
         retrieved. This happens in the second pass of the Database.insert ***/
    public testmethod static void errorsStoredInDbTdtmCustomConfig() {
    	if (strTestOnly != '*' && strTestOnly != 'errorsStoredInDbTdtmCustomConfig') return;
    	
    	setup();
    	
    	insert new Trigger_Handler__c(Active__c = true, Asynchronous__c = false, 
              Class__c = 'ERR_ParentAccountUpdater_TEST', Load_Order__c = 1, Object__c = 'Contact', 
              Trigger_Action__c = 'BeforeInsert;');
    	            
    	//Create account
    	Account acc1 = new Account(Name='test1');
    	Account acc2 = new Account(Name='test2');
    	Account acc3 = new Account(Name='test3');
        insert new Account[] {acc1, acc2, acc3};
        
        //Create contact
        Contact contact1 = new Contact(FirstName = 'test', LastName = 'testerson1', AccountId = acc1.Id, Title = 'VP1');
        Contact contact2 = new Contact(FirstName = 'test', LastName = 'testerson2', AccountId = acc2.Id, Title = 'VP2');
        Contact contact3 = new Contact(FirstName = 'test', LastName = 'testerson3', AccountId = acc3.Id, Title = 'VP3');

        //Delete the account to get ERR_ParentAccountUpdater_TEST code to throw an exception
        delete acc2;
        
        Test.startTest();
	    List<Contact> contacts = new Contact[]{contact1, contact2, contact3};
	    LIST<database.SaveResult> results = Database.insert(contacts, false);
        Test.stopTest();
        
        //If a non-dml error occurs we rolled the whole thing back, and flag all message as having errors.
        //(Unfortunately we cannot check (and assert) the error messages added.)
        System.assertEquals(true, results[0].isSuccess());  
        System.assertEquals(false, results[1].isSuccess()); 
        System.assertEquals(true, results[2].isSuccess()); 

        //Verify 2 contacts were properly inserted
        list<Contact> insertedContacts = [select Id from Contact where Id in :contacts];
        System.assertEquals(2, insertedContacts.size()); 
        
        //Verify error record was created
        List<Error__c> errors = [select Id, Full_Message__c, Stack_Trace__c from Error__c];
        System.assertEquals(1, errors.size()); 
    }
    
    /** To prove that there are different types of null pointer exceptions. In this case the account
    name is always available. The error does not get stored because the second time that Database.insert 
    runs there are no errors. **/
    public testmethod static void errorsStoredInDbTdtmCustomConfig2() {
        if (strTestOnly != '*' && strTestOnly != 'errorsStoredInDbTdtmCustomConfig') return;
        
        setup();
        
        insert new Trigger_Handler__c(Active__c = true, Asynchronous__c = false, 
              Class__c = 'ERR_ParentAccountUpdater2_TEST', Load_Order__c = 1, Object__c = 'Contact', 
              Trigger_Action__c = 'BeforeInsert;');
                    
        //Create account
        Account acc1 = new Account(Name='test1');
        Account acc2 = new Account(Name='test2');
        Account acc3 = new Account(Name='test3');
        insert new Account[] {acc1, acc2, acc3};
        
        //Create contact
        Contact contact1 = new Contact(FirstName = 'test', LastName = 'testerson1', AccountId = acc1.Id, Title = 'VP1');
        Contact contact2 = new Contact(FirstName = 'test', LastName = 'testerson2', AccountId = acc2.Id, Title = 'VP2');
        Contact contact3 = new Contact(FirstName = 'test', LastName = 'testerson3', AccountId = acc3.Id, Title = 'VP3');

        //Delete the account to get ERR_ParentAccountUpdater_TEST code to throw an exception
        delete acc2;
        
        Test.startTest();
        List<Contact> contacts = new Contact[]{contact1, contact2, contact3};
        LIST<database.SaveResult> results = Database.insert(contacts, false);
        Test.stopTest();
        
        //If a non-dml error occurs we rolled the whole thing back, and flag all message as having errors.
        //(Unfortunately we cannot check (and assert) the error messages added.)
        System.assertEquals(true, results[0].isSuccess());  
        System.assertEquals(false, results[1].isSuccess()); 
        System.assertEquals(true, results[2].isSuccess());

        //Verify 2 contacts were properly inserted
        list<Contact> insertedContacts = [select Id from Contact where Id in :contacts];
        System.assertEquals(2, insertedContacts.size()); 
        
        //Verify no error record was created
        List<Error__c> errors = [select Id, Full_Message__c, Stack_Trace__c from Error__c];
        System.assertEquals(0, errors.size()); 
    }
    
    /** Test using the default configuration of classes that implement TDTM_Runnable **/
    public testmethod static void errorStoredInDbTdtmStandardConfig() {
    	if (strTestOnly != '*' && strTestOnly != 'errorStoredInDbTdtmStandardConfig') return;
    
        setup();
        
        AFFL_Affiliations_TEST.getAffiliationsSettingsForTests(new npe5__Affiliations_Settings__c(
                                           npe5__Automatic_Affiliation_Creation_Turned_On__c = true));
                    
        //Create account
        Account acc1 = new Account(Name='test1');
        Account acc2 = new Account(Name='test2');
        Account acc3 = new Account(Name='test3');
        insert new Account[] {acc1, acc2, acc3};
        
        //Create contact
        Contact contact1 = new Contact(FirstName = 'test', LastName = 'testerson1', AccountId = acc1.Id, Title = 'VP1');
        Contact contact2 = new Contact(FirstName = 'test', LastName = 'testerson2', AccountId = acc2.Id, Title = 'VP2');
        Contact contact3 = new Contact(FirstName = 'test', LastName = 'testerson3', AccountId = acc3.Id, Title = 'VP3');

        //Delete the account to get the affiliations code to throw an exception
        delete acc2;
        
        Test.startTest();
        List<Contact> contacts = new Contact[]{contact1, contact2, contact3};
        LIST<database.SaveResult> results = Database.insert(contacts, false);
        Test.stopTest();
        
        //If a non-dml error occurs we rolled the whole thing back, and flag all message as having errors.
        //(Unfortunately we cannot check (and assert) the error messages added.)
        System.assertEquals(true, results[0].isSuccess());  
        System.assertEquals(false, results[1].isSuccess()); 
        System.assertEquals(true, results[2].isSuccess()); 

        //Verify 2 contacts were properly inserted
        list<Contact> insertedContacts = [select Id from Contact where Id in :contacts];
        System.assertEquals(2, insertedContacts.size()); 
        
        //Verify error record was created -> Nope. Since we are using Database insert the operation
        //gets rolled back and then run again only with records that succeed. No error is saved.
        List<Error__c> errors = [select Id, Full_Message__c, Stack_Trace__c from Error__c];
        System.assertEquals(0, errors.size());                                    
    }
    
    /** This is the same test called testErrorRecordCreation in the REL_Relationships_TEST class, but
        using simple insert instead of Database.insert ***/
    static testMethod void errorStoredInDatabaseFromInsert() {
        if (strTestOnly != '*' && strTestOnly != 'errorStoredInDatabaseFromInsert') return;
        
        setup();
        
        Contact contact1 = new Contact(FirstName = 'test', LastName = 'testerson1', Title = 'VP1');
        insert contact1;
                
        npe4__Relationship__c[] relationships = new npe4__Relationship__c[]{
            new npe4__Relationship__c(npe4__contact__c = contact1.id, npe4__Type__c='TestLookupType') };
        
        insert relationships;
        //assert an error record was created - Required fields are missing: [npe4__Contact__c]
        system.assertEquals(1, [select count() from Error__c]);
        
        //update relationship - this will create the missing npe4__Contact__c field
        relationships[0].npe4__RelatedContact__c = contact1.id;
        Database.SaveResult[] updateResults = Database.update(relationships, false);
        
        //process error
        ERR_Handler errorHandler = new ERR_Handler();
        errorHandler.processUpdateResults(updateResults, (List<SObject>)relationships, ERR_Handler.Context.REL);

        //assert no additional error was created on update
        system.assertEquals(1, [select count() from Error__c]);
    }
    
    /*** Tests that DML that occurs before an exception is thrown and caught does not get automatically rolled back ***/
    static testMethod void controllerWithoutManualRollback() {
        if (strTestOnly != '*' && strTestOnly != 'controllerWithoutManualRollback') return;
        
        setup();
        
        ERR_Handler_CTRL_TEST controller = new ERR_Handler_CTRL_TEST();
        
        Test.startTest();
        controller.withoutManualRollback();
        Test.stopTest();
        
        //assert contact record creation was not automatically rolled back
         system.assertEquals(1, [select count() from Contact]);
        
        //assert relationship record was stored (but the additional relationship was not created)
         system.assertEquals(1, [select count() from npe4__Relationship__c]);
         
        //assert an error record was created - Required fields are missing: [npe4__Contact__c]
        system.assertEquals(1, [select count() from Error__c]);  
    }
    
    /*** Tests that DML changes are properly rolled back in a controller that adheres to our error-handling design, and
         that the error is properly stored. ***/
    static testMethod void controllerWithManualRollback() {
        if (strTestOnly != '*' && strTestOnly != 'controllerWithManualRollback') return;
        
        setup();
        
        ERR_Handler_CTRL_TEST controller = new ERR_Handler_CTRL_TEST();
        
        Test.startTest();
        controller.withManualRollback();
        Test.stopTest();
        
        //assert contact record creation was rolled back
         system.assertEquals(0, [select count() from Contact]);
        
        //assert relationship record was not stored
         system.assertEquals(0, [select count() from npe4__Relationship__c]);
         
        //assert an error record was created - Required fields are missing: [npe4__Contact__c]
        system.assertEquals(1, [select count() from Error__c]);    
    }
}