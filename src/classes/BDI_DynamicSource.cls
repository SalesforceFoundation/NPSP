public with sharing class BDI_DynamicSource {
    @AuraEnabled public String objectMappingDevName;
    @AuraEnabled public String objectMappingTemplateDevName;
    @AuraEnabled public String fieldMappingSetDevName;
    @AuraEnabled public Id importedRecordId;
    @AuraEnabled public String importedRecordStatus;
    @AuraEnabled public SObject sourceObj;

    public BDI_DynamicSource() {

    }
}