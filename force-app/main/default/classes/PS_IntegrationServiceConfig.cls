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
* @group Elevate Payment Services
* @description Determines the Elevate Payment Integration Services status and permissions
*/
public with sharing class PS_IntegrationServiceConfig {
    
    // Names of Payment Service configuration sets
    public static final String PAYMENTS_SERVICE_NAME = 'payments';
    @TestVisible static final String MAKANA_SERVICE_NAME = 'makana';

    // Properties used to configure headers in
    // HTTP Requests to Elevate payment services
    public static final String API_KEY = 'apiKey';
    public static final String BASE_URL = 'baseURL';
    public static final String JWT_TOKEN = 'jwttoken';

    // Note that the casing difference between "sfdo.merchantids" and "sfdo.gatewayIds" is intentional
    public static final String SFDO_MERCHANTIDS = 'sfdo.merchantids'; 
    public static final String SFDO_GATEWAYIDS = 'sfdo.gatewayIds';
    public static final String SFDO_USERNAME = 'sfdo.username';
    public static final String ELEVATE_SDK = 'elevateSDK';
    public static final String CLIENTID = 'clientId';
    public static final String PRODUCTID = 'productId';

    //Determine if Elevate connection is active
    public static final String IS_ACTIVE = 'isActive';

    // Elevate record view types
    public enum VIEW_TYPE {
        COMMITMENT,
        PAYMENT
    }

    // Elevate record view type suffixes
    public static final String VIEW_TYPE_COMMITMENT_SUFFIX = 'admin/recurring';
    public static final String VIEW_TYPE_PAYMENT_SUFFIX = 'admin/transaction';

    @TestVisible
    private static final List<String> REQUIRED_CONFIG_KEYS = new List<String> {
        ELEVATE_SDK,
        BASE_URL,
        API_KEY,
        SFDO_MERCHANTIDS,
        SFDO_GATEWAYIDS
    };

    /**
    * @description Determines if the Elevate integration service is configured and enabled.
    * The Elevate Payment Services integration is considered enabled when all required
    * service records are present with value and Integration is Active
    * @return Boolean
    */
    public Boolean isIntegrationEnabled() {
        return isIntegrationActive() && hasAllRequiredServiceData();
    }

    /**
    * @description Determines if the current user has the appropriate permissions to modify Elevate records
    * @return Boolean
    */
    public Boolean hasIntegrationPermissions() {
        return hasPermissions;
    }

    /**
    * @description Determine if isActive service record exist. If the record exist,
    * using the record to determine if Elevate is registered. Else assume the key
    * is active
    * @return Boolean
    */
    private Boolean isIntegrationActive() {
       return ElevateConfigService.getIsActiveFlag();
    }

    /**
    * @description Determine if all required Elevate service records exist and have values stored in it.
    * @return Boolean
    */
    private Boolean hasAllRequiredServiceData() {
        return ElevateConfigService.hasAllRequiredServiceData();
    }

    /**
    * @description Determines if the current user has the appropriate permissions to modify Elevate records
    * @return Boolean
    */
    private Boolean hasPermissions {
        get {
            if (hasPermissions == null) {
                Payment_Services_Configuration__c lastModifiedRecord = config.lastModifiedRecord;
                return lastModifiedRecord != null 
                    ? lastModifiedRecord.LastModifiedById == UserInfo.getUserId() 
                    : false;
            }
            return hasPermissions;
        }
        set;
    }


    /**
    * @description Returns the same instance of the Configuration inner class
    * @return Configuration 
    */
    private static Configuration config {
        get {
            if (config == null) {
                config = new Configuration();
            }
            return config;
        } set;
    }

     /**
    * @description Returns the instance of Elevate Related Configuration Service
    * @return Service
    */
    private static Service ElevateConfigService {
        get {
            if (ElevateConfigService == null) {
                ElevateConfigService = new Service();
            }
            return ElevateConfigService;
        } set;
    }

    @TestVisible
    private static PaymentServicesConfigurationSelector paymentServicesConfigurationSelector {
        get {
            if (paymentServicesConfigurationSelector == null) {
                paymentServicesConfigurationSelector = new PaymentServicesConfigurationSelector();
            }
            return paymentServicesConfigurationSelector;
        }
        set;
    }

    /**
    * @description Inner class responsible for retrieving Payment Services configuration from
    *              application storage and building and exposing a set of key-value
    *              configuration pairs.
    *              We use 'without sharing' to ensure that the query against 
    *              Payment_Services_Configuration__c always works regardless of what permissions 
    *              the current user has
    */
    public without sharing class Configuration {
        public Configuration() {}

        // use a class variable to enable caching and 
        // avoid querying the config object multiple times
        List<Payment_Services_Configuration__c> lastModifiedRecords;

        /* @description returns a map of key value pairs from the configuration object
        */
        public Map<String, String> keyValueMap {
            get {
                if (keyValueMap == null) {
                    keyValueMap = new Map<String, String>();
                    String makanaKey;

                    for (Payment_Services_Configuration__c configRecord :
                        paymentServicesConfigurationSelector.getConfigRecordsByName(
                        new List<String> { PAYMENTS_SERVICE_NAME, MAKANA_SERVICE_NAME }
                    )) {

                        if (configRecord.Service__c == PAYMENTS_SERVICE_NAME) {
                            keyValueMap.put(configRecord.Key__c, configRecord.Value__c);

                        } else if (configRecord.Key__c == API_KEY 
                            && configRecord.Service__c == MAKANA_SERVICE_NAME
                        ) {
                            makanaKey = configRecord.Value__c;
                        }
                    }

                    // If the payments service config does not have an Api key
                    // and makana does, use the makana Api key
                    if (makanaKey != null && keyValueMap.get(API_KEY) == null) {
                        keyValueMap.put(API_KEY, makanaKey);
                    }
                }

                return keyValueMap;
            }
            private set;
        }

        /* @description Returns the last modified configuration record
        */
        public Payment_Services_Configuration__c lastModifiedRecord {
            get {
                if (lastModifiedRecords == null) {
                    lastModifiedRecords = paymentServicesConfigurationSelector.getLastModifiedConfigRecord();
                    lastModifiedRecord = lastModifiedRecords.isEmpty() ? null : lastModifiedRecords[0];
                }
                return lastModifiedRecord;
            }
            private set;
        }
    }

    /***
    * @description Returns Elevate integration configuration
    */
    public without sharing class Service {
        private Map<String, String> config {
            get {
                if (config == null) {
                    config = new Configuration().keyValueMap;
                }
                return config;
            }
            set;
        }

        public String getEndpointRoot() {
            return config.get(BASE_URL);
        }

        public String getElevateSDKURL() {
            return config.get(ELEVATE_SDK);
        }

        /**
         * This method returns productId or clientId to allow for pilot customers of Elevate in Gift Entry to keep
         * using their existing configuration
         * @return clientId || productId
         */
        public String getClientId() {
            return config.get(CLIENTID) == null
                ? config.get(PRODUCTID)
                :  config.get(CLIENTID);
        }

        public String getGatewayIds() {
            return config.get(SFDO_GATEWAYIDS);
        }

        public String getMerchantIds() {
            return config.get(SFDO_MERCHANTIDS);
        }

        public String getAPIKey() {
            return config.get(API_KEY);
        }

        /**
         * This method returns 'true' as default because configuration records without an active flag
         * are regarded as 'active' records
         * @return Boolean
         */
        public Boolean getIsActiveFlag() {
            return hasIsActiveFlag() 
                ? Boolean.valueOf(config.get(IS_ACTIVE))
                : true;
        }

        public String getViewURLPrefix(PS_IntegrationServiceConfig.VIEW_TYPE recordType) {
            return getRecordViewURL('', recordType);
        }

        public String getRecordViewURL(String elevateId, PS_IntegrationServiceConfig.VIEW_TYPE recordType) {
            return getRecordViewBaseURL() + '/' + getRecordViewTypeSuffix(recordType) + '/' + elevateId;
        }

        public Boolean hasIsActiveFlag() {
            return config.containsKey(IS_ACTIVE);
        }

        public Boolean hasAllRequiredServiceData() {
            if (config.keySet().containsAll(REQUIRED_CONFIG_KEYS)) {
               return String.isNotBlank(config.get(PRODUCTID))
                   || String.isNotBlank(config.get(CLIENTID));
            }
            return false;
        }

        private String getRecordViewBaseURL() {
            return getEndpointRoot().remove('payments-api.').replace('https://', 'https://admin.');
        }

        private String getRecordViewTypeSuffix(PS_IntegrationServiceConfig.VIEW_TYPE recordType) {
            String typeSuffix;

            switch on recordType {
                when COMMITMENT {
                    typeSuffix = PS_IntegrationServiceConfig.VIEW_TYPE_COMMITMENT_SUFFIX;
                }

                when PAYMENT {
                    typeSuffix = PS_IntegrationServiceConfig.VIEW_TYPE_PAYMENT_SUFFIX;
                }
            }

            return typeSuffix;
        }
    }
}
