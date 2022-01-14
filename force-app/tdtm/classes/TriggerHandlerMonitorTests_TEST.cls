@IsTest
private class TriggerHandlerMonitorTests_TEST {
//    @IsTest
//    static void should_return_only_results_for_handler_and_context() {
//        TriggerHandlerRunResults runResults = new TriggerHandlerRunResults();
//        String individualAccountsTDTMTypeName = ACCT_IndividualAccounts_TDTM.class.getName();
//        String action = 'AfterInsert';
//        runResults.add(
//                new TriggerHandlerRunResultFake(
//                        individualAccountsTDTMTypeName,
//                        action,
//                        10,
//                        10,
//                        10,
//                        10
//                )
//        );
//        runResults.add(
//                new TriggerHandlerRunResultFake(
//                        'testOtherService',
//                        action,
//                        10,
//                        10,
//                        10,
//                        10
//                )
//        );
//
//        System.assertEquals(
//                1,
//                runResults.getRunResultsFor(
//                        individualAccountsTDTMTypeName,
//                        action
//                )
//                .getRunResults()
//                .size(),
//                'There should be one run result for this trigger handler and context.'
//        );
//    }

    @IsTest
    static void should_record_dml_rows_used() {
        TDTM_TriggerHandler.isMonitoringEnabled = true;
        Contact c = TEST_ContactBuilder.dummyContact();
//        c.FirstName = null;
        insert c;
        TriggerHandlerRunResults triggerHandlerRunResults = TDTM_TriggerHandler.Monitor.getResults();
        triggerHandlerRunResults.printStack();
        System.assert(
                triggerHandlerRunResults.usageSummary().totalDmlRows() > 0,
                'The usage summary should show at least one DML row.');

    }
}