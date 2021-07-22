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
* @description Tests for UTIL_IntegrationGateway
*/
@isTest
public with sharing class UTIL_IntegrationGateway_TEST {

    /**
     * @description Confirms handleBeforeDelete tries to call integration callable api if installed
     * and passes correct parameters to it
     */
    @isTest
    private static void shouldDispatchToIntegrationsOnBeforeDeleteWhenInstalled() {
        UTIL_IntegrationConfig_TEST.MockPackage mockPackage = new UTIL_IntegrationConfig_TEST.MockPackage();
        mockPackage.isInstalled = true;

        MockCallable callableMock = new MockCallable();
        mockPackage.callableApi = callableMock;

        UTIL_IntegrationGateway gateway = new UTIL_IntegrationGateway();
        gateway.archiveBridgeConfig = mockPackage;

        List<SObject> triggerOld = UTIL_UnitTestData_TEST.createMultipleTestAccounts(10, null);
        UTIL_UnitTestData_TEST.setMockIds(triggerOld);

        Test.startTest();
        gateway.handleBeforeDelete(triggerOld);
        Test.stopTest();

        System.assertEquals(1, callableMock.callCount, 'The archive bridge api should have been called once');

        System.assert(callableMock.paramsByAction.containsKey(UTIL_IntegrationGateway.ACTION_HANDLE_BEFORE_DELETE),
            'The archive bridge api should have been called with the correct action');

        Map<String, Object> paramsForAction = callableMock.paramsByAction.get(UTIL_IntegrationGateway.ACTION_HANDLE_BEFORE_DELETE);

        System.assertEquals(triggerOld, paramsForAction.get(UTIL_IntegrationGateway.PARAM_TRIGGER_OLD),
            'Should pass Trigger.old to the archive API with the correct parameter');
    }

    /**
     * @description Confirms handleBeforeDelete does not try to call integration callable api if not installed
     */
    @isTest
    private static void shouldNotDispatchToIntegrationsOnBeforeDeleteWhenNotInstalled() {
        UTIL_IntegrationConfig_TEST.MockPackage mockPackage = new UTIL_IntegrationConfig_TEST.MockPackage();
        mockPackage.isInstalled = false;

        MockCallable callableMock = new MockCallable();
        mockPackage.callableApi = callableMock;

        UTIL_IntegrationGateway gateway = new UTIL_IntegrationGateway();
        gateway.archiveBridgeConfig = mockPackage;

        List<SObject> triggerOld = UTIL_UnitTestData_TEST.createMultipleTestAccounts(10, null);
        UTIL_UnitTestData_TEST.setMockIds(triggerOld);

        Test.startTest();
        gateway.handleBeforeDelete(triggerOld);
        Test.stopTest();

        System.assertEquals(0, callableMock.callCount, 'The archive bridge api should not have been called');
    }

    /**
     * @description Mock Callable class that takes place of the Bridge callable class
     */
    private class MockCallable implements System.Callable {
        Integer callCount = 0;
        Map<String, Map<String, Object>> paramsByAction = new Map<String, Map<String, Object>>();
        /**
         * @description Mocks the call method, tracks the action called, the provided params
         */
        public Object call(String action, Map<String, Object> params) {
            paramsByAction.put(action, params);
            callCount++;

            return null;
        }
    }

    /*******************************************************************************************************************
    * @description Stub for UTIL_Permissions instance
    */
    public class Stub implements System.StubProvider {
        public Map<String, Map<String,Object>> paramsByMethodName = new Map<String, Map<String,Object>>();

        public Object handleMethodCall(
            Object stubbedObject,
            String stubbedMethodName,
            Type returnType,
            List<Type> paramTypes,
            List<String> params,
            List<Object> paramValues
        ) {
            if (!paramsByMethodName.containsKey(stubbedMethodName)) {
                paramsByMethodName.put(stubbedMethodName, new Map<String,Object>());
            }

            if (params != null && !params.isEmpty()) {
                for (Integer i = 0; i < params.size(); i++) {
                    paramsByMethodName.get(stubbedMethodName).put(params[i], paramValues[i]);
                }
            }

            return null;
        }
    }
}
