public with sharing class TriggerHandlerRunResults {

    public List<TriggerHandlerRunResult> results = new List<TriggerHandlerRunResult>();
    Long totalTimeUsedInMillis = 0;
    Integer totalQueriesUsed = 0;
    Integer totalCpuTimeUsed = 0;

    public void add(TriggerHandlerRunResult result) {
        results.add(result);
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
            System.debug(LoggingLevel.ERROR, '*** variable value: ' + triggerHandlerRunResult.triggerHandlerName());
            System.debug(LoggingLevel.ERROR, '*** variable value: ' + triggerHandlerRunResult.triggerContext());
            i++;
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