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
* @description Provides a public interface to the Payment Services Integration Package
*/
global class PS_IntegrationService {

    @TestVisible
    private static final String INVALID_CONFIG_PARAMS = System.Label.gePS_IntegrationTestInvalidConfigParams;
    private static final String ELEVATE_ONBOARDING_ERROR = System.Label.commonElevateFailedOnboarding;
    public static final String SERVICE_CONST = 'service';
    public static final String IS_SECRET_CONST = 'isSecret';
    public static final String KEY_CONST = 'key';
    public static final String VALUE_CONST = 'value';
    public static final String TRUE_CONST = 'true';
    public static final String FALSE_CONST = 'false';
    public static final String DELIMETER_CONST = '::';

    private static final Map<String, String> fieldMappingConstants = new Map<String, String>{
            KEY_CONST => 'Key__c',
            VALUE_CONST => 'Value__c',
            IS_SECRET_CONST => 'Is_Secret__c',
            SERVICE_CONST => 'Service__c'
    };


    /*******************************************************************************************************
    * @description Provides an endpoint for the Payment Services Integrations package
    * to call when a Customer registers, and pass parameters containing the secrets
    * needed for calls to Payment Services endpoints(Tokenize, Purchase) and creating JWTs
    * @param configParams contains settings, such as the baseURL for connecting to payments services
    */
    global static void setConfiguration(Map<String, List<Map<String, String>>> configParams) {

        if (configParams == null || configParams.isEmpty()) {
            throw new IntegrationServiceException(INVALID_CONFIG_PARAMS);
        }

        List<Payment_Services_Configuration__c> configurations = new List<Payment_Services_Configuration__c>();

        for (String service : configParams.keySet()) {
            for (Map<String, String> valueMap : configParams.get(service)) {
                configurations.add(createConfiguration(service, valueMap));
            }
        }

        try {
            upsert configurations Service_Key__c;
        } catch (Exception ex) {
            throw new IntegrationServiceException(ELEVATE_ONBOARDING_ERROR + ex.getMessage());
        }

    }

    /******************************************************************************************************
    * @description This method builds the a configuration object based on key value pair configuration
    * parameters and the configuration service type
    * @param service Configuration service type, ex: payments, makana
    * @param keyValuePairs
    *
    * @return Payment Services Configuration object
    */
    private static Payment_Services_Configuration__c createConfiguration(
            String service, Map<String, String> keyValuePairs) {

        Payment_Services_Configuration__c configuration = new Payment_Services_Configuration__c();
        configuration = setValue(configuration, SERVICE_CONST, service);

        for (String key : keyValuePairs.keySet()) {
            Object value = keyValuePairs.get(key);
            configuration = setValue(configuration, key, value);
        }

        configuration.Service_Key__c = configuration.Service__c + DELIMETER_CONST + configuration.Key__c;
        return configuration;
    }


    private static Payment_Services_Configuration__c setValue(
            Payment_Services_Configuration__c configuration, String key, Object value) {

        if (key.equalsIgnoreCase(IS_SECRET_CONST)) {
            if (((String)value) != TRUE_CONST && ((String)value) != FALSE_CONST) {
                throw new JSONException();
            }
            value = Boolean.valueOf(value);
        }

        configuration.put(fieldMappingConstants.get(key), value);

        return configuration;
    }

    // Custom Exception
    public class IntegrationServiceException extends Exception {}

    // Inner class representation of the configuration parameters for tests
    public class Config {
        public String key;
        public String value;

        public Config (String key, String value){
            this.key = key;
            this.value = value;
        }

    }



}