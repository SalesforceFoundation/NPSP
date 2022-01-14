@IsTest
private class ContactTests_TEST {
    @IsTest
    static void insert_single_contact() {
        // Enable logging and monitoring for this test method:
        UTIL_Debug.enabledForTests = true;
        TDTM_TriggerHandler.isMonitoringEnabled = true;
        TDTM_TriggerHandler.isCompactLoggingEnabled = true;

        // Run test and view debug log output
        Contact c = TEST_ContactBuilder.dummyContact();
        // Try commenting out these lines to see differences in the log...
//        c.FirstName = null;
        c.MailingStreet = '123 ABC Street';
        insert c;

        // Get the run results from the Monitor:
        List<TriggerHandlerRunResult> allRunResults =
                TDTM_TriggerHandler.Monitor.getResults().getRunResults();
        System.assert(!allRunResults.isEmpty(),
                'There should be at least one trigger handler run result.');

        // Results for a specific handler + context/action:
        TriggerHandlerRunResults runResultsForEachHandlerAndContext =
                TDTM_TriggerHandler.Monitor.getResultsFor(
                        'ACCT_Accounts_TDTM',
                        'BeforeUpdate'
                );
        System.assert(!runResultsForEachHandlerAndContext.getRunResults().isEmpty());

        // Now you can assert against trigger handler run stats (!)
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

        // Compare Trigger Handler Run usage with a benchmark increment:
        TriggerHandlerRunResults r =
                TDTM_TriggerHandler.Monitor.getResults();

        UsageIncrement benchmark = new UsageIncrement(
                1245, 20, 306, 0
        );
        System.debug(LoggingLevel.ERROR, '*** benchmark: ' + benchmark.toString());
        System.debug(LoggingLevel.ERROR, '*** Usage Increment from benchmark value: ' +
                        JSON.serializePretty(r.getIncrementFrom(benchmark)));

        // Set a benchmark to assert against if a benchmark limit is reached:
        Integer queryBenchmark = 13;
        UsageSummary rUsageSummary = r.usageSummary();
        System.assertEquals(queryBenchmark, rUsageSummary.totalQueries(),
                'This service is benchmarked at ' + queryBenchmark + ' queries used.');

        //And print Usage Summaries to the debug log:
        r.printUsageSummary();
        r.printUsageSummaryByServiceByContext();
    }
}