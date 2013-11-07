public with sharing class TDTM_SettingsDataGateway implements TDTM_iTableDataGateway {

    private static Map<String, SObject> classesToCallOnTriggers;
    
    public static Map<String, SObject> getClassesToCallOnTriggers() {
        if (classesToCallOnTriggers == null) {
           classesToCallOnTriggers = Trigger_Handler_Setting__c.getAll();
        }
        return classesToCallOnTriggers;
    }
}