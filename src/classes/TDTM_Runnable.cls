public interface TDTM_Runnable {

    void runFuture(Set<Id> newList, Set<Id> oldList, String ta, String obj);
    
    TDTM_TriggerHandler.DmlWrapper runMain(List<Sobject> newlist, List<Sobject> oldlist, 
                TDTM_TriggerActionHelper.Action ta, Schema.Describesobjectresult obj);
                
    TDTM_TriggerHandler.DmlWrapper runInProgress(List<Sobject> newlist, List<Sobject> oldlist, 
                TDTM_TriggerActionHelper.Action ta, Schema.Describesobjectresult obj);  
}