@IsTest
private class ContactInsertTests_TEST {

    @IsTest
    static void insert_duplicate_contact_should_not_throw_required_field_missing_error() {
        // Arrange
        String exceptionMessage;
        Contact existingContact = TEST_ContactBuilder.dummyContact();
        existingContact.MailingStreet = '123 Main';
        existingContact.MailingCity = 'ABCity';
        insert existingContact;
        Contact dupeContact = TEST_ContactBuilder.dummyContact();
        dupeContact.MailingStreet = '123 Main';
        dupeContact.MailingCity = 'ABCity';

        // Act
        try {
            // This will succeed or fail depending on the org's duplicate rule configuration.
            // If it succeeds the test does and should pass.
            insert dupeContact;
        } catch (Exception e) {
            exceptionMessage = e.getMessage();
        }

        // Assert
        if (exceptionMessage != null) {
            // If it fails, assert that it is not due to the required fields missing error
            System.assertEquals(
                    false,
                    exceptionMessage.contains(
                            'Required fields are missing:Household_Account__c'
                    ),
                    'An address should not be created for a new Contact until ' +
                            'its Household Account has been created.'
            );
        } else {
            // Some other Exception thrown.
            // 'Required fields are missing:Household_Account__c' exception NOT thrown
        }
    }
}