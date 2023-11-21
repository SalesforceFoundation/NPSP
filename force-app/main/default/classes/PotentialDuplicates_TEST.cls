@IsTest(IsParallel=false)
private with sharing class PotentialDuplicates_TEST {

    @IsTest
    private static void shouldReturnNullWhenNoDuplicatesAreFound() {
        Id recordId = UTIL_UnitTestData_TEST.mockId(Contact.getSObjectType());
        Map<String, Object> data = PotentialDuplicates.getDuplicates(recordId);
        String setOfMatches = (String) data.get('setOfMatches');

        List<DuplicateRule> activeContactRules = [
                SELECT Id
                from DuplicateRule
                WHERE SObjectType = 'Contact'
                AND isActive = TRUE
        ];

        if (activeContactRules.isEmpty()) {
            System.assertEquals(null, setOfMatches,
                'PotentialDuplicates.getDuplicates() should return null if there are no active Duplicate Rules for Contact');
        } else {
            System.assertEquals('', setOfMatches, 'There should be no duplicates');
        }
    }

    @IsTest
    private static void shouldReturnIdsWhenDuplicatesAreFound() {
        List<Contact> contactList = UTIL_UnitTestData_TEST.getContacts(3);
        for (Contact c : contactList) {
            c.FirstName = 'Test';
            c.LastName = 'LastName';
            c.Email = 'tester@example.com';
        }
        insert contactList;

        List<DuplicateRule> activeContactRules = [
                SELECT Id
                from DuplicateRule
                WHERE SObjectType = 'Contact'
                AND isActive = TRUE
        ];

        Map<String, Object> data = PotentialDuplicates.getDuplicates(contactList[0].Id);
        String setOfMatches = (String) data.get('setOfMatches');

        if (activeContactRules.isEmpty()) {
            System.assertEquals(null, setOfMatches,
                'PotentialDuplicates.getDuplicates() should return null if there are no active Duplicate Rules for Contact');
        } else if (sObjectType.Contact.fields.Name.isEncrypted()) {
            // Duplicates will not be found if encryption is enabled / standard rules deactivated
            System.assertEquals('', setOfMatches, 'No duplicate Ids should be returned if encryption is enabled');
        } else {
            Integer numberOfMatches = setOfMatches.split(',').size();
            System.assertNotEquals('', setOfMatches, 'Duplicate Ids should be returned');
            System.assertEquals(2, numberOfMatches, 'There should be 2 duplicates returned');
        }
    }
}