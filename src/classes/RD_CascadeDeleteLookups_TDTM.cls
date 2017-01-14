public with sharing class RD_CascadeDeleteLookups_TDTM extends UTIL_CascadeDeleteLookups_TDTM {
    private static List<Cascade> cascades = new List<Cascade>{
        new Cascade('Opportunity','npe03__Recurring_Donation__c', new List<String>{'IsWon','IsClosed'}),
        new Cascade(UTIL_Namespace.StrTokenNSPrefix('Allocation__c'),'Recurring_Donation__c')
    };
    
    public override List<Cascade> getCascades() {
        return cascades;
    }

    public override void addDeletionErrors() {
        for (Cascade cc : getCascades()) {
            //special case deleting opportunities
            if (cc.objectName == 'Opportunity') {
                for (SObject child : cc.children.values()) {
                    //don't cascade closed/won opportunities
                    if ((Boolean)child.get('IsClosed') && (Boolean)child.get('IsWon')) {
                        putError(cc, child.id, Label.ClosedWonOpportunities);
                    }
                }
            }
        }
    }
}