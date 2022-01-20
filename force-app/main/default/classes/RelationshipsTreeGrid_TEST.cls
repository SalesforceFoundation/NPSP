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

    @IsTest
    static void whenNoRelationsFoundReturnsEmptyList() {
        Id fakeContactId = UTIL_UnitTestData_TEST.mockId(Contact.SObjectType);
        RelationshipsService.getInstance().selector = (RelationshipSelector) Test.createStub(RelationshipSelector.class, new RelationshipsSelectorStub());
        RelationshipsTreeGridController.RelationshipsListView listView = RelationshipsTreeGridController.getInitialView(fakeContactId);
        System.assertEquals(0, listView.relations.size());
    }

    @IsTest
    static void whenOneRelationReturnsSingleItem() {
        Id fakeContactId = UTIL_UnitTestData_TEST.mockId(Contact.SObjectType);
        RelationshipsSelectorStub selectorStub = new RelationshipsSelectorStub();
        RelationshipsService.getInstance().selector = (RelationshipSelector) Test.createStub(selectorStub.classType, selectorStub);
        selectorStub.setSingleResult();
        RelationshipsTreeGridController.RelationshipsListView listView = RelationshipsTreeGridController.getInitialView(fakeContactId);
        System.assertEquals(1, listView.relations.size());
    }

    @IsTest
    static void canRetrieveAdditionalRelations() {
        Id fakeContactId = UTIL_UnitTestData_TEST.mockId(Contact.SObjectType);
        RelationshipsSelectorStub selectorStub = new RelationshipsSelectorStub();
        RelationshipsService.getInstance().selector = (RelationshipSelector) Test.createStub(selectorStub.classType, selectorStub);
        selectorStub.setSingleResult();
        List<RelationshipsTreeGridController.RelationshipView> relations = RelationshipsTreeGridController.getRelationships(fakeContactId);
        System.assertEquals(1, relations.size());
    }

    @IsTest
    static void initialViewThrowsExceptionWhenInsufficientPerms() {
        Id fakeContactId = UTIL_UnitTestData_TEST.mockId(Contact.SObjectType);
        RelationshipsSelectorStub selectorStub = new RelationshipsSelectorStub();
        RelationshipsService.getInstance().selector = (RelationshipSelector) Test.createStub(selectorStub.classType, selectorStub);
        RelationshipsService.getInstance().permissions = (UTIL_Permissions) Test.createStub(UTIL_Permissions.class, new UTIL_PermissionsMock(false, false));

        AuraHandledException caughtException;
        try {
            RelationshipsTreeGridController.getInitialView(fakeContactId);
        } catch (AuraHandledException ex) {
            caughtException = ex;
        }
        System.assertNotEquals(null, caughtException);
        System.assertEquals(Label.commonInsufficientPermissions, caughtException.getMessage());
    }

    @IsTest
    static void whenNoRelationshipCreateAccessHidesCreateButton() {
        Id fakeContactId = UTIL_UnitTestData_TEST.mockId(Contact.SObjectType);
        RelationshipsSelectorStub selectorStub = new RelationshipsSelectorStub();
        RelationshipsService.getInstance().selector = (RelationshipSelector) Test.createStub(selectorStub.classType, selectorStub);
        RelationshipsService.getInstance().permissions = (UTIL_Permissions) Test.createStub(UTIL_Permissions.class, new UTIL_PermissionsMock(true, false));

        RelationshipsTreeGridController.RelationshipsListView listView = RelationshipsTreeGridController.getInitialView(fakeContactId);
        System.assertEquals(false, listView.showCreateRelationshipButton);
    }

    @IsTest
    static void responseContainsVFPageURL() {
        Id fakeContactId = UTIL_UnitTestData_TEST.mockId(Contact.SObjectType);
        RelationshipsService.getInstance().selector = (RelationshipSelector) Test.createStub(RelationshipSelector.class, new RelationshipsSelectorStub());
        RelationshipsTreeGridController.RelationshipsListView listView = RelationshipsTreeGridController.getInitialView(fakeContactId);
        System.assertEquals(Page.REL_RelationshipsViewer.getUrl(), listView.vfPageURL);
    }

    @IsTest
    static void responseContainsExpectedLabels() {
        Id fakeContactId = UTIL_UnitTestData_TEST.mockId(Contact.SObjectType);
        RelationshipsService.getInstance().selector = (RelationshipSelector) Test.createStub(RelationshipSelector.class, new RelationshipsSelectorStub());
        RelationshipsTreeGridController.RelationshipsListView listView = RelationshipsTreeGridController.getInitialView(fakeContactId);
        String expectedLabel = UTIL_Describe.getFieldLabel('Contact', 'Name');
        System.assertEquals(expectedLabel, listView.labels.get('contactName'));
        System.assertNotEquals(null, listView.labels.get('relationshipExplanation'));
        System.assertNotEquals(null, listView.labels.get('title'));
        System.assertNotEquals(null, listView.labels.get('accountName'));
        System.assertNotEquals(null, listView.labels.get('relationshipsPlural'));
    }

    @IsTest
    static void mapsFieldsIntoRelationshipView() {
        Id fakeContactId = UTIL_UnitTestData_TEST.mockId(Contact.SObjectType);
        RelationshipsSelectorStub selectorStub = new RelationshipsSelectorStub();
        RelationshipsService.getInstance().selector = (RelationshipSelector) Test.createStub(selectorStub.classType, selectorStub);
        selectorStub.setSingleResult();
        RelationshipsTreeGridController.RelationshipsListView listView = RelationshipsTreeGridController.getInitialView(fakeContactId);
        RelationshipsTreeGridController.RelationshipView view = listView.relations[0];

        System.assertEquals(view.contactId, selectorStub.queryResults[0].npe4__RelatedContact__c);
        System.assertEquals(view.title, selectorStub.queryResults[0].npe4__RelatedContact__r.Title);
        System.assertEquals(view.accountName, selectorStub.queryResults[0].npe4__RelatedContact__r.Account.Name);
        System.assertEquals(view.contactName, selectorStub.queryResults[0].npe4__RelatedContact__r.Name);
        System.assertEquals(view.relationshipExplanation, selectorStub.queryResults[0].npe4__Relationship_Explanation__c);
        System.assertEquals(view.relationshipId, selectorStub.queryResults[0].Id);
    }

    @IsTest
    static void selectorCanQueryRelationships() {
        List<Contact> contacts = UTIL_UnitTestData_TEST.createAccountContactTestData(
                CAO_Constants.HH_ACCOUNT_TYPE,
                1,
                2,
                0
        );

        npe4__Relationship__c relationship = new npe4__Relationship__c(
                npe4__Contact__c = contacts[0].Id,
                npe4__RelatedContact__c = contacts[1].Id,
                npe4__Type__c = 'Sibling'
        );

        insert relationship;

        RelationshipsService service = new RelationshipsService();
        List<npe4__Relationship__c> relationships = service.getContactRelations(contacts[0].Id);
        System.assertEquals(1, relationships.size());

        // ensure that required fields are being queried, since all tests use a mock of this selector except this one
        System.assertEquals('Sibling', relationships[0].npe4__Type__c, 'Relationship type field wrong value');
        System.assertEquals(contacts[1].Id, relationships[0].npe4__RelatedContact__c, 'Related contact field wrong value');
        System.assertNotEquals(null, relationships[0].npe4__Relationship_Explanation__c, 'Missing relationship explanation field');
        System.assertNotEquals(null, relationships[0].npe4__RelatedContact__r.Name, 'Misisng related contact name field');
        System.assertNotEquals(null, relationships[0].npe4__RelatedContact__r.Account.Name, 'Missing Account Name field');
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

        public void setSingleResult() {
            Id relationshipId = UTIL_UnitTestData_TEST.mockId(npe4__Relationship__c.SObjectType);
            Id relatedContactId = UTIL_UnitTestData_TEST.mockId(Contact.SObjectType);
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


    private class UTIL_PermissionsMock implements StubProvider {

        Boolean canRead;
        Boolean canCreate;

        public UTIL_PermissionsMock(Boolean canRead, Boolean canCreate) {
            this.canCreate = canCreate;
            this.canRead = canRead;
        }

        public Object handleMethodCall(Object stubbedObject, String stubbedMethodName,
                Type returnType, List<Type> listOfParamTypes, List<String> listOfParamNames,
                List<Object> listOfArgs) {

            switch on stubbedMethodName {
                when 'canRead' {
                    return this.canRead;
                }
                when 'canCreate' {
                    return this.canCreate;
                }
            }
            return null;
        }
    }
}