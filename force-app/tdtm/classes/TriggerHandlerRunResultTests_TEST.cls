@IsTest
private class TriggerHandlerRunResultTests_TEST {
    @IsTest
    static void should_calculate_correct_increment() {
        UsageSnapshot start = new UsageSnapshotFake(30);
        UsageSnapshot stop = new UsageSnapshotFake(45);

        UsageIncrement usageIncrement =
                stop.usageIncrement().getIncrementFrom(start.usageIncrement());

        UsageSnapshot expectedIncrement =
                new UsageSnapshotFake(15);

        System.assert(usageIncrement.equals(expectedIncrement.usageIncrement()));
    }
}