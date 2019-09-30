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
* @description Unit tests to cover methods in FormServiceGiftEntryTest.
*/
@isTest
private with sharing class FormServiceGiftEntryTest {

    @IsTest
    static void shouldCommitAndRetrieveTemplate() {
        FormService fs = new FormService();

        FormTemplate template = createSampleTemplate();
        String templateJSON = JSON.serialize(template);
        //System.debug('TemplateJSON is: ' + templateJSON);
        fs.storeFormTemplate(null,templateJSON,template.layout.version);

        FormTemplate templateResult = fs.retrieveDefaultFormTemplate();
        String templateResultJSON = JSON.serialize(templateResult);
        //System.debug('Expected: ' + template.layout.sections[0].elements );
        //System.debug('Actual: ' + template.layout.sections[0].elements );
        System.debug('Expected: ' + templateJSON );
        System.debug('Actual: ' + templateResultJSON );
        System.assertEquals(templateJSON, templateResultJSON);

        //System.assertEquals(template.layout.sections[0].elements,templateResult.layout.sections[0].elements);
        //System.assertEquals(template, templateResult);
    }

    //Creates a sample template for testing. To be removed before release.
    
    private static FormTemplate createSampleTemplate () {
        
        FormElement field = new FormElement('FormField',
                                        'True',
                                        null,
                                        'CustomLabel',
                                        new DataImportFieldMapping[]{});
        
        FormElement widget = new FormElement('FormWidget',
                                            'DisplayRule',
                                            'ComponentName',
                                            new DataImportFieldMapping[]{});
        
        FormElement[] elements = new FormElement[]{field,widget};

        FormSection section = new FormSection('SectionLabel',
                                                'Accordion',
                                                'Expanded',
                                                'True',
                                                elements);
        
        FormLayout layout = new FormLayout('DefaultMappingSet',
                                            '1.0',
                                            new FormSection[]{section});


        FormTemplate template = new FormTemplate('Sample Template',
                                                layout);
        return template;

    }
}
