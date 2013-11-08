public with sharing abstract class TDTM_aTriggerHandler {

    protected List<Sobject> newlist;
    protected List<Sobject> oldlist; 
    protected TDTM_TriggerActionHelper.Action thisAction;
    protected Schema.DescribeSobjectResult obj;
    
    public void initializeHandler(Boolean isBefore, Boolean isAfter, Boolean isInsert, Boolean isUpdate,
    Boolean isDelete, Boolean isUnDelete, List<Sobject> newlistfromtrigger, List<Sobject>oldlistFromTrigger, 
    Schema.DescribeSobjectResult describeobj) {
        
        newlist = newlistfromtrigger;
        oldlist = oldlistfromtrigger;

        thisAction = TDTM_TriggerActionHelper.determineTriggerAction(isBefore, isAfter, isInsert, isUpdate,
                                                                        isDelete, isUnDelete);

        obj = describeobj;
    }
    
    public class ClassToCallWrapper implements Comparable {

        public final SObject classToCall;
        public ClassToCallWrapper(SObject classToCall){ 
        	System.debug('****Class to call in wrapper constructor: ' + classToCall);
        	this.classToCall = classToCall; 
        }
    
        public Integer compareTo(Object compareTo) {
            // Cast argument to OpportunityWrapper
            ClassToCallWrapper compareToSSM = (ClassToCallWrapper)compareTo;
            
            Integer LoadOrderThis = Integer.valueOf(classToCall.get('Load_Order__c'));
            Integer LoadOrderThat = Integer.valueOf(compareToSSM.classToCall.get('Load_Order__c'));
                        
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