@isTest
private class SoftCredits_TEST {

    @isTest
    static void shouldReturn2OpportunityContactRolesFromAdditionalObjectJSON() {
        SoftCredits softCredits = new SoftCredits(null, DUMMY_ADDITIONAL_OBJECT_JSON_WITH_SOFT_CREDITS);

        System.assertEquals(2, softCredits.all().size());
    }

    @isTest
    static void shouldReturn0OpportunityContactRoles() {
        SoftCredits softCredits = new SoftCredits(null, DUMMY_ADDITIONAL_OBJECT_JSON_WITH_ALLOCATIONS);

        System.assertEquals(0, softCredits.all().size());
    }

    static final String DUMMY_ADDITIONAL_OBJECT_JSON_WITH_SOFT_CREDITS = '{"name":"Additional_Object_JSON__c","dynamicSourceByObjMappingDevName":{"Opportunity_Contact_Role_1temp2":{"sourceObj":{"attributes":{"type":"DataImport__c"},"Opportunity_Contact_Role_1_Role__c":"Household Member","Contact1Imported__c":"0035600000VNllNAAT"},"objectMappingTemplateDevName":"Opportunity_Contact_Role_1","objectMappingDevName":"Opportunity_Contact_Role_1temp2","importedRecordStatus":null,"importedRecordId":null,"fieldMappingSetDevName":"Migrated_Custom_Field_Mapping_Set"},"Opportunity_Contact_Role_1temp1":{"sourceObj":{"attributes":{"type":"DataImport__c"},"Opportunity_Contact_Role_1_Role__c":"Matched Donor","Contact1Imported__c":"0035600000VNllSAAT"},"objectMappingTemplateDevName":"Opportunity_Contact_Role_1","objectMappingDevName":"Opportunity_Contact_Role_1temp1","importedRecordStatus":null,"importedRecordId":null,"fieldMappingSetDevName":"Migrated_Custom_Field_Mapping_Set"}}}';
    static final String DUMMY_ADDITIONAL_OBJECT_JSON_WITH_ALLOCATIONS = '{"name":"Additional_Object_JSON__c","dynamicSourceByObjMappingDevName":{"GAU_Allocation_1temp2":{"sourceObj":{"attributes":{"type":"DataImport__c"},"GAU_Allocation_1_GAU__c":"DUMMY_ID","GAU_Allocation_1_Percent__c":0,"GAU_Allocation_1_Amount__c":100},"objectMappingTemplateDevName":"GAU_Allocation_1","objectMappingDevName":"GAU_Allocation_1temp2","importedRecordStatus":null,"importedRecordId":null,"fieldMappingSetDevName":"Migrated_Custom_Field_Mapping_Set"},"GAU_Allocation_1temp1":{"sourceObj":{"attributes":{"type":"DataImport__c"},"GAU_Allocation_1_GAU__c":"DUMMY_ID","GAU_Allocation_1_Percent__c":0,"GAU_Allocation_1_Amount__c":200},"objectMappingTemplateDevName":"GAU_Allocation_1","objectMappingDevName":"GAU_Allocation_1temp1","importedRecordStatus":null,"importedRecordId":null,"fieldMappingSetDevName":"Migrated_Custom_Field_Mapping_Set"}}}';
}
