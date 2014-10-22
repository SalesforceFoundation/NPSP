public with sharing class UTIL_Debug {

    public static boolean enabled = UTIL_CustomSettingsFacade.getErrorSettings().Enable_Debug__c;

    public static void debug (string message) {
        if (test.isRunningTest() || enabled) {
            system.debug(message);
        }
    }

    public static void debug (System.LoggingLevel level, string message) {
        if (test.isRunningTest() || enabled) {
            system.debug(level, message);
        }
    }

    public static void debugWithInfo (string message) {
        if (test.isRunningTest() || enabled) {
            system.debug(
                message + 
                ' Heap:' + Limits.getHeapSize() + '/' + Limits.getLimitHeapSize() +
                ' CPU:' + Limits.getCpuTime() + '/' + Limits.getLimitCpuTime() + 
                ' Query:' + Limits.getQueries() + '/' + Limits.getLimitQueries() + 
                ' Rows:' + Limits.getDMLRows() + '/' + Limits.getLimitDMLRows()
            );
        }
    }

    public static void debugWithInfo (System.LoggingLevel level, string message) {
        if (test.isRunningTest() || enabled) {
            system.debug(
                level,
                message + 
                ' Heap:' + Limits.getHeapSize() + '/' + Limits.getLimitHeapSize() +
                ' CPU:' + Limits.getCpuTime() + '/' + Limits.getLimitCpuTime() + 
                ' Query:' + Limits.getQueries() + '/' + Limits.getLimitQueries() + 
                ' Rows:' + Limits.getDMLRows() + '/' + Limits.getLimitDMLRows()
            );
        }
    }
}