public with sharing class TriggerHandlerMonitor {

    private TriggerHandlerRunResults runResults = new TriggerHandlerRunResults();
    private Boolean isCompactLoggingEnabled;
    private UsageSnapshot start;
    private Map<String, Set<String>> serviceMonitoringMap {
        get {
            if (serviceMonitoringMap == null) {
                serviceMonitoringMap = new Map<String, Set<String>>();
            }
            return serviceMonitoringMap;
        }
        set;
    }

    public TriggerHandlerMonitor(Boolean isCompactLogging){
       this.isCompactLoggingEnabled = isCompactLogging;
    }

    public void stopMonitoring(TriggerHandler triggerHandler, TriggerContext context) {
        UsageSnapshot currentSnapshot = new UsageSnapshot();
        UsageSnapshot usageIncrement = currentSnapshot.getIncrementFrom(start);

        runResults.add(
                new TriggerHandlerRunResult(
                        context,
                        triggerHandler,
                        usageIncrement
                )
        );
    }

    public void startMonitoring(TriggerHandler triggerHandler, TriggerContext triggerContext) {
        System.debug(LoggingLevel.ERROR, '*** ##### starting monitoring for ' +
                triggerHandler.className() + triggerContext.action().name()+
                '######');
        //Currently, only supporting one service and context at a time.
        start = new UsageSnapshot();
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