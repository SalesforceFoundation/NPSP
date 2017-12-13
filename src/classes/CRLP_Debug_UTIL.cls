/**
* ====================================
* TODO REMOVE THIS CLASS EVENTUALLY
* ====================================
* TEMPORARY STATIC VALUE AND METHODS TO HOLD CURRENT STATE TO USE FOR ROLLUP DEBUGGING
*/
public class CRLP_Debug_UTIL {

    private static List<String> currentRollupState = new List<String>();

    public static void clearCurrentRollupState() {
        currentRollupState.clear();
    }

    public static void setCurrentRollupState(String state) {
        currentRollupState.add(state);
    }

    public static void amendLastCurrentRollupState(String state) {
        String lastStateVal = currentRollupState[currentRollupState.size()-1];
        currentRollupState[currentRollupState.size()-1] = lastStateVal + ' ' + state;
    }

    public static void setCurrentRollupState(String state, CRLP_Rollup rollup) {
        String rollupData = '';
        for (Rollup__mdt rcmt : rollup.rollupsMdt) {
            rollupData += rcmt.DeveloperName + '-' + rcmt.Operation__c + ';';
        }
        currentRollupState.add(state + ' ==> Rollup(' + rollupData.removeEnd(';') + ')');
    }

    public static String getCurrentRollupState() {
        String val = '';
        for (Integer n=currentRollupState.size()-1; n>=0; n--) {
            if (!currentRollupState[n].startsWith(' ')) {
                val += '* ' + currentRollupState[n] + '\n';
            } else {
                val += '  ' + currentRollupState[n] + '\n';
            }
        }
        return val;
    }

    public static String getRollupCurrentValues(CRLP_Rollup r) {
        return '==================================' +
                '\n* # of MDT records=' + r.rollupsMdt.size() +
                '\n* resultFieldName=' + r.resultFieldName + '/' + r.resultFieldType +
                '\n* yearlyOperation=' + r.yearlyOperation +
                '\n* theCount=' + r.theCount +
                '\n* theSum=' + r.theSum +
                '\n* minvalue=' + r.minValue +
                '\n* maxValue=' + r.maxValue +
                '\n* minDate=' + r.minDate +
                '\n* maxDate=' + r.maxDate +
                '\n* minDateTime=' + r.minDateTime +
                '\n* maxDateTime=' + r.maxDateTime +
                '\n* minByYear=' + JSON.serialize(r.minByYear) +
                '\n* maxByYear=' + JSON.serialize(r.maxByYear) +
                '\n* sumByYear=' + JSON.serialize(r.sumByYear) +
                '\n* countByYear=' + JSON.serialize(r.countByYear) +
                '\n* textValue=' + JSON.serialize(r.textValue) +
                '\n* numValue=' + JSON.serialize(r.numValue) +
                '\n* idValue=' + JSON.serialize(r.idValue) +
                '\n==================================';
    }

}