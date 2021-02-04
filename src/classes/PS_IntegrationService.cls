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

    @TestVisible
    private static Map<String, Payment_Services_Configuration__c> configurationsToUpsertByServiceKey;
    @TestVisible
    private static Map<String, Payment_Services_Configuration__c> configurationsToInsertByServiceKey;
    @TestVisible
    private static Map<String, Payment_Services_Configuration__c> configurationsToUpdateByServiceKey;

    /*******************************************************************************************************
    * @description Provides an endpoint for the Payment Services Integrations package
    * to call when a Customer registers, and pass parameters containing the secrets
    * needed for calls to Payment Services endpoints(Tokenize, Purchase) and creating JWTs
    *
    * @param configParams contains settings, such as the baseURL for connecting to payments services
    */
    global static void setConfiguration(Map<String, List<Map<String, String>>> configParams) {
        configurationsToUpsertByServiceKey = createConfigurationsToUpsert(configParams);
        List<Payment_Services_Configuration__c> existingConfigurations =
            getExistingRecords(configurationsToUpsertByServiceKey.keySet());

        if (!existingConfigurations.isEmpty()) {
            applyExistingIdsToNewConfigurations(existingConfigurations, configurationsToUpsertByServiceKey);
        }

        Set<String> existingConfigurationServiceKeys = collectServiceKeys(existingConfigurations);

        configurationsToInsertByServiceKey = configurationsToUpsertByServiceKey.clone();
        configurationsToInsertByServiceKey.keySet().removeAll(existingConfigurationServiceKeys);

        configurationsToUpdateByServicekey = configurationsToUpsertByServiceKey.clone();
        configurationsToUpdateByServiceKey.keySet().retainAll(existingConfigurationServiceKeys);

        insertConfigurationRecords(configurationsToInsertByServiceKey.values());
        updateConfigurationRecords(configurationsToUpdateByServiceKey.values());
    }

    /*******************************************************************************************************
    * @description Creates a map of Payment_Services_Configuration__c records by their Service_Key__c from
    * the parameters provided by the caller that need to be upserted.
    *
    * @param configParams contains settings, such as the baseURL for connecting to payments services
    * @return A map of Payment_Services_Configuration__c records by their Service_Key__c
    */
    private static Map<String, Payment_Services_Configuration__c> createConfigurationsToUpsert(
        Map<String, List<Map<String, String>>> configParams) {

        if (configParams == null || configParams.isEmpty()) {
            throw new IntegrationServiceException(INVALID_CONFIG_PARAMS);
        }

        Map<String, Payment_Services_Configuration__c> configurationsToUpsert =
            new Map<String, Payment_Services_Configuration__c>();

        for (String service : configParams.keySet()) {
            for (Map<String, String> valueMap : configParams.get(service)) {
                Payment_Services_Configuration__c configuration = createConfiguration(service, valueMap);
                configurationsToUpsert.put(configuration.Service_Key__c, configuration);
            }
        }

        return configurationsToUpsert;
    }

    /*******************************************************************************************************
    * @description Queries for existing Payment_Services_Configuration__c records
    *
    * @param serviceKeys A set of Payment_Services_Configuration__c.Service_Key__c values
    */
    private static List<Payment_Services_Configuration__c> getExistingRecords(Set<String> serviceKeys) {
        return [
            SELECT Id,
                Service_Key__c,
                Key__c,
                Value__c
            FROM Payment_Services_Configuration__c
            WHERE Service_Key__c IN :serviceKeys
        ];
    }

    /*******************************************************************************************************
    * @description Applies the existing configuration record ids to the corresponding newly generated
    * configuration in preparation for an update.
    *
    * @param existingConfigurations List of existing Payment_Services_Configuration__c records
    * @param configurationsToUpsertByServiceKey Map of newly generated Payment_Services_Configuration__c records
    * from the parameters provided by the caller of 'setConfiguration'.
    */
    private static void applyExistingIdsToNewConfigurations(
        List<Payment_Services_Configuration__c> existingConfigurations,
        Map<String, Payment_Services_Configuration__c> configurationsToUpsertByServiceKey) {

        for (Payment_Services_Configuration__c configuration : existingConfigurations) {
            Payment_Services_Configuration__c newConfiguration =
            configurationsToUpsertByServiceKey.get(configuration.Service_Key__c);
            newConfiguration.Id = configuration.Id;
        }
    }

    /*******************************************************************************************************
    * @description Collects a set of Service_Key__c fields from a list of Payment_Services_Configuration__c
    * records
    *
    * @param existingConfigurations List of existing Payment_Services_Configuration__c records
    */
    private static Set<String> collectServiceKeys(List<Payment_Services_Configuration__c> existingConfigurations) {
        Set<String> existingConfigurationKeys = new Set<String> {};

        for (Payment_Services_Configuration__c configuration : existingConfigurations) {
            if (configuration.Service_Key__c != null) {
                existingConfigurationKeys.add(configuration.Service_Key__c);
            }
        }

        return existingConfigurationKeys;
    }

    /*******************************************************************************************************
    * @description Inserts a list of Payment_Services_Configuration__c records
    *
    * @param configurationRecords List of Payment_Services_Configuration__c records
    */
    private static void insertConfigurationRecords(List<Payment_Services_Configuration__c> configurationRecords) {
        try {
            insert configurationRecords;
        } catch (Exception ex) {
            throw new IntegrationServiceException(ELEVATE_ONBOARDING_ERROR + ex.getMessage());
        }
    }

    /*******************************************************************************************************
    * @description Updates a list of Payment_Services_Configuration__c records
    *
    * @param configurationRecords List of Payment_Services_Configuration__c records
    */
    private static void updateConfigurationRecords(List<Payment_Services_Configuration__c> configurationRecords) {
        try {
            update configurationRecords;
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