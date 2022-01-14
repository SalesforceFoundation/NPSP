public with sharing class ServiceMonitor {

    private TriggerHandlerRunResults runResults = new TriggerHandlerRunResults();
    private Boolean isCompactLoggingEnabled;
    private UsageSnapshot start;
    private Map<String, UsageSnapshot> monitoringMap = new Map<String, UsageSnapshot>();

    private LimitsMonitor limitsMonitor {
        get {
            if (limitsMonitor == null) {
                limitsMonitor = new LimitsMonitor();
            } return limitsMonitor;
        }
        set;
    }

    public ServiceMonitor(Boolean isCompactLogging) {
        this.isCompactLoggingEnabled = isCompactLogging;
    }

    public void startMonitoring(String service, String action) {
        //Currently, only supporting one instance of service+context at a time.
        start = limitsMonitor.getUsageSnapshot();
        monitoringMap.put(service + action, start);
    }

    public void stopMonitoring(TriggerHandler triggerHandler, TriggerContext context) {
        UsageSnapshot stop = limitsMonitor.getUsageSnapshot();
        TriggerHandlerRunResult runResult = new TriggerHandlerRunResult(
                context,
                triggerHandler,
                monitoringMap.get(triggerHandler.className()+context.action().name()),
                stop
        );

        runResults.add(runResult);
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