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
@IsTest
private class RelationshipsTreeGrid_TEST {

    static IDGenerator idGenerator = new IDGenerator();

    @IsTest
    static void whenNoRelationsFoundReturnsEmptyList() {
        Id fakeContactId = idGenerator.generate(Contact.SObjectType);
        RelationshipsService.getInstance().selector = (RelationshipSelector) Test.createStub(RelationshipSelector.class, new RelationshipsSelectorStub());
        RelationshipsTreeGridController.RelationshipsListView listView = RelationshipsTreeGridController.getRelationships(fakeContactId);
        System.assertEquals(0, listView.relations.size());
    }

    @IsTest
    static void whenOneRelationReturnsSingleItem() {
        Id fakeContactId = idGenerator.generate(Contact.SObjectType);
        RelationshipsSelectorStub selectorStub = new RelationshipsSelectorStub();
        RelationshipsService.getInstance().selector = (RelationshipSelector) Test.createStub(selectorStub.classType, selectorStub);
        selectorStub.setSingleResult(fakeContactId);
        RelationshipsTreeGridController.RelationshipsListView listView = RelationshipsTreeGridController.getRelationships(fakeContactId);
        System.assertEquals(1, listView.relations.size());
    }

    @IsTest
    static void throwsExceptionWhenInsufficientPerms() {

    }

    @IsTest
    static void responseContainsVFPageURL() {
        Id fakeContactId = idGenerator.generate(Contact.SObjectType);
        RelationshipsService.getInstance().selector = (RelationshipSelector) Test.createStub(RelationshipSelector.class, new RelationshipsSelectorStub());
        RelationshipsTreeGridController.RelationshipsListView listView = RelationshipsTreeGridController.getRelationships(fakeContactId);
        System.assertEquals(Page.REL_RelationshipsViewer.getUrl(), listView.vfPageURL);
    }

    @IsTest
    static void responseContainsExpectedLabels() {
        Id fakeContactId = idGenerator.generate(Contact.SObjectType);
        RelationshipsService.getInstance().selector = (RelationshipSelector) Test.createStub(RelationshipSelector.class, new RelationshipsSelectorStub());
        RelationshipsTreeGridController.RelationshipsListView listView = RelationshipsTreeGridController.getRelationships(fakeContactId);
        System.assertEquals(null, listView.labels.get('somelabel'));
    }

    @IsTest
    static void mapsFieldsIntoRelationshipView() {
        Id fakeContactId = idGenerator.generate(Contact.SObjectType);
        RelationshipsSelectorStub selectorStub = new RelationshipsSelectorStub();
        RelationshipsService.getInstance().selector = (RelationshipSelector) Test.createStub(selectorStub.classType, selectorStub);
        selectorStub.setSingleResult(fakeContactId);
        RelationshipsTreeGridController.RelationshipsListView listView = RelationshipsTreeGridController.getRelationships(fakeContactId);
        RelationshipsTreeGridController.RelationshipView view = listView.relations[0];

        System.assertEquals(view.contactId, selectorStub.queryResults[0].npe4__RelatedContact__c);
        System.assertEquals(view.title, selectorStub.queryResults[0].npe4__RelatedContact__r.Title);
        System.assertEquals(view.accountName, selectorStub.queryResults[0].npe4__RelatedContact__r.Account.Name);
        System.assertEquals(view.relationshipExplanation, selectorStub.queryResults[0].npe4__Relationship_Explanation__c);
        System.assertEquals(view.relationshipId, selectorStub.queryResults[0].Id);
    }

    static Contact generateContactWithName(String name) {
        return (Contact) JSON.deserialize('{"Name": "' + name + '"}', Contact.class);
    }

    static npe4__Relationship__c generateRelationshipWithExplanation(String explanation) {
        return (npe4__Relationship__c) JSON.deserialize(
            '{"npe4__Relationship_Explanation__c": "' + explanation + '"}',
            npe4__Relationship__c.class
        );
    }

    private class RelationshipsSelectorStub implements System.StubProvider {

        public List<npe4__Relationship__c> queryResults;

        public Type classType = RelationshipSelector.class;

        public RelationshipsSelectorStub() {
            this.setEmptyResult();
        }

        public void setEmptyResult() {
            this.queryResults = new List<npe4__Relationship__c>();
        }

        public void setSingleResult(Id contactId) {
            Id relationshipId = idGenerator.generate(npe4__Relationship__c.SObjectType);
            Id relatedContactId = idGenerator.generate(Contact.SObjectType);
            Contact relatedContact = generateContactWithName('Fake Name');
            relatedContact.Id = relatedContactId;
            relatedContact.Title = 'Fake Title';
            relatedContact.Account = new Account(Name = 'Some Household');

            npe4__Relationship__c relationship = generateRelationshipWithExplanation('Fake Name is Other Person\'s friend');
            relationship.Id = relationshipId;
            relationship.npe4__RelatedContact__c = relatedContactId;
            relationship.npe4__RelatedContact__r = relatedContact;

            this.queryResults = new List<npe4__Relationship__c>{
                    relationship
            };
        }

        public Object handleMethodCall(Object param1, String param2, Type param3, List<Type> param4, List<String> param5, List<Object> param6) {
            return this.queryResults;
        }
    }

    /**
     * Credit to fflib-apex-mocks fflib_IDGenerator
     * https://github.com/apex-enterprise-patterns/fflib-apex-mocks/blob/master/sfdx-source/apex-mocks/main/classes/fflib_IDGenerator.cls
     */
    private class IDGenerator {
        private Integer fakeIdCount = 0;
        private final String ID_PATTERN = '000000000000';


        private Id generate(Schema.SObjectType sObjectType) {
            String keyPrefix = UTIL_Describe.getObjectDescribe(sObjectType).getKeyPrefix();
            fakeIdCount++;

            String fakeIdPrefix = ID_PATTERN.substring(0, ID_PATTERN.length() - String.valueOf(fakeIdCount).length());

            return Id.valueOf(keyPrefix + fakeIdPrefix + fakeIdCount);
        }
    }
}