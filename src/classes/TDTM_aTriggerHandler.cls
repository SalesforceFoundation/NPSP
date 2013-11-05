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
    
    public class SubmoduleWrapper implements Comparable {

        public final SObject classToCall;
        public SubmoduleWrapper(SObject classToCall){ classToCall = classToCall; }
    
        public Integer compareTo(Object compareTo) {
            // Cast argument to OpportunityWrapper
            SubmoduleWrapper compareToSSM = (SubmoduleWrapper)compareTo;
            
            Integer LoadOrderThis = Integer.valueOf(classToCall.get('Load_Order__c'));
            Integer LoadOrderThat = Integer.valueOf(compareToSSM.classToCall.get('Load_Order__c'));
                        
            // The return value of 0 indicates that both elements are equal
            if (LoadOrderThis > LoadOrderThat) return -1;
            else if (LoadOrderThis < LoadOrderThat) return 1;
            return 0;       
        }
    }
}