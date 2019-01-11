/*
    Copyright (c) 2012, Salesforce.org
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
* @date 2012 
* @group Relationships
* @description Controller for Relationships viewer VF page 
*/
global with sharing class REL_RelationshipsViewer_CTRL{

    public Boolean showPermissionError {get; set;}

    private static List<String> contactFields = new List<String> {
        'LastName',
        'FirstName',
        'Id',
        'Title',
        'Account.Name'
    };

    private static List<String> relationshipFields = new List<String> {
        'Id',
        'npe4__Contact__c',
        'toLabel(npe4__Type__c)',
        'npe4__RelatedContact__r.FirstName',
        'npe4__RelatedContact__r.LastName',
        'npe4__Status__c',
        'npe4__RelatedContact__r.Id',
        'npe4__RelatedContact__r.Account.Name',
        'npe4__RelatedContact__r.Title',
        'npe4__ReciprocalRelationship__r.Id'
    };

    /*******************************************************************************************************
    * @description constructor.
    * @param isDryRun ApexPages Standard controller.
    */
    public REL_RelationshipsViewer_CTRL(ApexPages.StandardController controller) {
        showNoAccess();
    }

    /*******************************************************************************************************
    * @description Sets the flag and error message if the current user does not have permission on the
    * objects (Contact, Relationship) or fields used by the viewer.
    * @return PageReference to the current page.
    */
    private PageReference showNoAccess() {
        List<String> blockingSObjects = new List<String>();

        // Check whether the user has permission to read the Contact object without throwing an exception if not
        if (!UTIL_Permissions.canRead('Contact', false)) {
            blockingSObjects.add(UTIL_Describe.getObjectLabel('Contact'));
        }

        // Check whether the user has permission to read the Relationship object without throwing an exception if not
        if (!UTIL_Permissions.canRead('npe4__Relationship__c', false)) {
            blockingSObjects.add(UTIL_Describe.getObjectLabel('npe4__Relationship__c'));
        }

        String flsErrorMessage = null;
        if(!blockingSObjects.isEmpty()) {
            flsErrorMessage = String.format(Label.flsError, new List<String> {String.join(blockingSObjects, ', ')});
        } else {

            // We should check object fields and not their relationships.
            List<String> contactFieldsToCheck = new List<String> {
                'LastName',
                'FirstName',
                'Id',
                'Title'
            };

            List<String> relationshipFieldsToCheck = new List<String> {
                'Id',
                'npe4__Contact__c',
                'npe4__Type__c',
                'npe4__Status__c',
                'npe4__ReciprocalRelationship__c',
                'npe4__RelatedContact__c'
            };

            List<String> accountFieldsToCheck = new List<String>{
                'Name'
            };

            Map<String, List<String>> fieldNamesBySObjectNameForSOQL = new Map<String, List<String>> {
                'Contact' => contactFieldsToCheck,                
                'npe4__Relationship__c' => relationshipFieldsToCheck,
                'Account' => accountFieldsToCheck
            };
            // check access on all the soql fields
            for(String objName: fieldNamesBySObjectNameForSOQL.keySet()) {
                try {
                    // Thorws an exception if the user do not have permission for a given field.
                    checkFieldPermissionsForAnObject(objName, fieldNamesBySObjectNameForSOQL);                    
                } catch (Exception e) {
                    flsErrorMessage = String.format(Label.flsError, 
                        new List<String> {objName+': '+String.join(fieldNamesBySObjectNameForSOQL.get(objName), ', ')});
                }
            }
        }

        if(flsErrorMessage != null) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL,flsErrorMessage));
            showPermissionError = true;
        }

        return null;
    }

    private void checkFieldPermissionsForAnObject(String objName, Map<String, List<String>> fieldNamesBySObjectNameForSOQL) {
        List<String> fieldNames = fieldNamesBySObjectNameForSOQL.get(objName);
        for (String currentFieldName : fieldNames) {
            UTIL_Permissions.canRead(objName, currentFieldName, true);
        }
    }

    /*******************************************************************************************************
    * @description constructs the soql String to run a Data Import process with or without a Batch.
    * @param contactId the Id of the Contact
    * @param isInitialLoad Boolean stating if the base node info has been retrieved.
    * @param relIds a List of Relationship Ids.
    * @return List containing the Nodes.
    */
    @RemoteAction
    global static List<Node> getRelationships(Id contactId, Boolean isInitialLoad, List<String> relIds) {
        List<Node> nodes = new List<Node>();
        List<npe4__Relationship__c> relationships = new List<npe4__Relationship__c>();

        contactId = String.escapeSingleQuotes(contactId);

        List<Id> renderedRelationships;
        if (relIds != null) {
            renderedRelationships = (List<Id>)relIds;
        } else {
            renderedRelationships = new List<Id>();
        }

        if (isInitialLoad) {
            //base node
            Node basenode = new Node();

            String contactQuery = 'SELECT '+String.join(contactFields, ', ')+
                ' FROM Contact WHERE Id = \''+contactId+'\' LIMIT 1';

            List<Contact> contacts = Database.query(contactQuery);
            Contact primaryContact = null;
            if(!contacts.isEmpty()) {
                primaryContact = (Contact)Database.query(contactQuery).get(0);
            }

            basenode.lastName = primaryContact.LastName;
            basenode.firstName = primaryContact.FirstName;
            basenode.title = primaryContact.Title;
            basenode.accountName = primaryContact.Account.Name;
            basenode.id = primaryContact.Id;
            nodes.add(basenode);
        } else {
            relationships.clear();
            nodes.clear();
        }

        String relationshipQuery = 'SELECT '+String.join(relationshipFields, ', ')+
            ' FROM npe4__Relationship__c WHERE npe4__Contact__c = \''+contactId+'\'';
        
        if(!renderedRelationships.isEmpty()) {
            relationshipQuery += ' AND Id NOT IN :renderedRelationships'+
            ' AND npe4__ReciprocalRelationship__r.Id NOT IN :renderedRelationships'; 
        }

        relationships = Database.query(relationshipQuery);

        for(npe4__Relationship__c currentRelationship : relationships) {

            Node n = new Node();
            n.lastName = currentRelationship.npe4__RelatedContact__r.LastName;
            n.id = currentRelationship.npe4__RelatedContact__r.Id;
            n.type = currentRelationship.npe4__Type__c;
            n.status = currentRelationship.npe4__Status__c;
            n.firstName = currentRelationship.npe4__RelatedContact__r.FirstName;
            n.link =  URL.getSalesforceBaseUrl().toExternalForm() + '/' + currentRelationship.npe4__RelatedContact__r.Id;
            n.accountName = currentRelationship.npe4__RelatedContact__r.Account.Name;
            n.title = currentRelationship.npe4__RelatedContact__r.Title;
            n.relId = currentRelationship.Id;
            nodes.add(n);
        }
        return nodes;
    }

    /*******************************************************************************************************
    * @description get Relationship object prefix for links
    * @return a new RelationshipInfo object.
    */
    @RemoteAction
    global static RelationshipInfo getRelationshipInfo() {
        return new RelationshipInfo();
    }


    global class RelationshipInfo {
        String prefix;
        String nameField;
        String nameIdField;

        /*******************************************************************************************************
        * @description constructor.
        */
        public RelationshipInfo() {
            npe4__Relationship_Settings__c rs = UTIL_CustomSettingsFacade.getRelationshipSettings();

            this.prefix = npe4__Relationship__c.sObjectType.getDescribe().getKeyPrefix();
            if (rs.npe4__Relationship_Name_Field_Id__c != null) {
                this.nameField = rs.npe4__Relationship_Name_Field_Id__c;
            }
            if (rs.npe4__Relationship_Name_Id_Field_Id__c != null) {
                this.nameIdField = rs.npe4__Relationship_Name_Id_Field_Id__c;
            }
        }
    }

    global class Node {
        public String firstName;
        public String lastName;
        public String id;
        public String status;
        public String type;
        public String link;
        public String accountName;
        public String title;
        public String relId;
    }  
    
}