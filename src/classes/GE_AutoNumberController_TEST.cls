/**
 * Created by kenneth.lewis on 7/21/20.
 */
@IsTest
public class GE_AutoNumberController_TEST {

    @IsTest
    static void shouldInsertRecord() {
        AutoNumber__c a = new AutoNumber__c(
                Object_API_Name__c=String.valueOf(DataImportBatch__c.SObjectType),
                Field_API_Name__c='Description2',
                Display_Format__c='ABCRT1-{000}',
                Starting_Number__c=100,
                IsActive__c=false
        );

        String autoNumberString = JSON.serialize(a);
        System.debug(LoggingLevel.ERROR, '*** variable value: ' + autoNumberString);
        System.debug(LoggingLevel.ERROR, '^^^^^^ autoNumberString ^^^^^^');

        AutoNumber__c savedAutoNumber = GE_AutoNumberController.save(autoNumberString);
        System.debug(LoggingLevel.ERROR, '*** variable value: ' + savedAutoNumber);
        System.debug(LoggingLevel.ERROR, '^^^^^^ saved ^^^^^^');
        List<AutoNumber__c> autoNumbers = [SELECT Id FROM AutoNumber__c];
        System.assert(autoNumbers.size() > 0, 'AutoNumber should have been inserted.');
    }
}