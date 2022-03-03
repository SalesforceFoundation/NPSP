public without sharing virtual class UsageIncrement {

    protected Long timeUsedMillis;
    protected Integer queriesUsed;
    protected Integer cpuUsed;
    protected Integer dmlRows;

    private class UsageIncrementException extends System.Exception {
    }

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
            throw (Exception) new UsageIncrementException(
                    'All parameters are required.'
            );
        }
        timeUsedMillis = timeMillis;
        queriesUsed = queries;
        cpuUsed = cpu;
        dmlRows = dml;
    }

    public virtual Long timeMillis() {
        return timeUsedMillis;
    }

    public virtual Integer queries() {
        return queriesUsed;
    }

    public virtual Integer cpuTime() {
        return cpuUsed;
    }

    public virtual Integer dmlRows() {
        return dmlRows;
    }

    public Boolean equals(Object obj) {
        if (obj == null) {
            return false;
        }

        if (obj instanceof UsageIncrement) {
            UsageIncrement other = (UsageIncrement) obj;
            return timeMillis() == other.timeMillis()
                    && queries() == other.queries()
                    && cpuTime() == other.cpuTime()
                    && dmlRows() == other.dmlRows();
        } else {
            return false;
        }
    }

    public Integer hashCode() {
        return (31 * ((Integer) timeMillis() + queries()) + dmlRows()) ^ cpuTime();
    }

    public UsageIncrement getIncrementFrom(UsageIncrement other) {
        return new UsageIncrement(
                timeMillis() - other.timeMillis(),
                queries() - other.queries(),
                cpuTime() - other.cpuTime(),
                dmlRows() - other.dmlRows()
        );
    }
}