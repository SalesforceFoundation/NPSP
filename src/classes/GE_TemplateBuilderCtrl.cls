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
    public static FORM_Template retrieveDefaultFormTemplate(){
        return FORM_ServiceGiftEntry.retrieveDefaultFormTemplate();
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
                for (Data_Import_Field_Mapping__mdt fieldMapping : objectMapping.Data_Import_Field_Mappings__r) {
                    CheckboxWrapper fieldMappingWrapper = new CheckboxWrapper(
                        fieldMapping.MasterLabel,
                        fieldMapping.DeveloperName,
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
            wrappers.add(new CheckboxWrapper(fields.get(key)));
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
       // @AuraEnabled public String type;

        public CheckboxWrapper(Schema.DescribeFieldResult describe) {
            this.label = describe.getLabel();
            this.value = describe.getName();
            this.checked = false;
            /* Remember, got a grandchild branch that uses this to determine what type of lightning-input to render in the UI */
            //this.type = String.valueOf(describe.getType());
        }

        public CheckboxWrapper(String label, String value, Boolean checked) {
            this.label = label;
            this.value = value;
            this.checked = checked;
        }
    }
}
