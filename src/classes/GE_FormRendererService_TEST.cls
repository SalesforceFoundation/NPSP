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
        
        FORM_Template template = FORM_ServiceGiftEntryTest.createSampleTemplate();
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

    //VERSION OF TEST FOR DATAIMPORT__C OBJECT IN WIDGET DATA
    /*******************************************************************************************************
     * @description Tests that widget data can be properly coverted to the BDI_DynamicSourceGroup format required
     * by BDI for N number of objects processing.
     */
    @isTest
    private static void widgetDataShouldBeConvertedIntoDynamicSources() {
        General_Accounting_Unit__c gau1 = new General_Accounting_Unit__c(Name = 'TestGroupA GAU 1',
                                                                        Active__c = true);

        General_Accounting_Unit__c gau2 = new General_Accounting_Unit__c(Name = 'TestGroupA GAU 2',
                                                                        Active__c = true);
        General_Accounting_Unit__c[] testGAUs = new General_Accounting_Unit__c[]{gau1,gau2};
        insert testGAUs;

        SObject sourceObjA1 = UTIL_Describe.getPrototypeObject(SObjectType.DataImport__c.getName());
        sourceObjA1.put(DataImport__c.GAU_Allocation_1_GAU__c.getDescribe().getName(),
                    gau1.Id);    
        sourceObjA1.put(DataImport__c.GAU_Allocation_1_Percent__c.getDescribe().getName(),75);    

        SObject sourceObjA2 = UTIL_Describe.getPrototypeObject(SObjectType.DataImport__c.getName());
        sourceObjA2.put(DataImport__c.GAU_Allocation_1_GAU__c.getDescribe().getName(),
                    gau2.Id);    
        sourceObjA2.put(DataImport__c.GAU_Allocation_1_Percent__c.getDescribe().getName(),25);    

        Sobject[] testWidgetRecords = new Sobject[]{sourceObjA1,sourceObjA2};
        
        Map<String,SObject[]> widgetData = new Map<String,SObject[]>();

        widgetData.put('GAU_Allocation_1',testWidgetRecords);

        String widgetDataString = JSON.serialize(widgetData);

        DataImport__c testDI = new DataImport__c();
        Test.startTest();
        GE_FormRendererService.convertWidgetDataToObjectJSON(testDI,widgetDataString);
        Test.stopTest();

        System.assertNotEquals(null,testDI.Additional_Object_JSON__c);

        BDI_DynamicSourceGroup testDSG = 
            (BDI_DynamicSourceGroup)JSON.deserialize(testDI.Additional_Object_JSON__c, BDI_DynamicSourceGroup.class);

        System.assertNotEquals(null,testDSG);
        System.assertEquals(2,testDSG.dynamicSourceByObjMappingDevName.size());

        BDI_DynamicSource dynSource1;
        BDI_DynamicSource dynSource2;

        for (String objMappingDevName : testDSG.dynamicSourceByObjMappingDevName.keySet()) {
            BDI_DynamicSource tempDS = testDSG.dynamicSourceByObjMappingDevName.get(objMappingDevName);
            if (tempDS.sourceObj.get('GAU_Allocation_1_GAU__c') == gau1.Id) {
                dynSource1 = tempDS;
            } else if (tempDS.sourceObj.get('GAU_Allocation_1_GAU__c')  == gau2.Id) {
                dynSource2 = tempDS;
            }
        }

        System.assertNotEquals(null, dynSource1);
        System.assertNotEquals(null, dynSource2);
        System.assertEquals(75,dynSource1.sourceObj.get('GAU_Allocation_1_Percent__c'));
        System.assertEquals(25,dynSource2.sourceObj.get('GAU_Allocation_1_Percent__c'));
    }

    //VERSION OF TEST FOR TARGET OBJECT IN WIDGET DATA
    /*******************************************************************************************************
     * @description Tests that widget data can be properly coverted to the BDI_DynamicSourceGroup format required
     * by BDI for N number of objects processing.
     */
    /*
    @isTest
    private static void widgetDataShouldBeConvertedIntoDynamicSources() {
        General_Accounting_Unit__c gau1 = new General_Accounting_Unit__c(Name = 'TestGroupA GAU 1',
                                                                        Active__c = true);

        General_Accounting_Unit__c gau2 = new General_Accounting_Unit__c(Name = 'TestGroupA GAU 2',
                                                                        Active__c = true);
        General_Accounting_Unit__c[] testGAUs = new General_Accounting_Unit__c[]{gau1,gau2};
        insert testGAUs;

        SObject sourceObjA1 = UTIL_Describe.getPrototypeObject(SObjectType.Allocation__c.getName());
        sourceObjA1.put(Allocation__c.General_Accounting_Unit__c.getDescribe().getName(),
                    gau1.Id);    
        sourceObjA1.put(Allocation__c.Percent__c.getDescribe().getName(),75);    

        SObject sourceObjA2 = UTIL_Describe.getPrototypeObject(SObjectType.Allocation__c.getName());
        sourceObjA2.put(Allocation__c.General_Accounting_Unit__c.getDescribe().getName(),
                    gau2.Id);    
        sourceObjA2.put(Allocation__c.Percent__c.getDescribe().getName(),25);    

        Sobject[] testWidgetRecords = new Sobject[]{sourceObjA1,sourceObjA2};
        
        Map<String,SObject[]> widgetData = new Map<String,SObject[]>();

        widgetData.put('GAU_Allocation_1',testWidgetRecords);

        String widgetDataString = JSON.serialize(widgetData);

        DataImport__c testDI = new DataImport__c();
        Test.startTest();
        GE_FormRendererService.convertWidgetDataToObjectJSON(testDI,widgetDataString);
        Test.stopTest();

        System.assertNotEquals(null,testDI.Additional_Object_JSON__c);

        BDI_DynamicSourceGroup testDSG = 
            (BDI_DynamicSourceGroup)JSON.deserialize(testDI.Additional_Object_JSON__c, BDI_DynamicSourceGroup.class);

        System.assertNotEquals(null,testDSG);
        System.assertEquals(2,testDSG.dynamicSourceByObjMappingDevName.size());

        BDI_DynamicSource dynSource1;
        BDI_DynamicSource dynSource2;

        for (String objMappingDevName : testDSG.dynamicSourceByObjMappingDevName.keySet()) {
            BDI_DynamicSource tempDS = testDSG.dynamicSourceByObjMappingDevName.get(objMappingDevName);
            if (tempDS.sourceObj.get('GAU_Allocation_1_GAU__c') == gau1.Id) {
                dynSource1 = tempDS;
            } else if (tempDS.sourceObj.get('GAU_Allocation_1_GAU__c')  == gau2.Id) {
                dynSource2 = tempDS;
            }
        }

        System.assertNotEquals(null, dynSource1);
        System.assertNotEquals(null, dynSource2);
        System.assertEquals(75,dynSource1.sourceObj.get('GAU_Allocation_1_Percent__c'));
        System.assertEquals(25,dynSource2.sourceObj.get('GAU_Allocation_1_Percent__c'));
    }
    */
}
