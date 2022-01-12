public without sharing class TriggerHandlerRunResultFake extends TriggerHandlerRunResult {

    private String action;
    private String serviceName;
    private Long timeUsed;
    private Integer cpu;
    private Integer queries;
    private Integer dml;

    public TriggerHandlerRunResultFake(
            String serviceName,
            String action,
            Long timeMillis,
            Integer cpu,
            Integer queries,
            Integer dmlRows
    ) {
        this.serviceName = serviceName;
        this.action = action;
        this.timeUsed = timeMillis;
        this.cpu = cpu;
        this.queries = queries;
        this.dml = dmlRows;

    }
    public override Long timeUsed() {
        return timeUsed;
    }

    public override Integer queriesUsed() {
        return queries;
    }

    public override Integer cpuUsed() {
        return cpu;
    }

    public override Integer dmlRows() {
        return dml;
    }

    public override String triggerHandlerName() {
        return serviceName;
    }

    public override String triggerContext() {
        return action;
    }

    public override UsageIncrement getUsageIncrement() {
        return new UsageIncrement(timeUsed(), queriesUsed(), cpuUsed(), dmlRows());
    }
}