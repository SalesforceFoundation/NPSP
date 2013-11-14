public interface TDTM_Runnable {

    Boolean wasAlreadyCalled();
    
    void runFuture(Set<Id> newList, Set<Id> oldList, String ta, String obj);
    
    TDTM_TriggerHandler.DmlWrapper run(List<Sobject> newlist, List<Sobject> oldlist, 
                TDTM_TriggerActionHelper.Action ta, Schema.Describesobjectresult obj);
}