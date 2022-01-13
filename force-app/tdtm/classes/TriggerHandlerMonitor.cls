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

    private LimitsMonitor limitsMonitor {
        get {
            if (limitsMonitor == null) {
                limitsMonitor = new LimitsMonitor();
            } return limitsMonitor;
        }
        set;
    }

    public TriggerHandlerMonitor(Boolean isCompactLogging) {
        this.isCompactLoggingEnabled = isCompactLogging;
    }

    public void startMonitoring() {
        //Currently, only supporting one service and context at a time.
        start = limitsMonitor.getUsageSnapshot();
    }

    public void stopMonitoring(TriggerHandler triggerHandler, TriggerContext context) {
        UsageSnapshot stop = limitsMonitor.getUsageSnapshot();
        runResults.add(
                new TriggerHandlerRunResult(
                        context,
                        triggerHandler,
                        start,
                        stop
                )
        );
    }

    public TriggerHandlerRunResults getResults() {
        return runResults;
    }

    public TriggerHandlerRunResults getResultsFor(String className) {
        TriggerHandlerRunResults runResults = new TriggerHandlerRunResults();
        for (TriggerHandlerRunResult triggerHandlerRunResult : this.runResults.getRunResults()) {
            if (triggerHandlerRunResult.service() == className) {
                runResults.add(triggerHandlerRunResult);
            }
        }
        return runResults;
    }

    public TriggerHandlerRunResults getResultsFor(String className, String context) {
        TriggerHandlerRunResults runResults = new TriggerHandlerRunResults();
        for (TriggerHandlerRunResult triggerHandlerRunResult : this.runResults.getRunResults()) {
            if (triggerHandlerRunResult.service().equals(className) &&
                    triggerHandlerRunResult.action().equals(context)) {
                runResults.add(triggerHandlerRunResult);
            }
        }
        return runResults;
    }
}