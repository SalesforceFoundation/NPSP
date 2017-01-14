public with sharing class CON_CascadeDeleteLookups_TDTM extends UTIL_CascadeDeleteLookups_TDTM {
    
    private static List<Cascade> cascades = new List<Cascade>{
        new Cascade('Opportunity','Primary_Contact__c', new List<String>{'IsWon','IsClosed','AccountId'}),
        new Cascade('npe03__Recurring_Donation__c', 'npe03__Contact__c'),
        new Cascade('npe4__Relationship__c', 'npe4__ReciprocalRelationship__r.npe4__Contact__c')
    };
    
    public override List<Cascade> getCascades() {
        return cascades;
    }

    public override void addDeletionErrors() {
        for (Cascade cc : getCascades()) {
            //special case deleting opportunities
            if (cc.objectName == 'Opportunity') {
                
                for (SObject child : cc.children.values()) {
                    Id parentId = cc.childToParent.get(child.id);
                    Id oppAccount = (Id)child.get('AccountId');
                    Id conAccount = (Id)cc.parents.get(parentId).get('AccountId');
                    
                    //contacts deleting opps: verify opp attribution is contact's hh account
                    if (oppAccount != conAccount) {
                        putError(cc, child.id, Label.OrganizationalOpportunities);
                    }
                    //don't cascade closed/won opportunities
                    if ((Boolean)child.get('IsClosed') && (Boolean)child.get('IsWon')) {
                        putError(cc, child.id, Label.ClosedWonOpportunities);
                    }
                }
            }
        }
    }
}