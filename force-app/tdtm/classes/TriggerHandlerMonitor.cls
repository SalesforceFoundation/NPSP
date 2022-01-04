public with sharing class TriggerHandlerMonitor {

    private Map<String, Integer> classNameToTimesCalled =
            new Map<String, Integer>();
    private Map<String, Integer> classNameToNumberOfQueries =
            new Map<String, Integer>();
    private Map<String, Map<String, Integer>> classNameToTimesCalledByContext =
            new Map<String, Map<String, Integer>>();
    private Boolean isCompactLoggingEnabled = true;
    private Integer queries = 0;

    public TriggerHandlerMonitor(Boolean isCompactLogging){
       this.isCompactLoggingEnabled = isCompactLogging;
    }

    public void stopMonitoring(TriggerHandler triggerHandler, TriggerContext context) {
        incrementTimesCalledByContext(triggerHandler.className(), context.triggerAction().name());
        incrementTimesCalled(triggerHandler.className());
        updateNumberOfQueriesUsed(triggerHandler.className());
        queries = 0;
    }

    private void updateNumberOfQueriesUsed(String className) {
        classNameToNumberOfQueries.put(
                className,
                classNameToNumberOfQueries.get(className) == null
                        ? 0
                        : classNameToNumberOfQueries.get(className)
                        + (Limits.getQueries() - queries));
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

    public void startMonitoring(TriggerHandler triggerHandler, TriggerContext triggerContext) {
        System.debug(LoggingLevel.ERROR, '*** ##### starting monitoring for ' +
                triggerHandler.className() + triggerContext.triggerAction().name()+
                '######');
        queries = Limits.getQueries();
    }
}