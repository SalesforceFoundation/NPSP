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
* @description Unit Tests for the Customizable Rollups Api Service class
*/
@IsTest(IsParallel=true)
private class CRLP_ApiService_TEST {
    private static UTIL_IntegrationConfig_TEST.MockPackage mockPackage;
    private static MockCallable callableMock;

    private static final String ROLLUP_DEFINITIONS = '[{"useFiscalYear":false,"timeBoundOperation":"All_Time","theSum":0,"theCount":0,"textValue":[null,null,null,null],"summaryObject":"General_Accounting_Unit__c","sumByYear":{}}]';

    /**
     * @description Validate the getRollupDefinitions returns the expected collection of CRLP_Rollup instances.
     * Calls the mocking utilities to build a bunch of rollup definitions and filter groups/rules fo
     */
    @IsTest
    private static void shouldReturnRollupDefinitionsWhenParameterIsValid() {
        mockRollupDefinitions();

        UTIL_CustomSettingsFacade.getRollupSettingsForTests(new Customizable_Rollup_Settings__c (
            Customizable_Rollups_Enabled__c = true
        ));

        CRLP_ApiService service = new CRLP_ApiService();

        Test.startTest();
        for (CRLP_RollupProcessingOptions.RollupType rollupType : CRLP_RollupProcessingOptions.RollupType.values()) {
            List<CRLP_Rollup> rollups = service.getRollupDefinitions(rollupType.name());
            System.assertEquals(1, rollups.size(),
                'The collection of returned rollups should contain exactly 1 instance for ' + rollupType.name());
            System.assertEquals(2, rollups[0].rollupsMdt.size(),
                'There should be two Rollup__mdt records associated with the CRLP_Rollup instance');
        }
    }

    /**
     * @description Validate the getRollupDefinitions returns an exception if the RollupType is null or invalid
     */
    @IsTest
    private static void shouldThrowExceptionWhenParameterIsInvalid() {
        CRLP_ApiService service = new CRLP_ApiService();

        UTIL_CustomSettingsFacade.getRollupSettingsForTests(new Customizable_Rollup_Settings__c (
            Customizable_Rollups_Enabled__c = true
        ));

        Test.startTest();
        for (String param : new String[] { null, 'NonExistentType' }) {
            Exception actualException = null;
            try {
                service.getRollupDefinitions(param);
            } catch (Exception e) {
                actualException = e;
            }
            System.assertNotEquals(null, actualException,
                'An exception should be thrown for invalid param: ' + param);
            System.assert(actualException.getMessage().containsIgnoreCase(CRLP_ApiService.PARAM_ROLLUPTYPE),
                'Message should contain "' + CRLP_ApiService.PARAM_ROLLUPTYPE + '" param: ' + actualException.getMessage());
        }
    }

    /**
     * @description Validate the getRollupDefinitions returns an empty list<> when CRLP is not enabled
     */
    @IsTest
    private static void shouldReturnEmptyListWhenCRLPNotEnabled() {
        CRLP_ApiService service = new CRLP_ApiService();

        System.assert(service.getRollupDefinitions(null).isEmpty(),
            'When CRLP is disabled, then call to getRollupDefinitions should return an empty list');
    }

    /**
     * @description Confirms that isRollupStateEnabled returns true if the bridge is installed
     */
    @isTest
    private static void shouldReturnTrueIfRollupStateEnabled() {
        CRLP_ApiService service = new CRLP_ApiService();
        setupMockIntegration(service);

        Test.startTest();
        Boolean isRollupStateEnabled = service.isRollupStateEnabled();
        Test.stopTest();

        System.assert(isRollupStateEnabled, 'API should indicate that rollup state is enabled');
    }

    /**
     * @description Confirms that isRollupStateEnabled returns false if the bridge is not installed
     */
    @isTest
    private static void shouldReturnFalseIfRollupStateEnabled() {
        CRLP_ApiService service = new CRLP_ApiService();
        setupMockIntegration(service);
        mockPackage.isInstalled = false;

        Test.startTest();
        Boolean isRollupStateEnabled = service.isRollupStateEnabled();
        Test.stopTest();

        System.assertEquals(false, isRollupStateEnabled, 'API should indicate that rollup state is not enabled');
    }

