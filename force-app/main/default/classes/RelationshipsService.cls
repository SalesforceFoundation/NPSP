public with sharing class RelationshipsService {

    private static RelationshipsService instance;

    public static RelationshipsService getInstance() {
        if(instance == null) {
            instance = new RelationshipsService();
        }
        return instance;
    }

    @TestVisible
    private RelationshipSelector selector {
        get {
            if (selector == null) {
                selector = new RelationshipSelector();
            }
            return selector;
        }
        set;
    }

    public List<npe4__Relationship__c> getContactRelations(Id contactId) {
        return selector.getContactRelations(contactId);
    }

    public String getVFPageURL() {
        return Page.REL_RelationshipsViewer.getUrl();
    }

    public Map<String, String> getListUILabels() {
        return new Map<String, String>();
    }
}