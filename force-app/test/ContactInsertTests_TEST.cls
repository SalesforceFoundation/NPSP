@IsTest
private class ContactInsertTests_TEST {

    @IsTest
    static void insert_duplicate_contact_should_not_throw_required_field_missing_error() {
        // Default TDTM
        // Account Dupe Rules Ops on Create: Alert:true
        // Workflow Rules deactivated
        TDTM_TriggerHandler.isMonitoringEnabled = true;
        UTIL_Debug.enabledForTests = true;
        TDTM_TriggerHandler.isCompactLoggingEnabled = false;
        Contact c = TEST_ContactBuilder.dummyContact();
        c.MailingStreet = '123 Main';
        c.MailingCity = 'ABCity';
        insert c;

        Contact cInsert2 = TEST_ContactBuilder.dummyContact();
        cInsert2.MailingStreet = '123 Main';
        cInsert2.MailingCity = 'ABCity';
        insert cInsert2;
    }
}