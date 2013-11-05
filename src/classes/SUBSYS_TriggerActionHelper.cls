public with sharing class SUBSYS_TriggerActionHelper {

    public enum SUBSYS_TriggerAction {
        
        BeforeInsert, 
        BeforeUpdate, 
        BeforeDelete, 
        AfterUndelete, 
        AfterInsert, 
        AfterUpdate, 
        AfterDelete
    }
    
    public static SUBSYS_TriggerAction determineTriggerAction(Boolean isBefore, Boolean isAfter, Boolean isInsert,
    Boolean isUpdate, Boolean isDelete, Boolean isUnDelete) {
        if (isBefore) {
            if (isInsert) return SUBSYS_TriggerAction.BeforeInsert;
            else if (isUpdate) return SUBSYS_TriggerAction.BeforeUpdate;
            else return SUBSYS_TriggerAction.BeforeDelete;
        } else {
            if (isInsert) return SUBSYS_TriggerAction.AfterInsert;
            else if (isUpdate) return SUBSYS_TriggerAction.AfterUpdate;
            else if (isDelete) return SUBSYS_TriggerAction.AfterDelete;
            else return SUBSYS_TriggerAction.AfterUndelete;
        }
    }
    
    /** Static methods for triggers to invoke settings **/
    public static SUBSYS_TriggerAction getTriggerActionFromName(String name){
        SUBSYS_TriggerAction ta;
    
        if (name == SUBSYS_TriggerAction.BeforeInsert.name())
           ta = SUBSYS_TriggerAction.BeforeInsert;
        else if(name == SUBSYS_TriggerAction.BeforeUpdate.name())
           ta = SUBSYS_TriggerAction.BeforeUpdate;
        else if(name == SUBSYS_TriggerAction.BeforeDelete.name())
           ta = SUBSYS_TriggerAction.BeforeDelete;
        else if(name == SUBSYS_TriggerAction.AfterInsert.name())
           ta = SUBSYS_TriggerAction.AfterInsert;
        else if(name == SUBSYS_TriggerAction.AfterUpdate.name())
           ta = SUBSYS_TriggerAction.AfterUpdate;
        else if(name == SUBSYS_TriggerAction.AfterDelete.name())
           ta = SUBSYS_TriggerAction.AfterDelete;
        else if(name == SUBSYS_TriggerAction.AfterUndelete.name())
           ta = SUBSYS_TriggerAction.AfterUndelete;
        return ta;
    }
}