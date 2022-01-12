public with sharing class TriggerHandlerRunResults {
    // RunResults holds a collection of TriggerHandlerRunResult and
    // provides summary calculations

    protected List<TriggerHandlerRunResult> results = new List<TriggerHandlerRunResult>();
    public Boolean isCompactLoggingEnabled = true;

    private Map<String, Integer> classNameToTimesCalled =
            new Map<String, Integer>();
    private Map<String, Integer> classNameToNumberOfQueries =
            new Map<String, Integer>();
    private Map<String, Map<String, Integer>> classNameToTimesCalledByContext =
            new Map<String, Map<String, Integer>>();
    private Map<String, Map<String, UsageSummary>> classNameToUsageSummaryByContext =
            new Map<String, Map<String, UsageSummary>>();

    private Long totalTimeUsedInMillis = 0;
    private Integer totalQueriesUsed = 0;
    private Integer totalCpuTimeUsed = 0;

    public void add(TriggerHandlerRunResult result) {
        results.add(result);
        incrementTimesCalledByContext(result.triggerHandlerName(), result.triggerContext());
        incrementTimesCalled(result.triggerHandlerName());
        updateNumberOfQueriesUsed(result.triggerHandlerName(), result.queriesUsed());
        totalTimeUsedInMillis += result.timeUsed();
        totalQueriesUsed += result.queriesUsed();
        totalCpuTimeUsed += result.cpuUsed();
    }

    public void logResults() {
        UsageSummary usageSummary = new
                UsageSummary(getUsageIncrements());
        System.debug(LoggingLevel.ERROR, '*** ##### USAGE SUMMARY: All Results ######');
        System.debug(LoggingLevel.ERROR, '*** variable value: ' + usageSummary.format());
        System.debug(LoggingLevel.ERROR, '^^^^^^ usageSummary.format() ^^^^^^');
    }

    private List<UsageIncrement> getUsageIncrements() {
        List<UsageIncrement> usageIncrements = new List<UsageIncrement>();
        for (TriggerHandlerRunResult runResult : getRunResults()) {
            usageIncrements.add(
                    runResult.getUsageIncrement()
            );
        }
        return usageIncrements;
    }

    public List<TriggerHandlerRunResult> getRunResults() {
        return this.results;
    }

    public void printStack() {
        System.debug(LoggingLevel.ERROR, '*** ##### Printing STACK ######');
        Integer i = 1;
        SObjectType currentType;
        for (TriggerHandlerRunResult triggerHandlerRunResult : this.results) {
            SObjectType sObjectType = triggerHandlerRunResult.getSObjectType();
            if (currentType != null && sObjectType !=
                    currentType) {
                System.debug(LoggingLevel.ERROR,
                        '*** ##### --------------------------- SOBJECT SWITCH ('
                                + currentType + '--> ' + sObjectType + ') ' +
                                '--------------------------- ######');
            }
            currentType = sObjectType;
            System.debug(LoggingLevel.ERROR, '*** ##### ' + i + ':  ######');
            System.debug(LoggingLevel.ERROR, '*** ' + sObjectType + ' :: ' +
                    triggerHandlerRunResult.triggerContext() + ' :: ' +
                    triggerHandlerRunResult.triggerHandlerName());
            UsageSummary usageSummary = triggerHandlerRunResult.usageSummary();
            System.debug(LoggingLevel.ERROR,
                    '*** cpuUsed: '
                            + usageSummary.totalCpu()
                            + ' :: queriesUsed: '
                            + usageSummary.totalQueries()
                            + ' :: timeUsedMillis: '
                            + usageSummary.totalTimeMillis()
                            + ' :: dmlRows: '
                            + usageSummary.totalDmlRows());
            i++;
        }
    }

    public Integer timesRun(String className, String context) {
        System.debug(LoggingLevel.ERROR, '*** variable value: ' + classNameToTimesCalledByContext);
        System.debug(LoggingLevel.ERROR, '^^^^^^ classNameToTimesCalledByContext ^^^^^^');
        return classNameToUsageSummaryByContext.get(className)?.get(context).timesRun();
    }

    public void logTriggerHandlerInfo() {
        UTIL_Debug.debug(LoggingLevel.ERROR, '*** Number of Times Run by Trigger ' +
                'Handler: ' +
                stringVersionOf(classNameToTimesCalled));

        UTIL_Debug.debug(LoggingLevel.ERROR, '*** Number of Times Run by Trigger ' +
                'Handler ' +
                'by Context: ' +
                stringVersionOf(classNameToTimesCalledByContext));

        UTIL_Debug.debug(LoggingLevel.ERROR, '*** Number of Queries used by Trigger ' +
                'Handler: ' +
                stringVersionOf(classNameToNumberOfQueries));

        UTIL_Debug.debug(LoggingLevel.ERROR, '*** totalQueries(): ' + totalQueries());
    }

    private String stringVersionOf(Object o) {
        return isCompactLoggingEnabled
                ? JSON.serialize(o)
                : JSON.serializePretty(o);
    }

    private Integer totalQueries() {
        return new UsageSummary(getUsageIncrements()).totalQueries();
    }

    private void updateNumberOfQueriesUsed(String className, Integer queriesUsed) {
        Integer numberOfQueries = classNameToNumberOfQueries.get(className);
        classNameToNumberOfQueries.put(
                className,
                numberOfQueries == null
                        ? queriesUsed
                        : numberOfQueries + queriesUsed);
    }

    private void incrementTimesCalled(String className) {
        if (classNameToTimesCalled.get(className) == null) {
            classNameToTimesCalled.put(className, 1);
        } else {
            classNameToTimesCalled.put(className, classNameToTimesCalled.get(className) + 1);
        }
    }

    private void incrementTimesCalledByContext(String className, String actionName) {
        if (classNameToTimesCalledByContext.get(className) == null) {
            classNameToTimesCalledByContext.put(
                    className,
                    new Map<String, Integer>{
                            actionName => 1
                    });
        } else {
            Integer timesForContext = classNameToTimesCalledByContext.get(className).get(actionName);
            if (timesForContext == null) {
                classNameToTimesCalledByContext.get(className).put(actionName, 1);
            } else {
                classNameToTimesCalledByContext.get(className).put(actionName, timesForContext + 1);
            }
        }
    }

    public TriggerHandlerRunResults getRunResultsFor(String serviceName) {
        TriggerHandlerRunResults serviceContextRunResults = new TriggerHandlerRunResults();
        for (TriggerHandlerRunResult triggerHandlerRunResult : this.results) {
            if (triggerHandlerRunResult.triggerHandlerName() == serviceName) {
                serviceContextRunResults.add(triggerHandlerRunResult);
            }
        }
        return serviceContextRunResults;
    }

    public TriggerHandlerRunResults getRunResultsFor(String serviceName, String context) {
        TriggerHandlerRunResults serviceContextRunResults = new TriggerHandlerRunResults();
        for (TriggerHandlerRunResult triggerHandlerRunResult : this.results) {
            if (triggerHandlerRunResult.triggerHandlerName() == serviceName
                    && triggerHandlerRunResult.triggerContext() == context) {
                serviceContextRunResults.add(triggerHandlerRunResult);
            }
        }
        return serviceContextRunResults;
    }

    public UsageSummary usageSummary() {
        return new UsageSummary(usageIncrements());
    }

    private List<UsageIncrement> usageIncrements() {
        List<UsageIncrement> usageIncrements = new List<UsageIncrement>();
        for (TriggerHandlerRunResult triggerHandlerRunResult : results) {
            usageIncrements.add(triggerHandlerRunResult.getUsageIncrement());
        }
        return usageIncrements;
    }

    public void debugMin() {
        for (TriggerHandlerRunResult triggerHandlerRunResult : results) {
            System.debug(LoggingLevel.ERROR,
                    triggerHandlerRunResult.triggerHandlerName()
                            + ' ' + triggerHandlerRunResult.triggerContext()
                            + ' ' + triggerHandlerRunResult.usageSummary().format());
        }
    }

    public UsageSummary usageSummaryFor(String service) {
        return new UsageSummary(
                getRunResultsFor(service).getUsageIncrements()
        );
    }
    public UsageSummary usageSummaryFor(String service, String action) {
        return new UsageSummary(
                getRunResultsFor(service, action).getUsageIncrements()
        );
    }

    public Map<String, UsageSummary> usageSummaryByService() {
        Map<String, UsageSummary> summariesByStrings = new Map<String, UsageSummary>();
        for (String handlerName : classNameToTimesCalled.keySet()) {
            summariesByStrings.put(handlerName, usageSummaryFor(handlerName));
        }
        return summariesByStrings;
    }

    public Map<String, Map<String, UsageSummary>> usageSummaryByServiceByAction() {
        Map<String, Map<String, UsageSummary>> summaryByServiceByContext =
                new Map<String, Map<String, UsageSummary>>();
        for (TriggerHandlerRunResult triggerHandlerRunResult : results) {
            Map<String, UsageSummary> summaryByContext = summaryByServiceByContext.get
                    (triggerHandlerRunResult.triggerHandlerName());
            if (summaryByContext == null) {
                summaryByServiceByContext.put(
                        triggerHandlerRunResult.triggerHandlerName(),
                        new Map<String, UsageSummary>{
                                triggerHandlerRunResult.triggerContext() =>
                                        usageSummaryFor(
                                                triggerHandlerRunResult.triggerHandlerName(),
                                                triggerHandlerRunResult.triggerContext()
                                        )
                        }
                );
            }
        }

        return summaryByServiceByContext;
    }

    public void printUsageSummary() {
        System.debug(LoggingLevel.ERROR, '*** TriggerHandlerRunResults Usage Summary '
                + usageSummary().format());
        System.debug(LoggingLevel.ERROR, '^^^^^^ r.usageSummary() ^^^^^^');
    }

    public void printUsageSummaryByServiceByContext() {

        System.debug(LoggingLevel.ERROR, '*** ##### USAGE BY SERVICE ######');
        Map<String, UsageSummary> byService = usageSummaryByService();
        for (String str : byService.keySet()) {
            System.debug(LoggingLevel.ERROR, str + ' ' + byService.get(str).format());
        }
        //todo: next
        System.debug(LoggingLevel.ERROR, '*** ##### USAGE BY SERVICE BY ACTION ######');
        Map<String, Map<String, UsageSummary>> byServiceByAction =
                usageSummaryByServiceByAction();
        for (String str : byServiceByAction.keySet()) {
            System.debug(LoggingLevel.ERROR, '*** variable value: ' + str);
            Map<String, UsageSummary> contextUsageMap =
                    byServiceByAction.get(str);
            for (String str2 : contextUsageMap.keySet()) {
                System.debug(LoggingLevel.ERROR, '*** variable value: ' + str2);
                System.debug(LoggingLevel.ERROR, '*** variable value: ' + contextUsageMap.get(str2).format());
            }
            System.debug(LoggingLevel.ERROR, str + ' Totals:' + byService.get(str)
                    .format());
        }
    }

    public UsageIncrement getIncrementFrom(UsageIncrement usageIncrement) {
        UsageSummary usageSummary = usageSummary();
        return new UsageIncrement(usageSummary.totalTimeMillis() - usageIncrement
                .timeMillis(),
                usageSummary.totalQueries() - usageIncrement.queries(),
                usageSummary.totalCpu() - usageIncrement.cpuTime(),
                usageSummary.totalDmlRows() - usageIncrement.dmlRows());
    }

//    public void logBySObjectAndContext(){
////                          action/context ... UsageSummary
//        Map<SObjectType, Map<String, UsageSnapshot>> m =
//                new Map<SObjectType, Map<String, UsageSnapshot>>();
//
//        for (TriggerHandlerRunResult triggerHandlerRunResult : this.results) {
//            Map<String, UsageSnapshot> usageByContext =
//                    m.get(triggerHandlerRunResult.getSObjectType());
//
//            if (usageByContext == null) {
//                usageByContext.put(
//                        triggerHandlerRunResult.triggerContext(),
//                        triggerHandlerRunResult.usageSummary()
//                );
//            } else {
//
//
//            }
//        }
//    }

}