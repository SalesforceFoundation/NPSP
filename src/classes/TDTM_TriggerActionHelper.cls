public with sharing class TDTM_TriggerActionHelper {

    public enum Action {   
        BeforeInsert, 
        BeforeUpdate, 
        BeforeDelete, 
        AfterInsert, 
        AfterUpdate, 
        AfterDelete,
        AfterUndelete
    }
    
    public static Action determineTriggerAction(Boolean isBefore, Boolean isAfter, Boolean isInsert,
    Boolean isUpdate, Boolean isDelete, Boolean isUnDelete) {
        if (isBefore) {
            if (isInsert) return Action.BeforeInsert;
            else if (isUpdate) return Action.BeforeUpdate;
            else return Action.BeforeDelete;
        } else {
            if (isInsert) return Action.AfterInsert;
            else if (isUpdate) return Action.AfterUpdate;
            else if (isDelete) return Action.AfterDelete;
            else return Action.AfterUndelete;
        }
    }
    
    public static Action getTriggerActionFromName(String name){
        Action ta;
    
        if (name == Action.BeforeInsert.name())
           ta = Action.BeforeInsert;
        else if(name == Action.BeforeUpdate.name())
           ta = Action.BeforeUpdate;
        else if(name == Action.BeforeDelete.name())
           ta = Action.BeforeDelete;
        else if(name == Action.AfterInsert.name())
           ta = Action.AfterInsert;
        else if(name == Action.AfterUpdate.name())
           ta = Action.AfterUpdate;
        else if(name == Action.AfterDelete.name())
           ta = Action.AfterDelete;
        else if(name == Action.AfterUndelete.name())
           ta = Action.AfterUndelete;
        return ta;
    }
}