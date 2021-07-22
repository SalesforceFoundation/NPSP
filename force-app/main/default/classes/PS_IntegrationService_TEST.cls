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
* @group HGE
* @group-content ../../ApexDocContent/GiftEntry.htm
* @description Test class for the PS_IntegrationService class
*/

@IsTest
private class PS_IntegrationService_TEST {

    private static Map<String, List<Map<String, String>>> configParams;
    private static Map<String, PS_IntegrationService.Config> makanaConfigParams;
    private static Map<String, PS_IntegrationService.Config> paymentConfigParams;
    private static final String API_KEY = 'apiKey';
    private static final String PAYMENTS_APPLICATION_TYPE = 'payments';
    private static final String MAKANA_APPLICATION_TYPE = 'makana';

    static {
        buildConfigurationParams(); // Build Test Configuration Parameters
    }

    /*******************************************************************************************************
     * @description Test for storing the secrets we receive from the Payment Services
     * Integrations package with a valid API Key
     */
    @IsTest
    private static void shouldSetConfigurationWithPaymentsAPIKey() {
        Test.startTest();

        PS_IntegrationService.setConfiguration(configParams);

        List<Payment_Services_Configuration__c> configurations = [
                SELECT Key__c, Service_Key__c, Value__c, Is_Secret__c, Service__c
                FROM Payment_Services_Configuration__c
        ];
        Test.stopTest();
        System.assert(!configurations.isEmpty());
        for (Payment_Services_Configuration__c config : configurations) {
            if (config.Service__c == PAYMENTS_APPLICATION_TYPE) {
                System.assertEquals(paymentConfigParams.get(config.Key__c).value, config.Value__c);
            }

            if (config.Service__c == MAKANA_APPLICATION_TYPE) {
                System.assertEquals(makanaConfigParams.get(config.Key__c).value, config.Value__c);
            }
        }
    }

    /*******************************************************************************************************
    * @description Confirm that a user without the 'Modify All Data' System Permissions is able to set
    * Payment Services Configuration records.
    */
    @IsTest
    private static void shouldAllowSetConfigurationForUsersWithoutModifyAllPermission() {
        Test.startTest();
        User tempUser = UTIL_UnitTestData_TEST.createUserWithoutInsert(UTIL_Profile.PROFILE_STANDARD_USER);

        System.runAs(tempUser) {
            PS_IntegrationService.setConfiguration(configParams);
        }

        List<Payment_Services_Configuration__c> configurations = [
            SELECT Key__c, Service_Key__c, Value__c, Is_Secret__c, Service__c
            FROM Payment_Services_Configuration__c
        ];
        Test.stopTest();

        System.assert(!configurations.isEmpty());
        for (Payment_Services_Configuration__c config : configurations) {
            if (config.Service__c == PAYMENTS_APPLICATION_TYPE) {
                System.assertEquals(paymentConfigParams.get(config.Key__c).value, config.Value__c);
            }

            if (config.Service__c == MAKANA_APPLICATION_TYPE) {
                System.assertEquals(makanaConfigParams.get(config.Key__c).value, config.Value__c);
            }
        }
    }

    /*******************************************************************************************************
    * @description Confirm that payment services configurations are being collected to be inserted or updated
    * accordingly. If a configuration provided by the caller matches to an existing payment services
    * configuration, then it should be updated.
    */
    @IsTest
    private static void shouldInsertRecordsOnFirstRunAndUpdateRecordsOnSecondRun() {
        Test.startTest();
        // Confirm that there are no existing records
        List<Payment_Services_Configuration__c> configurations = [
                SELECT Key__c, Service_Key__c, Value__c, Is_Secret__c, Service__c
                FROM Payment_Services_Configuration__c
        ];
        System.assertEquals(0, configurations.size(), 'Should have 0 existing configuration records.');

        // Insert payment configuration records on first pass
        Map<String, PS_IntegrationService.Config> firstRunConfigParams = new Map<String, PS_IntegrationService.Config>{
            'sfdo.product' => new PS_IntegrationService.Config('sfdo.product', 'CRM'),
            'sub' => new PS_IntegrationService.Config('sub', 'psadie')
        };
        PS_IntegrationService.setConfiguration(buildConfigurationParams(firstRunConfigParams));
        Object sfdoProductConfigRecordId = PS_IntegrationService.configurationsToInsertByServiceKey
            .get('payments::sfdo.product')
            .get(Schema.Payment_Services_Configuration__c.Id);

        System.assertEquals('CRM', PS_IntegrationService.configurationsToUpsertByServiceKey
            .get('payments::sfdo.product')
            .get(Schema.Payment_Services_Configuration__c.Value__c));
        System.assertEquals(2, PS_IntegrationService.configurationsToUpsertByServiceKey.keySet().size(),
            'Should have 2 configuration records to upsert.');
        System.assertEquals(2, PS_IntegrationService.configurationsToInsertByServiceKey.keySet().size(),
            'Should have 2 configuration records to insert.');
        System.assertEquals(0, PS_IntegrationService.configurationsToUpdateByServiceKey.keySet().size(),
            'Should have 0 configuration records to update.');

        // Update existing and insert new payment configuration records on second pass
        Map<String, PS_IntegrationService.Config> secondRunConfigParams = new Map<String, PS_IntegrationService.Config>{
            'sfdo.product' => new PS_IntegrationService.Config('sfdo.product', 'TEST_CRM'),
            'apiKey' => new PS_IntegrationService.Config('apikey', 'a5146b4b-3d2b-4fc4-a5e5-8387968859a4')
        };
        PS_IntegrationService.setConfiguration(buildConfigurationParams(secondRunConfigParams));

        System.assertEquals('TEST_CRM', PS_IntegrationService.configurationsToUpsertByServiceKey
            .get('payments::sfdo.product')
            .get(Schema.Payment_Services_Configuration__c.Value__c));
        System.assertEquals(2, PS_IntegrationService.configurationsToUpsertByServiceKey.keySet().size(),
            'Should have 2 configuration record to upsert.');
        System.assertEquals(1, PS_IntegrationService.configurationsToInsertByServiceKey.keySet().size(),
            'Should have 1 configuration record to insert.');
        System.assertEquals(1, PS_IntegrationService.configurationsToUpdateByServiceKey.keySet().size(),
            'Should have 1 configuration record to update.');
        System.assertEquals(sfdoProductConfigRecordId, PS_IntegrationService.configurationsToUpdateByServiceKey
            .get('payments::sfdo.product')
            .get(Schema.Payment_Services_Configuration__c.Id),
            'Id of record to be updated should match previously inserted record id.');
        Test.stopTest();
    }

