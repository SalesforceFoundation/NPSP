public with sharing class RelationshipSelector {

    public List<npe4__Relationship__c> getContactRelations(Id contactId) {
        return [
                SELECT Id,
                        npe4__Relationship_Explanation__c,
                        npe4__RelatedContact__c,
                        toLabel(npe4__Type__c),
                        npe4__RelatedContact__r.Account.Name,
                        npe4__RelatedContact__r.Name,
                        npe4__RelatedContact__r.Title
                FROM npe4__Relationship__c
                WHERE npe4__Contact__c = :contactId
                WITH SECURITY_ENFORCED
        ];
    }
}