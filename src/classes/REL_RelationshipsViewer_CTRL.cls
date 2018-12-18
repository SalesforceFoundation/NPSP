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

    /*******************************************************************************************************
    * @description constructor.
    * @param isDryRun ApexPages Standard controller.
    */
    public REL_RelationshipsViewer_CTRL(ApexPages.StandardController controller) {
        showNoAccess();
    }

    /*******************************************************************************************************
    * @description Sets the flag and error message if the current user does not have permission on he Contacts object.
    * @return Pagereference to the current page.
    */
    private Pagereference showNoAccess() {
        Boolean contactAccessible = Contact.sObjectType.getDescribe().isAccessible();
        Boolean relationshipAccessible = npe4__Relationship__c.sObjectType.getDescribe().isAccessible();
        List<String> blockingSObjects = new List<String>();

        if(!contactAccessible) { 
            blockingSObjects.add(UTIL_Describe.getObjectLabel('Contact'));
        }
        if(!relationshipAccessible) {
            blockingSObjects.add(UTIL_Describe.getObjectLabel('npe4__Relationship__c'));
        }
        
        if(!blockingSObjects.isEmpty()) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL,String.format(Label.flsError, 
                new List<String> {String.join(blockingSObjects, ', ')})));
            showPermissionError = true;
        }

        return null;
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

        List<Id> renderedRelationships;
        if (relIds != null) {
            renderedRelationships = (List<Id>)relIds;
        } else {
            renderedRelationships = new List<Id>();
        }

        if (isInitialLoad) {
            //base node
            Node basenode = new Node();

            Contact c = [SELECT
                            LastName,
                            FirstName,
                            Id,
                            Title,
                            Account.Name
                        FROM Contact
                        WHERE Id = :contactId];

            basenode.lastName = c.LastName;
            basenode.firstName = c.FirstName;
            basenode.title = c.Title;
            basenode.accountName = c.Account.Name;
            basenode.id = c.Id;
            nodes.add(basenode);
        } else {
            relationships.clear();
            nodes.clear();
        }

        relationships = [SELECT
                                Id,
                                npe4__RelatedContact__r.LastName,
                                toLabel(npe4__Type__c),
                                npe4__Status__c,
                                npe4__RelatedContact__r.FirstName,
                                npe4__RelatedContact__r.Id,
                                npe4__RelatedContact__r.Account.Name,
                                npe4__RelatedContact__r.Title,
                                npe4__ReciprocalRelationship__r.Id
                        FROM    npe4__Relationship__c
                        WHERE   npe4__Contact__c = :contactId AND
                                Id NOT IN :renderedRelationships AND
                                npe4__ReciprocalRelationship__r.Id NOT IN :renderedRelationships];

        for (npe4__Relationship__c currentRelationship : relationships) {
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