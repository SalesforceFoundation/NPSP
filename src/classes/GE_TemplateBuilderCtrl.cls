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
    * @description Queries all Form_Template__c records.
    *
    * @return Form_Template__c[]: List of all Form_Template__c records
    */
    @AuraEnabled
    public static Form_Template__c[] getAllFormTemplates() {
        return [SELECT Id, Name, Template_JSON__c, Description__c, Format_Version__c FROM Form_Template__c];
    }

    /*******************************************************************************************************
<<<<<<< HEAD
    * @description Just an intermediary method for calling the storeFormTemplate method in the FormServiceGiftEntry
    * class. I've modified the FormServiceGiftEntry to return the newly inserted Form_Template__c id so I can
    * navigate to the record page in the UI. Should probably revert this back later depending on how we want
    * to handle what happens after save of a new template.
=======
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
>>>>>>> psadie/gift-entry__template-builder-updates
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
    * @description Method collects object mappings and field mappings using BDI_MappingServiceAdvanced
    * based on a field mapping set developer name. Creates ObjectMappingWrappers and CheckboxWrappers out
    * of the object mapping and field mappings respectively. These wrappers are easier to use in the UI. No
    * need to worry about namespaces in the fields.
    */
    @AuraEnabled
    public static BDI_ObjectMapping[] getFieldAndObjectMappingsByFieldMappingSetName(String fieldMappingSetName) {
        bdiMSAdv = BDI_MappingServiceAdvanced.getInstance(fieldMappingSetName);
        BDI_ObjectMapping[] objectMappings = new BDI_ObjectMapping[]{};

        for (BDI_ObjectMapping objectMapping : bdiMSAdv.objectMappingByDevName.values()) {
            objectMapping.Field_Mappings =
                bdiMSAdv.fieldMappingsByObjMappingDevName.get(objectMapping.DeveloperName);
            objectMappings.add(objectMapping);
        }

        return objectMappings;
    }
}
