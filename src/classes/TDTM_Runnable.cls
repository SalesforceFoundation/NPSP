public abstract class TDTM_Runnable {

    //It will be the duty of the run method implementation to set the fields alreadyCalledBefore and 
    //wasAlreadyCalledAfter to true. We cannot do that for them in TDTM_Handler, even if it's after 
    //calling the future, because then they might get set before the future runs (and since the future 
    //method calls the non-future method, which checks the flag, the future method would have no effect.)
    public abstract Boolean wasAlreadyCalledBefore();   
    public abstract Boolean wasAlreadyCalledAfter();
    
    //We need this method because Apex won't let us call a non-static method from a separate object instance
    public void runFutureNonStatic(Set<Id> newIds, Set<Id> oldIds, String action, String objectName, String classToRunName) {
        runFuture(newIds, oldIds, action, objectName, classToRunName);
    }
    
    @future
    public static void runFuture(Set<Id> newIds, Set<Id> oldIds, String action, String objectName, String classToRunName) {
        
        Schema.DescribeSObjectResult objResult = TDTM_TriggerActionHelper.getDescribeObjectByName(objectName);
        TDTM_TriggerActionHelper.Action triggerAction = TDTM_TriggerActionHelper.getTriggerActionFromName(action);
        
        //Get all fields for the object
        List<Schema.SObjectField> allFields = objResult.fields.getMap().values();
        
        //Getting the records the IDs refer to
        String qn = 'select ';
        for(Integer i = 0; i < allFields.size() - 1; i++) //add all fields, except last, to query
            qn += ' ' + allFields[i] + ', ';
        qn += ' ' + allFields[allFields.size() - 1]; //add last field to query
        qn += ' from ' + objectName + ' where id IN ';
        System.debug('****Query for future: ' + qn);
        List<SObject> newlist = Database.query(qn + ':newIds');
        List<SObject> oldlist = Database.query(qn + ':oldIds'); 

        //Call the non-future method
        Type classType = Type.forName(classToRunName);
        Object classInstance;         
        if(classType != null)
            classInstance = classType.newInstance();
        if(classInstance instanceof TDTM_Runnable) {
        	TDTM_Runnable runnable = (TDTM_Runnable) classInstance;
	        DmlWrapper dmlWrapper = runnable.run(newlist, oldlist, triggerAction, objResult);
	        
	        //Process the result
	        insert dmlWrapper.objectsToInsert;
	        update dmlWrapper.objectsToUpdate.values();
	        delete dmlWrapper.objectsToDelete.values();
        }
    }
    
    public abstract DmlWrapper run(List<SObject> newlist, List<SObject> oldlist, 
        TDTM_TriggerActionHelper.Action triggerAction, Schema.DescribeSObjectResult objResult);
            
    public class DmlWrapper {
        public List<SObject> objectsToInsert = new List<SObject>(); 
        public Map<Id, SObject> objectsToUpdate = new Map<Id, SObject>();
        public Map<Id, SObject> objectsToDelete = new Map<Id, SObject>();
    }
}