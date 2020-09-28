@IsTest
public with sharing class GS_ApplicationStatusControllerTest {
    
    @IsTest public static void testGetApplicationStatus() {
        GS_ApplicationStatusController.ApplicationStatus status = GS_ApplicationStatusController.getApplicationStatus();
        System.assert(status != null);
        System.assert(status.isSandBox);
    }
}