    /**
     * @description Confirms that getBaseRollupStateForRecords calls Bridge callable with correct action and params
     */
    @isTest
    private static void getBaseRollupStateForRecordsShouldCallBridgeCallable() {
        CRLP_ApiService service = new CRLP_ApiService();
        setupMockIntegration(service);

        String expectedRollupType = CRLP_RollupProcessingOptions.RollupType.AccountHardCredit.name();
        Set<Id> expectedReferenceIds = new Set<Id>(UTIL_UnitTestData_Test.mockIds(Account.SObjectType, 3));

        Test.startTest();

        service.getBaseRollupStateForRecords(
            expectedReferenceIds,
            CRLP_RollupProcessingOptions.RollupType.AccountHardCredit
        );

        Test.stopTest();

        System.assertEquals(CRLP_ApiService.ACTION_ARCHIVE_BRIDGE_GET_ROLLUP_STATE, callableMock.actionCalled,
            'The correct action should be called');

        System.assert(callableMock.providedParams.containsKey('RecordIds'),
            'The RecordIds param should be included');

        Object recordIds = callableMock.providedParams.get('RecordIds');

        System.assert(recordIds instanceof Set<Id>, 'The RecordIds param value should be a Set<Id>');
        System.assert(expectedReferenceIds.equals((Set<Id>) recordIds),
            'The correct Ids should be passed as the RecordIds param value');

        System.assert(callableMock.providedParams.containsKey('RollupType'),
            'The RollupType param should be included');

        Object actualRollupType = callableMock.providedParams.get('RollupType');

        System.assert(actualRollupType instanceof String, 'The RollupType param value should be a String');
        System.assertEquals(expectedRollupType, actualRollupType,
            'The correct RollupType should be passed as the RollupType param value');
    }

    /**
     * @description Confirms that getBaseRollupStateForRecords returns an empty map if not installed
     */
    @isTest
    private static void getBaseRollupStateForRecordsShouldReturnAnEmptyMapIfNotInstalled() {
        CRLP_ApiService service = new CRLP_ApiService();
        setupMockIntegration(service);
        mockPackage.isInstalled = false;

        Test.startTest();
        Map<Id, List<CRLP_Rollup>> actualRollupsByReferenceId =
            service.getBaseRollupStateForRecords(
                new Set<Id>(),
                CRLP_RollupProcessingOptions.RollupType.AccountHardCredit
            );
        Test.stopTest();

        System.assertEquals(null, callableMock.actionCalled, 'The callabled action should not be called');
        System.assert(actualRollupsByReferenceId.isEmpty(), 'An empty map should be returned');
    }

    /**
     * @description Confirms that getBaseRollupStateForRecords returns a CRLPRollupMap with the requested data
     */
    @isTest
    private static void getBaseRollupStateForRecordsShouldBuildCRLPRollupMap() {
        CRLP_ApiService service = new CRLP_ApiService();
        setupMockIntegration(service);

        Map<Id, String> expectedRollupsByReferenceId = new Map<Id, String>();
        Set<Id> expectedReferenceIds = new Set<Id>(UTIL_UnitTestData_Test.mockIds(Account.SObjectType, 3));
        for (Id referenceId : expectedReferenceIds) {
            expectedRollupsByReferenceId.put(referenceId, ROLLUP_DEFINITIONS);
        }

        callableMock.withReturnValue(expectedRollupsByReferenceId);

        Test.startTest();
        Map<Id, List<CRLP_Rollup>> actualRollupsByReferenceId =
            service.getBaseRollupStateForRecords(
                expectedReferenceIds,
                CRLP_RollupProcessingOptions.RollupType.AccountHardCredit
            );
        Test.stopTest();

        System.assertEquals(expectedReferenceIds, actualRollupsByReferenceId.keySet(),
            'The requested Ids should be keys in the CRLP rollup map');

        for (Id referenceId : actualRollupsByReferenceId.keySet()) {
            System.assertEquals(1, actualRollupsByReferenceId.get(referenceId).size(),
                'The correct number of rollups should be returned for each reference Id');
        }
    }

    // Helpers
    ////////////

