public interface TDTM_iTableDataGateway {

    /**
     * The list returned is already sorted by load order.
     **/ 
     List<SObject> getClassesToCallOnTriggers(String objectName, TDTM_TriggerActionHelper.Action action);
}