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
    * @description Instance of BDI_MappingServiceAdvanced
    */
    private static BDI_MappingServiceAdvanced bdiMSAdv;

    /*******************************************************************************************************
    * @description Template version
    */
    private static final String TEMPLATE_VERSION = '1.0';

    /*******************************************************************************************************
    * @description Just an intermediary method for calling the storeFormTemplate method in the FormServiceGiftEntry
    * class. I've modified the FormServiceGiftEntry to return the newly inserted Form_Template__c id so I can
    * navigate to the record page in the UI. Should probably revert this back later depending on how we want
    * to handle what happens after save of a new template.
    */
    @AuraEnabled
    public static String processFormTemplate(String templateJSON, String templateName, String templateDescription){
        String id = FORM_ServiceGiftEntry.storeFormTemplate(null,
            templateName,
            templateDescription,
            TEMPLATE_VERSION,
            templateJSON);
        return id;
    }

    /*******************************************************************************************************
    * @description Just an intermediary method. Can just import this method directly in the lwc.
    */
    @AuraEnabled
    public static FORM_Template retrieveFormTemplate(String templateId){
        return FORM_ServiceGiftEntry.retrieveFormTemplate(Id.valueOf(templateId));
    }

    /**
     * @description Retrieves the render wrapper for gift entry by template name. If the template is not found, it returns the wrapper for the Default template
     * @return      A render wrapper containing a template and information about the object/field mappings.
     * @param String template name
     */
    @AuraEnabled(cacheable=true)
    public static FORM_RenderWrapper retrieveFormRenderWrapper(String templateName) {
        return GE_FormRendererService.getRenderWrapper(templateName);
    }

    /**
     * @description Retrieves the default SGE render wrapper for gift entry.
     * @return      A render wrapper containing a template and information about the object/field mappings.
     */
    @AuraEnabled(cacheable=true)
    public static FORM_RenderWrapper retrieveDefaultSGERenderWrapper() {
        return GE_FormRendererService.getDefaultSGERenderWrapper();
    }

    /**
     * @description Retrieves the default BGE render wrapper for gift entry. 
     * @return      A render wrapper containing a template and information about the object/field mappings.
     */
    @AuraEnabled(cacheable=true)
    public static FORM_RenderWrapper retrieveDefaultBGERenderWrapper() {
        return GE_FormRendererService.getDefaultBGERenderWrapper();
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
    * @description Method collects object mappings and field mappings using BDI_MappingServiceAdvanced
    * based on a field mapping set developer name. Creates ObjectMappingWrappers and CheckboxWrappers out
    * of the object mapping and field mappings respectively. These wrappers are easier to use in the UI. No
    * need to worry about namespaces in the fields.
    */
    @AuraEnabled
    public static ObjectMappingWrapper[] getFieldAndObjectMappingsByFieldMappingSetName(String fieldMappingSetName) {
        bdiMSAdv = BDI_MappingServiceAdvanced.getInstance(fieldMappingSetName);
        ObjectMappingWrapper[] objectWrappers = new ObjectMappingWrapper[]{};

        for (BDI_ObjectMapping objectMapping : bdiMSAdv.objectMappingByDevName.values()) {
            ObjectMappingWrapper omw = new ObjectMappingWrapper(objectMapping);

            BDI_FieldMapping[] fieldMappings = bdiMSAdv.fieldMappingsByObjMappingDevName.get(objectMapping.DeveloperName);
            if (fieldMappings != null) {
                for (BDI_FieldMapping fieldMapping : fieldMappings) {

                    String objectAPIName = objectMapping.Object_API_Name;

                    CheckboxWrapper fieldMappingWrapper = new CheckboxWrapper(
                        fieldMapping.MasterLabel,
                        fieldMapping.DeveloperName,
                        UTIL_Describe.getFieldDescribe(objectAPIName, fieldMapping.Target_Field_API_Name),
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
                wrappers.add(checkboxWrapper);
            }
        }

        return wrappers;
    }

    public class ObjectMappingWrapper extends BDI_ObjectMapping {
        @AuraEnabled public CheckboxWrapper[] fieldMappingCheckboxes;

        ObjectMappingWrapper(BDI_ObjectMapping objectMapping) {
            this.DeveloperName = objectMapping.DeveloperName;
            this.MasterLabel = objectMapping.MasterLabel;
            this.Object_API_Name = objectMapping.Object_API_Name;
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
