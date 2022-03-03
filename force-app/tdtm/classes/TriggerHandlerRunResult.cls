public without sharing virtual class TriggerHandlerRunResult extends ServiceRunResult {
    protected SObjectType sObjType;

    public TriggerHandlerRunResult() {
    }

    public TriggerHandlerRunResult(
            TriggerContext triggerContext,
            TriggerHandler triggerHandler,
            UsageSnapshot start,
            UsageSnapshot stop
    ) {
        this.service = triggerHandler.className();
        this.action = triggerContext.action().name();
        this.start = start;
        this.stop = stop;
        this.sObjType = triggerContext.getSObjectType();
    }

    public virtual SObjectType getSObjectType() {
        return sObjType;
    }
}