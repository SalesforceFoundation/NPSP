public with sharing class FORM_MappingWrapper {

    String targetObject; 
    public Data_Import_Field_Mapping__mdt fieldMapping;
    List<String> picklistValues;
    Integer doubleSpecifiedPrecision;



    public FORM_MappingWrapper(Data_Import_Field_Mapping__mdt fieldMapping) {
        this.fieldMapping = fieldMapping;
        targetObject = fieldMapping.Target_Object_Mapping__r.Object_API_Name__c;

        // Get the target object/field describe to see what type it is
        Schema.DescribeFieldResult fieldDescribeResult = UTIL_Describe.getFieldDescribe(targetObject, fieldMapping.Target_Field_API_Name__c);


        // Get the necessary values from the describe 
        

    }
}
