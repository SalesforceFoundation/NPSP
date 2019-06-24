public with sharing class BDI_FieldMappingsCtrl {

    @AuraEnabled(cacheable=true)
    public static List<Data_Import_Field_Mapping__mdt> getFieldMappings() {
        System.debug('getFieldMappings()');
        List<Data_Import_Field_Mapping__mdt> fieldMappings =
            [SELECT Id, DeveloperName, Label FROM Data_Import_Field_Mapping__mdt LIMIT 10];
        System.debug(fieldMappings);

        return fieldMappings;
    }

    @AuraEnabled(cacheable=true)
    public static List<DataImportFieldMappingWrapper> getFieldMappingsByObjectMappingName(String name) {
        System.debug('getFieldMappingsByObjectMappingName()');
        Data_Import_Settings__c settings = Data_Import_Settings__c.getInstance();
        List<Data_Import_Field_Mapping__mdt> fieldMappings =
            [SELECT Id,
                DeveloperName,
                Label,
                MasterLabel,
                Source_Field_API_Name__c,
                Target_Field_API_Name__c
            FROM Data_Import_Field_Mapping__mdt
            WHERE Target_Object_Mapping__r.DeveloperName = :name
            AND Data_Import_Field_Mapping_Set__r.DeveloperName =
                :settings.Default_Data_Import_Field_Mapping_Set__c];
        System.debug(fieldMappings);

        List<DataImportFieldMappingWrapper> wrappers = new List<DataImportFieldMappingWrapper>();

        for (Data_Import_Field_Mapping__mdt fieldMapping : fieldMappings) {
            DataImportFieldMappingWrapper wrapper =
                new DataImportFieldMappingWrapper(fieldMapping);

            wrappers.add(wrapper);
        }

        return wrappers;
    }

    @AuraEnabled
    public static Data_Import_Object_Mapping__mdt fetchObjectMapping(String name) {
        System.debug('fetchObjectMapping()');
        List<Data_Import_Object_Mapping__mdt> objectMappings =
            [SELECT Id,
                DeveloperName,
                Label,
                MasterLabel
            FROM Data_Import_Object_Mapping__mdt
            WHERE DeveloperName = :name];
        System.debug(objectMappings);

        return objectMappings[0];
    }

    public class DataImportFieldMappingWrapper {
        @AuraEnabled
        public Data_Import_Field_Mapping__mdt dataImportFieldMapping;
        @AuraEnabled
        public String sourceFieldLabel;
        @AuraEnabled
        public String sourceFieldDataType;

        public DataImportFieldMappingWrapper(Data_Import_Field_Mapping__mdt fieldMapping) {
            Schema.DescribeFieldResult dfr = UTIL_Describe.getFieldDescribe(
                UTIL_Namespace.StrTokenNSPrefix('DataImport__c'),
                UTIL_Namespace.removeNSPrefixNpspOnly(fieldMapping.Source_Field_API_Name__c));

            this.dataImportFieldMapping = fieldMapping;
            this.sourceFieldLabel = dfr.label;
            this.sourceFieldDataType = String.valueOf(dfr.type);
        }
    }
}