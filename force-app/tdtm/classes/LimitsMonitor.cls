public without sharing virtual class LimitsMonitor {
    public virtual Integer queries() {
        return Limits.getQueries();
    }

    public virtual Integer cpuTime() {
        return Limits.getCpuTime();
    }

    public virtual Integer dmlRows() {
        return Limits.getDmlRows();
    }
}