/**
* ====================================
* TODO REMOVE THIS CLASS EVENTUALLY
* ====================================
* TEMPORARY STATIC VALUE AND METHODS TO HOLD CURRENT STATE TO USE FOR ROLLUP DEBUGGING
*/
public class CRLP_Debug_UTIL {

    private static final Boolean isEnabled = false;

    private static List<String> currentRollupState = new List<String>();

    public static void clearCurrentRollupState() {
        if (isEnabled) {
            currentRollupState.clear();
        }
    }

    public static void setCurrentRollupState(String state) {
        if (isEnabled) {
            UTIL_Debug.debugWithInfo('===== setCurrentRollupState(' + state + ')\n');
            currentRollupState.add(state);
        }
    }

    public static void amendLastCurrentRollupState(String state) {
        if (isEnabled) {
            String lastStateVal = currentRollupState[currentRollupState.size() - 1];
            UTIL_Debug.debug('===== setCurrentRollupState(' + lastStateVal + ' ' + state + ')');
            currentRollupState[currentRollupState.size() - 1] = lastStateVal + ' ' + state;
        }
    }

    public static void setCurrentRollupState(String state, CRLP_Rollup rollup) {
        if (isEnabled) {
            String rollupData = '';
            for (CRLP_Rollup.Rollupmdt rcmt : rollup.rollupsMdt) {
                rollupData += rcmt.summaryObject + '.' + rcmt.summaryField + '-' + rcmt.operation + ';';
            }
            currentRollupState.add(state + ' ==> Rollup(' + rollupData.removeEnd(';') + ')');
        }
    }

    public static String getCurrentRollupState() {
        String val = '';
        if (isEnabled) {
            for (Integer n = currentRollupState.size() - 1; n >= 0; n--) {
                if (!currentRollupState[n].startsWith(' ')) {
                    val += '* ' + currentRollupState[n] + '\n';
                } else {
                    val += '  ' + currentRollupState[n] + '\n';
                }
            }
        }
        return val;
    }

    public static String getRollupCurrentValues(CRLP_Rollup r) {
        return (!isEnabled ? '' :
                '\n* # of MDT records=' + r.rollupsMdt.size() +
                '\n* resultFieldName=' + r.resultFieldName + '/' + r.resultFieldType +
                '\n* timeBoundOperation=' + r.timeBoundOperation +
                '\n* theCount=' + r.theCount +
                '\n* theSum=' + r.theSum +
                '\n* minDateTime=' + r.minDateTime +
                '\n* maxDateTime=' + r.maxDateTime +
                '\n* minByYear=' + JSON.serialize(r.minByYear) +
                '\n* maxByYear=' + JSON.serialize(r.maxByYear) +
                '\n* sumByYear=' + JSON.serialize(r.sumByYear) +
                '\n* countByYear=' + JSON.serialize(r.countByYear) +
                '\n* textValue=' + JSON.serialize(r.textValue) +
                '\n* numValue=' + JSON.serialize(r.numValue) +
                '\n* dateValue=' + JSON.serialize(r.dateValue) +
                '\n* dateTimeValue=' + JSON.serialize(r.dateTimeValue) +
                '\n* idValue=' + JSON.serialize(r.idValue) +
                '\n==================================' );
    }

    public static String getRollupState(List<CRLP_Rollup> rollups) {
        String theState = '';
        if (isEnabled) {
            for (CRLP_Rollup r : rollups) {
                theState += getRollupCurrentValues(r) + '\n';
            }
        }
        return theState;
    }

    /**
     * @description Simple utility method to clear out all target roll-up fields on the specified Object.
     * Works for Account, Contact, and General_Accounting_Unit__c; and should clear out all target fields on
     * all records no matter how many records there are in the system.
     * @param summObjectType Summary Object Type
     */
    public static void clearAllRollupFields(SObjectType summObjectType) {
        System.enqueueJob(new clearRollupFieldsASync(summObjectType, 0));
    }

    /**
     * @description Queueable Implementation called by clearAllRollupFields()
     */
    private class clearRollupFieldsASync implements System.Queueable {

        private SObjectType objType;
        private Integer queryOffset;
        public clearRollupFieldsASync(SObjectType summObjectType, Integer queryOffset) {
            this.objType = summObjectType;
            this.queryOffset = queryOffset;
        }

        public void execute(QueueableContext qc) {
            List<Schema.DescribeFieldResult> fldList = CRLP_Rollup_SEL.getReferencedFieldsByObject(this.objType);
            String soql = 'SELECT ' + CRLP_Rollup_SEL.getReferencedFieldsByObjectAsString(this.objType) +
                    ' FROM ' + this.objType.getDescribe().getName() +
                    ' LIMIT 1000' +
                    (this.queryOffset != 0 ? ' OFFSET ' + this.queryOffset : '');
            List<SObject> records = database.query(soql);
            for (SObject s : records) {
                for (DescribeFieldResult dfr : fldList) {
                    s.put(dfr.getSobjectField(), null);
                }
            }
            if (records.size() > 0) {
                UTIL_DMLService.updateRecordBatchAndLogErrors(records, 'UTIL');
                System.enqueueJob(new clearRollupFieldsASync(this.objType, records.size()));
            }
        }
    }
}