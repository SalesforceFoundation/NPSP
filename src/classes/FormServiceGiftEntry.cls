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
public with sharing class FormServiceGiftEntry {

    /*******************************************************************************************************
    * @description Method for retrieving an existing template that you already have the Id for.
    * @param templateId - the Id of an existing form template record for retrieval.
    */
    public static FormTemplate retrieveFormTemplate(Id templateId) {
        FormTemplate template;

        Form_Template__c templateObj = [SELECT Id, Name, Format_Version__c, Template_JSON__c 
                                FROM Form_Template__c 
                                WHERE Id =: templateId
                                LIMIT 1];
        
        template = deserializeFormTemplateFromObj(templateObj);
    
        return template;
    }

    /*******************************************************************************************************
    * @description Method for retrieving the current default template.
    * @param templateId - the Id of an existing form template record for retrieval.
    */
    public static FormTemplate retrieveDefaultFormTemplate() {
        FormTemplate template;
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
    * @param formatVersion - the version id/number of the template format
    * @param templateJSON - The JSON for the FormTemplate class that is being stored.
    */
    public static String storeFormTemplate(String id, String name, String formatVersion, String templateJSON) {
        System.debug('storeFormTemplate');
        if (templateJSON != null) {
            FormTemplate template = (FormTemplate)JSON.deserialize(templateJSON, FormTemplate.class);
            System.debug('FormTemplate: ' + template);
            Form_Template__c templateObj = new Form_Template__c(Id = id, 
                                                            Name = name,
                                                            Template_JSON__c = templateJSON,
                                                            Format_Version__c = formatVersion);
            System.debug('Form_Template__c: ' + templateObj);
            upsert templateObj;
            return templateObj.id;
        }
        return null;
    }

    /*******************************************************************************************************
    * @description Private helper method for deserializing the JSON stored in a form template record.
    * @param templateObj - The Form_Template__c object with the Template JSON.
    */
    private static FormTemplate deserializeFormTemplateFromObj(Form_Template__c templateObj) {
        FormTemplate template;
        if (templateObj != null && templateObj.Template_JSON__c != null) {
            template = (FormTemplate)JSON.deserialize(templateObj.Template_JSON__c, FormTemplate.class);
            System.debug(template);
            System.debug(template.layout);
            System.debug(template.layout.sections[0]);
            System.debug(template.layout.sections[0].elements);
        }
        return template;
    }

}
