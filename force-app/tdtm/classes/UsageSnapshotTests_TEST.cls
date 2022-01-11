@IsTest
private class UsageSnapshotTests_TEST {
    @IsTest
    static void new_snapshot_should_have_values() {
        insert new Account(Name='test');

        UsageSnapshot usageSnapshot = new UsageSnapshot();

        System.assert(usageSnapshot.cpuTime() > 0);
    }
}