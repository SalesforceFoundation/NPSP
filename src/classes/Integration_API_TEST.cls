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
* @description Units tests for Integration_API
*/
@isTest(isParallel=true)
private with sharing class Integration_API_TEST {
    private static UTIL_IntegrationConfig_TEST.MockPackage mockPackage;
    private static MockCallable callableMock;
    private static Integration_API integrationApi = new Integration_API();

    /**
     * @description Confirms that isRollupStateEnabled returns true if the bridge is installed
     */
    @isTest
    private static void shouldReturnTrueIfRollupStateEnabled() {
        setupMockIntegration();

        Test.startTest();
        Boolean isRollupStateEnabled = integrationApi.isRollupStateEnabled();
        Test.stopTest();

        System.assert(isRollupStateEnabled, 'API should indicate that rollup state is enabled');
    }

    /**
     * @description Confirms that isRollupStateEnabled returns false if the bridge is not installed
     */
    @isTest
    private static void shouldReturnFalseIfRollupStateEnabled() {
        setupMockIntegration();
        mockPackage.isInstalled = false;

        Test.startTest();
        Boolean isRollupStateEnabled = integrationApi.isRollupStateEnabled();
        Test.stopTest();

        System.assertEquals(false, isRollupStateEnabled, 'API should indicate that rollup state is not enabled');
    }

    /**
     * @description Confirms that getBaseRollupStateForRecords calls Bridge callable with correct action and params
     */
    @isTest
    private static void getBaseRollupStateForRecordsShouldCallBridgeCallable() {
        setupMockIntegration();

        String expectedRollupType = CRLP_RollupProcessingOptions.RollupType.AccountHardCredit.name();
        Set<Id> expectedReferenceIds = new Set<Id>(UTIL_UnitTestData_Test.mockIds(Account.SObjectType, 3));

        Test.startTest();

        integrationApi.getBaseRollupStateForRecords(
            expectedReferenceIds,
            CRLP_RollupProcessingOptions.RollupType.AccountHardCredit
        );

        Test.stopTest();

        System.assertEquals(Integration_API.ACTION_ARCHIVE_BRIDGE_GET_ROLLUP_STATE, callableMock.actionCalled,
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
        setupMockIntegration();
        mockPackage.isInstalled = false;

        Test.startTest();
        Map<Id, List<CRLP_Rollup>> actualRollupsByReferenceId =
            integrationApi.getBaseRollupStateForRecords(
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
        setupMockIntegration();

        List<CRLP_Rollup> rollups = buildMockRollups();

        Map<Id, List<CRLP_Rollup>> expectedRollupsByReferenceId = new Map<Id, List<CRLP_Rollup>>();
        Set<Id> expectedReferenceIds = new Set<Id>(UTIL_UnitTestData_Test.mockIds(Account.SObjectType, 3));
        for (Id referenceId : expectedReferenceIds) {
            expectedRollupsByReferenceId.put(referenceId, rollups.clone());
        }

        callableMock.withReturnValue(
            JSON.serialize(expectedRollupsByReferenceId)
        );

        Test.startTest();
        Map<Id, List<CRLP_Rollup>> actualRollupsByReferenceId =
            integrationApi.getBaseRollupStateForRecords(
                expectedReferenceIds,
                CRLP_RollupProcessingOptions.RollupType.AccountHardCredit
            );
        Test.stopTest();

        System.assertEquals(expectedReferenceIds, actualRollupsByReferenceId.keySet(),
            'The requested Ids should be keys in the CRLP rollup map');

        for (Id referenceId : actualRollupsByReferenceId.keySet()) {
            System.assertEquals(2, actualRollupsByReferenceId.get(referenceId).size(),
                'The correct number of rollups should be returned for each reference Id');
        }
    }

    /**
     * @description Builds mock rollups
     */
    private static List<CRLP_Rollup> buildMockRollups() {
        String filterGroupId = CMT_UnitTestData_TEST.getNewRecordId();

        String rollupsJSON = '[' +

            CMT_UnitTestData_TEST.createRollupRecord('Total Donations All Time', filterGroupId,
                CMT_UnitTestData_TEST.RollupRecordType.OppToAcct,
                'npo02__TotalOppAmount__c', CRLP_Operation.RollupType.Sum, 'Amount') + ',' +

            CMT_UnitTestData_TEST.createRollupRecord('Count Donations All Year', filterGroupId,
                CMT_UnitTestData_TEST.RollupRecordType.OppToAcct,
                'npo02__NumberOfClosedOpps__c', CRLP_Operation.RollupType.Count, 'Amount') +
        ']';

        List<Rollup__mdt> rollupMetadata = (List<Rollup__mdt>) JSON.deserialize(rollupsJSON, List<Rollup__mdt>.class);

        List<CRLP_Rollup> rollups = new List<CRLP_Rollup>();

        for (Rollup__mdt r : rollupMetadata) {
            rollups.add(new CRLP_Rollup(r));
        }

        return rollups;
    }


    /**
     * @description Instantiates Integration_API with mock packages so tests can run without the Bridge being installed
     */
    private static void setupMockIntegration() {
        mockPackage = new UTIL_IntegrationConfig_TEST.MockPackage();
        mockPackage.isInstalled = true;

        callableMock = new MockCallable();
        mockPackage.callableApi = callableMock;

        integrationApi = new Integration_API();
        integrationApi.archiveBridgePackage = mockPackage;
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
            return returnValue == null ? JSON.serialize(new Map<Id, List<CRLP_Rollup>>()) : returnValue;
        }
     }
}
