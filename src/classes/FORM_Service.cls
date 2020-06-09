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
* @description Form Services for use in entering gifts or with other form types.
*/
public virtual with sharing class FORM_Service {

    /*******************************************************************************************************
    * @description Method for retrieving all existing form templates.
    */
    public virtual FORM_Template[] getAllFormTemplates() {
        return FORM_ServiceGiftEntry.getAllFormTemplates();
    }

    /*******************************************************************************************************
    * @description Method deletes a Form_Template__c record by id.
    * @param id: Form_Template__c record id
    */
    public virtual void deleteFormTemplates(String[] ids) {
        FORM_ServiceGiftEntry.deleteFormTemplates(ids);
    }

    /*******************************************************************************************************
    * @description Method for retrieving an existing template that you already have the Id for.
    * @param templateId - the Id of an existing form template record for retrieval.
    */
    public virtual FORM_Template retrieveFormTemplate(Id templateId) {
        return FORM_ServiceGiftEntry.retrieveFormTemplateById(templateId);
    }

    /*******************************************************************************************************
    * @description Method for retrieving the current default template.
    * @param templateId - the Id of an existing form template record for retrieval.
    */
    public virtual FORM_Template retrieveDefaultSGEFormTemplate() {
        return FORM_ServiceGiftEntry.retrieveDefaultSGEFormTemplate();
    }

    /*******************************************************************************************************
    * @description Stores the template JSON.
    * @param id - the Id of an existing form template record if this is an update of an existing template
    * @param name - The name that should be applied to template storage record.
    * @param description - the description of the template.
    * @param formatVersion - the version id/number of the template format
    * @param templateJSON - The JSON for the FormTemplate class that is being stored.
    */
    public virtual void storeFormTemplate(String id, 
                                            String name, 
                                            String description, 
                                            String formatVersion, 
                                            String templateJSON) {

        FORM_ServiceGiftEntry.storeFormTemplate(id,name,description,formatVersion,templateJSON);
    }
}