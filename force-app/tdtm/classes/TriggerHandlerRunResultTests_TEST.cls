@IsTest
private class TriggerHandlerRunResultTests_TEST {
    @IsTest
    static void should_calculate_correct_increment() {
        UsageSnapshot start = new UsageSnapshotFake(30);
        UsageSnapshot stop = new UsageSnapshotFake(45);

        UsageSnapshot usageIncrement =
                stop.getIncrementFrom(start);

        UsageSnapshot expectedIncrement =
                new UsageSnapshotFake(15);

        System.assert(usageIncrement.isEqualTo(expectedIncrement));

    }
}