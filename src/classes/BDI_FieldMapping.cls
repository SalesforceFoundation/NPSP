/*
    Copyright (c) 2019 Salesforce.org
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
* @date 2019
* @group Batch Data Import
* @group-content ../../ApexDocContent/BatchDataImport.htm
* @description Wrapper class to hold data related to the field mapping 
*/
public virtual with sharing class BDI_FieldMapping {
    @AuraEnabled public String DeveloperName;
    @AuraEnabled public String MasterLabel;
    @AuraEnabled public String Source_Field_Label;
    @AuraEnabled public String Source_Field_API_Name;
    @AuraEnabled public String Source_Field_Data_Type;
    @AuraEnabled public Boolean Source_Field_Required;
    @AuraEnabled public String Target_Field_Label;
    @AuraEnabled public String Target_Field_API_Name;
    @AuraEnabled public String Target_Field_Data_Type;
    @AuraEnabled public Boolean Target_Field_Required;
    @AuraEnabled public String Data_Import_Field_Mapping_Set;
    @AuraEnabled public String Target_Object_Mapping_Dev_Name;
    @AuraEnabled public String Target_Object_API_Name;
    @AuraEnabled public String Required;
    @AuraEnabled public Boolean Is_Deleted;
    @AuraEnabled public String Source_Field_Display_Type_Label;
    @AuraEnabled public String Target_Field_Display_Type_Label;
    @AuraEnabled public Boolean Is_Required;
    // Used for the Form Template Builder and Renderer
    @AuraEnabled public String Element_Type = 'field';
    // Used for Form Template Builder and Widgets
    @AuraEnabled public String Widget_Object_Mapping_Developer_Name;
    @AuraEnabled public Boolean isValid = true;

    public BDI_FieldMapping() {

    }

    // A mapping of picklist value to label.
    // Schema.PicklistEntry does not work with AuraEnabled.
    @AuraEnabled public Map<String, String>  Target_Field_Picklist_Values = new Map<String, String>();

    public BDI_FieldMapping(Data_Import_Field_Mapping__mdt fieldMappingMetadata) {
        String dataImport = SobjectType.DataImport__c.Name;

        this.Target_Object_API_Name = fieldMappingMetadata.Target_Object_Mapping__r.Object_API_Name__c;
        this.Source_Field_API_Name = fieldMappingMetadata.Source_Field_API_Name__c;
        this.Target_Field_API_Name = fieldMappingMetadata.Target_Field_API_Name__c;

        // Removing the npsp namespace since the code is not currently packaged.
        if (UTIL_Namespace.shouldAlignNamespace) {
            this.Target_Object_API_Name = 
                UTIL_Namespace.alignSchemaNSWithEnvironment(this.Target_Object_API_Name);
            this.Source_Field_API_Name = 
                UTIL_Namespace.alignSchemaNSWithEnvironment(this.Source_Field_API_Name);
            this.Target_Field_API_Name =
                 UTIL_Namespace.alignSchemaNSWithEnvironment(this.Target_Field_API_Name);
        }

        Schema.DescribeFieldResult sourceFieldDescribe;
        Schema.DescribeFieldResult targetFieldDescribe;

        try {
            sourceFieldDescribe = UTIL_Describe.getFieldDescribe(
                dataImport,
                this.Source_Field_API_Name);
            targetFieldDescribe = UTIL_Describe.getFieldDescribe(
                this.Target_Object_API_Name,
                this.Target_Field_API_Name);
        } catch (UTIL_Describe.SchemaDescribeException sde) {
            if (sde.getMessage().contains('Invalid')) {
                this.isValid = false;
            }
        }

        if (this.isValid) {
            constructValidFieldMapping(sourceFieldDescribe, targetFieldDescribe, fieldMappingMetadata);
        } else {
            constructInvalidFieldMapping(fieldMappingMetadata, this);
        }

    }


    /*****************************************************************************************************************
     * @description Constructs a valid field mapping
     * @param sourceFieldDescribe Source Field Describe data
     * @param targetFieldDescribe Target Field Describe data
     * @param fieldMapping Data Import Field Mapping Metadata
     */
    private void constructValidFieldMapping (Schema.DescribeFieldResult sourceFieldDescribe,
        Schema.DescribeFieldResult targetFieldDescribe, Data_Import_Field_Mapping__mdt fieldMapping) {
        //Updating field and object names to make sure they are using the actual correctly cased
        //API names so it doesn't cause problems with some LWC functions
        this.Target_Object_API_Name = UTIL_Describe.getObjectName(this.Target_Object_API_Name);
        this.Target_Field_API_Name = UTIL_Describe.getFieldName(this.Target_Object_API_Name, this.Target_Field_API_Name);
        this.Source_Field_API_Name = UTIL_Describe.getFieldName(SObjectType.DataImport__c.Name,
            this.Source_Field_API_Name);

        this.DeveloperName = fieldMapping.DeveloperName;
        this.MasterLabel = fieldMapping.MasterLabel;

        this.Source_Field_Label = sourceFieldDescribe.label;
        this.Source_Field_Data_Type = String.valueOf(sourceFieldDescribe.type);
        this.Source_Field_Display_Type_Label = UTIL_Describe.getLabelForDisplayType(this.Source_Field_Data_Type);

        // If a field is nillable, it can have a null value. A non-nillable field means it is required.
        this.Source_Field_Required = !sourceFieldDescribe.isNillable();

        this.Target_Field_Label = targetFieldDescribe.label;
        this.Target_Field_Data_Type = String.valueOf(targetFieldDescribe.type);
        this.Target_Field_Display_Type_Label = UTIL_Describe.getLabelForDisplayType(this.Target_Field_Data_Type);

        // If a field is nillable, it can have a null value. A non-nillable field means it is required.
        this.Target_Field_Required = !targetFieldDescribe.isNillable();

        this.Data_Import_Field_Mapping_Set = fieldMapping.Data_Import_Field_Mapping_Set__r.DeveloperName;
        this.Target_Object_Mapping_Dev_Name = fieldMapping.Target_Object_Mapping__r.DeveloperName;
        this.Required = fieldMapping.Required__c;
        this.Is_Deleted = fieldMapping.Is_Deleted__c;

        List<Schema.PicklistEntry> picklistEntriesList = targetFieldDescribe.getPicklistValues();

        for (Schema.PicklistEntry picklistEntry : picklistEntriesList) {

            // Create a mapping of active picklist entry value to label
            if (picklistEntry.isActive()) {
                Target_Field_Picklist_Values.put(picklistEntry.getValue(), picklistEntry.getLabel());
            }
        }

        this.Is_Required = !sourceFieldDescribe.isNillable() ? true : false;
        this.isValid = true;
    }

    /*****************************************************************************************************************
     * @description Constructs an invalid field mapping
     * @param difm Data Import Field Mapping Metadata
     * @param fieldMapping Field Mapping object being built
     */
    private void constructInvalidFieldMapping (Data_Import_Field_Mapping__mdt difm, BDI_FieldMapping fieldMapping) {
        fieldMapping.isValid = false;
        fieldMapping.Target_Object_Mapping_Dev_Name = difm.Target_Object_Mapping__r.DeveloperName;
        fieldMapping.MasterLabel = difm.MasterLabel;
        fieldMapping.Is_Deleted = difm.Is_Deleted__c;
        fieldMapping.DeveloperName = difm.DeveloperName;
        fieldMapping.Data_Import_Field_Mapping_Set = difm.Data_Import_Field_Mapping_Set__r.DeveloperName;
    }
}
