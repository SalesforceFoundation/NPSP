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
* @description Unit tests to cover methods in GE_FormRendererService.
*/
@isTest
private with sharing class GE_FormRendererService_TEST {

    /*******************************************************************************************************
     * @description Confirm that the DataImport process used in Gift Entry works
     */
    @isTest
    private static void createAndProcessDataImportRecord() {
        DataImport__c di = BDI_DataImport_TEST.newDI('First', 'Last', 100);
        // TODO: Update this test to take a Additional Object string, and also process that
        Id oppId = GE_FormRendererService.saveAndProcessSingleGift(di, null);
        System.assert(oppId != null);
    }

    /*******************************************************************************************************
     * @description Confirm that a default FORM_RenderWrapper is correctly returned
     */
    @isTest
    private static void createAndReturnDefaultFormTemplate() {
        Gift_Entry_Settings__c giftEntryCustomSetting = new Gift_Entry_Settings__c();
        Form_Template__c defaultTemplate = returnFormTemplate();

        giftEntryCustomSetting.Default_Single_Gift_Entry_Template__c = defaultTemplate.Name;

        UTIL_CustomSettingsFacade.getGiftEntrySettingsForTests(giftEntryCustomSetting);
        
        FORM_Template template = FORM_ServiceGiftEntry_TEST.createSampleTemplate();
        String templateJSON = JSON.serialize(template);
        defaultTemplate.Template_JSON__c = templateJSON;
        
        insert defaultTemplate;

        FORM_RenderWrapper frw = GE_FormRendererService.getDefaultSGERenderWrapper();
        System.assert(frw.formTemplate != null);
        System.assert(frw.formTemplate.name == template.name);

        frw = GE_FormRendererService.getRenderWrapperById(defaultTemplate.Id);
        System.assert(frw.formTemplate != null);
        System.assert(frw.formTemplate.name == template.name);

    }

    private static Form_Template__c returnFormTemplate(){
        return new Form_Template__c(
            Name = 'Test',
            Format_Version__c = '1.0'
        );
    }

}
