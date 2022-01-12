@IsTest
private class TriggerHandlerRunResultsTests_TEST {
    @IsTest
    static void should_return_usage_increments() {
        TriggerHandlerRunResultFake runResultFake =
                new TriggerHandlerRunResultFake(
                       'service1', 'action1', 1,1,1,1
                );
        TriggerHandlerRunResultFake runResultFake2 =
                new TriggerHandlerRunResultFake(
                       'service1', 'action1', 1,1,1,1
                );
        TriggerHandlerRunResults runResults =
                new TriggerHandlerRunResults();
        runResults.add(runResultFake);
        runResults.add(runResultFake2);

        UsageSummary usageSummary = runResults.usageSummaryFor(
                'service1',
                'action1'
        );
        System.debug(LoggingLevel.ERROR, '*** variable value: ' + usageSummary.format());
        System.debug(LoggingLevel.ERROR, '^^^^^^ usageSummary.format() ^^^^^^');

    }
}