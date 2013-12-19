@isTest
public with sharing class ERR_Handler_TEST {

    // if you only want to run one test in this class, fill in its name here.
    // if you want to run all tests, then use '*'
    private static string strTestOnly = 'errorsStoredInDatabase';

    public testmethod static void errorsStoredInDatabase() {
    	if (strTestOnly != '*' && strTestOnly != 'errorsStoredInDatabase') return;
    	
    	AFFL_Affiliations_TEST.getAffiliationsSettingsForTests(new npe5__Affiliations_Settings__c(
    	                                   npe5__Automatic_Affiliation_Creation_Turned_On__c = true));
            
    	//Create account
    	Account acc = new Account(Name='test77');
        insert acc;
        Id accId = acc.Id;
        
        //Create contact
        Contact contact = new Contact(FirstName = 'test', LastName = 'testerson', AccountId = acc.Id, Title = 'VP');
        
        //Delete the account go get the affiliations code to throw an exception
        delete acc;
        
        Test.startTest();
	    //Insert contact - ACCT_IndividualAccounts trigger will fail
	    Database.insert(contact, false);
        Test.stopTest();
        
        //Verify no affiliation was created
        List<npe5__Affiliation__c> affs = [select Id from npe5__Affiliation__c 
                                           where npe5__Contact__c = :contact.Id];
        System.assertEquals(0, affs.size());
        
        //Verify one error record was created
        List<Error__c> errors = [select Id, Full_Message__c from Error__c limit 10];
        System.assertEquals(1, errors.size());
        System.debug('****' + errors[0].Full_Message__c);
        //System.assertEquals('Failed to find account with id ' + accId, errors[0].Full_Message__c);
    }
    
    public testmethod static void errorsReturnedToTriggerCaller() {
    	if (strTestOnly != '*' && strTestOnly != 'errorsReturnedToTriggerCaller') return;
    	
        //Creating a few contacts
        List<Contact> contacts = UTIL_UnitTestData_TEST.CreateMultipleTestContacts(5);
        
        //Make all of them invalid - should fail validation rule
        for(Contact contact : contacts) {
            contact.npe01__AlternateEmail__c = '';
            contact.npe01__WorkEmail__c = '';
            contact.npe01__HomeEmail__c = '';
        }
        
        //Try inserting
        Test.startTest();
        insert contacts;
        Test.stopTest();
        
        //Verify no contacts were inserted
        List<Contact> contactsInserted = [select Id from Contact 
                                           where LastName = :CAO_Constants.CONTACT_LASTNAME_FOR_TESTS];
        System.assertEquals(0, contactsInserted.size());
        
        //See error message added
        for(Contact contact : contacts) {
            //@TODO: How do we see it? There is no error property or getError method in Contact?
            //http://www.salesforce.com/us/developer/docs/apexcode/Content/apex_System_SObject_addError.htm
        }
    }
    
    //Tests that errors are properly handled not only for those records that are in Trigger.new/Trigger.old,
    //but also for records that are inserted/modified as a side-effect of the original DML 
    public testmethod static void errorsHandledForTriggersSideEffects() {
        if (strTestOnly != '*' && strTestOnly != 'theTestMethodName') return;
        
    }
}