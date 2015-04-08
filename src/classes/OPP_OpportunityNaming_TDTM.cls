public class OPP_OpportunityNaming_TDTM extends TDTM_Runnable {
/*
trim opp name to 120 char
*/
    public static list<Opportunity_Naming_Settings__c> listOppNamingSettings = Opportunity_Naming_Settings__c.getAll().clone().values();
    DmlWrapper dmlWrapper = new DmlWrapper();

    public override DmlWrapper run(List<SObject> newlist, List<SObject> oldlist, 
        TDTM_Runnable.Action triggerAction, Schema.DescribeSObjectResult objResult) {

        list<Opportunity> newOpps = (list<Opportunity>) newlist;

        set<string> allFields = new set<string>();
 
        for (Opportunity_Naming_Settings__c ons : listOppNamingSettings) {
            allFields.addAll(OPP_OpportunityNaming.getFieldNamesFromSpec(ons.Opportunity_Name_Format__c));
        }

        list<Opportunity> oppsForUpdate = database.query(OPP_OpportunityNaming.getOppQuery(allFields) + ' WHERE Id IN :newOpps');

        system.debug('lookhere!: allFields: ' +allFields+ 'oppsForUpdate' + oppsForUpdate);

        for (Opportunity opp : oppsForUpdate) {
            for (Opportunity_Naming_Settings__c ons : listOppNamingSettings) {
                if (ons.Opportunity_Record_Types__c.contains(opp.RecordTypeId) && !string.isBlank(ons.Opportunity_Name_Format__c))
                    opp.Name = OPP_OpportunityNaming.replaceFieldNamesWithValues(opp, ons);
            }
        }

        dmlWrapper.objectsToUpdate.addAll((list<sObject>)oppsForUpdate);

        return dmlWrapper;
    }

}