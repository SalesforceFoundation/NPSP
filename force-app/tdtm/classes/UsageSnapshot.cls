public with sharing class UsageSnapshot {

    private Clock clock { get; set; }

    private class UsageSnapshotException extends System.Exception {
    }
    public Long timeUsedMillis;
    public Integer queriesUsed;
    public Integer cpuUsed;
    private Integer dmlRows;
    private Datetime timeStamp;

    public UsageSnapshot() {
        this.timeUsedMillis = clock.getCurrentTimeMillis();
        this.queriesUsed = queries();
        this.cpuUsed = cpuTime();
        this.dmlRows = dmlRows();
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
                queries() - offsetUsage.queriesUsed,
                cpuTime() - offsetUsage.cpuUsed,
                dmlRows() - offsetUsage.dmlRows
        );
    }

    private Integer dmlRows() {
        return Limits.getDmlRows();
    }

    private Integer cpuTime() {
        return Limits.getCpuTime();
    }

    private Integer queries() {
        return Limits.getQueries();
    }

}