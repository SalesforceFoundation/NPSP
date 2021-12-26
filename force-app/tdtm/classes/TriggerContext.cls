public with sharing class TriggerContext {

    private TDTM_Runnable.Action thisAction;
    public List<SObject> records;
    public List<SObject> existingRecords;

    public TriggerContext(TDTM_Runnable.Action triggerAction){
        this.thisAction = triggerAction;
    }
    public TriggerContext(TDTM_Runnable.Action triggerAction, List<SObject> newList,
            List<SObject> oldList){
        this.thisAction = triggerAction;
        this.records = newList;
        this.existingRecords = oldList;
    }

    public Boolean isBefore() {
        Boolean isBefore = (thisAction == TDTM_Runnable.Action.BeforeInsert ||
                thisAction == TDTM_Runnable.Action.BeforeUpdate || thisAction == TDTM_Runnable.Action.BeforeDelete);
        return isBefore;
    }

    public TDTM_Runnable.Action action(){
        return thisAction;
    }

}