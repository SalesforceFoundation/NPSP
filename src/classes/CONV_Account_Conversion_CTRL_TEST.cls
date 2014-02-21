@isTest
public with sharing class CONV_Account_Conversion_CTRL_TEST {
    public static testmethod void testConversionCtrl() {

        //set account model to 1:1 for the test and enable household creation
        CONV_Account_Conversion_BATCH_TEST.setPreHHAccountModel(true);

        Contact c = new Contact(LastName = 'Contact', FirstName = 'Test');
        insert c;
        system.assertEquals(1, [select count() from Account where Name = 'Test Contact' and npe01__One2OneContact__c = :c.id]);
        String HHName = 'Contact ' + system.label.npo02.DefaultHouseholdName;
        system.assertEquals(1, [select count() from npo02__Household__c where Name = :HHName]);

        //add an oppty to the Contact as well
        Opportunity o = new Opportunity(Name = 'Test Oppty', Amount = 1000, StageName = UTIL_UnitTestData_TEST.getClosedWonStage(), CloseDate = system.today(), npe01__Contact_Id_For_Role__c = c.Id);
        insert o;
        system.assertEquals(1, [select count() from OpportunityContactRole where isPrimary = true and ContactId = :c.Id]);

        Test.startTest();

        // create the page 
        PageReference pageRef=Page.CONV_Account_Conversion; 
        Test.setCurrentPage(pageRef); 

        // instantiate the controller
        CONV_Account_Conversion_CTRL controller = new CONV_Account_Conversion_CTRL();

        // convert up everyone
        controller.convert();
        controller.cancel();
    }
}