    /*******************************************************************************************************
    * @description Test for storing the secrets we receive from the Payment Services
    * Integrations package with invalid configuration parameters
    */
    @IsTest
    private static void shouldSetConfigurationWithInvalidConfigurationParameters() {
        configParams = new Map<String, List<Map<String, String>>>();

        Test.startTest();
        try {
            PS_IntegrationService.setConfiguration(configParams);
        } catch (PS_IntegrationService.IntegrationServiceException ex) {
            System.assertEquals(PS_IntegrationService.INVALID_CONFIG_PARAMS, ex.getMessage());
        }
        Test.stopTest();
    }

    /*******************************************************************************************************
    * @description Helper method to build test configuration parameters
    */
    private static void buildConfigurationParams() {
        List<Map<String, String>> applicationConfig = new List<Map<String, String>>();
        configParams = new Map<String, List<Map<String, String>>>();
        paymentConfigParams = new Map<String, PS_IntegrationService.Config>{
                'iss' => new PS_IntegrationService.Config('iss', 'ApiKeyManager'),
                'sub' => new PS_IntegrationService.Config('sub', 'voduyemi'),
                'sfdo.roles' => new PS_IntegrationService.Config('sfdo.roles',
                        'Payments.Purchase, Payments.Refund, Payments.Commitment'),
                'sfdo.product' => new PS_IntegrationService.Config('sfdo.product', 'CRM'),
                'apiKey' => new PS_IntegrationService.Config('apiKey', 'a5146b4b-3d2b-4fc4-a5e5-8387968859a4'),
                'sfdo.merchantids' => new PS_IntegrationService.Config('sfdo.merchantids',
                        '47b70ca4-0f6e-4c52-819f-667ae804f9d2'),
                'gatewayids' => new PS_IntegrationService.Config('gatewayids',
                        'f23da98a-c7aa-4637-962a-8c852e765e38'),
                'baseURL' => new PS_IntegrationService.Config('baseURL',
                        'https://SOMEURL.execute-api.us-west-2.amazonaws.com/v1')
        };

        makanaConfigParams = new Map<String, PS_IntegrationService.Config>{
                'apiKey' => new PS_IntegrationService.Config('apiKey',
                        'a5146b4b-3d2b-4fc4-a5e5-8387968859a4-makana'),
                'baseURL' => new PS_IntegrationService.Config('baseURL',
                        'https://SOMEURL.execute-api.us-west-2.amazonaws.com/v1')
        };

        for (String field : paymentConfigParams.keySet()) {
            Map<String, String> stringMap = new Map<String, String>();
            stringMap.put(PS_IntegrationService.KEY_CONST, field);
            stringMap.put(PS_IntegrationService.VALUE_CONST, paymentConfigParams.get(field).value);
            stringMap.put(PS_IntegrationService.IS_SECRET_CONST, field == API_KEY ? 'true' : 'false');
            applicationConfig.add(stringMap);
        }

        configParams.put(PAYMENTS_APPLICATION_TYPE, applicationConfig);
        applicationConfig = new List<Map<String, String>>();

        for (String field : makanaConfigParams.keySet()) {
            Map<String, String> stringMap = new Map<String, String>();
            stringMap.put(PS_IntegrationService.KEY_CONST, field);
            stringMap.put(PS_IntegrationService.VALUE_CONST, makanaConfigParams.get(field).value);
            stringMap.put(PS_IntegrationService.IS_SECRET_CONST, field == API_KEY ? 'true' : 'false');
            applicationConfig.add(stringMap);
        }

        configParams.put(MAKANA_APPLICATION_TYPE, applicationConfig);
    }

    /*******************************************************************************************************
    * @description Helper method to build test configuration parameters
    */
    private static Map<String, List<Map<String, String>>> buildConfigurationParams(
        Map<String, PS_IntegrationService.Config> paymentConfigParams) {

        List<Map<String, String>> applicationConfig = new List<Map<String, String>>();
        configParams = new Map<String, List<Map<String, String>>>();

        for (String field : paymentConfigParams.keySet()) {
            Map<String, String> stringMap = new Map<String, String>();
            stringMap.put(PS_IntegrationService.KEY_CONST, field);
            stringMap.put(PS_IntegrationService.VALUE_CONST, paymentConfigParams.get(field).value);
            stringMap.put(PS_IntegrationService.IS_SECRET_CONST, field == API_KEY ? 'true' : 'false');
            applicationConfig.add(stringMap);
        }

        configParams.put(PAYMENTS_APPLICATION_TYPE, applicationConfig);

        return configParams;
    }
}