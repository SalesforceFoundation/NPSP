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
* @description Unit tests to cover methods in FORM_ServiceGiftEntryTest.
*/
@isTest
private with sharing class FORM_ServiceGiftEntryTest {

    /*******************************************************************************************************
    * @description Confirming that method returns the correct number of records
    */
    @IsTest
    static void shouldReturnCorrectNumberOfRecords() {
        FORM_Service fs = new FORM_Service();

        FORM_Template template0 = createSampleTemplate();
        String templateJSON0 = JSON.serialize(template0);
        fs.storeFormTemplate(null,template0.name, template0.description, template0.version, templateJSON0);

        FORM_Template template1 = createSampleTemplate();
        String templateJSON1 = JSON.serialize(template1);
        fs.storeFormTemplate(null,template1.name, template1.description, template1.version, templateJSON1);

        System.assertEquals(2, fs.getAllFormTemplates().size());
    }

    /*******************************************************************************************************
    * @description Confirming that method deletes Form Template records with given ids.
    */
    @IsTest
    static void shouldDeleteFormTemplatesWithGivenIds() {
        FORM_Service fs = new FORM_Service();

        FORM_Template template0 = createSampleTemplate();
        String templateJSON0 = JSON.serialize(template0);
        fs.storeFormTemplate(null,template0.name, template0.description, template0.version, templateJSON0);

        FORM_Template template1 = createSampleTemplate();
        String templateJSON1 = JSON.serialize(template1);
        fs.storeFormTemplate(null,template1.name, template1.description, template1.version, templateJSON1);

        Form_Template__c[] formTemplates = [SELECT Id, Name FROM Form_Template__c];

        System.assertEquals(2, formTemplates.size());
        fs.deleteFormTemplates(new String[]{ formTemplates[0].id, formTemplates[1].id });

        formTemplates = [SELECT Id, Name FROM Form_Template__c];
        System.assertEquals(0, formTemplates.size());
    }

    /*******************************************************************************************************
    * @description Confirming that method clones Form Template with given record id.
    */
    @IsTest
    static void shouldCloneFormTemplateWithGivenId() {
        FORM_Service fs = new FORM_Service();

        FORM_Template template = createSampleTemplate();
        String templateJSON = JSON.serialize(template);
        fs.storeFormTemplate(null,template.name, template.description, template.version, templateJSON);

        Form_Template__c[] formTemplates = [SELECT Id, Template_JSON__c FROM Form_Template__c];
        Form_Template clonedTemplate = fs.cloneFormTemplate(formTemplates[0].id);

        System.assertEquals(
            JSON.serialize(template.layout),
            JSON.serialize(clonedTemplate.layout),
            'Original template and cloned template layouts are equal.');
        System.assertNotEquals(
            template.name,
            clonedTemplate.name,
            'Original template and cloned template names are not equal');
    }

    /*******************************************************************************************************
    * @description Confirming that the lifecycle of storing and retrieving the template does not corrupt
    * the data.
    */
    @IsTest
    static void shouldCommitAndRetrieveTemplate() {
        FORM_Service fs = new FORM_Service();

        FORM_Template template = createSampleTemplate();
        String templateJSON = JSON.serialize(template);
        fs.storeFormTemplate(null,template.name, template.description, template.version, templateJSON);

        FORM_Template templateResult = fs.retrieveDefaultFormTemplate();
        String templateResultJSON = JSON.serialize(templateResult);

        System.assertEquals(templateJSON, templateResultJSON);
    }

    //Utility method for creating a sample template.
    private static FORM_Template createSampleTemplate () {
        
        FORM_Element field = new FORM_Element('FormField',
                                        'True',
                                        null,
                                        'CustomLabel',
                                        new String[]{});
        
        FORM_Element widget = new FORM_Element('FormWidget',
                                            'DisplayRule',
                                            'ComponentName',
                                            new String[]{});
        
        FORM_Element[] elements = new FORM_Element[]{field,widget};

        FORM_Section section = new FORM_Section('SectionLabel',
                                                'Accordion',
                                                'Expanded',
                                                'True',
                                                elements);
        
        FORM_Layout layout = new FORM_Layout('DefaultMappingSet',
                                            new FORM_Section[]{section});


        FORM_Template template = new FORM_Template('Sample Template',
                                                'This is the description.',
                                                '1.0',
                                                layout);
        return template;
    }
}
