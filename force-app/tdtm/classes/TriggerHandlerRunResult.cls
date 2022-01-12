public without sharing virtual class TriggerHandlerRunResult {
    private TriggerContext triggerContext;
    private TriggerHandler triggerHandler;
    private UsageSnapshot start;
    private UsageSnapshot stop;

    public TriggerHandlerRunResult() {
    }

    public TriggerHandlerRunResult(
            TriggerContext triggerContext,
            TriggerHandler triggerHandler,
            UsageSnapshot start,
            UsageSnapshot stop
    ) {
        this.triggerContext = triggerContext;
        this.triggerHandler = triggerHandler;
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

    public virtual String triggerHandlerName() {
        return triggerHandler.className();
    }

    public virtual String triggerContext() {
        return triggerContext.action().name();
    }

    public SObjectType getSObjectType() {
        return triggerContext.getSObjectType();
    }

    public UsageSummary usageSummary() {
        return new UsageSummary(
                new List<UsageIncrement>{
                        getUsageIncrement()
                }
        );
    }

    public virtual UsageIncrement getUsageIncrement() {
        return stop.getIncrementFrom(start);
    }
}