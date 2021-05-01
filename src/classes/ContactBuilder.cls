@IsTest
public class ContactBuilder {

    @TestVisible
    private static Contact dummyContact() {
        Contact con = new Contact(
                FirstName = CAO_Constants.CONTACT_FIRSTNAME_FOR_TESTS,
                LastName = CAO_Constants.CONTACT_LASTNAME_FOR_TESTS,
                Title = 'Doctor',
                npe01__WorkEmail__c = CAO_Constants.CONTACT_EMAIL_FOR_TESTS,
                npe01__Preferred_Email__c = CAO_Constants.CONTACT_PREFERRED_EMAIL_FOR_TESTS,
                npe01__WorkPhone__c = CAO_Constants.CONTACT_PHONE_FOR_TESTS,
                npe01__PreferredPhone__c = CAO_Constants.CONTACT_PREFERRED_PHONE_FOR_TESTS
        );
        return con;
    }

}