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
* @group API
* @group-content ../../ApexDocContent/API.htm
* @description Tests specific to Callable API.
*/
@IsTest(isParallel=true)
private with sharing class Callable_API_TEST {

    private static final String TDTM_TRIGGER_ACTION = 'TDTM.DisableAllTriggers';
    private static final String CRLP_IS_ENABLED_ACTION = 'CRLP.iscrlpenabled';
    private static final String RD2_EXECUTE_MIGRATION_ACTION = 'RD2.ExecuteDataMigration';
    private static final String RD2_ENABLE_ACTION = 'Settings.EnableEnhancedRecurringDonations';
    private static final String JOB_SCHEDULE_ACTION = 'Apex.ScheduleJob';
    private static final String RD2_PAUSE_ACTION = 'rd2.pause';
    private static final String ADVANCED_MAPPING_ACTION = 'settings.enableadvancedmapping';
    private static final String GIFT_ENTRY_ACTION = 'settings.enablegiftentry';
    private static final String PROCESS_REFUNDS = 'pmt.procressrefunds';

    /**
    * @description verify the TDTM Callable action returns an Object
    */
    @IsTest
    private static void verifyCallableReturnsAnObject() {
        // skip the test if Advancement is installed
        if (ADV_PackageInfo_SVC.useAdv()) {
            return;
        }

        Test.startTest();

        Integer accountCountBefore = Database.countQuery('SELECT COUNT() FROM Account');

        Callable npspApi = (Callable) Type.forName('Callable_API').newInstance();
        Map<String, Object> triggerArgs = new Map<String, Object>();
        Object result = npspApi.call(TDTM_TRIGGER_ACTION, triggerArgs);

        Contact contact1 = new Contact(LastName = 'CallableApi_Test');
        insert contact1;

        Test.stopTest();

        Object callResult = result;
        System.assertNotEquals(null, callResult, 'No result was returned from call');

        Integer accountCountAfter = Database.countQuery('SELECT COUNT() FROM Account');
        System.assertEquals(accountCountBefore, accountCountAfter, 'Account record was created');
    }

    /**
    * @description verify the CRLP call returns true if enabled
    */
    @isTest
    private static void verifyCrlpEnabledCallReturnsRollupEnabled() {
         UTIL_CustomSettingsFacade.getRollupSettingsForTests(new Customizable_Rollup_Settings__c (
            Customizable_Rollups_Enabled__c = true
        ));

        Test.startTest();

        Callable npspApi = (Callable) Type.forName('Callable_API').newInstance();
        Map<String, Object> args = new Map<String, Object>();
        Object result = npspApi.call(CRLP_IS_ENABLED_ACTION, args);

        Test.stopTest();

        System.assertEquals(true, (Boolean) result, 'CRLP is identified as enabled');
    }

    /**
    * @description Call the API with an invalid action text and make sure an exception is thrown
    */
    @IsTest
    private static void callableApiThrowsExceptionWhenActionIsInvalid() {

        Test.startTest();

        Callable npspApi = (Callable) Type.forName('Callable_API').newInstance();
        Map<String, Object> triggerArgs = new Map<String, Object>();

        String expectedMessagePortion = ((System.Label.CallableApiMethodNotImplemented).split('}')[1]).trim();

        try {
            Object result = npspApi.call('InvalidAction', triggerArgs);
            System.assert(false, 'The exception was not thrown');
        } catch (Callable_API.MalformedMethodInvocationException apiException) {
            System.assert(apiException.getMessage().contains(expectedMessagePortion), apiException.getMessage());
        }

        Test.stopTest();
    }

    @IsTest
    private static void shouldCallEnableAdvancedMappingOnAction() {
        Callable_API callableApi = new Callable_API();
        AdvancedMappingEnablementServiceMock mappingServiceMock = new AdvancedMappingEnablementServiceMock();
        callableApi.advancedMappingEnablementService = stubFor(mappingServiceMock);

        Test.startTest();
            callableApi.call(ADVANCED_MAPPING_ACTION, null);
        Test.stopTest();

        System.assert(mappingServiceMock.enableAdvancedMappingCalled, 'The enable advanced mapping service method ' +
                'should be called.');
    }

    @IsTest
    private static void shouldNotCallEnableAdvancedMappingIfMappingIsEnabled() {
        Callable_API callableApi = new Callable_API();
        AdvancedMappingEnablementServiceMock mappingServiceMock = new
                AdvancedMappingEnablementServiceMock();
        mappingServiceMock.setEnabled();

        callableApi.advancedMappingEnablementService = stubFor(mappingServiceMock);

        Test.startTest();
            callableApi.call(ADVANCED_MAPPING_ACTION, null);
        Test.stopTest();

        System.assert(!mappingServiceMock.enableAdvancedMappingCalled, 'The enable advanced mapping service method ' +
                'should not be called.');
    }

    @IsTest
    private static void shouldCallEnableGiftEntryOnAction() {
        Callable_API callableApi = new Callable_API();
        GiftEntryEnablementServiceMock giftEntryEnablementServiceMock = new GiftEntryEnablementServiceMock();

        callableApi.giftEntryEnablementService = stubFor(giftEntryEnablementServiceMock);

        Test.startTest();
            callableApi.call(GIFT_ENTRY_ACTION, null);
        Test.stopTest();

        System.assert(giftEntryEnablementServiceMock.enableGiftEntryCalled, 'The enable gift entry service method ' +
            'should be called.');
    }

    @IsTest
    private static void shouldNotCallEnableGiftEntryIfAlreadyEnabled() {
        GiftEntryEnablementServiceMock giftEntryEnablementServiceMock = new GiftEntryEnablementServiceMock();
        giftEntryEnablementServiceMock.setEnabled();

        Callable_API callableApi = new Callable_API();
        callableApi.giftEntryEnablementService = stubFor(giftEntryEnablementServiceMock);

        Test.startTest();
            callableApi.call(ADVANCED_MAPPING_ACTION, null);
        Test.stopTest();

        System.assert(!giftEntryEnablementServiceMock.enableGiftEntryCalled, 'The enable gift entry service ' +
                'method should not be called.');
    }

    /**
     * @description Verifies if Enhanced Recurring Donations are enabled
     */
    @IsTest
    private static void shouldEnableRD2OnEnableRD2Action() {
        RD2_EnablementService_Test.setCustomizableRollups(true);

        Test.startTest();

        Callable callableApi = (Callable) Type.forName('Callable_API').newInstance();
        Map<String, Object> args = new Map<String, Object>{ 'ScheduleJobs' => false };
        callableApi.call(RD2_ENABLE_ACTION, args);

        Test.stopTest();

        System.assertEquals(true,  STG_Panel.stgService.stgRD.IsRecurringDonations2Enabled__c);
    }

    /**
     * @description Verifies Enhanced Recurring Donations migration batch job is executed
     */
    @IsTest
    private static void shouldRunRD2DataMigrationWhenRD2IsEnabled() {
        RD2_EnablementService_TEST.setRecurringDonations2Enabled();

        Test.startTest();

        Callable callableApi = (Callable) Type.forName('Callable_API').newInstance();
        Map<String, Object> args = new Map<String, Object>();
        Object result = callableApi.call(RD2_EXECUTE_MIGRATION_ACTION, args);

        Test.stopTest();
        
        AsyncApexJob job = new TEST_SObjectGateway.AsyncApexJobGateway()
            .getRecord('RD2_DataMigration_BATCH');
        System.assertNotEquals(null, job, 'The batch should be executed');
    }

    @isTest
    private static void shouldProcessPauseRequestWhenCallingPauseAPI() {
        RD2_EnablementService_TEST.setRecurringDonations2Enabled();
        

        Map<String, Object> pauseData = new Map<String, Object> {
            'startDate' => Date.Parse('04/02/2019'),
            'endDate' => Date.Parse('7/02/2019'),
            'unPause' => false,
            'statusReason' => 'Vacation'
        };
        Map<Id,Object> rdPauseData = new Map<Id,Object>{
            UTIL_UnitTestData_TEST.MOCK_ACCOUNT_ID => pauseData
        };
        
        Map<String, Object> params = new Map<String, Object> { CallableApiParameters.PARAM_PAUSE_DATA => rdPauseData };
        Callable callable = (System.Callable)Type.forName('', 'Callable_Api').newInstance();
        
        Test.startTest();
        String response = (String) callable.call(RD2_PAUSE_ACTION, params);
        Test.stopTest();
    
        Map<String, RD2_ApiService.PauseObject> result =
            (Map<String, RD2_ApiService.PauseObject>)JSON.deserialize(response, Map<String, RD2_ApiService.PauseObject>.class);

        RD2_ApiService.PauseObject returnPause = result.get(UTIL_UnitTestData_TEST.MOCK_ACCOUNT_ID);

        System.assertNotEquals(null, returnPause.isSuccess, 'Expect a PauseObject payload is returned');
        System.assertEquals(false, returnPause.isSuccess, 'Expect the operation fail because of the invalid Id');

        String expectedErrorMessage = String.format(System.Label.RD2_InvalidRecurringDonationId,
            new List<String> { UTIL_UnitTestData_TEST.MOCK_ACCOUNT_ID });
        System.assertEquals(expectedErrorMessage, returnPause.error, 'An error with unexpected Id should be return');
    }

    @isTest
    private static void  shouldProcessRefundAllocationsAndOpportunity() {
        Opportunity oppRecord = PMT_RefundService_TEST.getOpportunityRecord();
        npe01__OppPayment__c originalPayment = PMT_RefundService_TEST.getPaymentRecord(oppRecord.Id);
        List<Allocation__c> allocations = PMT_RefundService_TEST.getAllocationRecords(oppRecord);

        PMT_RefundService refundService = PMT_RefundService_TEST.setupRefundServiceWithStubs(
            new List<npe01__OppPayment__c>{originalPayment},
            new List<Opportunity>{oppRecord},
            allocations
        );

        Callable_API callableApi = new Callable_API();
        callableApi.refundService = refundService;

        Decimal refundAmount = originalPayment.npe01__Payment_Amount__c / 2;
        Decimal expectedPercentage = allocations[0].Amount__c / oppRecord.Amount * 100;
        

        Map<String, Object> args = new Map<String, Object>{
            'RefundRecords' => new List<npe01__OppPayment__c> {refundService.buildRefundRecord(originalPayment, refundAmount)}
        };
        

        Test.startTest();
        callableApi.call(PROCESS_REFUNDS, args);
        Test.stopTest();

        List<Allocation__c> updatedAllocations = callableApi.refundService.allocationsToUpdate;
        Opportunity parentOpp = refundService.opportunityMap.values()?.get(0);
        for (Allocation__c allo : updatedAllocations) {
            System.assertEquals(expectedPercentage , allo.Percent__c,
                'Fixed Amount should be convet into percentage');
        }
        System.assertNotEquals(null, parentOpp, 'The parent opportunity should be proccessed');
        System.assertEquals(originalPayment.npe01__Payment_Amount__c - refundAmount, parentOpp.Amount,
            'Partial Refund Amount should be deducted from the opportunity amount');
    }

    private static GiftEntryEnablementService stubFor(GiftEntryEnablementServiceMock giftEntryEnablementServiceMock) {
        return (GiftEntryEnablementService) Test.createStub(
                GiftEntryEnablementService.class, giftEntryEnablementServiceMock);
    }

    private static AdvancedMappingEnablementService stubFor(AdvancedMappingEnablementServiceMock
            advancedMappingControllerMock) {
        return (AdvancedMappingEnablementService) Test.createStub(
                AdvancedMappingEnablementService.class, advancedMappingControllerMock);
    }

    private class GiftEntryEnablementServiceMock implements StubProvider {
        Boolean enableGiftEntryCalled = false;
        Boolean isEnabled = false;

        public void setEnabled() {
            isEnabled = true;
        }

        public Object handleMethodCall(
                Object stubbedObject,
                String stubbedMethodName,
                Type returnType,
                List<Type> listOfParamTypes,
                List<String> listOfParamNames,
                List<Object> listOfArgs) {

            switch on (stubbedMethodName) {
                when 'enable' {
                    enableGiftEntryCalled = true;
                }
                when 'isEnabled' {
                    return isEnabled;
                }
            }
            return null;
        }
    }
}
