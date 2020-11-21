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
    @AuraEnabled(cacheable=false)
    public static Map<String, Object> getData(Id recordId) {
        Map<String, Object> data = new Map<String, Object>();

        try {
            data = new Map<String, Object> {
                'isElevateCustomer' => RD2_ElevateIntegrationService.isElevateCreateEnabled()
            };

            Boolean hasPermissions = hasFieldPermissions();
            data.put('hasFieldPermissions', hasPermissions);

            if (hasPermissions) {
                data.put('alert', RD2_VisualizeScheduleController.getValidationAlert(recordId));
                data.put('errorMessage', getLatestErrorMessage(recordId));
            }

        } catch (Exception e) {
            UTIL_AuraEnabledCommon.throwAuraHandledException(e.getMessage());
        }

        return data;
    }

    /**
     * @description Checks if the user has access for fields retrieved by the Elevate information widget
     * @return Boolean
     */
    private static Boolean hasFieldPermissions() {
        Set<String> requiredFields = new Set<String>{
            UTIL_Namespace.StrTokenNSPrefix('Status__c'),
            UTIL_Namespace.StrTokenNSPrefix('ClosedReason__c'),
            UTIL_Namespace.StrTokenNSPrefix('CommitmentId__c')
        };

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

    /***
     * @description Displays the latest error when latest payment could not be charged or
     * any other issue with the recurring commitment in Elevate
     * @param recordId Recurring Donation Id
     * @return String The latest error message if no successful payment is created after it.
     */
    private static String getLatestErrorMessage(Id recordId) {
        Error__c error = finder.getLatestError(recordId);

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


    /***
     * @description Retrieves records
     */
    public without sharing class RecordFinder {

        /***
         * @description Returns the latest error (if any) for the provided record
         * @param recordId Record Id
         * @return Error__c
         */
        public Error__c getLatestError(Id recordId) {
            List<Error__c> errors = [
                SELECT Full_Message__c, CreatedDate
                FROM Error__c
                WHERE Related_Record_ID__c = :recordId
                ORDER BY CreatedDate DESC
                LIMIT 1
            ];

            return errors == null || errors.isEmpty()
                ? null
                : errors[0];
        }

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
