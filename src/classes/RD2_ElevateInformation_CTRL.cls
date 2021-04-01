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
* @description Displays Elevate recurring commitment information
*/
public with sharing class RD2_ElevateInformation_CTRL {


    /**
    * @description Finds records related to Recurring Donation Elevate data
    */
    @TestVisible
    private static RecordFinder finder {
        get {
            if (finder == null) {
                finder = new RecordFinder();
            }
            return finder;
        }
        set;
    }

    /**
    * @description Returns data required for the Elevate Information widget
    * @param recordId Recurring Donation Id
    * @return Map<String, Object> Data value by key
    */
    @AuraEnabled(cacheable=true)
    public static Map<String, Object> getPermissionData(Id recordId) {
        Map<String, Object> data = new Map<String, Object>();

        try {
            data = new Map<String, Object> {
                'isElevateCustomer' => RD2_ElevateIntegrationService.isIntegrationEnabled()
            };

            Boolean hasRDUpdatePermission = UTIL_Permissions.canUpdate('npe03__Recurring_Donation__c', false);

            Boolean hasKeyRequiredFieldReadPermissions = hasReadPermissionsToFields(new Set<String>{
                UTIL_Namespace.StrTokenNSPrefix('Status__c'),
                UTIL_Namespace.StrTokenNSPrefix('ClosedReason__c'),
                UTIL_Namespace.StrTokenNSPrefix('CommitmentId__c')
            });

            Boolean hasKeyFieldsUpdatePermissions = hasUpdatePermissionsToFields(new Set<String>{
                UTIL_Namespace.StrTokenNSPrefix('CardLast4__c'),
                UTIL_Namespace.StrTokenNSPrefix('CardExpirationMonth__c'),
                UTIL_Namespace.StrTokenNSPrefix('CardExpirationYear__c')
            });

            data.put('hasFieldPermissions', hasKeyRequiredFieldReadPermissions);
            data.put('hasFieldUpdatePermission', hasKeyFieldsUpdatePermissions);
            data.put('hasRDSObjectUpdatePermission', hasRDUpdatePermission);

            if (hasKeyRequiredFieldReadPermissions) {
                data.put('alert', RD2_VisualizeScheduleController.getValidationAlert(recordId));
            }

            data.put('showLastFourDigits', hasReadPermissionsToFields(new Set<String>{
                UTIL_Namespace.StrTokenNSPrefix('CardLast4__c'),
                UTIL_Namespace.StrTokenNSPrefix('ACH_Last_4__c') }
            ));
            data.put('showExpirationDate', hasReadPermissionsToFields(new Set<String>{
                UTIL_Namespace.StrTokenNSPrefix('CardExpirationMonth__c'),
                UTIL_Namespace.StrTokenNSPrefix('CardExpirationYear__c') }
            ));

            if (RD2_ElevateIntegrationService.isIntegrationEnabled()) {
                PS_IntegrationServiceConfig.Service service = new PS_IntegrationServiceConfig.Service();
                data.put('commitmentURLPrefix', service.getViewURLPrefix(PS_IntegrationServiceConfig.VIEW_TYPE.COMMITMENT));
            }

        } catch (Exception e) {
            UTIL_AuraEnabledCommon.throwAuraHandledException(e.getMessage());
        }

        return data;
    }

    /***
    * @description Displays the latest error when latest payment could not be charged or
    * any other issue with the recurring commitment in Elevate
    * @param recordId Recurring Donation Id
    * @return String The latest error message if no successful payment is created after it.
    */
    @AuraEnabled(cacheable=false)
    public static String getLatestErrorMessage(Id recordId) {
        Error__c error = new ERR_LogService().getLatestError(recordId);

        if (error == null) {
            return null;
        }

        //Do not return error if the error is outdated,
        //ie created before the latest successful payment
        Opportunity paidOpp = finder.getLatestPaidOpportunity(recordId);

        Boolean isLatestError = paidOpp == null
            || paidOpp.CreatedDate <= error.CreatedDate;

        return isLatestError
            ? String.format(System.Label.commonErrorPrefix, new String[]{ error.Full_Message__c })
            : null;
    }

    /**
     * @description Checks if the user has read access for fields retrieved by the Elevate information widget
     * @return Boolean
     */
    private static Boolean hasReadPermissionsToFields(Set<String> requiredFields) {
        Boolean hasPermissions = true;
        for (String fld : requiredFields) {
            DescribeFieldResult dfr = UTIL_Describe.getFieldDescribe('npe03__Recurring_Donation__c', fld);
            if (!dfr.isAccessible()) {
                hasPermissions = false;
                break;
            }
        }
        return hasPermissions;
    }

    /**
     * @description Checks if the user has update access for fields retrieved by the Elevate information widget
     * @return Boolean
     */
    private static Boolean hasUpdatePermissionsToFields(Set<String> requiredFields) {
        Boolean hasPermissions = true;
        for (String fld : requiredFields) {
            DescribeFieldResult dfr = UTIL_Describe.getFieldDescribe('npe03__Recurring_Donation__c', fld);
            if (!dfr.isUpdateable()) {
                hasPermissions = false;
                break;
            }
        }
        return hasPermissions;
    }


    /***
     * @description Retrieves records
     */
    private without sharing class RecordFinder {

        /***
         * @description Returns the latest Closed Won Opportunity for the provided record
         * @param recordId Recurring Donation Id
         * @return Opportunity
         */
        public Opportunity getLatestPaidOpportunity(Id recordId) {
            List<Opportunity> opps = [
                SELECT Id, CreatedDate
                FROM Opportunity
                WHERE npe03__Recurring_Donation__c = :recordId
                AND IsClosed = true
                AND IsWon = true
                ORDER BY CreatedDate DESC
                LIMIT 1
            ];

            return opps == null || opps.isEmpty()
                ? null
                : opps[0];
        }
    }
}