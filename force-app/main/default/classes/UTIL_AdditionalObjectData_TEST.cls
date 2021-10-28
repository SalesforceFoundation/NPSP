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
* @description Contains methods to create additional object json test data.
*/
@isTest
public with sharing class UTIL_AdditionalObjectData_TEST {
    private String additionalObjJSONFieldName = String.valueOf(DataImport__c.Additional_Object_JSON__c);
    private String ocrMappingTemplateName = 'Opportunity_Contact_Role_1';
    private String gauMappingTemplateName = 'GAU_Allocation_1';
    private BDI_MappingServiceAdvanced mappingService;
    private BDI_FieldMapping[] ocrFieldMappings;
    private BDI_FIeldMapping[] gauFieldMappings;
    private sObject gauSourceObject;
    private DataImport__c sampleDataImport = new DataImport__c();

    private Map<String,BDI_DynamicSource> dynamicSourceByObjMappingDevName = new Map<String,BDI_DynamicSource>();

    public UTIL_AdditionalObjectData_TEST() {
        Data_Import_Settings__c dataImportSettings = UTIL_CustomSettingsFacade.getDataImportSettings();
        dataImportSettings.Field_Mapping_Method__c = BDI_DataImportService.FM_DATA_IMPORT_FIELD_MAPPING;
        dataImportSettings.Default_Data_Import_Field_Mapping_Set__c = 
            BDI_MappingServiceAdvanced.DEFAULT_DATA_IMPORT_FIELD_MAPPING_SET_NAME;
        UTIL_CustomSettingsFacade.setDataImportSettings(dataImportSettings);
        mappingService = BDI_MappingServiceAdvanced.getInstance();

        ocrFieldMappings = mappingService.fieldMappingsByObjMappingDevName.get(ocrMappingTemplateName);
        gauFieldMappings = mappingService.fieldMappingsByObjMappingDevName.get(gauMappingTemplateName);

        gauSourceObject = UTIL_Describe.getPrototypeObject(SObjectType.DataImport__c.getName());
        gauSourceObject.put(DataImport__c.GAU_Allocation_1_Amount__c.getDescribe().getName(),
                    sampleDataImport.GAU_Allocation_1_Amount__c);
        gauSourceObject.put(DataImport__c.GAU_Allocation_1_GAU__c.getDescribe().getName(),
                    sampleDataImport.GAU_Allocation_1_GAU__c);
        gauSourceObject.put(DataImport__c.GAU_Allocation_1_Percent__c.getDescribe().getName(),
                    sampleDataImport.GAU_Allocation_1_Percent__c);
    }

    public UTIL_AdditionalObjectData_TEST withOpportunityContactRoles(Integer count) {
        for (Integer i = 0; i < count; i++) {
            sObject ocrSourceObject;
            ocrSourceObject = UTIL_Describe.getPrototypeObject(SObjectType.DataImport__c.getName());
            ocrSourceObject.put(DataImport__c.Opportunity_Contact_Role_1_Role__c.getDescribe().getName(), 'Soft Credit');

            BDI_DynamicSource ocrDynamicSource = new BDI_DynamicSource();
            ocrDynamicSource.objectMappingDevName = ocrMappingTemplateName + '0' + i;
            ocrDynamicSource.objectMappingTemplateDevName = ocrMappingTemplateName;
            ocrDynamicSource.fieldMappingSetDevName = ocrFieldMappings[0].Data_Import_Field_Mapping_Set;
            ocrSourceObject.put(
                DataImport__c.Contact1Imported__c.getDescribe().getName(),
                UTIL_UnitTestData_TEST.mockId(Contact.sObjectType));
            ocrDynamicSource.sourceObj = ocrSourceObject;

            dynamicSourceByObjMappingDevName.put(ocrDynamicSource.objectMappingDevName, ocrDynamicSource);
        }

        return this;
    }

    public UTIL_AdditionalObjectData_TEST withGeneralAccountingUnits(Integer count) {
        for (Integer i = 0; i < count; i++) {
            BDI_DynamicSource gauDynamicSource = new BDI_DynamicSource();
            gauDynamicSource.objectMappingDevName = gauMappingTemplateName + '0' + i;
            gauDynamicSource.objectMappingTemplateDevName = gauMappingTemplateName;
            gauDynamicSource.fieldMappingSetDevName = gauFieldMappings[0].Data_Import_Field_Mapping_Set;
            gauDynamicSource.sourceObj = gauSourceObject;

            dynamicSourceByObjMappingDevName.put(gauDynamicSource.objectMappingDevName, gauDynamicSource);
        }

        return this;
    }

    public String build() {
        BDI_DynamicSourceGroup dynamicSourceGroup = new BDI_DynamicSourceGroup();
        dynamicSourceGroup.dynamicSourceByObjMappingDevName = dynamicSourceByObjMappingDevName;
        dynamicSourceGroup.name = additionalObjJSONFieldName;

        return JSON.serialize(dynamicSourceGroup);
    }
}
