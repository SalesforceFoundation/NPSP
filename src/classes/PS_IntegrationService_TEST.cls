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
    private static Map<String, Config> makanaConfigParams;
    private static Map<String, Config> paymentConfigParams;


    static {
        buildConfigurationParams(); // Build Test Configuration Parameters
    }

    /*******************************************************************************************************
     * @description Test for storing the secrets we receive from the Payment Services
     * Integrations package with a valid API Key
     */
    @IsTest
    private static void setConfigurationWithPaymentsAPIKey() {
        Test.startTest();

        PS_IntegrationService.setConfiguration(configParams);

        List<Payment_Services_Configuration__c> configurations = [
                SELECT apiKey__c, iss__c, sub__c,
                        sfdo_product__c, sfdo_roles__c,
                        sfdo_merchantids__c, gatewayids__c,
                        baseURL__c
                FROM Payment_Services_Configuration__c
        ];
        Test.stopTest();
        System.assert(!configurations.isEmpty());
        System.assertEquals(paymentConfigParams.get('iss').value, configurations[0].iss__c);
        System.assertEquals(paymentConfigParams.get('sub').value, configurations[0].sub__c);
        System.assertEquals(paymentConfigParams.get('sfdo.roles').value, configurations[0].sfdo_roles__c);
        System.assertEquals(paymentConfigParams.get('sfdo.product').value, configurations[0].sfdo_product__c);
        System.assertEquals(paymentConfigParams.get('sfdo.merchantids').value, configurations[0].sfdo_merchantids__c);
        System.assertEquals(paymentConfigParams.get('gatewayids').value, configurations[0].gatewayids__c);
        System.assertEquals(paymentConfigParams.get('apiKey').value, configurations[0].apiKey__c);
        System.assertEquals(paymentConfigParams.get('baseURL').value, configurations[0].baseURL__c);
    }

    /*******************************************************************************************************
    * @description Test for storing the configuration parameters received from the Payment Services
    * Integrations package with the fall-back valid API Key
    */
    @IsTest
    private static void setConfigurationWithFallBackApiKey() {

        updateConfigurationParameter('apiKey', null,
                        configParams.get(PS_IntegrationService.PAYMENTS_APPLICATION_TYPE));

        Test.startTest();

        PS_IntegrationService.setConfiguration(configParams);

        List<Payment_Services_Configuration__c> configurations = [
                SELECT apiKey__c
                FROM Payment_Services_Configuration__c
        ];
        Test.stopTest();
        System.assert(!configurations.isEmpty());
        System.assertEquals(makanaConfigParams.get('apiKey').value, configurations[0].apiKey__c);
    }

    @IsTest
    private static void setConfigurationWithInvalidApiKey() {

        updateConfigurationParameter('apiKey', null,
                configParams.get(PS_IntegrationService.PAYMENTS_APPLICATION_TYPE));

        updateConfigurationParameter('apiKey', null,
                configParams.get(PS_IntegrationService.MAKANA_APPLICATION_TYPE));

        Test.startTest();
        try {
            PS_IntegrationService.setConfiguration(configParams);
        } catch (PS_IntegrationService.IntegrationServiceException ex) {
            System.assertEquals(PS_IntegrationService.API_KEY_ELEVATE_ERROR, ex.getMessage());
        }
        Test.stopTest();
    }


    /*******************************************************************************************************
    * @description Test for storing the secrets we receive from the Payment Services
    * Integrations package with invalid configuration parameters
    */
    @IsTest
    private static void setConfigurationWithInvalidConfigurationParameters() {
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
        paymentConfigParams = new Map<String, Config> {
                'iss' => new Config('iss', 'ApiKeyManager'),
                'sub' => new Config('sub', 'cbaxter'),
                'sfdo.roles' => new Config('sfdo.roles', 'Payments.Purchase, Payments.Refund'),
                'sfdo.product' => new Config('sfdo.product', 'CRM'),
                'apiKey' => new Config('apiKey', 'a5146b4b-3d2b-4fc4-a5e5-8387968859a4'),
                'sfdo.merchantids' => new Config('sfdo.merchantids', '47b70ca4-0f6e-4c52-819f-667ae804f9d2'),
                'gatewayids' => new Config('gatewayids', 'f23da98a-c7aa-4637-962a-8c852e765e38'),
                'baseURL' => new Config('baseURL', 'https://x2t03i3rn5.execute-api.us-west-2.amazonaws.com/v1')
        };

        makanaConfigParams = new Map<String, Config> {
                'apiKey' => new Config('apiKey', 'a5146b4b-3d2b-4fc4-a5e5-makana'),
                'baseURL' => new Config('baseURL', 'https://x2t03i3rn5.execute-api.us-west-2.amazonaws.com/v1')
        };


        for(String field : paymentConfigParams.keySet()) {
            Map<String, String> stringMap = new Map<String, String>();
            stringMap.put(paymentConfigParams.get(field).key, paymentConfigParams.get(field).value);
            applicationConfig.add(stringMap);
        }

        configParams.put(PS_IntegrationService.PAYMENTS_APPLICATION_TYPE, applicationConfig);

        applicationConfig = new List<Map<String, String>>();

        for (String field : makanaConfigParams.keySet()) {
            Map<String, String> stringMap = new Map<String, String>();
            stringMap.put(makanaConfigParams.get(field).key, makanaConfigParams.get(field).value);
            applicationConfig.add(stringMap);
        }

        configParams.put(PS_IntegrationService.MAKANA_APPLICATION_TYPE, applicationConfig);
    }

    /*******************************************************************************************************
    * @description Helper method to update configuration parameters
    */
    private static void updateConfigurationParameter (String configurationParameter, String value,
            List<Map<String, String>> configurationParameters) {
        for (Integer index = 0; index < configurationParameters.size(); index++) {
            if (configurationParameters[index].keySet().contains(configurationParameter)) {
                configurationParameters.remove(index);
                configurationParameters.add(new Map<String, String >{ configurationParameter => value });
                break;
            }
        }
    }

    // Inner class representation of the configuration parameters
    public class Config {
        String key;
        String value;

        public Config (String key, String value){
            this.key = key;
            this.value = value;
        }

    }
}
