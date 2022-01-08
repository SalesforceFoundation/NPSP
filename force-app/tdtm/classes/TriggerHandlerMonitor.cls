public with sharing class TriggerHandlerMonitor {

    private Integer queriesAtStart;
    private Datetime startTime;
    private Long startTimeMillis;
    private Integer cpuAtStart;
    private TriggerHandlerRunResults runResults = new TriggerHandlerRunResults();
    private Boolean isCompactLoggingEnabled;

    public TriggerHandlerMonitor(Boolean isCompactLogging){
       this.isCompactLoggingEnabled = isCompactLogging;
    }

    public void stopMonitoring(TriggerHandler triggerHandler, TriggerContext context) {
        UsageSnapshot usageSnapshot = new UsageSnapshot(
                startTimeMillis,
                queriesAtStart,
                cpuAtStart
        );

        runResults.add(
                new TriggerHandlerRunResult(
                        context,
                        triggerHandler,
                        usageSnapshot
                )
        );
    }

    public void startMonitoring(TriggerHandler triggerHandler, TriggerContext triggerContext) {
        System.debug(LoggingLevel.ERROR, '*** ##### starting monitoring for ' +
                triggerHandler.className() + triggerContext.triggerAction().name()+
                '######');
        cpuAtStart = Limits.getCpuTime();
        queriesAtStart = Limits.getQueries();
        startTime = System.now();
        startTimeMillis = System.currentTimeMillis();
    }

    public TriggerHandlerRunResults getResults() {
        return runResults;
    }

    public TriggerHandlerRunResults getResultsFor(String className, String context) {
        TriggerHandlerRunResults runResults = new TriggerHandlerRunResults();
        for (TriggerHandlerRunResult triggerHandlerRunResult : this.runResults.results) {
            if (triggerHandlerRunResult.triggerHandlerName() == className &&
                    triggerHandlerRunResult.triggerContext() == context) {
                runResults.add(triggerHandlerRunResult);
            }
        }
        return runResults;
    }
}