public with sharing class UsageSnapshot {

    public Long timeUsedMillis;
    public Integer queriesUsed;
    public Integer cpuUsed;
    private Integer dmlRows;
    private Datetime timeStamp;

    public UsageSnapshot() {
        this.timeUsedMillis = getCurrentTimeMillis();
        this.queriesUsed = queries();
        this.cpuUsed = cpuTime();
        this.dmlRows = dmlRows();
        this.timeStamp = timeStamp();
    }

    public UsageSnapshot(
            Long currentTimeMillis,
            Integer queries,
            Integer cpu,
            Integer dml
    ) {
        timeUsedMillis = currentTimeMillis;
        queriesUsed = queries;
        cpuUsed = cpu;
        dmlRows = dml;
    }

    public UsageSnapshot getIncrementFrom(UsageSnapshot offsetUsage) {
        return new UsageSnapshot(
            getCurrentTimeMillis() - offsetUsage.timeUsedMillis,
                queries() - offsetUsage.queriesUsed,
                cpuTime() - offsetUsage.cpuUsed,
                dmlRows() - offsetUsage.dmlRows
        );
    }

    private Datetime timeStamp() {
        return System.now();
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

    private Long getCurrentTimeMillis() {
        return System.currentTimeMillis();
    }

}