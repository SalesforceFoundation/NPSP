public with sharing class UTIL_Debug {

    //enable debug logs in all tests, otherwise get the setting
    public static boolean enabled = test.isRunningTest() ? true : UTIL_CustomSettingsFacade.getErrorSettings().Enable_Debug__c;

    public static void debug (string message) {
        if (enabled) {
            system.debug(message);
        }
    }

    public static void debug (System.LoggingLevel level, string message) {
        if (enabled) {
            system.debug(level, message);
        }
    }

    public static void debugWithInfo (string message) {
        if (enabled) {
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
        if (enabled) {
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