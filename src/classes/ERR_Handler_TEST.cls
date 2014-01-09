@isTest
public with sharing class ERR_Handler_TEST {

    // if you only want to run one test in this class, fill in its name here.
    // if you want to run all tests, then use '*'
    private static string strTestOnly = '*';
    
    /*** In this case we need to use Database.insert because we otherwise we get a compilation error ***/
    public testmethod static void errorsStoredInDatabaseFromDatabaseInsert() {
    	if (strTestOnly != '*' && strTestOnly != 'errorsStoredInDatabaseFromDatabaseInsert') return;
    	
    	insert new Trigger_Handler__c(Active__c = true, Asynchronous__c = false, 
              Class__c = 'ERR_ParentAccountUpdater_TEST', Load_Order__c = 1, Object__c = 'Contact', 
              Trigger_Action__c = 'BeforeInsert;');
    	
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
        
        //Unfortunately we cannot see error messages added. There is "addError" method in SObjcet but no "getError".
        //The easiest way to see the error message added to the record is to look at a VF. The errors get displayed by default
        //if the page contains an apex:pageMessages element. There is an example of this in 
        //https://github.com/SalesforceFoundation/Error_Handling.
        System.assertEquals(true, results[0].isSuccess());  
        System.assertEquals(false, results[1].isSuccess()); 
        System.assertEquals(true, results[2].isSuccess()); 
        
        //Verify two contacts were properly inserted. This means the transaction was not rolled back.
        list<Contact> insertedContacts = [select Id from Contact where Id in :contacts];
        System.assertEquals(2, insertedContacts.size());
        
        //Verify error record was created
        List<Error__c> errors = [select Id, Full_Message__c, Stack_Trace__c from Error__c limit 10];
        System.assertEquals(1, errors.size()); 
    }
    
    /** We can do simple DML in this case ***/
    static testMethod void errorStoredInDatabaseFromInsert() {
        if (strTestOnly != '*' && strTestOnly != 'errorStoredInDatabaseFromInsert') return;
        
        Contact contact1 = new Contact(FirstName = 'test', LastName = 'testerson1', Title = 'VP1');
        insert contact1;
                
        npe4__Relationship__c[] relationships = new npe4__Relationship__c[]{
            new npe4__Relationship__c(npe4__contact__c = contact1.id, npe4__Type__c='TestLookupType') };
        
        insert relationships;
        //assert an error record was created
        system.assertEquals(1, [select count() from Error__c]);
        
        //update relationship
        relationships[0].npe4__RelatedContact__c = contact1.id;
        Database.SaveResult[] updateResults = Database.update(relationships, false);
        
        //process error
        ERR_Handler errorHandler = new ERR_Handler();
        errorHandler.processResults(null, updateResults, null, null, null, (List<SObject>)relationships, null, null);

        //assert additional error was created on update
        system.assertEquals(2, [select count() from Error__c]);
    }
}