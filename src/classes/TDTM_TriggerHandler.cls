public with sharing class TDTM_TriggerHandler {

    private static List<Sobject> newlist;
    private static List<Sobject> oldlist; 
    private static TDTM_TriggerActionHelper.Action thisAction;
    private static Schema.DescribeSobjectResult obj;
    
    public static String activeClassName; //The class that is currently running
    
    public static void initialize(Boolean isBefore, Boolean isAfter, Boolean isInsert, Boolean isUpdate,
    Boolean isDelete, Boolean isUnDelete, List<Sobject> newlistfromtrigger, List<Sobject>oldlistFromTrigger, 
    Schema.DescribeSobjectResult describeobj) {
        
        newlist = newlistfromtrigger;
        oldlist = oldlistfromtrigger;

        thisAction = TDTM_TriggerActionHelper.determineTriggerAction(isBefore, isAfter, isInsert, isUpdate,
                                                                        isDelete, isUnDelete);

        obj = describeobj;
    }
    
    public static void runClasses(TDTM_iTableDataGateway dao) {
        
        DmlWrapper dmlWrapper = new DmlWrapper();
        
        //Get the classes to run
        List<SObject> classesToCallOnTriggers = dao.getClassesToCallOnTriggers(obj.getName(), thisAction);
        
        if(classesToCallOnTriggers != null) {
            
            //Run the relevant classes
            for (SObject classToRun : classesToCallOnTriggers) {
                DmlWrapper dmlWrapperLocal = runClass(classToRun);
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
    
    private static DmlWrapper runClass(SObject classToRunRecord) {
    	        
        if(classToRunRecord != null) {
	        String classToRunName = String.valueOf(classToRunRecord.get('Class__c'));
	        System.debug('****Name of class to run: ' + classToRunName);
	        Type classType = Type.forName(classToRunName);
	        
	        if(classType != null) {	        	
	        	Object classInstance = classType.newInstance();
	        	
	        	//The objects we create dynamically need to implement the TDTM_Runnable interface
	        	if(classInstance instanceof TDTM_Runnable) {
			        TDTM_Runnable classToRun = (TDTM_Runnable)classInstance;
			        Boolean async = Boolean.valueOf(classToRunRecord.get('Asynchronous__c'));
			        String action = String.valueOf(classToRunRecord.get('Trigger_Action__c'));
			        			        
			        if(!async) {
                        System.debug('****Running Sync: ' + classToRunName); 
                        return classToRun.run(newlist, oldlist, thisAction, obj);
			             
			        } else if(async && action != 'BeforeInsert') {
			        	System.debug('****Running Async: ' + classToRunName);
			        	runAsync(classToRun, classToRunName);
			        
			        //A class can only run asynchronously (calling a future) if we have the ids of the
                    //records we want to affect. This means we can only run it for after in insert
			        } else if(async && action == 'BeforeInsert') {
			        	System.debug('****Cannot run the class aynchronously on beforeinsert.');
			        	System.debug('********Running Sync: ' + classToRunName);
			        	return classToRun.run(newlist, oldlist, thisAction, obj);
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
    
    private static void runAsync(TDTM_Runnable classToRun, String classToRunName) {       
       Map<Id,Sobject> nm = new Map<Id,Sobject>(newlist);
       Map<Id,Sobject> om = new Map<Id,Sobject>(oldlist);
       classToRun.runFuture(nm.keySet(), om.keySet(), thisAction.name(), obj.getName());
    }
    
    public class DmlWrapper {
        public List<SObject> objectsToInsert = new List<SObject>(); 
        public Map<Id, SObject> objectsToUpdate = new Map<Id, SObject>();
        public Map<Id, SObject> objectsToDelete = new Map<Id, SObject>();
    }
}