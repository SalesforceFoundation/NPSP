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
    * @description Method for retrieving all existing form templates.
    *
    * @return FORM_Template[]: List of all Form_Template__c records
    */
    @AuraEnabled
    public static FORM_Template[] getAllFormTemplates() {
        return FORM_ServiceGiftEntry.getAllFormTemplates();
    }

    /*******************************************************************************************************
    * @description Method clones a Form_Template__c record by id.
    *
    * @param id: Form_Template__c record id
    *
    * @return clonedFormTemplate: A Form_Template__c record
    */
    @AuraEnabled
    public static FORM_Template cloneFormTemplate(String id) {
        return FORM_ServiceGiftEntry.cloneFormTemplate(id);
    }

    /*******************************************************************************************************
    * @description Method deletes a Form_Template__c record by id.
    *
    * @param id: Form_Template__c record id
    */
    @AuraEnabled
    public static void deleteFormTemplates(String[] ids) {
        FORM_ServiceGiftEntry.deleteFormTemplates(ids);
    }

    /*******************************************************************************************************
    * @description Just an intermediary method. Can just import this method directly in the lwc.
    */
    @AuraEnabled
    public static FORM_Template retrieveFormTemplate(String templateId) {
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
     * @description Retrieve the default form render wrapper for gift entry. Placeholder, uses the first record found.
     * @return      A render wrapper containing a template and information about the object/field mappings.
     */
    @AuraEnabled(cacheable=true)
    public static FORM_RenderWrapper retrieveDefaultFormRenderWrapper() {
        return GE_FormRendererService.getDefaultRenderWrapper();
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
    * @description Returns the currently active field mapping method
    */
    @AuraEnabled
    public static string getFieldMappingMethod() {
        return UTIL_CustomSettingsFacade.getDataImportSettings().Field_Mapping_Method__c;
    }
}
