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

    /*******************************************************************************************************
    * @description Template version
    */
    private static final String TEMPLATE_VERSION = '1.0';

    /*******************************************************************************************************
    * @description List of required DataImportBatch__c fields
    */
    private static final String[] REQUIRED_BATCH_HEADER_FIELDS = new String[]{
        'name'
    };
    
    /*******************************************************************************************************
    * @description Queries all Form_Template__c records.
    *
    * @return Form_Template__c[]: List of all Form_Template__c records
    */
    @AuraEnabled
    public static Form_Template__c[] getAllFormTemplates() {
        return [SELECT Id, Name, Template_JSON__c, Description__c, Format_Version__c FROM Form_Template__c];
    }

    /*******************************************************************************************************
    * @description Method clones a Form_Template__c record by id.
    *
    * @param id: Form_Template__c record id
    *
    * @return clonedFormTemplate: A Form_Template__c record
    */
    @AuraEnabled
    public static Form_Template__c cloneFormTemplate(String id) {
        Form_Template__c[] templates = [SELECT Id,
                Name,
                Template_JSON__c,
                Description__c,
                Format_Version__c
            FROM Form_Template__c
            WHERE Id = :id];

        if (templates.size() > 0) {
            Form_Template__c clonedFormTemplate = templates[0].clone();
            clonedFormTemplate.Name += ' [CLONED ' + Date.today().format() + ']';
            insert clonedFormTemplate;

            return clonedFormTemplate;
        }

        return null;
    }

    /*******************************************************************************************************
    * @description Method deletes a Form_Template__c record by id.
    *
    * @param id: Form_Template__c record id
    */
    @AuraEnabled
    public static void deleteFormTemplate(String id) {
        Form_Template__c[] templates = [SELECT Id FROM Form_Template__c WHERE Id = :id];
        delete templates;
    }

    /*******************************************************************************************************
    * @description Just an intermediary method. Can just import this method directly in the lwc.
    */
    @AuraEnabled
    public static FORM_Template retrieveFormTemplate(String templateId){
        return FORM_ServiceGiftEntry.retrieveFormTemplate(Id.valueOf(templateId));
    }

    /*******************************************************************************************************
    * @description Stores the template JSON.
    *
    * @param id - the Id of an existing form template record if this is an update of an existing template
    * @param name - The name that should be applied to template storage record.
    * @param description - the description of the template.
    * @param formatVersion - the version id/number of the template format
    * @param templateJSON - The JSON for the FormTemplate class that is being stored.
    *
    * @return newRecordId - Form_Template__c record id
    */
    @AuraEnabled
    public static String storeFormTemplate(String id, String name, String description, String formatVersion, String templateJSON) {
        String newRecordId =
            FORM_ServiceGiftEntry.storeFormTemplate(id, name, description, formatVersion, templateJSON);
        return newRecordId;
    }

    /*******************************************************************************************************
    * @description Method that retrieves all Field Mapping Sets in an org. Used in the Gift Fields tab's
    * Field Mapping Sets combobox in the Form Template Builder. Field Mapping Set selection determines
    * which Object Groups and Field Mappings are available to the Form Builder.
    */
    @AuraEnabled(cacheable=true)
    public static Data_Import_Field_Mapping_Set__mdt[] getFieldMappingSetNames() {
        return [SELECT Id, DeveloperName, MasterLabel FROM Data_Import_Field_Mapping_Set__mdt];
    }

    /*******************************************************************************************************
    * @description Method collects object mappings and field mappings using BDI_FieldMappingCustomMetadata
    * based on a field mapping set developer name. Creates ObjectMappingWrappers and CheckboxWrappers out
    * of the object mapping and field mappings respectively. These wrappers are easier to use in the UI. No
    * need to worry about namespaces in the fields.
    */
    @AuraEnabled
    public static ObjectMappingWrapper[] getFieldAndObjectMappingsByFieldMappingSetName(String fieldMappingSetName) {
        bdiCMT = BDI_FieldMappingCustomMetadata.retrieveInstance(fieldMappingSetName);
        ObjectMappingWrapper[] objectWrappers = new ObjectMappingWrapper[]{};

        for (Data_Import_Object_Mapping__mdt objectMapping : bdiCMT.objMappingsByDevName.values()) {
            ObjectMappingWrapper omw = new ObjectMappingWrapper(objectMapping);

            if (objectMapping.Data_Import_Field_Mappings__r != null) {
                String objectAPIName = objectMapping.Object_API_Name__c;

                for (Data_Import_Field_Mapping__mdt fieldMapping : objectMapping.Data_Import_Field_Mappings__r) {
                    CheckboxWrapper fieldMappingWrapper = new CheckboxWrapper(
                        fieldMapping.MasterLabel,
                        fieldMapping.DeveloperName,
                        UTIL_Describe.getFieldDescribe(objectAPIName, fieldMapping.Target_Field_API_Name__c),
                        false
                    );
                    omw.fieldMappingCheckboxes.add(fieldMappingWrapper);
                }
            }

            objectWrappers.add(omw);
        }

        return objectWrappers;
    }

    /*******************************************************************************************************
    * @description Method checks the Data Import Batch object's field describes and returns a list of
    * CheckboxWrappers for use in the UI's Batch Header tab.
    */
    @AuraEnabled(cacheable=true)
    public static CheckboxWrapper[] getBatchFields() {
        CheckboxWrapper[] wrappers = new CheckboxWrapper[]{};

        Map<String, Schema.DescribeFieldResult> fields = UTIL_Describe.getAllFieldsDescribe(SObjectType.DataImportBatch__c.Name);

        for (String key : fields.keySet()) {
            DescribeFieldResult dfr = fields.get(key);

            if (dfr.isAccessible() && dfr.isCreateable()) {
                CheckboxWrapper checkboxWrapper = new CheckboxWrapper(fields.get(key));

                if (REQUIRED_BATCH_HEADER_FIELDS.contains(key)) {

                    checkboxWrapper.isRequired = true;
                    checkboxWrapper.isRequiredFieldDisabled = true;
                }

                wrappers.add(checkboxWrapper);
            }
        }

        return wrappers;
    }

    public class ObjectMappingWrapper {
        @AuraEnabled public String DeveloperName;
        @AuraEnabled public String MasterLabel;
        @AuraEnabled public String Object_API_Name;
        @AuraEnabled public CheckboxWrapper[] fieldMappingCheckboxes;

        ObjectMappingWrapper(Data_Import_Object_Mapping__mdt objectMapping) {
            this.DeveloperName = objectMapping.DeveloperName;
            this.MasterLabel = objectMapping.MasterLabel;
            this.Object_API_Name = objectMapping.Object_API_Name__c;
            this.fieldMappingCheckboxes = new CheckboxWrapper[]{};
        }
    }

    public class CheckboxWrapper {
        @AuraEnabled public String label;
        @AuraEnabled public String value;
        @AuraEnabled public Boolean checked;
        // TODO: Change to displayType and add new attribute for dataType
        @AuraEnabled public String dataType;
        @AuraEnabled public PicklistOptionWrapper[] picklistOptions;
        @AuraEnabled public Boolean isRequired = false;
        @AuraEnabled public Boolean isRequiredFieldDisabled = false;

        public CheckboxWrapper(Schema.DescribeFieldResult describe) {
            this.label = describe.getLabel();
            this.value = describe.getName();
            this.checked = false;
            this.dataType = String.valueOf(describe.getType());

            if (this.dataType == 'PICKLIST') {
                picklistOptions = getPicklistOptions(describe);
            }

            if (this.dataType == 'TEXTAREA' && describe.isHtmlFormatted()) {
                this.dataType = 'RICHTEXT';
            }
        }

        public CheckboxWrapper(String fieldMappingLabel,
            String fieldMappingDeveloperName,
            Schema.DescribeFieldResult targetFieldDescribe,
            Boolean checked) {

            this.label = fieldMappingLabel;
            this.value = fieldMappingDeveloperName;
            this.checked = checked;
            this.dataType = String.valueOf(targetFieldDescribe.getType());

            if (this.dataType == 'PICKLIST') {
                picklistOptions = getPicklistOptions(targetFieldDescribe);
            }

            if (this.dataType == 'TEXTAREA' && targetFieldDescribe.isHtmlFormatted()) {
                this.dataType = 'RICHTEXT';
            }
        }

        private List<PicklistOptionWrapper> getPicklistOptions(Schema.DescribeFieldResult describe) {
            List<PicklistOptionWrapper> pickListValuesList= new List<PicklistOptionWrapper>();
            List<Schema.PicklistEntry> ple = describe.getPicklistValues();
            for( Schema.PicklistEntry pickListVal : ple) {
                if (pickListVal.isActive()) {
                    pickListValuesList.add(new PicklistOptionWrapper(
                        pickListVal.getLabel(),
                        pickListVal.getValue()));
                }
            }
            return pickListValuesList;
        }
    }

    public class PicklistOptionWrapper {
        @AuraEnabled public String label;
        @AuraEnabled public String value;

        public PicklistOptionWrapper(String label, String value) {
            this.label = label;
            this.value = value;
        }
    }
}
