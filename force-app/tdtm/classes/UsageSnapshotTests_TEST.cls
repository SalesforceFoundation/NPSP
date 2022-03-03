@IsTest
private class UsageSnapshotTests_TEST {
    @IsTest
    static void new_snapshot_should_have_values() {
        insert new Account(Name = 'test');

        UsageSnapshot usageSnapshot = new UsageSnapshot(
                System.now(),
                new UsageIncrement(1, 1, 1, 1)
        );

        System.assert(usageSnapshot.usageIncrement().cpuTime() > 0);
        System.assert(usageSnapshot.timeStamp() != null,
                'Every UsageSnapshot should have a timestamp.');
    }
}