public with sharing class UsageSnapshot {

    public Long timeUsedMillis;
    public Integer queriesUsed;
    public Integer cpuUsed;
    private Integer dmlRows;
    private Datetime timeStamp;

    public UsageSnapshot() {
        this.timeUsedMillis = System.currentTimeMillis();
        this.queriesUsed = Limits.getQueries();
        this.cpuUsed = Limits.getCpuTime();
        this.dmlRows = Limits.getDmlRows();
        this.timeStamp = System.now();
    }

    public UsageSnapshot(
            Long offsetTimeMillis,
            Integer offsetQueries,
            Integer offsetCpu) {
        timeUsedMillis = System.currentTimeMillis() - offsetTimeMillis;
        queriesUsed = Limits.getQueries() - offsetQueries;
        cpuUsed = Limits.getCpuTime() - offsetCpu;
    }

}