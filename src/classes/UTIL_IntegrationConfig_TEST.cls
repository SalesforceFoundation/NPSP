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
* @description Unit Tests for the UTIL_IntegrationConfig
*/
@isTest(isParallel=true)
public with sharing class UTIL_IntegrationConfig_TEST {
    /**********************************************************************************************************
    * @description Verifies package configuration inquiry returns correct indicator if it is installed
    */
    @isTest
    private static void shouldConfirmIfPackageIsInstalled() {
        MockPackage pkg = new MockPackage();

        System.assertEquals(true, pkg.isInstalled(), 'Package should be installed');
    }

    /**********************************************************************************************************
    * @description Verifies package returns entity name prefixed with its namespace
    */
    @isTest
    private static void shouldPrefixPackageEntityWithNamespace() {
        MockPackage pkg = new MockPackage();

        String namespace = 'foo';
        pkg.namespace = namespace;

        String entity = 'TestSObject__c';
        System.assertEquals(namespace + '__' + entity, pkg.prefixNamespace(entity));
    }

    /**********************************************************************************************************
    * @description Verifies package returns System.Callable as its Callable API
    */
    @isTest
    private static void shouldReturnDSOBridgeCallableApiIfInstalled() {
        UTIL_IntegrationConfig.DsoNpspPackage dsoBridgePackage = new UTIL_IntegrationConfig.DsoNpspPackage();
        dsoBridgePackage.namespace = '';
        dsoBridgePackage.isInstalled = true;

        //Using an existing callable class to mock bridge callable class
        dsoBridgePackage.callableApiClassName = 'Callable_API';

        System.Callable callableApi = dsoBridgePackage.getCallableApi();
        System.assertNotEquals(null, callableApi, 'Callable API should be instantiated');
    }

    /**********************************************************************************************************
    * @description Verifies package returns null if Callable API package is not installed
    */
    @isTest
    private static void shouldReturnNullIfDSOBridgeIsNotInstalled() {
        UTIL_IntegrationConfig.DsoNpspPackage dsoBridgePackage = new UTIL_IntegrationConfig.DsoNpspPackage();
        System.Callable callableApi = dsoBridgePackage.getCallableApi();
        System.assertEquals(null, callableApi, 'Callable API should not be instantiated');
    }

    /**********************************************************************************************************
    * @description Verifies package configuration confirms it is installed
    */
    @isTest
    private static void shouldConfirmThatBridgePackageIsInstalled() {
        UTIL_IntegrationConfig.DsoNpspPackage dsoBridgePackage = new UTIL_IntegrationConfig.DsoNpspPackage();
        dsoBridgePackage.isInstalled = true;
        System.assertEquals(true, dsoBridgePackage.isInstalled(), 'Package should be installed for the correct namespace');

        dsoBridgePackage.namespace = 'foo';
        dsoBridgePackage.isInstalled = null;//reset the flag so it is recalculated
        System.assertEquals(false, dsoBridgePackage.isInstalled(), 'Package should be not be installed for invalid namespace');
    }

    /**********************************************************************************************************
    * @description Create a mock package config to test the abstract class methods
    */
    public class MockPackage extends UTIL_IntegrationConfig {
        public Boolean isInstalled = true;
        private String namespace = 'foo';

        public MockPackage() {
            callableApiClassName = 'MockCallableApi';
        }

        public override Boolean initIsInstalled() {
            return isInstalled;
        }

        public override String initNamespace() {
            return namespace;
        }
    }
}
