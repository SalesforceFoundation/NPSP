public class OPP_OpportunityNaming_TDTM extends TDTM_Runnable {

    public override DmlWrapper run(List<SObject> newlist, List<SObject> oldlist, 
        TDTM_Runnable.Action triggerAction, Schema.DescribeSObjectResult objResult) {

        DmlWrapper dmlWrapper = new DmlWrapper();

        list<Opportunity> oppsForUpdate = OPP_OpportunityNaming.getOppNamesAfterInsert((list<Opportunity>) newlist);
        dmlWrapper.objectsToUpdate.addAll((list<sObject>)oppsForUpdate);

        return dmlWrapper;
    }

}