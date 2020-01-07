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
    * @description Method retrieves records based on a query string.
    */
    @AuraEnabled
    public static SObject[] retrieveRecords(String[] selectFields,
        String sObjectApiName, String[] whereClauses, String orderByClause, Integer limitClause) {

        String queryString = new UTIL_Query()
            .withSelectFields(selectFields)
            .withFrom(sObjectApiName)
            .withWhere(whereClauses)
            .withOrderBy(orderByClause)
            .withLimit(limitClause)
            .build();

        return Database.query(queryString);
    }

    /*******************************************************************************************************
    * @description Method retrieves custom Column Header List Custom Setting records for tables in the Gift
    * Entry landing page.
    */
    @AuraEnabled
    public static Custom_Column_Header__c[] retrieveCustomColumnHeaders(String listName) {
        return [SELECT Id, Name, Field_Api_Name__c, Index__c, List_Name__c
            FROM Custom_Column_Header__c
            WHERE List_Name__c = :listName
            ORDER BY Index__c ASC];
    }

    /*******************************************************************************************************
    * @description Method retrieves records based on a query string.
    */
    @AuraEnabled
    public static Custom_Column_Header__c[] upsertCustomColumnHeaders(String columnHeadersString,
        String listName) {
        System.debug('columnHeadersString: ' + columnHeadersString);
        Custom_Column_Header__c[] columnHeaders =
            (Custom_Column_Header__c[])JSON.deserialize(columnHeadersString, Custom_Column_Header__c[].class);
        System.debug(columnHeaders);
        upsert columnHeaders;

        Id[] headerIdsToKeep = new Id[]{};
        for (Custom_Column_Header__c columnHeader : columnHeaders) {
            headerIdsToKeep.add(columnHeader.Id);
        }

        Custom_Column_Header__c[] headersToDelete =
            [SELECT Id FROM Custom_Column_Header__c WHERE Id NOT IN :headerIdsToKeep];
        System.debug('headersToDelete: ' + headersToDelete.size());
        delete headersToDelete;

        return columnHeaders;
    }

    /*******************************************************************************************************
    * @description Method for retrieving all existing form templates.
    */
    @AuraEnabled
    public static FORM_Template[] getAllFormTemplates() {
        FORM_Template[] formTemplates = new FORM_Template[]{};
        Form_Template__c[] allTemplates = [SELECT Id,
            Name,
            Template_JSON__c,
            Description__c,
            Format_Version__c
            FROM Form_Template__c];

        for (Form_Template__c formTemplate : allTemplates) {
            FORM_Template deserializedFormTemplate = deserializeFormTemplateFromObj(formTemplate);
            if (formTemplate.id != null) {
                deserializedFormTemplate.id = formTemplate.id;
            }

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

            String newId = storeFormTemplate(null,
                clonedFormTemplate.Name,
                clonedFormTemplate.Description__c,
                clonedFormTemplate.Format_Version__c,
                clonedFormTemplate.Template_JSON__c);

            FORM_Template deserializedClonedTemplate = deserializeFormTemplateFromObj(clonedFormTemplate);
            deserializedClonedTemplate.id = newId;

            return deserializedClonedTemplate;
        }

        return null;
    }

    /*******************************************************************************************************
    * @description Method deletes a Form_Template__c record by id.
    *
    * @param id: Form_Template__c record id
    *
    * @return list: List of deleted Form_Template__c names
    */
    @AuraEnabled
    public static String[] deleteFormTemplates(String[] ids) {
        Form_Template__c[] templates = [SELECT Id, Name FROM Form_Template__c WHERE Id IN :ids];
        delete templates;

        String[] formTemplateNames = new String[] {};
        for (Form_Template__c template : templates) {
            formTemplateNames.add(template.Name);
        }
        return formTemplateNames;
    }

    /*******************************************************************************************************
    * @description Method for retrieving an existing template that you already have the Id for.
    * @param templateId - the Id of an existing form template record for retrieval.
    */
    @AuraEnabled
    public static FORM_Template retrieveFormTemplateById(Id templateId) {
        FORM_Template template;

        Form_Template__c templateObj = [SELECT Id, Name, Format_Version__c, Template_JSON__c 
                                FROM Form_Template__c 
                                WHERE Id =: templateId
                                LIMIT 1];
        
        template = deserializeFormTemplateFromObj(templateObj);

        return template;
    }

    /*******************************************************************************************************
    * @description Method for retrieving the template by name
    * @param templateName - the name of an existing form template 
    */
    public static FORM_Template retrieveFormTemplate(String templateName) {
        FORM_Template template;

        List<Form_Template__c> templateList = [SELECT Id, Name, Format_Version__c, Template_JSON__c 
                                FROM Form_Template__c 
                                WHERE Name = :templateName
                                LIMIT 1];

        return !templateList.isEmpty() ? deserializeFormTemplateFromObj(templateList[0]) : null;
    }

    /*******************************************************************************************************
    * @description Method for retrieving the current default template.
    */
    public static FORM_Template retrieveDefaultBGEFormTemplate() {
        Gift_Entry_Settings__c giftEntrySettings = UTIL_CustomSettingsFacade.getGiftEntrySettings();
        FORM_Template template;

        List<Form_Template__c> templateObjList = [SELECT Id, Name, Format_Version__c, Template_JSON__c 
                                FROM Form_Template__c 
                                WHERE Name =: giftEntrySettings.Default_Batch_Gift_Entry_Template__c];

        if (!templateObjList.isEmpty()) {
            template = deserializeFormTemplateFromObj(templateObjList[0]);
        }
        

        return template;
    }

    /*******************************************************************************************************
    * @description Method for retrieving the current default template.
    */
    public static FORM_Template retrieveDefaultSGEFormTemplate() {
        Gift_Entry_Settings__c giftEntrySettings = UTIL_CustomSettingsFacade.getGiftEntrySettings();
        FORM_Template template;
        List<Form_Template__c> templateObjList = [SELECT Id, Name, Format_Version__c, Template_JSON__c 
                                FROM Form_Template__c 
                                WHERE Name =: giftEntrySettings.Default_Single_Gift_Entry_Template__c];
        
         if (!templateObjList.isEmpty()) {
            template = deserializeFormTemplateFromObj(templateObjList[0]);
        }

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
    @AuraEnabled
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
