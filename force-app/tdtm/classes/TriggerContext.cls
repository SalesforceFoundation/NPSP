public with sharing class TriggerContext {

    public List<SObject> records;
    public List<SObject> existingRecords;
    private Boolean isBefore = false;
    private Boolean isAfter = false;
    private Boolean isInsert = false;
    private Boolean isUpdate = false;
    private Boolean isDelete = false;
    private Boolean isUndelete = false;
    private SObjectType sObjType;

    public TriggerContext(
            Boolean isBefore,
            Boolean isAfter,
            Boolean isInsert,
            Boolean isUpdate,
            Boolean isDelete,
            Boolean isUndelete,
            List<SObject> newList,
            List<SObject> oldList,
            SObjectType sObjType) {
        this.isBefore = isBefore;
        this.isAfter = isAfter;
        this.isInsert = isInsert;
        this.isUpdate = isUpdate;
        this.isDelete = isDelete;
        this.isUndelete = isUndelete;
        this.records = newList;
        this.existingRecords = oldList;
        this.sObjType = sObjType;
    }

    public Boolean isBefore() {
        return isBefore;
    }

    public TDTM_Runnable.Action action() {
        return determineTriggerAction(
                isBefore,
                isInsert,
                isUpdate,
                isDelete
        );
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

    /*******************************************************************************************************
    * @description a cache of SObject maps for each object type, used by FixupOldList()
    */
    private Map<Schema.DescribeSobjectResult, Map<Id, SObject>> mapDescObjToMapOldForUpdates =
            new Map<Schema.DescribeSobjectResult, Map<Id, SObject>>();

    /*******************************************************************************************************
    * @description Creates the correct old list of objects for the trigger, for the current context.  By
    * caching the newList in all After triggers, it can provide the correct oldList in BeforeUpdate and
    * AfterUpdate, that the system will incorrectly peg to the original execution context, rather than what
    * state those objects are already in from preceding DML in the execution context.  Specifically, works
    * around the issue that a workflow rule that runs after any of our inserts or update to objects, will
    * contain the original state of those objects, rather than the current state.  This is a known system
    * 'by design' feature that prevents our triggers from doing the right thing.
    *
    * @param describeObj the describe for the SObject
    * @return list<SObject> the correct oldList for the current trigger
    */
    public void fixupOldList() {

        // return cached objects if we have them
        if (action() == TDTM_Runnable.Action.AfterUpdate
                || action() == TDTM_Runnable.Action.BeforeUpdate) {
            List<SObject> listSObj = new List<SObject>();
            Map<Id, SObject> mapIdToSObj = mapDescObjToMapOldForUpdates.get(
                    UTIL_Describe.getObjectDescribe(sObjType)
            );
            if (mapIdToSObj != null) {

                for (SObject sobj : existingRecords) {
                    SObject sobjCached = mapIdToSObj.get(sobj.Id);
                    if (sobjCached != null) {
                        listSObj.add(sobjCached);
                    } else {
                        listSObj.add(sobj);
                    }
                }

                // update existingRecords with the correct cached state of the objects
                existingRecords = listSObj;
                //UTIL_Debug.debug(LoggingLevel.WARN, '**** fixup existingRecords to : ' + existingRecords);
            } else {
                //UTIL_Debug.debug(LoggingLevel.WARN, '**** fixup not done since mapIdToSobj was null. mapDescObjToMapOldForUpdates:  ' + mapDescObjToMapOldForUpdates);
            }
        }

        // now cache objects for future Update calls
        if (action() == TDTM_Runnable.Action.AfterInsert
                || action() == TDTM_Runnable.Action.AfterUpdate) {
            mapDescObjToMapOldForUpdates.put(
                    UTIL_Describe.getObjectDescribe(sObjType),
                    new Map<Id, SObject>(records)
            );
            //UTIL_Debug.debug(LoggingLevel.WARN, '**** cached records: ' + records);
        }
    }

    public SObjectType getSObjectType() {
        return sObjType;
    }
}