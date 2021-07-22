/*
    Copyright (c) 2021 Salesforce.org
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
* @date 2021
* @description Domain class for Form Templates.
*/
public with sharing class GiftTemplate {

    private GE_Template.Template template;
    private static final String ELEVATE_WIDGET_COMPONENT_NAME = 'geFormWidgetTokenizeCard';

    public GiftTemplate() {
        this.template = defaultFormTemplate();
    }

    public GiftTemplate(String templateJSON) {
        this.template = (GE_Template.Template) JSON.deserialize(
            templateJSON,
            GE_Template.Template.class);
    }

    public GE_Template.Template template() {
        return this.template;
    }

    public List<String> giftFieldApiNames() {
        return this.template.giftFieldApiNames();
    }

    public Boolean hasElevateWidget() {
        Boolean hasWidget = false;
        for (GE_Template.Section section : template.layout.sections) {
            for (GE_Template.Element element : section.elements) {
                if (isElevateWidget(element)) {
                    hasWidget = true;
                }
            }
        }
        return hasWidget;
    }

    private GE_Template.Template defaultFormTemplate() {
        Form_Template__c defaultFormTemplate = queryDefaultFormTemplate();
        return (GE_Template.Template)
            JSON.deserialize(defaultFormTemplate.Template_JSON__c, GE_Template.Template.class);
    }

    private Form_Template__c queryDefaultFormTemplate() {
        Gift_Entry_Settings__c giftEntrySettings = getGiftEntrySettings();
        List<Form_Template__c> formTemplates = [
            SELECT Id, Name, Format_Version__c, Template_JSON__c
            FROM Form_Template__c
            WHERE Id =: giftEntrySettings.Default_Gift_Entry_Template__c
            WITH SECURITY_ENFORCED
        ];

        if (formTemplates.size() == 1) {
            return formTemplates[0];
        }
        return null;
    }

    private Gift_Entry_Settings__c getGiftEntrySettings() {
        GE_Template.createDefaultTemplateIfNecessary();
        Gift_Entry_Settings__c giftEntryCustomSetting = UTIL_CustomSettingsFacade.getGiftEntrySettings();
        return giftEntryCustomSetting;
    }

    private Boolean isElevateWidget(GE_Template.Element element) {
        return element.componentName != null
            && element.componentName == ELEVATE_WIDGET_COMPONENT_NAME;
    }
}
