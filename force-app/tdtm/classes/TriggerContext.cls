public with sharing class TriggerContext {

    private TDTM_Runnable.Action thisAction;

    public TriggerContext(TDTM_Runnable.Action triggerAction){
        this.thisAction = triggerAction;
    }

    public Boolean isBefore() {
        Boolean isBefore = (thisAction == TDTM_Runnable.Action.BeforeInsert ||
                thisAction == TDTM_Runnable.Action.BeforeUpdate || thisAction == TDTM_Runnable.Action.BeforeDelete);
        return isBefore;
    }
}