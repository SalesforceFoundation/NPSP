public with sharing class TriggerContext {

    public List<SObject> records;
    public List<SObject> existingRecords;
    private Boolean isBefore = false;
    private Boolean isAfter = false;
    private Boolean isInsert = false;
    private Boolean isUpdate = false;
    private Boolean isDelete = false;
    private Boolean isUndelete = false;
    public DescribeSObjectResult describeObj;

    public TriggerContext(
            Boolean isBefore,
            Boolean isAfter,
            Boolean isInsert,
            Boolean isUpdate,
            Boolean isDelete,
            Boolean isUndelete,
            List<SObject> newList,
            List<SObject> oldList,
            DescribeSObjectResult describeSObjResult) {
        this.isBefore = isBefore;
        this.isAfter = isAfter;
        this.isInsert = isInsert;
        this.isUpdate = isUpdate;
        this.isDelete = isDelete;
        this.isUndelete = isUndelete;
        this.records = newList;
        this.existingRecords = oldList;
        this.describeObj = describeSObjResult;
    }

    public Boolean isBefore() {
        return isBefore;
    }

    public TDTM_Runnable.Action action(){
        return determineTriggerAction(isBefore
                , isInsert, isUpdate, isDelete);
    }

    /*******************************************************************************************************
    * @description Determines which TDTM action applies, based on the trigger environment.
    * @param isBefore Are we in a before trigger context.
    * @param isInsert Are we in an insert trigger context.
    * @param isUpdate Are we in an update trigger context.
    * @param isDelete Are we in a delete trigger context.
    * @param isUndelete Are we in an undelete trigger context.
    * @return TDTM_Runnable.Action The applicable action, based on the trigger environment.
    */
    private static TDTM_Runnable.Action determineTriggerAction(
            Boolean isBefore,
            Boolean isInsert,
            Boolean isUpdate,
            Boolean isDelete) {
        if (isBefore) {
            if (isInsert) return TDTM_Runnable.Action.BeforeInsert;
            else if (isUpdate) return TDTM_Runnable.Action.BeforeUpdate;
            else return TDTM_Runnable.Action.BeforeDelete;
        } else {
            if (isInsert) return TDTM_Runnable.Action.AfterInsert;
            else if (isUpdate) return TDTM_Runnable.Action.AfterUpdate;
            else if (isDelete) return TDTM_Runnable.Action.AfterDelete;
            else return TDTM_Runnable.Action.AfterUndelete;
        }
    }
}