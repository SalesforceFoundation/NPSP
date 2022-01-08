public with sharing class TriggerHandlerRunResults {
    // RunResults holds a collection of TriggerHandlerRunResult and
    // provides summary calculations

    public List<TriggerHandlerRunResult> results = new List<TriggerHandlerRunResult>();
    public Boolean isCompactLoggingEnabled = true;

    private Map<String, Integer> classNameToTimesCalled =
            new Map<String, Integer>();
    private Map<String, Integer> classNameToNumberOfQueries =
            new Map<String, Integer>();
    private Map<String, Map<String, Integer>> classNameToTimesCalledByContext =
            new Map<String, Map<String, Integer>>();

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
        System.debug(LoggingLevel.ERROR, '*** ##### LOG RESULTS ######');
        System.debug(LoggingLevel.ERROR, '*** totalTimeUsedInMillis: ' + totalTimeUsedInMillis);
        System.debug(LoggingLevel.ERROR, '*** totalQueriesUsed: ' + totalQueriesUsed);
        System.debug(LoggingLevel.ERROR, '*** totalCpuTimeUsed: ' + totalCpuTimeUsed);
    }

    public void logStack() {
        integer i = 1;
        for (TriggerHandlerRunResult triggerHandlerRunResult : results) {
            System.debug(LoggingLevel.ERROR, '*** ##### '+ i +':  ######');
            System.debug(LoggingLevel.ERROR, '***' + triggerHandlerRunResult.getSObjectType() + ' | ' + triggerHandlerRunResult.triggerContext() + ' | ' + triggerHandlerRunResult.triggerHandlerName());
            System.debug(LoggingLevel.ERROR, '*** cpu: ' + triggerHandlerRunResult.cpuUsed
                    () + ' :: queries: ' + triggerHandlerRunResult.queriesUsed() + ' :: ' +
                    'time:' + triggerHandlerRunResult.timeUsed());
            i++;
        }
    }

    public Integer timesRun(String className, String context) {
        System.debug(LoggingLevel.ERROR, '*** variable value: ' + classNameToTimesCalledByContext);
        System.debug(LoggingLevel.ERROR, '^^^^^^ classNameToTimesCalledByContext ^^^^^^');
        return classNameToTimesCalledByContext.get(className)?.get(context);
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
        Integer total = 0;
        for (String str : classNameToNumberOfQueries.keySet()) {
            total = total + classNameToNumberOfQueries.get(str);
        }
        return total;
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


//    private enum Action {
//        BeforeInsert,
//        BeforeUpdate,
//        BeforeDelete,
//        AfterInsert,
//        AfterUpdate,
//        AfterDelete,
//        AfterUndelete
//    }

//    public void logBySObjectAndContext(){
//        Map<SObjectType, Map<String, UsageSnapshot>> m =
//                new Map<SObjectType, Map<String, UsageSnapshot>>();
//        for (TriggerHandlerRunResult triggerHandlerRunResult : results) {
//            Map<String, UsageSnapshot> usageByContext =
//                    m.get(triggerHandlerRunResult.sObjectType());
//            if (usageByContext == null) {
//                usageByContext.put(
//                        triggerHandlerRunResult.triggerContext(),
//                        triggerHandlerRunResult.usage()
//                );
//            } else {
//
//            }
//        }
//    }
//
}