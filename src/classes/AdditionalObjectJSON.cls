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
