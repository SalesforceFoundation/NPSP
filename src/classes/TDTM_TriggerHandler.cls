public with sharing class TDTM_TriggerHandler {

    protected List<Sobject> newlist;
    protected List<Sobject> oldlist; 
    protected TDTM_TriggerActionHelper.Action thisAction;
    protected Schema.DescribeSobjectResult obj;
    
    public String activeClassName; //The class that is currently running
    
    public TDTM_TriggerHandler(Boolean isBefore, Boolean isAfter, Boolean isInsert, Boolean isUpdate,
    Boolean isDelete, Boolean isUnDelete, List<Sobject> newlistfromtrigger, List<Sobject>oldlistFromTrigger, 
    Schema.DescribeSobjectResult describeobj) {
        
        newlist = newlistfromtrigger;
        oldlist = oldlistfromtrigger;

        thisAction = TDTM_TriggerActionHelper.determineTriggerAction(isBefore, isAfter, isInsert, isUpdate,
                                                                        isDelete, isUnDelete);

        obj = describeobj;
    }
    
    public void runClasses(TDTM_iTableDataGateway dao) {
        
        DmlWrapper dmlWrapper = new DmlWrapper();
        
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
            for (ClassToCallWrapper classWrapper : classesToCallNow) {
                DmlWrapper dmlWrapperLocal = runClass(classWrapper);
                if(dmlWrapperLocal != null) {
                	if(dmlWrapperLocal.objectsToInsert != null && dmlWrapperLocal.objectsToInsert.size() > 0)
                        dmlWrapper.objectsToInsert.addAll(dmlWrapperLocal.objectsToInsert);
                    if(dmlWrapperLocal.objectsToUpdate != null && !dmlWrapperLocal.objectsToUpdate.isEmpty())
                        dmlWrapper.objectsToUpdate.putAll(dmlWrapperLocal.objectsToUpdate);
                    if(dmlWrapperLocal.objectsToDelete != null && !dmlWrapperLocal.objectsToDelete.isEmpty())
                        dmlWrapper.objectsToDelete.putAll(dmlWrapperLocal.objectsToDelete);
                }          
            }    
        }  
        
        insert dmlWrapper.objectsToInsert;
        update dmlWrapper.objectsToUpdate.values();
        delete dmlWrapper.objectsToDelete.values();
    }
    
    private List<ClassToCallWrapper> getClassesToCall(Map<String, SObject> classesToCall) {
        List<ClassToCallWrapper> submoduleRunList = new List<ClassToCallWrapper>();
        
        for (String s : classesToCall.keySet()){
            SObject classToCall = classesToCall.get(s);
            Boolean isActive = Boolean.valueOf(classToCall.get('Active__c'));
            String action = String.valueOf(classToCall.get('Trigger_Actions__c'));
            String targetObject = String.valueOf(classToCall.get('Object__c'));
 
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
    
    private DmlWrapper runClass(ClassToCallWrapper classWrapper) {
    	        
        if(classWrapper.triggerHandler != null) {
	        String classToRunName = String.valueOf(classWrapper.triggerHandler.get('Class__c'));
	        System.debug('****Name of class to run: ' + classToRunName);
	        Type classType = Type.forName(classToRunName);
	        
	        if(classType != null) {	        	
	        	Object classInstance = classType.newInstance();
	        	
	        	//The objects we create dynamically need to implement the TDTM_Runnable interface
	        	if(classInstance instanceof TDTM_Runnable) {
			        TDTM_Runnable classToRun = (TDTM_Runnable)classInstance;
			        Boolean async = Boolean.valueOf(classWrapper.triggerHandler.get('Asynchronous__c'));
			        String action = String.valueOf(classWrapper.triggerHandler.get('Trigger_Actions__c'));
			        			        
			        if(!async) {
                        System.debug('****Running Sync: ' + classToRunName); 
                        return runSync(classToRun, classToRunName);
			             
			        } else if(async && action != 'BeforeInsert') {
			        	System.debug('****Running Async: ' + classToRunName);
			        	runAsync(classToRun, classToRunName);
			        
			        //A class can only run asynchronously (calling a future) if we have the ids of the
                    //records we want to affect. This means we can only run it for after in insert
			        } else if(async && action == 'BeforeInsert') {
			        	System.debug('****Cannot run the class aynchronously on beforeinsert.');
			        	System.debug('********Running Sync: ' + classToRunName);
			        	return runSync(classToRun, classToRunName);
			        }
	        	} else {
	        		System.debug('****The class does not implement the required interface.');
	        	}
	        } else {
	        	System.debug('****ClassType was null.');
	        }
        } else {
        	System.debug('****ClassToCall was null');
        }
        return null;
    }
    
    private TDTM_TriggerHandler.DmlWrapper runSync(TDTM_Runnable classToRun, String classToRunName) {
    	System.debug('****Class to run name: ' + classToRun);
        if(classToRunName != activeClassName) {
            System.debug('****Class ' + classToRun + ' was not running');
            activeClassName = classToRunName;
            return classToRun.runMain(newlist, oldlist, thisAction, obj);
        } else {
            System.debug('****Class ' + classToRun + ' already running');
            return classToRun.runInProgress(newlist, oldlist, thisAction, obj);
        }
    }
    
    private void runAsync(TDTM_Runnable classToRun, String classToRunName) {       
       Map<Id,Sobject> nm = new Map<Id,Sobject>(newlist);
       Map<Id,Sobject> om = new Map<Id,Sobject>(oldlist);
       classToRun.runFuture(nm.keySet(), om.keySet(), thisAction.name(), obj.getName());
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
    
    public class DmlWrapper {
        public List<SObject> objectsToInsert = new List<SObject>(); 
        public Map<Id, SObject> objectsToUpdate = new Map<Id, SObject>();
        public Map<Id, SObject> objectsToDelete = new Map<Id, SObject>();
    }
}