    /**
     * @description Mock the Rollup__mdt records for use within this unit test class
     */
    private static void mockRollupDefinitions() {

        String filterGroupId = CMT_UnitTestData_TEST.getNewRecordId();

        // Create two Rollup Definition per Rollup Type that will be grouped into a single CRLP_Rollup instance.
        // The FilterGroup itself doesn't need to exist for this test, but an Id is needed.
        String rollupsJSON = '[' +

            // Contact Hard Credit
            CMT_UnitTestData_TEST.createRollupRecord('Total Donations All Time', filterGroupId,
                CMT_UnitTestData_TEST.RollupRecordType.OppToContact,
                'npo02__TotalOppAmount__c', CRLP_Operation.RollupType.Sum, 'Amount') + ',' +

            CMT_UnitTestData_TEST.createRollupRecord('Count Donations All Year', filterGroupId,
                CMT_UnitTestData_TEST.RollupRecordType.OppToContact,
                'npo02__NumberOfClosedOpps__c', CRLP_Operation.RollupType.Count, 'Amount') + ',' +

            // Account Hard Credit
            CMT_UnitTestData_TEST.createRollupRecord('Total Donations All Time', filterGroupId,
                CMT_UnitTestData_TEST.RollupRecordType.OppToAcct,
                'npo02__TotalOppAmount__c', CRLP_Operation.RollupType.Sum, 'Amount') + ',' +

            CMT_UnitTestData_TEST.createRollupRecord('Count Donations All Year', filterGroupId,
                CMT_UnitTestData_TEST.RollupRecordType.OppToAcct,
                'npo02__NumberOfClosedOpps__c', CRLP_Operation.RollupType.Count, 'Amount') + ',' +

            // Account Contact Soft Credit
            CMT_UnitTestData_TEST.createRollupRecord('Account: Soft Credits - Total', filterGroupId,
                CMT_UnitTestData_TEST.RollupRecordType.ContactSoftCreditToAccount,
                'npo02__TotalOppAmount__c', CRLP_Operation.RollupType.Sum, 'Amount__c') + ',' +

            CMT_UnitTestData_TEST.createRollupRecord('Count Donations All Year', filterGroupId,
                CMT_UnitTestData_TEST.RollupRecordType.ContactSoftCreditToAccount,
                'npo02__NumberOfClosedOpps__c', CRLP_Operation.RollupType.Count, 'Amount') + ',' +

            // Account Soft Credit
            CMT_UnitTestData_TEST.createRollupRecord('Total Account Soft Credits', filterGroupId,
                CMT_UnitTestData_TEST.RollupRecordType.AccountSoftCreditToAccount, 'Matching_Gift_Amount_Max__c',
                CRLP_Operation.RollupType.Sum, 'Amount__c') + ',' +

            CMT_UnitTestData_TEST.createRollupRecord('Count Donations All Year', filterGroupId,
                CMT_UnitTestData_TEST.RollupRecordType.AccountSoftCreditToAccount,
                'npo02__NumberOfClosedOpps__c', CRLP_Operation.RollupType.Count, 'Amount') + ',' +

            // Contact Soft Credit
            CMT_UnitTestData_TEST.createRollupRecord('Contact: Soft Credits - Total', filterGroupId,
                CMT_UnitTestData_TEST.RollupRecordType.SoftCreditToContact,
                'npo02__Soft_Credit_Total__c', CRLP_Operation.RollupType.Sum, 'Amount__c') + ',' +

            CMT_UnitTestData_TEST.createRollupRecord('Count Donations All Year', filterGroupId,
                CMT_UnitTestData_TEST.RollupRecordType.SoftCreditToContact,
                'npo02__NumberOfClosedOpps__c', CRLP_Operation.RollupType.Count, 'Amount') + ',' +

            // GAU
            CMT_UnitTestData_TEST.createRollupRecord('Total Allocations All Time', filterGroupId,
                CMT_UnitTestData_TEST.RollupRecordType.GAU,
                'Total_Allocations__c', CRLP_Operation.RollupType.Sum, 'Amount__c',
                CRLP_Operation.TimeBoundOperationType.All_Time, 0) + ',' +

            CMT_UnitTestData_TEST.createRollupRecord('Count Donations All Year', filterGroupId,
                CMT_UnitTestData_TEST.RollupRecordType.GAU,
                'Total_Number_of_Allocations__c', CRLP_Operation.RollupType.Count, 'Amount') + ',' +

            // Recurring Donations
            CMT_UnitTestData_TEST.createRollupRecord('RD Next Payment Date', filterGroupId,
                CMT_UnitTestData_TEST.RollupRecordType.OppToRD,
                'npe03__Next_Payment_Date__c', CRLP_Operation.RollupType.First, 'CloseDate') + ',' +

            CMT_UnitTestData_TEST.createRollupRecord('Count Donations All Year', filterGroupId,
                CMT_UnitTestData_TEST.RollupRecordType.OppToRD,
                'npe03__Total_Paid_Installments__c', CRLP_Operation.RollupType.Count, 'Amount') +

            ']';

        // Deserialize the rollups to use for testing
        CRLP_Rollup_SEL.cachedRollups = (List<Rollup__mdt>) JSON.deserialize(rollupsJSON, List<Rollup__mdt>.class);

    }

    /**
     * @description Sets up mock package and callable api on the provided CRLP_ApiService instance
     * so tests can run without the Bridge being installed
     */
    private static void setupMockIntegration(CRLP_ApiService service) {
        mockPackage = new UTIL_IntegrationConfig_TEST.MockPackage();
        mockPackage.isInstalled = true;

        callableMock = new MockCallable();
        mockPackage.callableApi = callableMock;

        service.archiveBridgeConfig = mockPackage;
    }

    /**
     * @description Mock Callable class that takes place of the Bridge callable class
     */
    private class MockCallable implements System.Callable {
        Object returnValue;
        Map<String, Object> providedParams;
        String actionCalled;

        /**
         * @description Sets return value for callable
         */
        private MockCallable withReturnValue(Object returnValue) {
            this.returnValue = returnValue;
            return this;
        }

        /**
         * @description Mocks the call method, tracks the action called, the provided params
         */
        public Object call(String action, Map<String, Object> params) {
            providedParams = params;
            actionCalled = action;
            return returnValue == null ? new Map<Id, String>() : returnValue;
        }
    }

}