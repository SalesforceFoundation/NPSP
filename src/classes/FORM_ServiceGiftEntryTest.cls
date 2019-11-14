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
public with sharing class FORM_ServiceGiftEntryTest {


    /*******************************************************************************************************
    * @description Confirming that the lifecycle of storing and retrieving the template does not corrupt
    * the data.
    */
    @IsTest
    static void shouldCommitAndRetrieveTemplate() {
        FORM_Service fs = new FORM_Service();

        FORM_Template template = createSampleTemplate();
        Gift_Entry_Settings__c giftEntryCustomSetting = new Gift_Entry_Settings__c();
        giftEntryCustomSetting.Default_Single_Gift_Entry_Template__c = template.name;

        UTIL_CustomSettingsFacade.getGiftEntrySettingsForTests(giftEntryCustomSetting);

        String templateJSON = JSON.serialize(template);
        fs.storeFormTemplate(null, template.name, template.description, template.version, templateJSON);

        FORM_Template templateResult = fs.retrieveDefaultSGEFormTemplate();
        String templateResultJSON = JSON.serialize(templateResult);

        System.assertEquals(templateJSON, templateResultJSON);
    }

    //Utility method for creating a sample template.
    public static FORM_Template createSampleTemplate () {
        
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
