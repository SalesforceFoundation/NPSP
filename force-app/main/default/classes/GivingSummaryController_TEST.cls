@isTest
public with sharing class GivingSummaryController_TEST {
    

    @IsTest
    public static void verifyCorrectContactWithDonationSummaryIsReturned() {
        
        Contact c = new Contact(Lastname = 'test', npo02__TotalOppAmount__c = 1 );
        insert c;
        System.assertEquals(c.Id, GivingSummaryController.getDonationsSummaryForContact(c.Id).Id, 'The contact id is not the same, should have returned the same contact id.');
        System.assertEquals(1, GivingSummaryController.getDonationsSummaryForContact(c.Id).npo02__TotalOppAmount__c, 'Same amount is expected, but it returned a different one');
     }
}
 