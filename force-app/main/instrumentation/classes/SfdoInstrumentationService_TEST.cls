/*
    Copyright (c) 2022 Salesforce.org
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
* @date 2022
* @group Product Instrumentation
* @description Unit Test for the Instrumetation Service Class
* The unit tests simply call the instrumentation service. It's not possible to mock or use an apex stub to truly validate these
* because the core apex class has to be defined as Static, which cannot be mocked or injected into the instrumentation service class.
*/
@IsTest
public with sharing class SfdoInstrumentationService_TEST {

    @IsTest
    private static void shouldConvertTriggerActionToEnum() {

        System.assertEquals(SfdoInstrumentationEnum.Action.AfterInsert, 
            SfdoInstrumentationService.getActionFromTriggerEvent(TDTM_Runnable.Action.AfterInsert),
            'The AfterInsert trigger action should be properly converted to the same InstrumetationService action');

        System.assertEquals(SfdoInstrumentationEnum.Action.AfterUpdate, 
            SfdoInstrumentationService.getActionFromTriggerEvent(TDTM_Runnable.Action.AfterUpdate),
            'The AfterUpdate trigger action should be properly converted to the same InstrumetationService action');

        System.assertEquals(SfdoInstrumentationEnum.Action.AfterDelete, 
            SfdoInstrumentationService.getActionFromTriggerEvent(TDTM_Runnable.Action.AfterDelete),
            'The AfterDelete trigger action should be properly converted to the same InstrumetationService action');

        System.assertEquals(SfdoInstrumentationEnum.Action.BeforeInsert, 
            SfdoInstrumentationService.getActionFromTriggerEvent(TDTM_Runnable.Action.BeforeInsert),
            'The BeforeInsert trigger action should be properly converted to the same InstrumetationService action');

        System.assertEquals(SfdoInstrumentationEnum.Action.BeforeUpdate, 
            SfdoInstrumentationService.getActionFromTriggerEvent(TDTM_Runnable.Action.BeforeUpdate),
            'The BeforeUpdate trigger action should be properly converted to the same InstrumetationService action');

        System.assertEquals(SfdoInstrumentationEnum.Action.BeforeDelete, 
            SfdoInstrumentationService.getActionFromTriggerEvent(TDTM_Runnable.Action.BeforeDelete),
            'The BeforeDelete trigger action should be properly converted to the same InstrumetationService action');
    }

    @IsTest
    private static void shouldInstrumentAction() {
        SfdoInstrumentationService.getInstance().log(
            SfdoInstrumentationEnum.Feature.Donations, 
            SfdoInstrumentationEnum.Component.Page,
            SfdoInstrumentationEnum.Action.Open);
        assertLastCallData(SfdoInstrumentationEnum.Feature.Donations, SfdoInstrumentationEnum.Component.Page, SfdoInstrumentationEnum.Action.Open);
    }

    @IsTest
    private static void shouldInstrumentActionWithValue() {
        Integer value = System.currentTimeMillis().intValue();
        SfdoInstrumentationService.getInstance().log(
            SfdoInstrumentationEnum.Feature.CustomizableRollups, 
            SfdoInstrumentationEnum.Component.Batch,
            SfdoInstrumentationEnum.Action.Duration, 
            value);
        assertLastCallData(SfdoInstrumentationEnum.Feature.CustomizableRollups, SfdoInstrumentationEnum.Component.Batch, SfdoInstrumentationEnum.Action.Duration, value);
    }

    @IsTest
    private static void shouldInstrumentActionWithContextMap() {
        Map<String, Object> context = new Map<String, Object>{ 'Test' => System.currentTimeMillis()};
        SfdoInstrumentationService.getInstance().log(
            SfdoInstrumentationEnum.Feature.Donations, 
            SfdoInstrumentationEnum.Component.Queueable,
            SfdoInstrumentationEnum.Action.Save, 
            context);
        context.put('RequestQuiddity', SfdoInstrumentationService.requestQuiddity);
        assertLastCallData(SfdoInstrumentationEnum.Feature.Donations, SfdoInstrumentationEnum.Component.Queueable, SfdoInstrumentationEnum.Action.Save, context);
    }

    @IsTest
    private static void shouldInstrumentActionWithMapAndValue() {
        Integer value = System.currentTimeMillis().intValue();
        Map<String, Object> context = new Map<String, Object>{ 'Test' => System.currentTimeMillis()};
        SfdoInstrumentationService.getInstance().log(
            SfdoInstrumentationEnum.Feature.Allocations, 
            SfdoInstrumentationEnum.Component.Future,
            SfdoInstrumentationEnum.Action.ProcessedCount, 
            context,
            value);
        context.put('RequestQuiddity', SfdoInstrumentationService.requestQuiddity);
        assertLastCallData(SfdoInstrumentationEnum.Feature.Allocations, SfdoInstrumentationEnum.Component.Future, SfdoInstrumentationEnum.Action.ProcessedCount, context, value);
    }

    @IsTest
    private static void shouldInstrumentActionWithSObjectAndValue() {
        SfdoInstrumentationService.getInstance().log(
            SfdoInstrumentationEnum.Feature.TDTM, 
            Account.getSObjectType(),
            SfdoInstrumentationEnum.Action.AfterInsert, 
            1);
        assertLastCallData(SfdoInstrumentationEnum.Feature.TDTM, Account.getSObjectType(), SfdoInstrumentationEnum.Action.AfterInsert, 1);
    }

    @IsTest
    private static void shouldInstrumentActionWithSObjectAndContextMap() {
        Map<String, Object> context = new Map<String, Object>{ 'Test' => System.currentTimeMillis()};
        SfdoInstrumentationService.getInstance().log(
            SfdoInstrumentationEnum.Feature.TDTM, 
            General_Accounting_Unit__c.getSObjectType(),
            SfdoInstrumentationEnum.Action.BeforeUpdate, 
            context,
            25);
        context.put('RequestQuiddity', SfdoInstrumentationService.requestQuiddity);
        assertLastCallData(SfdoInstrumentationEnum.Feature.TDTM, General_Accounting_Unit__c.getSObjectType(), SfdoInstrumentationEnum.Action.BeforeUpdate, context, 25);
    }

    @IsTest
    private static void shouldInstrumentActionWithSobject() {
        SfdoInstrumentationService.getInstance().log(
            SfdoInstrumentationEnum.Feature.RecordMerge, 
            Contact.getSObjectType(),
            SfdoInstrumentationEnum.Action.Dml_Merge);
        assertLastCallData(SfdoInstrumentationEnum.Feature.RecordMerge, Contact.getSObjectType(), SfdoInstrumentationEnum.Action.Dml_Merge);
    }

    @IsTest
    private static void shouldInstrumentActionWithSObjectContextMap() {
        Map<String, Object> context = new Map<String, Object>{ 'Test' => System.currentTimeMillis()};
        SfdoInstrumentationService.getInstance().log(
            SfdoInstrumentationEnum.Feature.Donations, 
            Opportunity.getSObjectType(),
            SfdoInstrumentationEnum.Action.Open,
            context);
        context.put('RequestQuiddity', SfdoInstrumentationService.requestQuiddity);
        assertLastCallData(SfdoInstrumentationEnum.Feature.Donations, Opportunity.getSObjectType(), SfdoInstrumentationEnum.Action.Open, context);
    }

    // ================================================================================================

    static void assertLastCallData(SfdoInstrumentationEnum.Feature feature, SfdoInstrumentationEnum.Component component, SfdoInstrumentationEnum.Action action, Integer value) {
        System.assertEquals(feature.name(), SfdoInstrumentationService.lastCallData.lastFeatureName);
        System.assertEquals(component.name(), SfdoInstrumentationService.lastCallData.lastComponentName);
        System.assertEquals(action.name(), SfdoInstrumentationService.lastCallData.lastActionName);
        System.assertEquals(value, SfdoInstrumentationService.lastCallData.lastValue);
    }
    static void assertLastCallData(SfdoInstrumentationEnum.Feature feature, SfdoInstrumentationEnum.Component component, SfdoInstrumentationEnum.Action action, Map<String, Object> context) {
        System.assertEquals(feature.name(), SfdoInstrumentationService.lastCallData.lastFeatureName);
        System.assertEquals(component.name(), SfdoInstrumentationService.lastCallData.lastComponentName);
        System.assertEquals(action.name(), SfdoInstrumentationService.lastCallData.lastActionName);
        System.assertEquals(context, SfdoInstrumentationService.lastCallData.lastContext);
    }
    static void assertLastCallData(SfdoInstrumentationEnum.Feature feature, SfdoInstrumentationEnum.Component component, SfdoInstrumentationEnum.Action action, Map<String, Object> context, Integer value) {
        System.assertEquals(feature.name(), SfdoInstrumentationService.lastCallData.lastFeatureName);
        System.assertEquals(component.name(), SfdoInstrumentationService.lastCallData.lastComponentName);
        System.assertEquals(action.name(), SfdoInstrumentationService.lastCallData.lastActionName);
        System.assertEquals(context, SfdoInstrumentationService.lastCallData.lastContext);
        System.assertEquals(value, SfdoInstrumentationService.lastCallData.lastValue);
    }
    static void assertLastCallData(SfdoInstrumentationEnum.Feature feature, SfdoInstrumentationEnum.Component component, SfdoInstrumentationEnum.Action action) {
        System.assertEquals(feature.name(), SfdoInstrumentationService.lastCallData.lastFeatureName);
        System.assertEquals(component.name(), SfdoInstrumentationService.lastCallData.lastComponentName);
        System.assertEquals(action.name(), SfdoInstrumentationService.lastCallData.lastActionName);
    }
    static void assertLastCallData(SfdoInstrumentationEnum.Feature feature, SObjectType objType, SfdoInstrumentationEnum.Action action) {
        System.assertEquals(feature.name(), SfdoInstrumentationService.lastCallData.lastFeatureName);
        System.assertEquals(String.valueOf(objType), SfdoInstrumentationService.lastCallData.lastComponentName);
        System.assertEquals(action.name(), SfdoInstrumentationService.lastCallData.lastActionName);
    }
    static void assertLastCallData(SfdoInstrumentationEnum.Feature feature, SObjectType objType, SfdoInstrumentationEnum.Action action, Integer value) {
        System.assertEquals(feature.name(), SfdoInstrumentationService.lastCallData.lastFeatureName);
        System.assertEquals(String.valueOf(objType), SfdoInstrumentationService.lastCallData.lastComponentName);
        System.assertEquals(action.name(), SfdoInstrumentationService.lastCallData.lastActionName);
        System.assertEquals(value, SfdoInstrumentationService.lastCallData.lastValue);
    }
    static void assertLastCallData(SfdoInstrumentationEnum.Feature feature, SObjectType objType, SfdoInstrumentationEnum.Action action, Map<String, Object> context, Integer value) {
        System.assertEquals(feature.name(), SfdoInstrumentationService.lastCallData.lastFeatureName);
        System.assertEquals(String.valueOf(objType), SfdoInstrumentationService.lastCallData.lastComponentName);
        System.assertEquals(action.name(), SfdoInstrumentationService.lastCallData.lastActionName);
        System.assertEquals(context, SfdoInstrumentationService.lastCallData.lastContext);
        System.assertEquals(value, SfdoInstrumentationService.lastCallData.lastValue);
    }
    static void assertLastCallData(SfdoInstrumentationEnum.Feature feature, SObjectType objType, SfdoInstrumentationEnum.Action action, Map<String, Object> context) {
        System.assertEquals(feature.name(), SfdoInstrumentationService.lastCallData.lastFeatureName);
        System.assertEquals(String.valueOf(objType), SfdoInstrumentationService.lastCallData.lastComponentName);
        System.assertEquals(action.name(), SfdoInstrumentationService.lastCallData.lastActionName);
        System.assertEquals(context, SfdoInstrumentationService.lastCallData.lastContext);
    }

    static void initServiceMock() {
        SfdoInstrumentationServiceMock serviceMock = new SfdoInstrumentationServiceMock();
        SfdoInstrumentationService service = (SfdoInstrumentationService) Test.createStub(
            SfdoInstrumentationService.class,
            serviceMock);
        SfdoInstrumentationService.instance = service;
    }

    private class SfdoInstrumentationServiceMock implements StubProvider {

        public Object handleMethodCall(Object stubbedObject, String stubbedMethodName,
                Type returnType, List<Type> listOfParamTypes, List<String> listOfParamNames,
                List<Object> listOfArgs) {

            if (stubbedMethodName == 'log') {
                // pretend it was logged
            }
            return null;
        }
    }

}
