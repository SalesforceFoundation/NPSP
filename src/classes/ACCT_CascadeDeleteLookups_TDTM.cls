public with sharing class ACCT_CascadeDeleteLookups_TDTM extends UTIL_CascadeDeleteLookups_TDTM {
    private static List<Cascade> cascades = new List<Cascade>{
        new Cascade('npe03__Recurring_Donation__c','npe03__Organization__c'),
        new Cascade('npe03__Recurring_Donation__c','npe03__Contact__r.AccountId'),
        new Cascade(UTIL_Namespace.StrTokenNSPrefix('Allocation__c'),'Opportunity__r.AccountId'),
        new Cascade('npe4__Relationship__c', 'npe4__ReciprocalRelationship__r.npe4__Contact__r.AccountId')
    };

    public override List<Cascade> getCascades() {
        return cascades;
    }
}