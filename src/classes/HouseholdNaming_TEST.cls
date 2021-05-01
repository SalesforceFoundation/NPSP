/**
 * Created by kenneth.lewis on 5/1/21.
 */

@IsTest
private class HouseholdNaming_TEST {

    @IsTest
    static void formalGreetingIsCorrectForDummyContact() {
        Contacts dummyContact = ContactBuilder.dummyContacts();
        HouseholdName householdName = new HouseholdName(dummyContact);
        System.assertEquals(
                'test Contact_forTests',
                householdName.asFormalGreeting());
    }

    @IsTest
    static void givenDummyHHNamingSettings_thenFormalGreetingIsCorrectForDummyContact() {
        HH_Households_TEST.setupHouseholdNamingSettings();
        Contacts dummyContact = ContactBuilder.dummyContacts();
        HouseholdName householdName = new HouseholdName(dummyContact);
        System.assertEquals(
                'Doctor Contact_forTests',
                householdName.asFormalGreeting());
    }

}