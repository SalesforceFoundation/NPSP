@IsTest
private class LimitsMonitorTests_TEST {
    @IsTest
    static void should_return_value_when_empty_constructor_used() {
        LimitsMonitor limitsMonitor = new LimitsMonitor();

        System.assert(limitsMonitor.cpuTime() > 0);
    }
}