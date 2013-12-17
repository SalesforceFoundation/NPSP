@isTest
public with sharing class ERR_Handler_TEST {

    public testmethod static void errorsStoredInDatabase() {
        //Creating a few contacts
        List<Contact> contacts = UTIL_UnitTestData_TEST.CreateMultipleTestContacts(5);
        
        //Make one of them invalid - should fail validation rule
        contacts[3].npe01__AlternateEmail__c = '';
        contacts[3].npe01__WorkEmail__c = '';
        contacts[3].npe01__HomeEmail__c = '';
        
        //Try inserting
        Test.startTest();
        insert contacts;
        Test.stopTest();
        
        //Verify four contacts were inserted
        List<Contact> contactsInserted = [select Id from Contact 
                                           where LastName = :CAO_Constants.CONTACT_LASTNAME_FOR_TESTS];
        System.assertEquals(4, contactsInserted.size());
        
        //Verify one error record was created
        //List<Error__c> errors = [select Id from Error];
        //System.assertEquals(1, errors.size());
        //System.assertEquals('put error message here', errors[0].message);
    }
    
    public testmethod static void errorsReturnedToTriggerCaller() {
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
        
    }
}