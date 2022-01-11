@IsTest
private class ContactTests_TEST {
    @IsTest
    static void insert_single_contact() {
        TDTM_TriggerHandler.isMonitoringEnabled = true;
        UTIL_Debug.enabledForTests = true;
        Contact c = TEST_ContactBuilder.dummyContact();
        c.FirstName = null;
        insert c;

        //Now you can assert against trigger handler run stats (!)
        System.assertEquals(1, TDTM_TriggerHandler.Monitor.getResults().timesRun(
                ACCT_Accounts_TDTM.class.getName(), 'BeforeUpdate'),
                'This trigger handler should only have run once in the ' +
                        'before update context for this test case.');
    }
}