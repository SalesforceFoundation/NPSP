public with sharing class TDTM_TriggerHandler extends TDTM_aTriggerHandler {

    public void runModules(TDTM_iTableDataGateway dao) {
        
        //Get the classes to run from memory
        Map<String, SObject> classesToCallOnTriggers = dao.getClassesToCallOnTriggers();
        
        if(classesToCallOnTriggers != null) {
            //Find the classes to call
            List<SubmoduleWrapper> classesToCallNow = getClassesToCall(classesToCallOnTriggers);
            
            //Sort the list of classes to call by fire-order
            classesToCallNow.sort();
            
            //Run the relevant classes
            for (SubmoduleWrapper wrapper : classesToCallNow) {
               runClass(wrapper);            
            }    
        }     
    }
    
    private List<SubmoduleWrapper> getClassesToCall(Map<String, SObject> modules) {
        List<SubmoduleWrapper> submoduleRunList = new List<SubmoduleWrapper>();
        
        for (String s : modules.keySet()){
            SObject classToCall = modules.get(s);
            Boolean isActive = Boolean.valueOf(classToCall.get('Active__c'));
            String action = String.valueOf(classToCall.get('Trigger_Actions__c'));
            String targetObject = String.valueOf(classToCall.get('Object__c'));
            
            System.debug('****Class active: ' + isActive);
            System.debug('****Class trigger action: ' + action);
            System.debug('****Object type name: ' + obj.getName());
            System.debug('****Action: ' + thisAction.name());
            
            if (classToCall != null && isActive == true 
            && obj != null && targetObject.equalsIgnoreCase(obj.getName())
            && action != null && thisAction != null 
            && action.containsIgnoreCase(thisAction.name())){
                submoduleRunList.add(new SubmoduleWrapper(classToCall));
            }
        }
        return submoduleRunList;    
    }
    
    private void runClass(SubmoduleWrapper wrapper) {
        //ceiroa: these two lines are important - here is where we read from the object and 
        //we instantiate the objects to be called (from data stored in the object)
        SObject classToCall = wrapper.classToCall;
        System.debug('****Class to call: ' + classToCall);
        if(classToCall != null) {
	        String className =  String.valueOf(wrapper.classToCall.get('Class__c'));
	        Type classType = Type.forName(className);
	        TDTM_Runnable ism = (TDTM_Runnable)classType.newInstance();
	    
	        Boolean async = Boolean.valueOf(wrapper.classToCall.get('Asynchronous__c'));
	        String action = String.valueOf(wrapper.classToCall.get('Trigger_Actions__c'));
	        if(!async) {
	           system.debug('****Running Sync: ' + className);
	           //ceiroa: the objects we create dynamically need to implement the iSubsystemModule
	           //interface - @TODO: check that they actually do 
	           ism.run(newlist, oldlist, thisAction, obj);
	        } else if(async && action != 'BeforeInsert') {
	           system.debug('****Running Async: ' + className);
	           //@TODO: it can only run asynchronously (calling a future) if we have the ids of the
	           //records we want to affect. This means we can only run it for after in insert
	           //(either before or after is fine for update and delete)
	           Map<Id,Sobject> nm = new Map<Id,Sobject>(newlist);
	           Map<Id,Sobject> om = new Map<Id,Sobject>(oldlist);
	           ism.runFuture(nm.keySet(), om.keySet(), thisAction.name(), obj.getName());
	        }
        } 
    }
}