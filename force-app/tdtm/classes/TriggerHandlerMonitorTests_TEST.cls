@IsTest
private class TriggerHandlerMonitorTests_TEST {
    @IsTest
    static void should_return_only_results_for_handler_and_context() {
        TriggerHandlerRunResults runResults = new TriggerHandlerRunResults();
        String individualAccountsTDTMTypeName = ACCT_IndividualAccounts_TDTM.class.getName();
        String action = 'AfterInsert';
        runResults.add(
                new TriggerHandlerRunResultFake(
                        individualAccountsTDTMTypeName,
                        action,
                        10,
                        10,
                        10,
                        10
                )
        );
        runResults.add(
                new TriggerHandlerRunResultFake(
                        'testOtherService',
                        action,
                        10,
                        10,
                        10,
                        10
                )
        );

        System.assertEquals(
                1,
                runResults.getRunResultsFor(
                        individualAccountsTDTMTypeName,
                        action
                )
                .results
                .size(),
                'There should be one run result for this trigger handler and context.'
        );
    }
}