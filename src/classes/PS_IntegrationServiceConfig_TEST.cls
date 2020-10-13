/*
    Copyright (c) 2020, Salesforce.org
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
* @date 2020
* @group Recurring Donations
* @description Unit Tests for the Elevate Integration Service configuration and enablement
*/
@IsTest
public with sharing class PS_IntegrationServiceConfig_TEST {

    public static String testMerchantId = 'abc123-xyz456';
    public static String testGatewayId = 'def123-ghi456';
    public static String testApiKey = 'def1234-tuv4567';
    public static String testMakanaApiKey = 'ghi12345-qrs45678';
    public static String testBaseUrl = 'https://elevate.test.com';

    // Key-Values by service name
    public static final Map<String, List<Map<String, String>>> testConfig = new Map<String, List<Map<String, String>>>{
        PS_IntegrationServiceConfig.PAYMENTS_SERVICE_NAME =>
            new List<Map<String, String>>{
                new Map<String, String>{
                    'key' => PS_IntegrationServiceConfig.SFDO_MERCHANTIDS,
                    'value' => testMerchantId
                },
                new Map<String, String>{
                    'key' => PS_IntegrationServiceConfig.SFDO_GATEWAYIDS,
                    'value' => testGatewayId
                },
                new Map<String, String>{
                    'key' => PS_IntegrationServiceConfig.API_KEY,
                    'value' => testApiKey
                },
                new Map<String, String>{
                    'key' => PS_IntegrationServiceConfig.BASE_URL,
                    'value' => testBaseUrl
                }
            }
        };

    /***
    * @description Stub for the integration service config instance
    */
    public class Stub implements System.StubProvider {
        private Boolean isEnabled = false;
        private Boolean hasPermissions = false;

        public Stub withIsIntegrationEnabled(Boolean isEnabled) {
            this.isEnabled = isEnabled;
            return this;
        }

        public Stub withHasIntegrationPermissions(Boolean hasPermissions) {
            this.hasPermissions = hasPermissions;
            return this;
        }

        public Object handleMethodCall(
            Object stubbedObject,
            String methodName,
            Type returnType,
            List<Type> paramTypes,
            List<String> paramNames,
            List<Object> args
        ) {
            switch on methodName {
                when 'isIntegrationEnabled' {
                    return isEnabled;

                } when 'hasIntegrationPermissions' {
                    return hasPermissions;

                } when else {
                    return null;
                }
            }
        }
    }

    @IsTest
    private static void shouldHaveIntegrationPermissions() {
        List<Payment_Services_Configuration__c> requiredConfigs = new List<Payment_Services_Configuration__c>();

        for (Integer i = 0; i < PS_IntegrationServiceConfig.REQUIRED_CONFIG_KEYS.size(); i++) {
            requiredConfigs.add(new Payment_Services_Configuration__c(
                Service__c = PS_IntegrationServiceConfig.PAYMENTS_SERVICE_NAME,
                Key__c = PS_IntegrationServiceConfig.REQUIRED_CONFIG_KEYS.get(i),
                Value__c = String.valueOf(i)
            ));
        }
        insert requiredConfigs;

        PS_IntegrationServiceConfig ps = new PS_IntegrationServiceConfig();
        Boolean hasIntegrationPermissions = ps.hasIntegrationPermissions();
        System.assert(hasIntegrationPermissions, 'The user should have integration permissions.');
    }

    @IsTest
    private static void shouldNotHaveIntegrationPermissions() {
        PS_IntegrationServiceConfig ps = new PS_IntegrationServiceConfig();
        Boolean hasIntegrationPermissions = ps.hasIntegrationPermissions();
        System.assert(!hasIntegrationPermissions,
            'The user should not have integration permissions without configuration keys.');
    }

    @IsTest
    private static void shouldHaveIntegrationEnabled() {
        List<Payment_Services_Configuration__c> requiredConfigs = new
        List<Payment_Services_Configuration__c>();

        for (Integer i = 0; i < PS_IntegrationServiceConfig.REQUIRED_CONFIG_KEYS.size(); i++) {
            requiredConfigs.add(new Payment_Services_Configuration__c(
                Service__c = PS_IntegrationServiceConfig.PAYMENTS_SERVICE_NAME,
                Key__c = PS_IntegrationServiceConfig.REQUIRED_CONFIG_KEYS.get(i),
                Value__c = String.valueOf(i)
            ));
        }
        insert requiredConfigs;

        PS_IntegrationServiceConfig ps = new PS_IntegrationServiceConfig();
        System.assert(ps.isIntegrationEnabled(),
            'The org should have Integration Enabled when '
            + 'all required configuration keys are present.');

    }

    @IsTest
    private static void shouldNotHaveIntegrationEnabled() {
        PS_IntegrationServiceConfig ps = new PS_IntegrationServiceConfig();
        System.assertEquals(false, ps.isIntegrationEnabled(),
            'The org should not have Integration Enabled without '
            + 'all required configuration keys present.');
    }

    @IsTest
    private static void shouldUsePaymentServicesConfig() {
        PS_IntegrationService.setConfiguration(testConfig);

        Test.startTest();
        GE_PaymentServices service = new GE_PaymentServices();
        Test.stopTest();

        // Verify that the config properties of the class are
        // the same as those of the inserted config records
        System.assertEquals(testMerchantId, service.config.get(PS_IntegrationServiceConfig.SFDO_MERCHANTIDS));
        System.assertEquals(testApiKey, service.config.get(PS_IntegrationServiceConfig.API_KEY));
    }

    /**
     * @description When GE_PaymentServices is initialized with its
     *              default payment service names, it should use the apiKey
     *              from "makana" set if not found or null in "payments" config set
    */
    @IsTest
    private static void shouldUseMakanaApiKey() {
        PS_IntegrationService.setConfiguration(testConfig);

        // Set payments Api key to null and set an Api key for makana
        PS_IntegrationService.setConfiguration(new Map<String, List<Map<String, String>>>{
            PS_IntegrationServiceConfig.PAYMENTS_SERVICE_NAME => new List<Map<String, String>>{
                new Map<String, String>{
                    'key' => PS_IntegrationServiceConfig.API_KEY,
                    'value' => null
                }
            },
            PS_IntegrationServiceConfig.MAKANA_SERVICE_NAME => new List<Map<String, String>>{
                new Map<String, String>{
                    'key' => PS_IntegrationServiceConfig.API_KEY,
                    'value' => testMakanaApiKey
                }
            }
        });

        Test.startTest();
        GE_PaymentServices service = new GE_PaymentServices();
        Test.stopTest();

        // Verify apiKey matches makana, while the rest match payments
        System.assertEquals(testMakanaApiKey, service.config.get(PS_IntegrationServiceConfig.API_KEY));
        System.assertEquals(testMerchantId,service.config.get(PS_IntegrationServiceConfig.SFDO_MERCHANTIDS));
    }
}