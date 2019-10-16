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
public with sharing class BDI_FieldMapping {
    @AuraEnabled public String DeveloperName;
    @AuraEnabled public String MasterLabel;
    @AuraEnabled public String Source_Field_Label;
    @AuraEnabled public String Source_Field_API_Name;
    @AuraEnabled public String Source_Field_Data_Type;
    @AuraEnabled public String Target_Field_Label;
    @AuraEnabled public String Target_Field_API_Name;
    @AuraEnabled public String Target_Field_Data_Type;
    @AuraEnabled public String Data_Import_Field_Mapping_Set;
    @AuraEnabled public String Target_Object_Mapping_Dev_Name;
    @AuraEnabled public String Required;
    @AuraEnabled public Boolean Is_Deleted;
    @AuraEnabled public String Source_Field_Display_Type_Label;
    @AuraEnabled public String Target_Field_Display_Type_Label;

    public BDI_FieldMapping(Data_Import_Field_Mapping__mdt fieldMapping) {
        String dataImport = SobjectType.DataImport__c.Name;
        String objectAPIName = fieldMapping.Target_Object_Mapping__r.Object_API_Name__c;
        String sourceFieldAPIName = fieldMapping.Source_Field_API_Name__c;
        String targetFieldAPIName = fieldMapping.Target_Field_API_Name__c;

        Schema.DescribeFieldResult sourceFieldDescribe = UTIL_Describe.getFieldDescribe(
            dataImport,
            sourceFieldAPIName);

        Schema.DescribeFieldResult targetFieldDescribe = UTIL_Describe.getFieldDescribe(
            objectAPIName,
            targetFieldAPIName);

        this.DeveloperName = fieldMapping.DeveloperName;
        this.MasterLabel = fieldMapping.MasterLabel;

        this.Source_Field_Label = sourceFieldDescribe.label;
        this.Source_Field_API_Name = fieldMapping.Source_Field_API_Name__c;
        this.Source_Field_Data_Type = String.valueOf(sourceFieldDescribe.type);
        this.Source_Field_Display_Type_Label = UTIL_Describe.LABELS_BY_DISPLAY_TYPE.get(this.Source_Field_Data_Type);

        this.Target_Field_Label = targetFieldDescribe.label;
        this.Target_Field_API_Name = fieldMapping.Target_Field_API_Name__c;
        this.Target_Field_Data_Type = String.valueOf(targetFieldDescribe.type);
        this.Target_Field_Display_Type_Label = UTIL_Describe.LABELS_BY_DISPLAY_TYPE.get(this.Target_Field_Data_Type);

        this.Data_Import_Field_Mapping_Set = fieldMapping.Data_Import_Field_Mapping_Set__r.DeveloperName;
        this.Target_Object_Mapping_Dev_Name = fieldMapping.Target_Object_Mapping__r.DeveloperName;
        this.Required = fieldMapping.Required__c;
        this.Is_Deleted = fieldMapping.Is_Deleted__c;
    }
}
