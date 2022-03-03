@IsTest
private class LimitsMonitorTests_TEST {
    @IsTest
    static void should_return_value_when_empty_constructor_used() {
        insert new Account(Name = 'test');
        LimitsMonitor limitsMonitor = new LimitsMonitor();

        UsageSnapshot usageSnapshot = limitsMonitor.getUsageSnapshot();
        System.assertNotEquals(null, usageSnapshot);
        System.assertNotEquals(0, usageSnapshot.usageIncrement().cpuTime());
        System.assertNotEquals(0, usageSnapshot.usageIncrement().dmlRows());
    }
}