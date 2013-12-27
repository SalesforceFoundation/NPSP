@isTest
public with sharing class ERR_Handler_TEST {

    // if you only want to run one test in this class, fill in its name here.
    // if you want to run all tests, then use '*'
    private static string strTestOnly = '*';

    public testmethod static void errorsStoredInDatabase() {
    	if (strTestOnly != '*' && strTestOnly != 'errorsStoredInDatabase') return;
    	
    	AFFL_Affiliations_TEST.getAffiliationsSettingsForTests(new npe5__Affiliations_Settings__c(
    	                                   npe5__Automatic_Affiliation_Creation_Turned_On__c = true));
            
    	//Create account
    	Account acc1 = new Account(Name='test1');
    	Account acc2 = new Account(Name='test2');
        insert new Account[] {acc1, acc2};
        
        //Create contact
        Contact contact1 = new Contact(FirstName = 'test', LastName = 'testerson', AccountId = acc1.Id, Title = 'VP');
        Contact contact2 = new Contact(FirstName = 'test', LastName = 'testerson2', AccountId = acc2.Id, Title = 'VP');
        
        //Delete the account to get the affiliations code to throw an exception
        delete acc1;
        
        Test.startTest();
        /*Inserting more than one countact to get around the nasty issue described here: 
        http://salesforce.stackexchange.com/questions/1496/can-i-force-to-store-information-even-if-the-trigger-throws-an-exception
	    Summary: if every record in the trigger has errors all work done in the trigger, including @future method calls, 
	    sending email, queueing batch jobs, or performing any DML, is rolled back.*/
	    List<Contact> contacts =new Contact[]{contact1, contact2};
	    LIST<database.SaveResult> results = Database.insert(contacts, false);
        Test.stopTest();
        
        for(database.SaveResult result : results) {
        	System.debug('***Record Errors:\n' + result.getErrors());
        }
        
        //Verify that one of the contacts (contact2) was properly inserted. This means the transaction
        //was not rolled back.
        list<Contact> insertedContacts = [select Id from Contact where Id in :contacts];
        System.assertEquals(1, insertedContacts.size());
        
        //Verify no affiliation was created for first contact
        List<npe5__Affiliation__c> affs = [select Id from npe5__Affiliation__c 
                                           where npe5__Contact__c = :contact1.Id];
        System.assertEquals(0, affs.size());
        
        //Verify error record was created
        List<Error__c> errors = [select Id, Full_Message__c, Stack_Trace__c from Error__c limit 100];
        System.assertEquals(1, errors.size());
        
        for(Error__c error : errors) {
            System.debug('****IN TEST - Error message: ' + error.Full_Message__c);
            System.debug('****Stack Trace: \n' + error.Stack_Trace__c);
        }
        
        //Unfortunately we cannot see error messages added. There is "addError" method in SObjcet but no "getError".
        System.assertNotEquals(true, results[0].isSuccess());  
    }
    
    //Tests that errors are properly handled not only for those records that are in Trigger.new/Trigger.old,
    //but also for records that are inserted/modified as a side-effect of the original DML 
    public testmethod static void errorsHandledForTriggersSideEffects() {
        if (strTestOnly != '*' && strTestOnly != 'theTestMethodName') return;
        
    }
}