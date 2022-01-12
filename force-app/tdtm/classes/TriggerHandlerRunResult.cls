public without sharing virtual class TriggerHandlerRunResult extends ServiceRunResult {
    private TriggerContext triggerContext;
    private TriggerHandler triggerHandler;

    public TriggerHandlerRunResult() {}

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