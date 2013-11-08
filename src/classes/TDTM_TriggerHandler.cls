public with sharing class TDTM_TriggerHandler extends TDTM_aTriggerHandler {

    public void runModules(TDTM_iTableDataGateway dao) {
        
        //Get the classes to run from memory
        Map<String, SObject> classesToCallOnTriggers = dao.getClassesToCallOnTriggers();
        
        if(classesToCallOnTriggers != null) {
            //Find the classes to call
            List<ClassToCallWrapper> classesToCallNow = getClassesToCall(classesToCallOnTriggers);
            System.debug('****Classes to call: ' + classesToCallNow);
            
            //Sort the list of classes to call by fire-order
            classesToCallNow.sort();
            System.debug('****Classes to call sorted: ' + classesToCallNow);
            
            //Run the relevant classes
            for (ClassToCallWrapper wrapper : classesToCallNow) {
               runClass(wrapper);            
            }    
        }     
    }
    
    private List<ClassToCallWrapper> getClassesToCall(Map<String, SObject> classesToCall) {
        List<ClassToCallWrapper> submoduleRunList = new List<ClassToCallWrapper>();
        
        for (String s : classesToCall.keySet()){
            SObject classToCall = classesToCall.get(s);
            Boolean isActive = Boolean.valueOf(classToCall.get('Active__c'));
            String action = String.valueOf(classToCall.get('Trigger_Actions__c'));
            String targetObject = String.valueOf(classToCall.get('Object__c'));
            
            System.debug('****Class active: ' + isActive);
            System.debug('****Sync: ' + Boolean.valueOf(classToCall.get('Asynchronous__c')));
            System.debug('****Target object: ' + obj.getName());
            System.debug('****Class trigger action: ' + action);
            System.debug('****This Action: ' + thisAction.name());
 
            if (classToCall != null && isActive == true && obj != null && targetObject.equalsIgnoreCase(obj.getName())
            && action != null && thisAction != null && action.containsIgnoreCase(thisAction.name())) {
            	System.debug('****Class ' + classToCall.get('Class__c') + ' will be called');
                submoduleRunList.add(new ClassToCallWrapper(classToCall));
            } else {
            	System.debug('****Class ' + classToCall.get('Class__c') + ' will NOT be called');
            }
        }
        return submoduleRunList;    
    }
    
    private void runClass(ClassToCallWrapper wrapper) {
        //ceiroa: these two lines are important - here is where we read from the object and 
        //we instantiate the objects to be called (from data stored in the object)
        SObject classToCall = wrapper.classToCall;
        System.debug('****About to run class ' + classToCall);
        if(classToCall != null) {
	        String className =  String.valueOf(wrapper.classToCall.get('Class__c'));
	        System.debug('****Name of class we are going to run: ' + className);
	        Type classType = Type.forName(className);
	        System.debug('****Type of class we are going to run: ' + classType);
	        if(classType != null) {
	        	Object classInstance = classType.newInstance();
	        	//The objects we create dynamically need to implement the TDTM_Runnable interface
	        	if(classInstance instanceof TDTM_Runnable) {
			        TDTM_Runnable ism = (TDTM_Runnable)classInstance;
			        Boolean async = Boolean.valueOf(wrapper.classToCall.get('Asynchronous__c'));
			        String action = String.valueOf(wrapper.classToCall.get('Trigger_Actions__c'));
			        if(!async) {
			           System.debug('****Running Sync: ' + className);
			           ism.run(newlist, oldlist, thisAction, obj);
			        } else if(async && action != 'BeforeInsert') {
			           System.debug('****Running Async: ' + className);       
			           Map<Id,Sobject> nm = new Map<Id,Sobject>(newlist);
			           Map<Id,Sobject> om = new Map<Id,Sobject>(oldlist);
			           ism.runFuture(nm.keySet(), om.keySet(), thisAction.name(), obj.getName());
			        //A class can only run asynchronously (calling a future) if we have the ids of the
                    //records we want to affect. This means we can only run it for after in insert
			        } else if(async && action == 'BeforeInsert') {
			        	System.debug('****You cannot run the class aynchronously on beforeinsert.');
			        	System.debug('****We will run the following class synchronously: ' + className);
			        	ism.run(newlist, oldlist, thisAction, obj);
			        }
	        	} else {
	        		System.debug('****The class does not implement the required interface.');
	        	}
	        }
        } 
    }
}