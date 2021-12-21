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
* @description Service class for Relationships
*/
public with sharing class RelationshipsService {

    private static RelationshipsService instance;

    public static RelationshipsService getInstance() {
        if (instance == null) {
            instance = new RelationshipsService();
        }
        return instance;
    }

    @TestVisible
    private UTIL_Permissions permissions {
        get {
            if (permissions == null) {
                permissions = UTIL_Permissions.getInstance();
            }
            return permissions;
        }
        set;
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

    public Boolean hasListViewRequiredPerms() {
        Map<Schema.SObjectType, Set<Schema.SObjectField>> requiredPerms =
                new Map<Schema.SObjectType, Set<Schema.SObjectField>> {
            Contact.SObjectType => new Set<Schema.SObjectField>{
                    Contact.Name,
                    Contact.Title
            },
            Account.SObjectType => new Set<Schema.SObjectField>{
                    Account.Name
            },
            npe4__Relationship__c.SObjectType => new Set<Schema.SObjectField>{
                    npe4__Relationship__c.npe4__Contact__c,
                    npe4__Relationship__c.npe4__Type__c,
                    npe4__Relationship__c.npe4__RelatedContact__c,
                    npe4__Relationship__c.npe4__Relationship_Explanation__c
            }
        };

        for(Schema.SObjectType sObjectType : requiredPerms.keySet()) {
            if(!permissions.canRead(sObjectType, requiredPerms.get(sObjectType))) {
                return false;
            }
        }

        return true;
    }

    public Boolean canCreateRelationship() {
        return permissions.canCreate(npe4__Relationship__c.SObjectType);
    }

    public List<npe4__Relationship__c> getContactRelations(Id contactId) {
        return selector.getContactRelations(contactId);
    }

    public String getVFPageURL() {
        return Page.REL_RelationshipsViewer.getUrl();
    }

    public Map<String, String> getListUILabels() {

        return new Map<String, String>{
                'contactName' => UTIL_Describe.getFieldLabel('Contact', 'Name'),
                'title' => UTIL_Describe.getFieldLabel('Contact', 'Title'),
                'accountName' => UTIL_Describe.getObjectLabel('Account'),
                'relationshipExplanation' => UTIL_Describe.getFieldLabel('npe4__Relationship__c', 'npe4__Relationship_Explanation__c'),
                'relationshipsPlural' => UTIL_Describe.getObjectLabelPlural('npe4__Relationship__c')
        };
    }
}