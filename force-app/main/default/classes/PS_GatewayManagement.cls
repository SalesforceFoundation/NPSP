/*
 * Copyright (c) 2020 Salesforce.org
 *     All rights reserved.
 *
 *     Redistribution and use in source and binary forms, with or without
 *     modification, are permitted provided that the following conditions are met:
 *
 *     * Redistributions of source code must retain the above copyright
 *       notice, this list of conditions and the following disclaimer.
 *     * Redistributions in binary form must reproduce the above copyright
 *       notice, this list of conditions and the following disclaimer in the
 *       documentation and/or other materials provided with the distribution.
 *     * Neither the name of Salesforce.org nor the names of
 *       its contributors may be used to endorse or promote products derived
 *       from this software without specific prior written permission.
 *
 *     THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 *     "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 *     LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 *     FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE
 *     COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
 *     INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
 *     BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 *     LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
 *     CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 *     LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN
 *     ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
 *     POSSIBILITY OF SUCH DAMAGE.
 */

public with sharing class PS_GatewayManagement {

    @AuraEnabled
    public static void setGatewayId(String gatewayId) {
        Map<String, List<Map<String, String>>> gatewayConfig = new Map<String, List<Map<String, String>>> {
                PS_IntegrationServiceConfig.PAYMENTS_SERVICE_NAME =>
                        new List<Map<String, String>>{
                                new Map<String, String>{
                                        'key' => PS_IntegrationServiceConfig.SFDO_GATEWAYIDS,
                                        'value' => gatewayId
                                }
                        }
        };
        PS_IntegrationService.setConfiguration(gatewayConfig);
    }
    @AuraEnabled
    public static void setGatewayAssignmentEnabled(Boolean gatewayAssignmentEnabled) {
        Gift_Entry_Settings__c giftEntrySettings = UTIL_CustomSettingsFacade.getGiftEntrySettings();
        giftEntrySettings.Enable_Gateway_Assignment__c = gatewayAssignmentEnabled;

        upsert giftEntrySettings;       
    }

    @TestVisible
    private static Boolean isGatewayAssignmentEnabled() {
        Gift_Entry_Settings__c giftEntrySettings = UTIL_CustomSettingsFacade.getGiftEntrySettings();

        return giftEntrySettings.Enable_Gateway_Assignment__c;
    }

    public static String getGatewayIdFromConfig() {
        PS_IntegrationServiceConfig.Service configService = new PS_IntegrationServiceConfig.Service();

        return configService.getGatewayIds();
    }

    private static Boolean isElevateCustomer() {
        PS_IntegrationServiceConfig ps = new PS_IntegrationServiceConfig();

        return ps.isIntegrationEnabled();
    }

    @TestVisible
    private static Boolean isSystemAdmin() {
        return STG_Panel.runningUserIsAdmin();
    }
    
    @AuraEnabled
    public static String getGatewayManagementSettings() {

        try {
            GatewayManagementSettings gmSettings = new GatewayManagementSettings();

            gmSettings.isElevateCustomer = isElevateCustomer();
            gmSettings.isGatewayAssignmentEnabled = isGatewayAssignmentEnabled();
            gmSettings.isSystemAdmin = isSystemAdmin();

            return JSON.serialize(gmSettings);

        } catch (Exception e) {
            UTIL_AuraEnabledCommon.throwAuraHandledException(e.getMessage());
        }

        return null;
    }

    public class GatewayManagementSettings {
        Boolean isElevateCustomer;
        Boolean isGatewayAssignmentEnabled;
        Boolean isSystemAdmin;
    }
}