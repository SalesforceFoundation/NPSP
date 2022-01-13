@IsTest
private class ContactTests_TEST {
    @IsTest
    static void insert_single_contact() {
        TDTM_TriggerHandler.isMonitoringEnabled = true;
        UTIL_Debug.enabledForTests = true;
        Contact c = TEST_ContactBuilder.dummyContact();
//        c.FirstName = null;
        insert c;

        TriggerHandlerRunResults triggerHandlerRunResults =
                TDTM_TriggerHandler.Monitor.getResultsFor(
                        'ACCT_Accounts_TDTM',
                        'BeforeUpdate'
                );

        List<TriggerHandlerRunResult> triggerHandlerRunResults2 =
                TDTM_TriggerHandler.Monitor.getResults().getRunResults();
        System.assert(!triggerHandlerRunResults2.isEmpty(),
                'There should be at least one trigger handler run result.');
        System.assert(!triggerHandlerRunResults.getRunResults().isEmpty());

        //Now you can assert against trigger handler run stats (!)
        // for specific services + actions:
        System.assertEquals(1,
                TDTM_TriggerHandler.Monitor.getResultsFor(
                        ACCT_Accounts_TDTM.class.getName(),
                        'BeforeUpdate'
                )
                        .usageSummary()
                        .timesRun(),
                'This trigger handler should only have run once in the ' +
                        'before update context for this test case.');

        TriggerHandlerRunResults runResults =
                TDTM_TriggerHandler.Monitor.getResultsFor(
                        ACCT_IndividualAccounts_TDTM.class.getName(),
                        'AfterInsert'
                );

        System.assert(runResults
                .usageSummary()
                .totalQueries() > 0,
                'This trigger handler should have at least 1 query in the ' +
                        'after insert context for this test case.');

        // Or for the entire Trigger Handler Run:
        TriggerHandlerRunResults r =
                TDTM_TriggerHandler.Monitor.getResults();
        Integer queryBenchmark = 13;
        UsageSummary rUsageSummary = r.usageSummary();

        UsageIncrement benchmark = new UsageIncrement(
                1245, 20, 306, 0
        );
        System.debug(LoggingLevel.ERROR, '*** variable value: ' + r.getIncrementFrom
                (benchmark).toString());
            System.debug(LoggingLevel.ERROR, '*** variable value: ' + new UsageSummary(
                    new List<UsageIncrement>{r.getIncrementFrom(benchmark)}).format());
            System.debug(LoggingLevel.ERROR, '^^^^^^ new UsageSummary(new List<UsageSnapshot>{r.getIncrementFrom(benchmark)}).format() ^^^^^^');
        System.debug(LoggingLevel.ERROR, '^^^^^^ r.getIncrementFrom(benchmark) ^^^^^^');

        System.assertEquals(queryBenchmark, rUsageSummary.totalQueries(),
                'This service is benchmarked at ' + queryBenchmark + ' queries used.');

        //And print Usage Summaries to the debug log:
        r.printUsageSummary();
        r.printUsageSummaryByServiceByContext();
    }
}