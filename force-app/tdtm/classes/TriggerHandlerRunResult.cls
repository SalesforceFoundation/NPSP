public with sharing class TriggerHandlerRunResult {
    private TriggerContext triggerContext;
    private TriggerHandler triggerHandler;
    private Long timeUsed;
    private Integer soqlUsed;
    private Integer cpuUsed;

    public TriggerHandlerRunResult(
            TriggerContext triggerContext,
            TriggerHandler triggerHandler,
            UsageSnapshot usageSnapshot
    ) {
        this.triggerContext = triggerContext;
        this.triggerHandler = triggerHandler;
        this.timeUsed = usageSnapshot.timeUsedMillis;
        this.soqlUsed = usageSnapshot.queriesUsed;
        this.cpuUsed = usageSnapshot.cpuUsed;
    }

    public Long timeUsed() {
        return timeUsed;
    }

    public Integer queriesUsed() {
        return soqlUsed;
    }

    public Integer cpuUsed() {
        return cpuUsed;
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

    public UsageSnapshot usage() {
        return new UsageSnapshot();
    }
}