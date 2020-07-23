@IsTest
private class AutoNumberService_TEST {

    @IsTest
    static void shouldSave() {
        String an = '{"fields":{"Object_API_Name__c":"DataImportBatch__c",' +
                '"Field_API_Name__c":"Batch_Number__c","Display_Format__c":"abc-{000}",' +
                '"Starting_Number__c":100,"Max_Used_Number__c":105,"IsActive__c":false}}';

        AutoNumberService ans = new AutoNumberService(DataImportBatch__c.SObjectType);
        ans.save(an);

        List<AutoNumber__c> autoNumbers = [
                SELECT Id, IsActive__c, Display_Format__c
                FROM AutoNumber__c
        ];

        System.assert(!autoNumbers.isEmpty(),
                'The AutoNumber should have been inserted.');
    }

    @IsTest
    static void shouldActivate() {
        Id autoNumberIdToActivate = setupAutoNumber(false, 'ABCZZZ-{000}');
        Id activeAutoNumberId = setupAutoNumber(true, 'INITIAL-ACTIVE-{000}');

        System.assertEquals(false, [
                SELECT IsActive__c
                FROM AutoNumber__c
                WHERE Id = :autoNumberIdToActivate
        ].IsActive__c);
        System.assertEquals(true, [
                SELECT IsActive__c
                FROM AutoNumber__c
                WHERE Id = :activeAutoNumberId
        ].IsActive__c);

        AutoNumberService ans = new AutoNumberService(DataImportBatch__c.SObjectType);
        ans.activate(autoNumberIdToActivate);

        System.assertEquals(true, [
                SELECT IsActive__c
                FROM AutoNumber__c
                WHERE Id = :autoNumberIdToActivate
        ].IsActive__c,
                'The AutoNumber record should be active.');
        System.assertEquals(false, [
                SELECT IsActive__c
                FROM AutoNumber__c
                WHERE Id = :activeAutoNumberId
        ].IsActive__c,
                'The initially active AutoNumber record should now be inactive.');
    }

    @IsTest
    static void shouldDeactivate() {
        Id autoNumberId = setupAutoNumber(true, 'ABCZZZ-{000}');

        System.assertEquals(true, [
                SELECT IsActive__c
                FROM AutoNumber__c
                WHERE Id = :autoNumberId
        ].IsActive__c);

        AutoNumberService ans = new AutoNumberService(DataImportBatch__c.SObjectType);
        ans.deactivate(autoNumberId);

        System.assertEquals(false, [
                SELECT IsActive__c
                FROM AutoNumber__c
                WHERE Id = :autoNumberId
        ].IsActive__c,
                'The AutoNumber record should be inactive.');
    }

    @IsTest
    static void shouldApply() {
        setupAutoNumber(true, 'ABCZZZ-{000}');

        //Insert Trigger Handler
        insert new AutoNumberService(DataImportBatch__c.SObjectType).triggerHandler;

        DataImportBatch__c b = new DataImportBatch__c();
        insert b;

        b = [SELECT Batch_Number__c FROM DataImportBatch__c WHERE Id = :b.Id];
        System.assertNotEquals(null, b.Batch_Number__c,
                'The Batch should have a Batch Number applied.');
    }

    static void shouldPreventDuplicatePrefix() {

    }

    static void shouldPreventDuplicatePattern() {

    }

    static Id setupAutoNumber(Boolean isActive, String displayFormat) {
        AutoNumber__c a = new AutoNumber__c(
                Object_API_Name__c = String.valueOf(DataImportBatch__c.SObjectType),
                Field_API_Name__c = String.valueOf(DataImportBatch__c.fields.Batch_Number__c),
                Display_Format__c = displayFormat,
                Starting_Number__c = 100,
                IsActive__c = isActive,
                Description__c = 'test description',
                Max_Used_Number__c = 0
        );
        insert a;
        return a.Id;
    }

}