public with sharing class UsageSnapshot {

    private LimitsMonitor limitsMonitor {
        get {
            if (limitsMonitor == null) {
                limitsMonitor = new LimitsMonitor();
            } return limitsMonitor;
        }
        set;
    }

    private Clock clock {
        get {
            if (clock == null) {
                clock = new Clock();
            } return clock;
        }
        set;
    }

    private class UsageSnapshotException extends System.Exception {
    }
    private Long timeUsedMillis;
    private Integer queriesUsed;
    private Integer cpuUsed;
    private Integer dmlRows;
    private Datetime timeStamp;

    public UsageSnapshot() {
        this.timeUsedMillis = clock.getCurrentTimeMillis();
        this.queriesUsed = limitsMonitor.queries();
        this.cpuUsed = limitsMonitor.cpuTime();
        this.dmlRows = limitsMonitor.dmlRows();
        this.timeStamp = clock.timeStamp();
    }

    public UsageSnapshot(
            Long timeMillis,
            Integer queries,
            Integer cpu,
            Integer dml
    ) {
        if (timeMillis == null
                || queries == null
                || cpu == null
                || dml == null) {
            throw new UsageSnapshotException('All parameters are required.');
        }
        timeUsedMillis = timeMillis;
        queriesUsed = queries;
        cpuUsed = cpu;
        dmlRows = dml;
        timeStamp = clock.timeStamp();
    }

    public UsageSnapshot getIncrementFrom(UsageSnapshot offsetUsage) {
        return new UsageSnapshot(
            clock.getCurrentTimeMillis() - offsetUsage.timeUsedMillis,
                limitsMonitor.queries() - offsetUsage.queriesUsed,
                limitsMonitor.cpuTime() - offsetUsage.cpuUsed,
                limitsMonitor.dmlRows() - offsetUsage.dmlRows
        );
    }

    public Integer dmlRows() {
        return dmlRows;
    }

    public Integer cpuTime() {
        return cpuUsed;
    }

    public Integer queries() {
        return queriesUsed;
    }

    public Long timeMillis() {
        return timeUsedMillis;
    }

    public Datetime timeStamp() {
        return timeStamp;
    }

}