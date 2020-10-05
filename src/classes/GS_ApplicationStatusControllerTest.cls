@IsTest
public with sharing class GS_ApplicationStatusControllerTest {

    @IsTest public static void testGetApplicationStatusTrialOrgNonApplicated() {
        Testing_Configuration__c tc = new Testing_Configuration__c(Configuration__c = '{"Sandbox":false,"TrialExpiration":"10/15/2020, 00:01 AM"}');
        insert tc; 

        GS_ApplicationStatusController.ApplicationStatus status = GS_ApplicationStatusController.getApplicationStatus();
        System.assert(status != null, 'Status should not be null');
        System.assert(!status.isSandbox, 'Status should not be sandbox');
        System.assertEquals(Date.parse('10/15/2020'), date.newInstance(status.trialExpirationDate.year(), status.trialExpirationDate.month(), status.trialExpirationDate.day()), 'Trial expiration date not equal');
        System.assert(status.applicationDate == null, 'application date should be null');
    }

        @IsTest public static void testGetApplicationStatusTrialOrgApplicated() {
        Testing_Configuration__c tc = new Testing_Configuration__c(Configuration__c = '{"Sandbox":false,"TrialExpiration":"10/15/2020, 00:01 AM", "Application":"10/02/2020"}');
        insert tc; 

        GS_ApplicationStatusController.ApplicationStatus status = GS_ApplicationStatusController.getApplicationStatus();
        System.assert(status != null, 'Status should not be null');
        System.assert(!status.isSandbox, 'Status should not be sandbox');
        System.assertEquals(Date.parse('10/15/2020'), date.newInstance(status.trialExpirationDate.year(), status.trialExpirationDate.month(), status.trialExpirationDate.day()), 'Trial expiration date not equal');
        System.assertEquals(Date.parse('10/02/2020'), status.applicationDate, 'ApplicationDate is not equals to 10/02/2020');
    }
}