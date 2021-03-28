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
    public static final String PRODUCTID = 'productId';

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
        PRODUCTID,
        BASE_URL,
        API_KEY,
        SFDO_MERCHANTIDS,
        SFDO_GATEWAYIDS
    };

    /**
    * @description Determines if the Elevate integration service is configured and enabled.
    * The Elevate Payment Services integration is considered "enabled" (for now) when there
    * is at least a single record in the protected Payment Services Configuration object
    * @return Boolean
    */
    private Boolean isEnabled {
        get {
            if (isEnabled == null) {
                return config.keyValueMap.keySet().containsAll(REQUIRED_CONFIG_KEYS);
            }
            return isEnabled;
        }
        set;
    }

    /**
    * @description Returns the Elevate integration service enablement status
    * @return Boolean
    */
    public Boolean isIntegrationEnabled() {
        return isEnabled;
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
    * @description Determines if the current user has the appropriate permissions to modify Elevate records
    * @return Boolean
    */
    public Boolean hasIntegrationPermissions() {
        return hasPermissions;
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

                    for (Payment_Services_Configuration__c configRecord : getConfigRecordsByName(
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
                    lastModifiedRecords = getLastModifiedConfigRecord();
                    lastModifiedRecord = lastModifiedRecords.isEmpty() ? null : lastModifiedRecords[0];
                }
                return lastModifiedRecord;
            }
            private set;
        }

        private List<Payment_Services_Configuration__c> getConfigRecordsByName(List<String> serviceNames) {
            return [
                SELECT Key__c, Value__c, Service__c
                FROM Payment_Services_Configuration__c
                WHERE Service__c IN :serviceNames
            ];
        }

        private List<Payment_Services_Configuration__c> getLastModifiedConfigRecord() {
            return [
                SELECT Key__c, Value__c, Service__c, 
                LastModifiedById, LastModifiedDate
                FROM Payment_Services_Configuration__c
                ORDER BY LastModifiedDate DESC
                LIMIT 1
            ];
        }
    }

    /***
    * @description Returns Elevate integration configuration 
    */
    public without sharing class Service {
        @TestVisible
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

        public String getProductId() {
            return config.get(PRODUCTID);
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

        public String getViewURLPrefix(PS_IntegrationServiceConfig.VIEW_TYPE recordType) {
            return getRecordViewURL('', recordType);
        }

        public String getRecordViewURL(String elevateId, PS_IntegrationServiceConfig.VIEW_TYPE recordType) {
            return getRecordViewBaseURL() + '/' + getRecordViewTypeSuffix(recordType) + '/' + elevateId;
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
