public with sharing class UsageSnapshot {

    public Long timeUsedMillis = 0;
    public Integer queriesUsed = 0;
    public Integer cpuUsed = 0;
    private Integer dmlRows;

    public UsageSnapshot() {
        this.timeUsedMillis = System.currentTimeMillis();
        this.queriesUsed = Limits.getQueries();
        this.cpuUsed = Limits.getCpuTime();
        this.dmlRows = Limits.getDmlRows();
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