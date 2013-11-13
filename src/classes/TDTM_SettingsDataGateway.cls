public with sharing class TDTM_SettingsDataGateway implements TDTM_iTableDataGateway {

    private static Map<String, Trigger_Handler_Setting__c> allClassesToCall;
    
    public static List<SObject> getClassesToCallOnTriggers(String objectName, TDTM_TriggerActionHelper.Action action) {
        Map<String, SObject> classesToCallMap = new Map<String, SObject>();
        if (allClassesToCall == null) {
           allClassesToCall = Trigger_Handler_Setting__c.getAll();
        }
        
        //Filter by params
        for(Trigger_Handler_Setting__c setting : allClassesToCall.values()) {
        	if(setting.Object__c == objectName && setting.Trigger_Action__c == action.name()) {
        	   classesToCallMap.put(setting.Name, setting);
        	}
        }
        
        //Sort
        List<ClassToCallWrapper> classesToCallSorted = new List<ClassToCallWrapper>();
        for(SObject classToCall : classesToCallMap.values()) {
        	classesToCallSorted.add(new ClassToCallWrapper(classToCall));
        }
        classesToCallSorted.sort();
        
        //Put them back in a list of SObjects
        List<SObject> classesToCallFinal = new List<SObject>();
        for(ClassToCallWrapper wrapper : classesToCallSorted) {
        	classesToCallFinal.add(wrapper.triggerHandler);
        }
        return classesToCallFinal;
    }
    
    public class ClassToCallWrapper implements Comparable {

        public final SObject triggerHandler;
        
        public ClassToCallWrapper(SObject triggerHandler) { 
            System.debug('****Class to call in wrapper constructor: ' + triggerHandler);
            this.triggerHandler = triggerHandler; 
        }
            
        public Integer compareTo(Object compareTo) {
            // Cast argument to OpportunityWrapper
            ClassToCallWrapper compareToSSM = (ClassToCallWrapper)compareTo;
            
            Integer LoadOrderThis = Integer.valueOf(triggerHandler.get('Load_Order__c'));
            Integer LoadOrderThat = Integer.valueOf(compareToSSM.triggerHandler.get('Load_Order__c'));
                        
            // The return value of 0 indicates that both elements are equal
            if (LoadOrderThis > LoadOrderThat) return -1;
            else if (LoadOrderThis < LoadOrderThat) return 1;
            return 0;
        }
    }
}