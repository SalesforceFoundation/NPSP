public with sharing class SoftCredits {
    private List<OpportunityContactRole> opportunityContactRoles;
    private List<OpportunityContactRole> unprocessedSoftCredits;

    public SoftCredits(
        List<OpportunityContactRole> existingOpportunityContactRoles,
        String additionalObjectJson) {
        
        opportunityContactRoles = new List<OpportunityContactRole>();

        if (existingOpportunityContactRoles != null) {
            opportunityContactRoles.addAll(existingOpportunityContactRoles);
        }

        if (additionalObjectJson != null) {
            unprocessedSoftCredits = instantiateOpportunityContactRolesFrom(additionalObjectJson);
            opportunityContactRoles.addAll(unprocessedSoftCredits);
        }
    }

    public List<OpportunityContactRole> all() {
        return opportunityContactRoles;
    }

    public Integer size() {
        return opportunityContactRoles.size();
    }

    private List<OpportunityContactRole> instantiateOpportunityContactRolesFrom(String additionalObjectJson) {
        List<OpportunityContactRole> contactRoles = new List<OpportunityContactRole>();
        List<BDI_DynamicSource> dynamicSources = new List<BDI_DynamicSource>();

        if (additionalObjectJson != null && additionalObjectJson.length() > 0) {

            BDI_DynamicSourceGroup dynamicSourceGroup = (BDI_DynamicSourceGroup)
                JSON.deserialize(additionalObjectJson, BDI_DynamicSourceGroup.class);

            List<String> opportunityContactRoleObjectMappingDeveloperNames = getSoftCreditsObjectMappingNames();

            for (BDI_DynamicSource dynamicSource : dynamicSourceGroup.dynamicSourceByObjMappingDevName.values()) {
                System.debug('dynamicSource: ' + dynamicSource);
                if (opportunityContactRoleObjectMappingDeveloperNames.contains(dynamicSource.objectMappingTemplateDevName)) {
                    dynamicSources.add(dynamicSource);
                    contactRoles.add(convertDynamicSourceToOpportunityContactRole(dynamicSource));
                }
            }
        }

        return contactRoles;
    }

    private OpportunityContactRole convertDynamicSourceToOpportunityContactRole(BDI_DynamicSource dynamicSource) {
        OpportunityContactRole ocr = new OpportunityContactRole();
        ocr.Role = (String) dynamicSource.sourceObj.get('Opportunity_Contact_Role_1_Role__c');
        ocr.ContactId = (Id) dynamicSource.sourceObj.get('Contact1Imported__c');
        return ocr;
    }

    private List<String> getSoftCreditsObjectMappingNames() {
        List<Data_import_Object_Mapping__mdt> objectMappings = [
            SELECT DeveloperName
            FROM Data_Import_Object_Mapping__mdt
            WHERE Object_API_Name__c = :SObjectType.OpportunityContactRole.getName()
                AND Is_Deleted__c = false
        ];

        List<String> softCreditsObjectMappingNames = new List<String>();
        for (Data_Import_Object_Mapping__mdt objectMapping : objectMappings) {
            softCreditsObjectMappingNames.add(objectMapping.DeveloperName);
        }

        return softCreditsObjectMappingNames;
    }
}
