public without sharing virtual class ServiceRunResult {
    protected String service;
    protected String action;
    protected UsageSnapshot start;
    protected UsageSnapshot stop;

    protected ServiceRunResult(){}

    public ServiceRunResult(
            String service,
            String action,
            UsageSnapshot start,
            UsageSnapshot stop
    ) {
        this.service = service;
        this.action = action;
        this.start = start;
        this.stop = stop;
    }

    public virtual Long timeUsed() {
        return stop.timeMillis() - start.timeMillis();
    }

    public virtual Integer queriesUsed() {
        return stop.queries() - start.queries();
    }

    public virtual Integer cpuUsed() {
        return stop.cpuTime() - start.cpuTime();
    }

    public virtual Integer dmlRows() {
        return stop.dmlRows() - start.dmlRows();
    }

    public virtual String service() {
        return service;
    }

    public virtual String action() {
        return action;
    }

}