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

    @TestVisible private static final String PAYMENTS_APPLICATION_TYPE = 'payments';
    @TestVisible private static final String MAKANA_APPLICATION_TYPE = 'makana';
    @TestVisible private static final String INVALID_CONFIG_PARAMS = 'Missing configuration parameters';
    @TestVisible private static final String API_KEY_ELEVATE_ERROR = 'An invalid api key has been provided ' +
            'for this elevate customer';
    private static final String ELEVATE_ONBOARDING_ERROR = 'An error has occurred with ' +
            'onboarding this elevate customer: ';
    @TestVisible private static final String API_KEY = 'apiKey';

    /*******************************************************************************************************
    * @description Provides an endpoint for the Payment Services Integrations package
    * to call when a Customer registers, and pass parameters containing the secrets
    * needed for calls to Payment Services endpoints(Tokenize, Purchase) and creating JWTs
    * @param configParams contains secrets, such as the api key for creating a JWT
    */
    global static void setConfiguration(Map<String, List<Map<String, String>>> configParams) {

        if (configParams == null || configParams.isEmpty()) {
            // If this is a significant point of failure, how do we want to alert the customer/caller ?
            throw new IntegrationServiceException(INVALID_CONFIG_PARAMS);
        }

        Payment_Services_Configuration__c psConfiguration = new Payment_Services_Configuration__c();
        List<Map<String, String>> paymentsConfiguration = configParams.get(PAYMENTS_APPLICATION_TYPE);
        List<Map<String, String>> makanaConfiguration = configParams.get(MAKANA_APPLICATION_TYPE);

        if (paymentsConfiguration != null) {
            for (Map<String, String> valueMap : paymentsConfiguration) {
                if (valueMap.keySet().contains(API_KEY)) {
                    psConfiguration.apiKey__c = valueMap.get(API_KEY);
                    if (useFallbackApiKey(psConfiguration, makanaConfiguration)) {
                        // Fall-back to the Makana API key if available
                        for (Map<String, String> makanaValueMap : makanaConfiguration) {
                            if (makanaValueMap.keySet().contains(API_KEY)) {
                                psConfiguration.apiKey__c = makanaValueMap.get(API_KEY);
                                break;
                            }
                        }
                    }

                    if (String.isBlank(psConfiguration.apiKey__c)) {
                        throw new IntegrationServiceException(API_KEY_ELEVATE_ERROR);
                    }
                }

                if (valueMap.keySet().contains('iss')) {
                    psConfiguration.iss__c = valueMap.get('iss');
                }

                if (valueMap.keySet().contains('sub')) {
                    psConfiguration.sub__c = valueMap.get('sub');
                }

                if (valueMap.keySet().contains('sfdo.merchantids')) {
                    psConfiguration.sfdo_merchantids__c = valueMap.get('sfdo.merchantids');
                }

                if (valueMap.keySet().contains('sfdo.roles')) {
                    psConfiguration.sfdo_roles__c = valueMap.get('sfdo.roles');
                }

                if (valueMap.keySet().contains('sfdo.product')) {
                    psConfiguration.sfdo_product__c = valueMap.get('sfdo.product');
                }

                if (valueMap.keySet().contains('gatewayids')) {
                    psConfiguration.gatewayids__c = valueMap.get('gatewayids');
                }

                if (valueMap.keySet().contains('baseURL')) {
                    psConfiguration.baseURL__c = valueMap.get('baseURL');
                }
            }
        }

        List<Payment_Services_Configuration__c> existingConfigurations = [
                SELECT Id FROM Payment_Services_Configuration__c
        ];

        if(!existingConfigurations.isEmpty()){
            psConfiguration.Id = existingConfigurations[0].Id;
        }

        try {
            upsert psConfiguration;
        } catch (Exception ex) {
            throw new IntegrationServiceException(ELEVATE_ONBOARDING_ERROR + ex.getMessage());
        }

    }

    private static Boolean useFallbackApiKey (Payment_Services_Configuration__c psConfiguration,
            List<Map<String, String>> makanaConfiguration) {
        return (String.isBlank(psConfiguration.apiKey__c)
                && makanaConfiguration != null);
    }

    // Custom Exception
    public class IntegrationServiceException extends Exception {}




}
