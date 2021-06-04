/*
    Copyright (c) 2019, Salesforce.org
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
* @group BGE
* @group-content ../../ApexDocContent/BatchDataImport.htm
* @description Unit Tests for the BGE Utility class.
*/

@isTest
private with sharing class BGE_BatchGiftEntry_UTIL_TEST {

    /*********************************************************************************************************
    * @description Tests truncateList()
    */
    @isTest
    static void testTruncateList() {
        List<String> fruits = new List<String> { 'apple', 'banana', 'pear', 'orange' };
        System.assertEquals('apple, banana, pear, orange', BGE_BatchGiftEntry_UTIL.truncateList(fruits, 5));
        System.assertEquals('apple, banana, pear, orange', BGE_BatchGiftEntry_UTIL.truncateList(fruits, 4));
        System.assertEquals('apple, banana, pear ...', BGE_BatchGiftEntry_UTIL.truncateList(fruits, 3));
        System.assertEquals('apple, banana ...', BGE_BatchGiftEntry_UTIL.truncateList(fruits, 2));
        System.assertEquals('apple ...', BGE_BatchGiftEntry_UTIL.truncateList(fruits, 1));
    }

    /*********************************************************************************************************
    * @description Tests handleMissingPermissions() methods
    */
    @isTest
    static void testHandleMissingPermissions() {
        DescribeFieldResult acctNameDescribe = UTIL_Describe.getFieldDescribe('Account','Name');
        DescribeFieldResult createdByIdDescribe = UTIL_Describe.getFieldDescribe('Account','CreatedById');
        List<DescribeFieldResult> dfrs = new List<DescribeFieldResult> { acctNameDescribe, createdByIdDescribe };

        String expectedErrorMsg = Label.bgeFLSError + ' ['
            + acctNameDescribe.getLabel() + ', ' + createdByIdDescribe.getLabel()
            + ']';

        try {
            BGE_BatchGiftEntry_UTIL.handleMissingPermissions(dfrs);
        } catch (AuraHandledException ex) {
            System.assertEquals(expectedErrorMsg, ex.getMessage());
        }
    }

    /*********************************************************************************************************
    * @description Tests checkFieldPermissionsNeededForBatch() methods
    */
    @isTest
    static void testCheckFieldPermissionsNeededForBatch() {
        Boolean hasError = false;
        try {
            BGE_BatchGiftEntry_UTIL.checkFieldPermissionsNeededForBatch();
        } catch (AuraHandledException ex) {
            hasError = true;
            String errorMsg = ex.getMessage();
            System.assert(errorMsg.contains(Label.bgeFLSError), 'Only perms errors should be thrown.');
        } catch (Exception ex) {
            hasError = true;
            System.assert(false, 'Unhandled exception thrown.');
        }
    }

    @isTest
    static void shouldIncludeWidgetFields() {
        GE_Template.Element widgetElement =
                new GE_Template.Element(
                        'widget', '', '', '',
                        new String[]{
                                'Account_2_Country',
                                'Account_2_City'
                        });

        GE_Template.Section formSection =
                new GE_Template.Section('', '', '', '',
                        new GE_Template.Element[]{
                                widgetElement
                        });

        GE_Template.Layout formLayout =
                new GE_Template.Layout('', new GE_Template.Section[]{
                        formSection
                });

        GE_Template.Template formTemplate =
                new GE_Template.Template(
                        'testTemplate', '', '', formLayout);

        Form_Template__c template = new Form_Template__c(
                Template_JSON__c = JSON.serialize(formTemplate),
                Format_Version__c = '1.0');
        insert template;

        DataImportBatch__c batch = new DataImportBatch__c(
                Form_Template__c = template.Id,
                Batch_Gift_Entry_Version__c = 2.0
        );
        insert batch;

        List<String> queryFields =
                BGE_BatchGiftEntry_UTIL.getDataImportFields(
                        batch.Id, true
                );

        System.assert(
                queryFields.contains(
                        String.valueOf(DataImport__c.Account2_Country__c).toLowerCase()));
        System.assert(
                queryFields.contains(
                        String.valueOf(DataImport__c.Account2_City__c).toLowerCase()));
    }

    @isTest
    static void shouldReturnElevateFieldsForElevateCustomer() {
        GE_PaymentServicesMock mockInstance = new GE_PaymentServicesMock();
        mockInstance.withIsElevateCustomer(true);
        GiftBatchMock giftBatchMock = new GiftBatchMock();
        BGE_BatchGiftEntry_UTIL.giftBatch = stubFor(giftBatchMock);

        GE_PaymentServices paymentServicesMock = (GE_PaymentServices) Test.createStub(
            GE_PaymentServices.class,
            mockInstance
        );
        GE_PaymentServices.setInstance(paymentServicesMock);
        Test.startTest();
        Id dummyId = UTIL_UnitTestData_TEST.mockId(DataImportBatch__c.SObjectType);
        List<String> elevateFields = BGE_BatchGiftEntry_UTIL.getDataImportElevateFields(dummyId);
        System.assert(!elevateFields.isEmpty(), 'Elevate fields should be returned for an Elevate customer.');
        Test.stopTest();
    }

    @isTest
    static void shouldReturnNoElevateFieldsForNonElevateCustomer() {
        GE_PaymentServicesMock mockInstance = new GE_PaymentServicesMock();
        mockInstance.withIsElevateCustomer(false);

        GE_PaymentServices paymentServicesMock = (GE_PaymentServices) Test.createStub(
                GE_PaymentServices.class,
                mockInstance
        );
        GE_PaymentServices.setInstance(paymentServicesMock);
        Test.startTest();
        Id dummyId = UTIL_UnitTestData_TEST.mockId(DataImportBatch__c.SObjectType);
        List<String> elevateFields = BGE_BatchGiftEntry_UTIL.getDataImportElevateFields(dummyId);
        System.assert(elevateFields.isEmpty(), 'Elevate fields should not returned when the user is not an ' +
            'Elevate customer.');
        Test.stopTest();
    }

    private class ElevateConfigMock implements System.StubProvider {
        Boolean isElevateCustomer;
        public Object handleMethodCall(Object stubbedObject,
                                        String stubbedMethodName,
                                        Type returnType,
                                        List<Type> listOfParamTypes,
                                        List<String> listOfParamNames,
                                        List<Object> listOfArgs) {
            switch on stubbedMethodName {
                when 'isElevateCustomer' {
                    return isElevateCustomer;
                }
            }
            return null;
        }
    }

    public class GiftBatchMock implements StubProvider {
        public Object handleMethodCall(Object stubbedObject,
            String stubbedMethodName,
            Type returnType,
            List<Type> listOfParamTypes,
            List<String> listOfParamNames,
            List<Object> listOfArgs) {

            switch on (stubbedMethodName) {
                when 'hasElevateWidget' {
                    return true;
                }
            }

            return null;
        }
    }

    private static GiftBatch stubFor(GiftBatchMock giftBatchMock) {
        return (GiftBatch) Test.createStub(GiftBatch.class, giftBatchMock);
    }
}