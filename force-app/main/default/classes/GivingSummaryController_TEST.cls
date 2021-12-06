@isTest
public with sharing class GivingSummaryController_TEST {
    

    @IsTest
    public static void getContactUserTest() {
        
        Contact c = new Contact(Lastname = 'test', npo02__TotalOppAmount__c = 1 );
        insert c;
        System.assertEquals(c.Id, GivingSummaryController.getContactForUser(c.Id).Id, 'contactId is not the same');
        System.assertEquals(1, GivingSummaryController.getContactForUser(c.Id).npo02__TotalOppAmount__c, 'contactId is not the same');
        


    }
}
 