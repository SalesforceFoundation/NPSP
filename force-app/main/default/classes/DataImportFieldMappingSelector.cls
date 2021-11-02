public with sharing class DataImportFieldMappingSelector {

    public List<Data_Import_Field_Mapping__mdt> getDataImportFieldMappings() {
        return [
                SELECT Id,
                        MasterLabel,
                        DeveloperName,
                        Target_Object_Mapping__r.DeveloperName,
                        Is_Deleted__c,
                        Data_Import_Field_Mapping_Set__r.DeveloperName,
                        Source_Field_API_Name__c
                FROM Data_Import_Field_Mapping__mdt
                WHERE Data_Import_Field_Mapping_Set__r.DeveloperName = :
                        BDI_MigrationMappingUtility.MIGRATED_CUSTOM_FIELD_MAPPING_SET_RECORD_NAME
        ];
    }

    public static DataImportFieldMappingSelector newInstance() {
        return new DataImportFieldMappingSelector();
    }
}