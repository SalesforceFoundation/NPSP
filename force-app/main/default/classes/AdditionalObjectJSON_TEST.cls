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
* @description AdditionalObjectJSON tests.
*/
@isTest
private class AdditionalObjectJSON_TEST {

    @isTest
    static void shouldReturnUsableDynamicSourceGroupWhenConvertingEmptyCollection() {
        AdditionalObjectJSON additionalObjectJSON = new AdditionalObjectJSON(null);
        String widgetDataString = '{"GAU_Allocation_1_6f5a83b87":[]}';
        String convertedWidgetData = additionalObjectJSON.convertWidgetDataToObjectJSON(widgetDataString);
        BDI_DynamicSourceGroup dummyDynamicSourceGroup = (BDI_DynamicSourceGroup)
            JSON.deserialize(convertedWidgetData, BDI_DynamicSourceGroup.class);

        System.assertNotEquals(null, convertedWidgetData);
        System.assertEquals(
            dummyDynamicSourceGroup.name,
            DataImport__c.Additional_Object_JSON__c.getDescribe().getName());
        System.assertNotEquals(null, dummyDynamicSourceGroup.dynamicSourceByObjMappingDevName);
    }

    @isTest
    static void shouldReturnUsableDynamicSourceGroupWhenConvertingEmptyString() {
        AdditionalObjectJSON additionalObjectJSON = new AdditionalObjectJSON(null);
        BDI_DynamicSourceGroup dummyDynamicSourceGroup = (BDI_DynamicSourceGroup)
            JSON.deserialize(additionalObjectJSON.convertWidgetDataToObjectJSON(''), BDI_DynamicSourceGroup.class);

        System.assertEquals(
            dummyDynamicSourceGroup.name,
            DataImport__c.Additional_Object_JSON__c.getDescribe().getName());
        System.assertNotEquals(null, dummyDynamicSourceGroup.dynamicSourceByObjMappingDevName);
    }

    @isTest
    static void shouldNotThrowExceptionWhenAdditionalObjectCollectionIsEmpty() {
        AdditionalObjectJSON additionalObjectJSON = new AdditionalObjectJSON('{"GAU_Allocation_1_6f5a83b87":[]}');
        String asJSON = additionalObjectJSON.asJSON();

        System.assertEquals(null, asJSON);
    }

    @isTest
    static void shouldAddSoftCreditsWhenAllocationsCollectionIsEmpty() {
        String dummyContactId0 = UTIL_UnitTestData_TEST.mockId(Contact.SObjectType);
        String dummyContactId1 = UTIL_UnitTestData_TEST.mockId(Contact.SObjectType);
        List<OpportunityContactRole> dummyOCRs = new List<OpportunityContactRole> {
            new OpportunityContactRole(Role = 'Influencer', ContactId = dummyContactId0),
            new OpportunityContactRole(Role = 'Soft Credit', ContactId = dummyContactId1)
        };

        AdditionalObjectJSON additionalObjectJSON = new AdditionalObjectJSON('{"GAU_Allocation_1_6f5a83b87":[]}');

        SoftCredits dummySoftCredits = new SoftCredits(dummyOCRs);
        additionalObjectJSON.add(dummySoftCredits);

        String backToJSON = additionalObjectJSON.asJSON();
        System.assert(backToJSON.contains(dummyContactId0));
        System.assert(backToJSON.contains(dummyContactId1));
    }

    @isTest
    static void shouldHaveSoftCreditsWithSize2() {
        String additionalObjectString =
            new UTIL_AdditionalObjectData_TEST()
            .withOpportunityContactRoles(2)
            .build();

        AdditionalObjectJSON additionalObjectJSON = new AdditionalObjectJSON(additionalObjectString);
        SoftCredits softCredits = additionalObjectJSON.asSoftCredits();

        System.assertEquals(2, softCredits.size());
    }

    @isTest
    static void shouldHaveSoftCreditsWithSize0() {
        String additionalObjectString =
            new UTIL_AdditionalObjectData_TEST()
            .withOpportunityContactRoles(0)
            .build();

        AdditionalObjectJSON additionalObjectJSON = new AdditionalObjectJSON(additionalObjectString);
        SoftCredits softCredits = additionalObjectJSON.asSoftCredits();

        System.assertEquals(0, softCredits.size());
    }

    @isTest
    static void shouldHaveSoftCreditsWithSize0ForNullAdditionalObjectJSONField() {
        AdditionalObjectJSON additionalObjectJSON = new AdditionalObjectJSON(null);
        SoftCredits softCredits = additionalObjectJSON.asSoftCredits();

        System.assertEquals(0, softCredits.size());
    }

    @isTest
    static void shouldAddSoftCreditsToDynamicSourceGroup() {
        String additionalObjectString =
            new UTIL_AdditionalObjectData_TEST()
            .withGeneralAccountingUnits(3)
            .build();

        AdditionalObjectJSON additionalObjectJSON = new AdditionalObjectJSON(additionalObjectString);

        String dummyContactId0 = UTIL_UnitTestData_TEST.mockId(Contact.SObjectType);
        String dummyContactId1 = UTIL_UnitTestData_TEST.mockId(Contact.SObjectType);
        String dummyContactId2 = UTIL_UnitTestData_TEST.mockId(Contact.SObjectType);
        List<OpportunityContactRole> dummyOCRs = new List<OpportunityContactRole> {
            new OpportunityContactRole(Role = 'Influencer', ContactId = dummyContactId0),
            new OpportunityContactRole(Role = 'Soft Credit', ContactId = dummyContactId1)
        };

        SoftCredits dummySoftCredits = new SoftCredits(dummyOCRs);

        BDI_DynamicSourceGroup dynamicSourceGroup = additionalObjectJSON.dynamicSourceGroup;
        System.assertEquals(dynamicSourceGroup.dynamicSourceByObjMappingDevName.values().size(), 3);

        additionalObjectJSON.add(dummySoftCredits);

        System.assertEquals(dynamicSourceGroup.dynamicSourceByObjMappingDevName.values().size(), 5);

        String backToJSON = additionalObjectJSON.asJSON();
        System.assert(backToJSON.contains(dummyContactId0));
        System.assert(backToJSON.contains(dummyContactId1));
        System.assert(!backToJSON.contains(dummyContactId2));
    }

    /***
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

        SObject sourceObjA1 = UTIL_Describe.getPrototypeObject(SObjectType.Allocation__c.getName());
        sourceObjA1.put(Allocation__c.General_Accounting_Unit__c.getDescribe().getName(),
                gau1.Id);
        sourceObjA1.put(Allocation__c.Percent__c.getDescribe().getName(),75);

        SObject sourceObjA2 = UTIL_Describe.getPrototypeObject(SObjectType.Allocation__c.getName());
        sourceObjA2.put(Allocation__c.General_Accounting_Unit__c.getDescribe().getName(),
                gau2.Id);
        sourceObjA2.put(Allocation__c.Percent__c.getDescribe().getName(),25);

        SObject[] testWidgetRecords = new SObject[]{sourceObjA1,sourceObjA2};

        Map<String,SObject[]> widgetData = new Map<String,SObject[]>();

        widgetData.put('GAU_Allocation_1',testWidgetRecords);

        String widgetDataString = JSON.serialize(widgetData);

        DataImport__c testDI = new DataImport__c();
        Test.startTest();
        AdditionalObjectJSON additionalObjectJSON = new AdditionalObjectJSON(null);
        testDI.Additional_Object_JSON__c = additionalObjectJSON.convertWidgetDataToObjectJSON(widgetDataString);
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
}
