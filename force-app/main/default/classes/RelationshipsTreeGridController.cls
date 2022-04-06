/*
    Copyright (c) 2021 Salesforce.org
    All rights reserved.

    Redistribution and use in source and binary forms, with or without
    modification, are permitted provided that the following conditions are met:

    * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution.
    * Neither the name of Salesforce.org nor the names of
      its contributors may be used to endorse or promote products derived
      from this software without specific prior written permission.

    THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
    "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
    LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
    FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE
    COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
    INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
    BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
    LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
    CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
    LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN
    ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
    POSSIBILITY OF SUCH DAMAGE.
*/
/**
* @author Salesforce.org
* @date 2021
* @description Controller class for RelationshipsTreeGrid LWC
*/
public with sharing class RelationshipsTreeGridController {

    @AuraEnabled(Cacheable=true)
    public static RelationshipsListView getInitialView(Id contactId) {
        RelationshipsService service = RelationshipsService.getInstance();

        List<RelationshipView> relationships = getRelationshipsWithAccessCheck(contactId);
        RelationshipsListView initialView = new RelationshipsListView(relationships);
        initialView.vfPageURL = service.getVFPageURL();
        initialView.labels = service.getListUILabels();
        initialView.showCreateRelationshipButton = service.canCreateRelationship();

        return initialView;
    }

    @AuraEnabled(Cacheable=true)
    public static List<RelationshipView> getRelationships(Id contactId) {
        return getRelationshipsWithAccessCheck(contactId);
    }

    private static List<RelationshipView> getRelationshipsWithAccessCheck(Id contactId) {
        RelationshipsService service = RelationshipsService.getInstance();
        if (service.hasListViewRequiredPerms()) {
            try {
                List<npe4__Relationship__c> relationships = service.getContactRelations(contactId);
                List<RelationshipView> listView = mapRelationshipListToViews(relationships);

                return listView;
            } catch (Exception ex) {
                throw new AuraHandledException(ex.getMessage());
            }
        } else {
            AuraHandledException ex = new AuraHandledException(Label.commonInsufficientPermissions);
            ex.setMessage(Label.commonInsufficientPermissions);
            throw ex;
        }
    }

    private static List<RelationshipView> mapRelationshipListToViews(List<npe4__Relationship__c> relationships) {
        List<RelationshipView> relations = new List<RelationshipView>();
        for (npe4__Relationship__c relationship : relationships) {
            relations.add(new RelationshipView(relationship));
        }
        return relations;
    }


    public class RelationshipsListView {
        @AuraEnabled public String vfPageURL;
        @AuraEnabled public Map<String, String> labels;
        @AuraEnabled public List<RelationshipView> relations;
        @AuraEnabled public Boolean showCreateRelationshipButton;

        public RelationshipsListView(List<RelationshipView> relationshipViews) {
            this.relations = relationshipViews;
        }
    }

    public class RelationshipView {
        @AuraEnabled public Id relationshipId;
        @AuraEnabled public Id contactId;
        @AuraEnabled public String contactName;
        @AuraEnabled public String relationshipExplanation;
        @AuraEnabled public String title;
        @AuraEnabled public String accountName;

        public RelationshipView(npe4__Relationship__c relationship) {
            this.relationshipId = relationship.Id;
            this.contactId = relationship.npe4__RelatedContact__c;
            this.contactName = relationship.npe4__RelatedContact__r.Name;
            this.title = relationship.npe4__RelatedContact__r.Title;
            this.accountName = relationship.npe4__RelatedContact__r.Account.Name;
            this.relationshipExplanation = relationship.npe4__Relationship_Explanation__c;
        }
    }
}