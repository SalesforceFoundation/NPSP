@IsTest
private class ContactTests_TEST {
    @IsTest
    static void insert_single_contact() {
        TDTM_TriggerHandler.isMonitoringEnabled = true;
        UTIL_Debug.enabledForTests = true;
        Contact c = TEST_ContactBuilder.dummyContact();
        c.FirstName = null;
        insert c;

        List<Account> accounts = [
                SELECT Name, npe01__SYSTEM_AccountType__c, RecordType.Name, (
                        SELECT Name, npe01__SystemAccountProcessor__c,
                                npo02__SystemHouseholdProcessor__c
                        FROM Contacts
                )
                FROM Account
        ];
        System.debug(loggingLevel.Error, '*** Number of accounts: ' + accounts.size());
        for (Account account : accounts) {
            System.debug(LoggingLevel.ERROR, '*** variable value: ' + account);
            System.debug(LoggingLevel.ERROR, '^^^^^^ account ^^^^^^');
            for (Contact c2 : account.Contacts) {
                System.debug(LoggingLevel.ERROR, '*** variable value: ' + c2);
                System.debug(LoggingLevel.ERROR, '^^^^^^ c2 ^^^^^^');
            }
        }
        UTIL_Debug.debugWithInfo('done');
        System.assertEquals(1, TDTM_TriggerHandler.timesRun(
                ACCT_Accounts_TDTM.class.getName(), 'BeforeUpdate'),
                'This class should only have run once before update for this test.');
    }
}