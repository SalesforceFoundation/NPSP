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
* @group Gift Entry
* @group-content ../../ApexDocContent/GiftEntry.htm
* @description Form Service implementations specifically used for gift entry use cases.
*/
public with sharing class FORM_ServiceGiftEntry {

    /*******************************************************************************************************
    * @description Method for retrieving all existing form templates.
    */
    public static FORM_Template[] getAllFormTemplates() {
        FORM_Template[] formTemplates = new FORM_Template[]{};

        for (Form_Template__c formTemplate : [SELECT Id, Name, Template_JSON__c, Description__c, Format_Version__c FROM Form_Template__c]) {
            FORM_Template deserializedFormTemplate = deserializeFormTemplateFromObj(formTemplate);
            deserializedFormTemplate.id = formTemplate.id;

            formTemplates.add(deserializedFormTemplate);
        }

        return formTemplates;
    }

    /*******************************************************************************************************
    * @description Method clones a Form_Template__c record by id.
    * @param id: Form_Template__c record id
    * @return string: A Form_Template__c record id
    */
    @AuraEnabled
    public static FORM_Template cloneFormTemplate(String id) {
        Form_Template__c formTemplate = [SELECT Id,
                Name,
                Template_JSON__c,
                Description__c,
                Format_Version__c
            FROM Form_Template__c
            WHERE Id = :id];

        if (formTemplate != null) {
            Form_Template__c clonedFormTemplate = formTemplate.clone();
            FORM_Template deserializedTemplate = deserializeFormTemplateFromObj(clonedFormTemplate);
            clonedFormTemplate.Name += ' [CLONED ' + Date.today().format() + ']';
            deserializedTemplate.name = clonedFormTemplate.Name;
            clonedFormTemplate.Template_JSON__c = JSON.serialize(deserializedTemplate);

            String newId = storeFormTemplate(clonedFormTemplate);
            FORM_Template deserializedClonedTemplate = deserializeFormTemplateFromObj(clonedFormTemplate);
            deserializedClonedTemplate.id = newId;

            return deserializedClonedTemplate;
        }

        return null;
    }

    /*******************************************************************************************************
    * @description Method deletes a Form_Template__c record by id.
    * @param id: Form_Template__c record id
    */
    @AuraEnabled
    public static void deleteFormTemplates(String[] ids) {
        Form_Template__c[] templates = [SELECT Id FROM Form_Template__c WHERE Id IN :ids];
        try {
            delete templates;
        } catch (DmlException e) {
            throw new DMLException(e.getMessage());
        }
    }

    /*******************************************************************************************************
    * @description Method for retrieving an existing template that you already have the Id for.
    * @param templateId - the Id of an existing form template record for retrieval.
    */
    public static FORM_Template retrieveFormTemplate(Id templateId) {
        FORM_Template template;

        Form_Template__c templateObj = [SELECT Id, Name, Format_Version__c, Template_JSON__c 
                                FROM Form_Template__c 
                                WHERE Id =: templateId
                                LIMIT 1];
        
        template = deserializeFormTemplateFromObj(templateObj);
    
        return template;
    }

    /*******************************************************************************************************
    * @description Method for retrieving the current default template.
    */
    public static FORM_Template retrieveDefaultFormTemplate() {
        FORM_Template template;
        // TBD: determine how default templates will be tracked for SGE.
        Form_Template__c templateObj = [SELECT Id, Name, Format_Version__c, Template_JSON__c 
                                FROM Form_Template__c 
                                LIMIT 1];

        template = deserializeFormTemplateFromObj(templateObj);

        return template;
    }

    /*******************************************************************************************************
    * @description Stores the template JSON.
    * @param id - the Id of an existing form template record if this is an update of an existing template
    * @param name - The name that should be applied to template storage record.
    * @param description - the description of the template.
    * @param formatVersion - the version id/number of the template format
    * @param templateJSON - The JSON for the FormTemplate class that is being stored.
    */
    public static String storeFormTemplate(String id, 
                                            String name, 
                                            String description,
                                            String formatVersion,
                                            String templateJSON) {
        if (templateJSON != null) {
            FORM_Template template = (FORM_Template)JSON.deserialize(templateJSON, FORM_Template.class);
            Form_Template__c templateObj = new Form_Template__c(Id = id, 
                                                            Name = name,
                                                            Description__c = description,
                                                            Template_JSON__c = templateJSON,
                                                            Format_Version__c = formatVersion);
            upsert templateObj;
            return templateObj.id;
        }
        return null;
    }

    /*******************************************************************************************************
    * @description Stores the template JSON.
    * @param formTemplate - Form_Template__c record to store
    */
    public static String storeFormTemplate(Form_Template__c formTemplate) {
        Form_Template__c templateObj = new Form_Template__c(Name = formTemplate.name,
                                                        Description__c = formTemplate.Description__c,
                                                        Template_JSON__c = formTemplate.Template_JSON__c,
                                                        Format_Version__c = formTemplate.Format_Version__c);
        insert templateObj;
        return templateObj.id;
    }

    /*******************************************************************************************************
    * @description Private helper method for deserializing the JSON stored in a form template record.
    * @param templateObj - The Form_Template__c object with the Template JSON.
    */
    private static FORM_Template deserializeFormTemplateFromObj(Form_Template__c templateObj) {
        FORM_Template template;
        if (templateObj != null && templateObj.Template_JSON__c != null) {
            template = (FORM_Template)JSON.deserialize(templateObj.Template_JSON__c, FORM_Template.class);
        }
        return template;
    }

}
