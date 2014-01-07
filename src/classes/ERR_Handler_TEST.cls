@isTest
public with sharing class ERR_Handler_TEST {

    public testmethod static void errorsStoredInDatabase() {
    	
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
        System.debug(LoggingLevel.WARN, '****IN TEST - Accounts inserted');
        
        //Create contact
        Contact contact1 = new Contact(FirstName = 'test', LastName = 'testerson1', AccountId = acc1.Id, Title = 'VP1');
        Contact contact2 = new Contact(FirstName = 'test', LastName = 'testerson2', AccountId = acc2.Id, Title = 'VP2');
        Contact contact3 = new Contact(FirstName = 'test', LastName = 'testerson3', AccountId = acc3.Id, Title = 'VP3');

        //Delete the account to get the affiliations code to throw an exception
        delete acc2;
        System.debug(LoggingLevel.WARN, '****IN TEST - Account deleted');
        
        Test.startTest();
        System.debug(LoggingLevel.WARN, '****IN TEST - StartTest called');
        /*Inserting more than one countact to get around the nasty issue described here: 
        http://salesforce.stackexchange.com/questions/1496/can-i-force-to-store-information-even-if-the-trigger-throws-an-exception
	    Summary: if every record in the trigger has errors all work done in the trigger, including @future method calls, 
	    sending email, queueing batch jobs, or performing any DML, is rolled back.*/
	    List<Contact> contacts = new Contact[]{contact1, contact2, contact3};
	    LIST<database.SaveResult> results = Database.insert(contacts, false);
        Test.stopTest();
        System.debug(LoggingLevel.WARN, 'IN TEST - ****StopTest called');
        
        //Unfortunately we cannot see error messages added. There is "addError" method in SObjcet but no "getError".
        System.assertEquals(true, results[0].isSuccess());  
        System.assertEquals(false, results[1].isSuccess()); 
        System.assertEquals(true, results[2].isSuccess()); 
        for(database.SaveResult result : results) {
        	System.debug(LoggingLevel.WARN, 'IN TEST - ***Record Errors:\n' + result.getErrors());
        }
        
        //Verify two contacts were properly inserted. This means the transaction was not rolled back.
        list<Contact> insertedContacts = [select Id from Contact where Id in :contacts];
        System.assertEquals(2, insertedContacts.size());
        for(Contact c : insertedContacts) {
        	System.debug(LoggingLevel.WARN, '****ID of inserted contact: ' + c.Id);
        	
        }
        
        //Verify error record was created
        List<Error__c> errors = [select Id, Full_Message__c, Stack_Trace__c from Error__c limit 10];
        System.assertEquals(1, errors.size());
        
        for(Error__c error : errors) {
            System.debug('****IN TEST - Error message: ' + error.Full_Message__c);
            System.debug('****IN TEST - Stack Trace: \n' + error.Stack_Trace__c);
        }  
    }
}