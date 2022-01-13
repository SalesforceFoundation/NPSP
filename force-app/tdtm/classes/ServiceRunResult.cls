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

    public virtual String service() {
        return service;
    }

    public virtual String action() {
        return action;
    }

    public virtual UsageSummary usageSummary() {
        return new UsageSummary(
                new List<UsageIncrement>{
                        usageIncrement()
                }
        );
    }

    public virtual UsageIncrement usageIncrement() {
        return stop.usageIncrement().getIncrementFrom(start.usageIncrement());
    }
}