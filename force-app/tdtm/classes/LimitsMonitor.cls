public without sharing virtual class LimitsMonitor {

    @TestVisible
    private Clock clock {
        get {
            if (clock == null) {
                clock = new Clock();
            }
            return clock;
        }
        set;
    }

    public UsageSnapshot getUsageSnapshot() {
        return new UsageSnapshot(
                clock.timeStamp(),
                getUsageIncrement()
        );
    }

    private UsageIncrement getUsageIncrement() {
        return new UsageIncrement(
                clock.getCurrentTimeMillis(),
                queries(),
                cpuTime(),
                dmlRows()
        );
    }

    private virtual Integer queries() {
        return Limits.getQueries();
    }

    private virtual Integer cpuTime() {
        return Limits.getCpuTime();
    }

    private virtual Integer dmlRows() {
        return Limits.getDmlRows();
    }
}