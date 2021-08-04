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

    @TestVisible
    private BDI_DynamicSourceGroup dynamicSourceGroup;
    private BDI_MappingServiceAdvanced mappingService;

    public AdditionalObjectJSON(String additionalObjectString) {
        mappingService = BDI_MappingServiceAdvanced.getInstance();
        if (additionalObjectString != null) {
            this.dynamicSourceGroup = (BDI_DynamicSourceGroup)
                JSON.deserialize(additionalObjectString, BDI_DynamicSourceGroup.class);
        }
    }

    public String asJSON() {
        return JSON.serialize(dynamicSourceGroup);
    }

    public void add(SoftCredits softCredits) {
        for (OpportunityContactRole softCredit : softCredits.unprocessed()) {
            BDI_DynamicSource dynamicSource = dynamicSourceFrom(softCredit);
            dynamicSourceGroup.dynamicSourceByObjMappingDevName.put(
                dynamicSource.objectMappingDevName,
                dynamicSource);
        }
    }

    private BDI_DynamicSource dynamicSourceFrom(OpportunityContactRole opportunityContactRole) {
        BDI_ObjectMapping objectMapping = objectMappingFor(SObjectType.OpportunityContactRole.getName());
        List<BDI_FieldMapping> fieldMappings =
            mappingService.fieldMappingsByObjMappingDevName.get(objectMapping.DeveloperName);
        DataImport__c tempDI = new DataImport__c();

        for (BDI_FieldMapping fieldMapping : fieldMappings) {
            Object value = opportunityContactRole.get(fieldMapping.Target_Field_API_Name);
            tempDI.put(fieldMapping.Source_Field_API_Name, value);
        }

        BDI_DynamicSource dynamicSource = new BDI_DynamicSource();
        dynamicSource.objectMappingDevName = objectMapping.DeveloperName + generateRandomString(7);
        dynamicSource.objectMappingTemplateDevName = objectMapping.DeveloperName;
        dynamicSource.fieldMappingSetDevName = mappingService.fieldMappingSetName;
        dynamicSource.sourceObj = tempDI;

        return dynamicSource;
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
        List<BDI_ObjectMapping> objectMappings = mappingService.objectMappingByDevName.values();
        List<String> objectMappingNames = new List<String>();
        for (BDI_ObjectMapping objectMapping : objectMappings) {
            if (objectMapping.Object_API_Name == objectApiName) {
                objectMappingNames.add(objectMapping.DeveloperName);
            }
        }

        return objectMappingNames;
    }

    private BDI_ObjectMapping objectMappingFor(String objectAPIName) {
        for (BDI_ObjectMapping objectMapping : mappingService.objectMappingByDevName.values()) {
            if (objectMapping.Object_API_Name == objectAPIName) {
                return objectMapping;
            }
        }
        return null;
    }

    private String generateRandomString(Integer length) {
        Blob blob128 = Crypto.GenerateAESKey(128);
        String hex = EncodingUtil.ConvertToHex(blob128);
        return hex.left(length);
    }
}
