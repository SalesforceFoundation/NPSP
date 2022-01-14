@IsTest
private class TriggerHandlerRunResultsTests_TEST {
    @IsTest
    static void should_return_usage_increments() {
        // Arrange
        TriggerHandlerRunResultFake runResultFake =
                new TriggerHandlerRunResultFake(
                       'service1', 'action1', Contact.SObjectType
                );
        TriggerHandlerRunResultFake runResultFake2 =
                new TriggerHandlerRunResultFake(
                       'service1', 'action1', Contact.SObjectType
                );
        TriggerHandlerRunResults runResults =
                new TriggerHandlerRunResults();
        runResults.add(runResultFake);
        runResults.add(runResultFake2);

        // Act
        UsageSummary usageSummary = runResults.usageSummaryFor(
                'service1',
                'action1'
        );

        // Assert
        System.assert(usageSummary.totalDmlRows() > 0,
                'The usage summary should show total DML greater than zero.');
    }
}