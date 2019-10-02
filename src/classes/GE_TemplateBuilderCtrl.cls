/*
    Copyright (c) 2019, Salesforce.org
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
* @group BGE
* @group-content ../../ApexDocContent/BatchDataImport.htm
* @description Controller for the geTemplateBuilder Lightning Web Component.
*/

public with sharing class GE_TemplateBuilderCtrl {

    /*******************************************************************************************************
    * @description Instance of BDI_FieldMappingCustomMetadata
    */
    private static BDI_FieldMappingCustomMetadata bdiCMT;

    @AuraEnabled
    public static String processFormTemplate(String templateJSON, String templateName){
        System.debug('processFormTemplate');
        System.debug(templateJSON);
        String id = FormServiceGiftEntry.storeFormTemplate(null, templateName, '1.0', templateJSON);
        return id;
    }

    @AuraEnabled
    public static FormTemplate retrieveDefaultFormTemplate(){
        return FormServiceGiftEntry.retrieveDefaultFormTemplate();
    }

    @AuraEnabled(cacheable=true)
    public static Data_Import_Field_Mapping_Set__mdt[] getFieldMappingSetNames() {
        return [SELECT Id, DeveloperName, MasterLabel FROM Data_Import_Field_Mapping_Set__mdt];
    }

    @AuraEnabled
    public static Data_Import_Object_Mapping__mdt[] getFieldAndObjectMappingsByFieldMappingSetName(String fieldMappingSetName) {
        System.debug('getFieldAndObjectMappingsByFieldMappingSetName');
        bdiCMT = BDI_FieldMappingCustomMetadata.getInstance(fieldMappingSetName);

        return bdiCMT.objMappingsByDevName.values();
    }

    @AuraEnabled(cacheable=true)
    public static DescribeFieldWrapper[] getBatchFields() {
        DescribeFieldWrapper[] wrappers = new DescribeFieldWrapper[]{};
        Map<String, Schema.DescribeFieldResult> fields = UTIL_Describe.getAllFieldsDescribe(SObjectType.DataImportBatch__c.Name);
        for (String key : fields.keySet()) {
            System.debug(key);
            wrappers.add(new DescribeFieldWrapper(fields.get(key)));
            System.debug(wrappers);
        }
        return wrappers;
    }

    public class DescribeFieldWrapper {
        @AuraEnabled public String label;
        @AuraEnabled public String value;
       // @AuraEnabled public String type;

        public DescribeFieldWrapper(Schema.DescribeFieldResult describe) {
            this.label = describe.getLabel();
            this.value = describe.getName();
            //this.type = String.valueOf(describe.getType());
        }
    }

    public class MappingWrapper {
        @AuraEnabled public Data_Import_Object_Mapping__mdt objectMapping;
        @AuraEnabled public Data_Import_Field_Mapping__mdt[] fieldMappings;

        public MappingWrapper(
            Data_Import_Object_Mapping__mdt objectMapping, Data_Import_Field_Mapping__mdt[] fieldMappings) {
            
            this.objectMapping = objectMapping;
            this.fieldMappings = fieldMappings;
        }
    }
}
