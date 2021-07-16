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
* @description Class for retrieving types (i.e. SoftCredits) from
*              an additional object JSON string.
*/
public inherited sharing class AdditionalObjectJSON {

    private BDI_DynamicSourceGroup dynamicSourceGroup;

    public AdditionalObjectJSON(String additionalObjectString) {
        if (additionalObjectString != null) {
            this.dynamicSourceGroup = (BDI_DynamicSourceGroup)
                JSON.deserialize(additionalObjectString, BDI_DynamicSourceGroup.class);
        }
    }

    public SoftCredits asSoftCredits() {
        if (dynamicSourceGroup == null) {
            return new SoftCredits(new List<OpportunityContactRole>());
        }

        String opportunityContactRole = SObjectType.OpportunityContactRole.getName();
        List<String> objectMappingNames = objectMappingNamesFor(opportunityContactRole);

        List<OpportunityContactRole> opportunityContactRoles = new List<OpportunityContactRole>();
        List<BDI_DynamicSource> ocrSourceObjects =
            collectDynamicSourceObjectsFor(opportunityContactRole, objectMappingNames);

        for (BDI_DynamicSource sourceObject : ocrSourceObjects) {
            opportunityContactRoles.add(opportunityContactRoleFrom(sourceObject));
        }

        return new SoftCredits(opportunityContactRoles);
    }

    private OpportunityContactRole opportunityContactRoleFrom(BDI_DynamicSource dynamicSource) {
        OpportunityContactRole ocr = new OpportunityContactRole();
        SObject sourceObject = dynamicSource.sourceObj;
        ocr.Role = (String) sourceObject.get(String.valueOf(DataImport__c.Opportunity_Contact_Role_1_Role__c));
        ocr.ContactId = (Id) sourceObject.get(String.valueOf(DataImport__c.Contact1Imported__c));
        return ocr;
    }

    private List<BDI_DynamicSource> collectDynamicSourceObjectsFor(
        String targetObjectApiName, List<String> objectMappingNames) {

        List<BDI_DynamicSource> sourceObjects = new List<BDI_DynamicSource>();
        for (BDI_DynamicSource dynamicSource : this.dynamicSourceGroup.dynamicSourceByObjMappingDevName.values()) {
            Boolean matchObjectMappingDeveloperNames =
                objectMappingNames.contains(dynamicSource.objectMappingTemplateDevName);
            if (matchObjectMappingDeveloperNames) {
                sourceObjects.add(dynamicSource);
            }
        }

        return sourceObjects;
    }

    private List<String> objectMappingNamesFor(String objectApiName) {
        List<Data_import_Object_Mapping__mdt> objectMappings = [
            SELECT DeveloperName
            FROM Data_Import_Object_Mapping__mdt
            WHERE Object_API_Name__c = :objectApiName
                AND Is_Deleted__c = false
        ];

        List<String> objectMappingNames = new List<String>();
        for (Data_Import_Object_Mapping__mdt objectMapping : objectMappings) {
            objectMappingNames.add(objectMapping.DeveloperName);
        }

        return objectMappingNames;
    }
}
