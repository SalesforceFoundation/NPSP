@IsTest
private class HouseholdNamingExclusions_TEST {

    @IsTest
    static void checkboxesShouldSyncToStringBeforeInsert() {
        Contact c = new Contact(
                LastName='test',
                Exclude_from_Household_Name__c = true
        );

        Contacts contacts = new Contacts(new List<Contact>{c});
        contacts.onBeforeInsert();
        
        HouseholdNamingExclusionsString householdNamingExclusionsString =
                new HouseholdNamingExclusionsString(c);
        System.assertEquals(true, householdNamingExclusionsString.isExcludedFromName(),
                'The Household Naming Exclusions String should be synced with the' +
                        'Exclusion Checkboxes on Contact insert.');
    }

    @IsTest
    static void checkboxesShouldSyncToStringBeforeUpdate() {
        Id id = UTIL_UnitTestData_TEST.mockId(Contact.SObjectType);
        Contact c = new Contact(
                Id = id,
                LastName='test',
                Exclude_from_Household_Name__c = true
        );

        Contact oldContact = new Contact(
                Id = id,
                LastName='test'
        );
        Contacts contacts = new Contacts(new List<Contact>{c}, new List<Contact>{oldContact});
        contacts.onBeforeUpdate();

        HouseholdNamingExclusionsString householdNamingExclusionsString =
                new HouseholdNamingExclusionsString(c);
        System.assertEquals(true, householdNamingExclusionsString.isExcludedFromName(),
                'The Household Naming Exclusions String should be synced with the ' +
                        'Exclusion Checkboxes on Contact update.');
    }

}