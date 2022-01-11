public with sharing class TriggerHandlerRunResult {
    private TriggerContext triggerContext;
    private TriggerHandler triggerHandler;
    private UsageSnapshot start;
    private UsageSnapshot stop;

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

    public Long timeUsed() {
        return stop.timeMillis() - start.timeMillis();
    }

    public Integer queriesUsed() {
        return stop.queries() - start.queries();
    }

    public Integer cpuUsed() {
        return stop.cpuTime() - start.cpuTime();
    }

    public Integer dmlRows() {
        return stop.dmlRows() - start.dmlRows();
    }

    public String triggerHandlerName() {
        return triggerHandler.className();
    }

    public String triggerContext() {
        return triggerContext.action().name();
    }

    public SObjectType getSObjectType() {
        return triggerContext.describeObj.SObjectType;
    }
}