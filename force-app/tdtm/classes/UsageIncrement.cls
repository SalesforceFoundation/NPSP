public without sharing class UsageIncrement extends UsageSnapshot {

    private class UsageIncrementException extends System.Exception {}

    public UsageIncrement(
            Long timeMillis,
            Integer queries,
            Integer cpu,
            Integer dml
    ) {
        if (timeMillis == null
                || queries == null
                || cpu == null
                || dml == null) {
            throw (Exception) new UsageIncrementException('All parameters are required.');
        }
        timeUsedMillis = timeMillis;
        queriesUsed = queries;
        cpuUsed = cpu;
        dmlRows = dml;
    }
}