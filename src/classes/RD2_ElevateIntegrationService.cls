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
* @description Services related to the RecurringDonation <-> Elevate integration
*/
public inherited sharing class RD2_ElevateIntegrationService {

    /***
     * @description Contains a prefix appended to a GUID to indicate the RD is in draft
     * and has a temp commitment Id so future installment Opportunities are not
     * created for this Recurring Donation and any user can change it
     * from a temp value to the actual value.
     */
    public static final String TEMP_COMMITMENT_ID_PREFIX = '_PENDING_';
    
    public static final String LOG_TYPE_COMMITMENT_CREATE = 'payment.commitment.create';
    public static final String LOG_TYPE_COMMITMENT_CANCEL = 'payment.commitment.cancel';

    /***
     * @description Max length of a string to be stored in a picklist field
     */
    private static final Integer MAX_PICKLIST_FIELD_LEN = 255;

    /***
     * @description CurrencyIsoCode field name
     */
    private static final String CURRENCY_ISO_CODE_FIELD = UTIL_Currency.CURRENCY_ISO_CODE_FIELD;

    /***
     * @description Contains configuration related to the Elevate integration service config and permissions
     */
    @TestVisible
    private static PS_IntegrationServiceConfig config {
        get {
            if (config == null) {
                config = new PS_IntegrationServiceConfig();
            }
            return config;
        }
        set;
    }

    /***
     * @description Determines if multi-currency is enabled for the org
     */
    @TestVisible
    private Boolean isMultiCurrencyEnabled {
        get {
            if (isMultiCurrencyEnabled == null) {
                isMultiCurrencyEnabled = UserInfo.isMultiCurrencyOrganization();
            }
            return isMultiCurrencyEnabled;
        }
        set;
    }

    /***
    * @description Returns the Elevate Integration service enablement status
    * @return Boolean
    */
    public static Boolean isIntegrationEnabled() {
        return config.isIntegrationEnabled();
    }

    /***
    * @description Returns the Elevate Integration service enablement status for Create Commitment feature.
    * The "Pilot Enabled" flag check should be removed when Create Commiment becomes GA.
    * @return Boolean
    */
    public static Boolean isElevateCreateEnabled() {
        return config.isIntegrationEnabled()
            && UTIL_FeatureEnablement.isPilotEnabled();
    }

    /***
    * @description Determines whether a Recurring Donation event is from the Elevate integration
    * @param rd Changed Recurring Donation
    * @param oldRd Old Recurring Donation
    * @return Boolean
    */
    public static Boolean isElevateEvent(RD2_RecurringDonation rd, RD2_RecurringDonation oldRd) {
        String elevateEvent = rd.getSObject().LastElevateEventPlayed__c;

        Boolean isElevateEventChanged = String.isNotBlank(elevateEvent)
            && elevateEvent != oldRd.getSObject().LastElevateEventPlayed__c;

        return isElevateEventChanged;
    }

    /***
     * @description Determines if the Recurring Donation can be changed
     * @param rd Changed Recurring Donation
     * @param oldRd Old Recurring Donation
     * @return Boolean
     */
    public Boolean hasUpdatePermissions(npe03__Recurring_Donation__c rd, npe03__Recurring_Donation__c oldRd) {
        // Do not check changed fields if
        // 1. the Recurring Donation is not referencing an Elevate record or
        // 2. the Elevate integration is not configured/enabled or
        // 3. the user *has* the Elevate integration permission to change the Recurring Donation
        if (String.isBlank(rd.CommitmentId__c)
            || !config.isIntegrationEnabled()
            || config.hasIntegrationPermissions()
        ) {
            return true;
        }

        // Check if any of the restricted fields has been changed
        Boolean isChanged = rd.npe03__Contact__c != oldRd.npe03__Contact__c
            || rd.npe03__Organization__c != oldRd.npe03__Organization__c
            || rd.npe03__Amount__c != oldRd.npe03__Amount__c
            || rd.npe03__Installment_Period__c != oldRd.npe03__Installment_Period__c
            || rd.npe03__Installments__c != oldRd.npe03__Installments__c
            || rd.InstallmentFrequency__c != oldRd.InstallmentFrequency__c
            || rd.npe03__Date_Established__c != oldRd.npe03__Date_Established__c
            || rd.StartDate__c != oldRd.StartDate__c
            || rd.Day_of_Month__c != oldRd.Day_of_Month__c
            || rd.RecurringType__c != oldRd.RecurringType__c
            || rd.PaymentMethod__c != oldRd.PaymentMethod__c;

        if (!isChanged) {
            String oldCommitmentId = oldRd.CommitmentId__c;
            Boolean isTempIdOverwrite = String.isNotBlank(oldCommitmentId)
                && oldCommitmentId.startsWith(TEMP_COMMITMENT_ID_PREFIX);

            isChanged = rd.CommitmentId__c != oldCommitmentId
                && !isTempIdOverwrite;
        }

        if (!isChanged && !(new RD2_RecurringDonation(rd)).isClosed()) {
            isChanged = rd.ClosedReason__c != oldRd.ClosedReason__c;
        }

        if (!isChanged && isMultiCurrencyEnabled) {
            isChanged = (String) rd.get(CURRENCY_ISO_CODE_FIELD) != (String) oldRd.get(CURRENCY_ISO_CODE_FIELD);
        }

        // If any of the restricted fields has been changed, prevent the RD update
        return !isChanged;
    }

    /***
     * @description Determines whether an Elevate Recurring Donation is changing from closed state to another state
     * @param rd Changed Recurring Donation
     * @param oldRd Old Recurring Donation
     * @return Boolean
     */
    public Boolean isElevateRecordReactivated(npe03__Recurring_Donation__c rd, npe03__Recurring_Donation__c oldRd) {
        if (!isIntegrationEnabled()) {
            return false;
        }

        RD2_RecurringDonation rdRecord = new RD2_RecurringDonation(rd);
        RD2_RecurringDonation oldRDRecord = new RD2_RecurringDonation(oldRd);

        Boolean isReactivated = oldRDRecord.isElevateRecord()
            && oldRDRecord.isClosed()
            && !rdRecord.isClosed();

        return isReactivated;
    }

    /**
    * @description For each CommitmentId, find any existing Opportunities with the matching Commitmentid
    * and update the RecuringDonation lookup field (only if null).
    * @param rdIdByCommitmentId Map by CommitmentId
    */
    public void matchRecurringDonationsToOpps(Map<String, Id> rdIdByCommitmentId) {

        if (rdIdByCommitmentId == null || rdIdByCommitmentId.isEmpty()) {
            return;
        }

        // Skip the process if the Id does not point to a RecurringDonation record
        if (rdIdByCommitmentId.values()[0].getSobjectType() != npe03__Recurring_Donation__c.SObjectType) {
            return;
        }

        List<Opportunity> oppsToUpdate = new List<Opportunity>();
        for (Opportunity opp : [SELECT Id, npe03__Recurring_Donation__c, CommitmentId__c
            FROM Opportunity
            WHERE CommitmentId__c IN :rdIdByCommitmentId.keySet()
        ]) {
            if (opp.CommitmentId__c == null || opp.npe03__Recurring_Donation__c != null) {
                continue;
            }
            opp.npe03__Recurring_Donation__c = rdIdByCommitmentId.get(opp.CommitmentId__c);
            oppsToUpdate.add(opp);
        }

        if (!oppsToUpdate.isEmpty()) {
            UTIL_DMLService.updateRecordBatchAndLogErrors(oppsToUpdate, ERR_Handler_API.Context.Elevate.name());
        }
    }

    /***
    * @description Match Opportunities originated in Elevate that are not referencing any Recurring Donation
    * with an Recurring Donation having the same Commitment Id value
    * @param opps Opportunities
    * @return void
    */
    public void matchOppsToRecurringDonations(List<Opportunity> opps) {
        Map<String, List<Opportunity>> oppsByCommitmentId = new Map<String, List<Opportunity>>();

        //extract Opps originated in Elevate that are not referencing a Recurring Donation
        for (Opportunity opp : opps) {
            if (opp.npe03__Recurring_Donation__c != null || String.isBlank(opp.CommitmentId__c)) {
                continue;
            }

            if (!oppsByCommitmentId.containsKey(opp.CommitmentId__c)) {
                oppsByCommitmentId.put(opp.CommitmentId__c, new List<Opportunity>());
            }
            oppsByCommitmentId.get(opp.CommitmentId__c).add(opp);
        }

        if (oppsByCommitmentId.isEmpty()) {
            return;
        }

        //set the Recurring Donation field on Opps matching the same Commitment Id
        for (npe03__Recurring_Donation__c rd : [
            SELECT CommitmentId__c
            FROM npe03__Recurring_Donation__c
            WHERE CommitmentId__c IN :oppsByCommitmentId.keySet()]) {

            for (Opportunity opp : oppsByCommitmentId.get(rd.CommitmentId__c)) {
                opp.npe03__Recurring_Donation__c = rd.Id;
            }
        }
    }


    /**
    * @description Cancels commitments in Elevate connected to the closed Recurring Donations
    * @param closedRDs Closed RDs with the user specified closed reason
    * @return void
    */
    public void cancelCommitments(List<npe03__Recurring_Donation__c> closedRDs) {
        new CancelCommitmentService().cancelCommitments(closedRDs);
    }

    /**
    * @description Handles cancelation of commitments in Elevate.
    * If the commitment cannot be closed, the RD closed reason
    * is set based on the Elevate error response.
    */
    public without sharing class CancelCommitmentService {

        /**
        * @description Sends requests and constructs the response
        */
        private UTIL_Http.RequestService requestService {
            get {
                if (requestService == null) {
                    requestService = new UTIL_Http.RequestService();
                }
                return requestService;
            }
            set;
        }

        /**
        * @description Sends cancel commitment reqeusts for closed Recurring Donations.
        * Sets RD closed reason back to user specified reason and insert any error.
        * @param closedRDs Closed RDs with the user specified closed reason
        * @return void
        */
        public void cancelCommitments(List<npe03__Recurring_Donation__c> closedRDs) {
            Logger logger = new Logger();
            List<UTIL_Http.Response> responses = new List<UTIL_Http.Response>();

            for (npe03__Recurring_Donation__c rd : closedRDs) {
                responses.add(sendRequest(rd.CommitmentId__c));
            }

            for (Integer i = 0; i < responses.size(); i++) {
                setClosedReason(closedRDs[i], responses[i], logger);
            }

            List<Database.SaveResult> dmlResults = Database.update(closedRDs, false);
            logger.addErrors(dmlResults, closedRDs);

            logger.processErrors();
        }

        /**
        * @description Sends cancel commitment reqeusts for closed Recurring Donations.
        * @param closedRDs Closed RDs with the user specified closed reason
        * @return UTIL_Http.Response
        */
        public UTIL_Http.Response sendRequest(String commitmentId) {
            UTIL_Http.Response response;

            try {
                HttpRequest request = buildCancelRequest(commitmentId);

                response = requestService.sendRequest(request);
            } catch (Exception ex) {
                response = requestService.buildErrorResponse(ex);
            }

            return response;
        }

        /**
        * @description Builds a cancel commitment request for the provided commitment Id
        * @param commitmentId Elevate recurring commitment Id
        * @return HttpRequest
        */
        private HttpRequest buildCancelRequest(String commitmentId) {
            return new PS_Request.Builder()
                .withCommitmentId(commitmentId)
                .withEndpoint(PS_Request.ElevateEndpoint.COMMITMENT_CANCEL)
                .withMethod(UTIL_Http.Method.POST)
                .build();
        }

        /**
        * @description Sets closed reason based on the cancel commitment response.
        * Recurring Donations already contain user specified closed reason value,
        * so the value is restored in database when:
        * - the commitment is sucessfully cancelled,
        * - the commitment cannot be found in Elevate,
        * - the request results in data conflict which is usually
        *   returned when the commitment is already cancelled.
        *
        * @param rd Recurring Donation
        * @param response Elevate API response
        * @param logger Error log container
        * @return void
        */
        private void setClosedReason(npe03__Recurring_Donation__c rd, UTIL_Http.Response response, Logger logger) {

            if (isCancelled(response)) {
                return;
            }

            String messages = response.getErrorMessages();
            logger.addError(rd.Id, messages, LOG_TYPE_COMMITMENT_CANCEL);

            rd.ClosedReason__c = messages.abbreviate(MAX_PICKLIST_FIELD_LEN);
        }

        /**
        * @description Checks if the commitment has been successfully cancelled in Elevate
        * @param response Elevate API response
        * @return Boolean
        */
        private Boolean isCancelled(UTIL_Http.Response response) {
            return response != null && response.statusCode == UTIL_Http.STATUS_CODE_OK;
        }

        /**
        * @description Checks if the commitment has not been found in Elevate
        * based on the provided commitment Id
        * @param response Elevate API response
        * @return Boolean
        */
        private Boolean isNotFound(UTIL_Http.Response response) {
            return response != null && response.statusCode == UTIL_Http.STATUS_CODE_NOT_FOUND;
        }

        /**
        * @description Checks if the commitment has data conflicted error response.
        * Possible reason might be that the commitment has already been cancelled.
        * @param response Elevate API response
        * @return Boolean
        */
        private Boolean isDataConflict(UTIL_Http.Response response) {
            return response != null && response.statusCode == UTIL_Http.STATUS_CODE_CONFLICT;
        }
    }



    /**
    * @description Builds and creates logs for errors and exceptions.
    * The current logger version is the ERR_Handler wrapper.
    */
    public class Logger {
        private final String context = ERR_Handler_API.Context.Elevate.name();
        private final String rdSObjectType = String.valueOf(npe03__Recurring_Donation__c.SObjectType);

        /* @description Contains errors */
        @TestVisible
        private ERR_Handler.Errors errorResult = new ERR_Handler.Errors();

        /**
        * @description Constructs log record and adds it into the error log container
        * @param recordId Id Recurring Donation record Id
        * @param message An error message
        * @param errorType An error type
        * @return void
        */
        public void addError(Id recordId, String message, String errorType) {
            Error__c error = new Error__c(
                Context_Type__c = context,
                Datetime__c = System.now(),
                Object_Type__c = rdSObjectType,
                Related_Record_ID__c = recordId,
                Record_URL__c = ERR_Handler.getRecordURL(recordId),
                Error_Type__c = errorType,
                Full_Message__c = message
            );

            errorResult.errorRecords.add(error);
        }

        /**
        * @description Constructs and collects error logs for records that failed in the DML operation
        * @param dmlResults Insert/update/delete DML operation results
        * @param records Records which were saved/deleted by the DML operation
        * @return void
        */
        public void addErrors(List<Object> dmlResults, List<SObject> records) {
            if (records.isEmpty()) {
                return;
            }

            ERR_Handler.Errors dmlErrors = ERR_Handler.getErrorsOnly(dmlResults, records);

            if (!dmlErrors.errorsExist) {
                return;
            }

            errorResult.errorRecords.addAll(
                dmlErrors.errorRecords
            );
        }

        /**
        * @description Saves errors
        * @return void
        */
        public void processErrors() {
            errorResult.errorsExist = !errorResult.errorRecords.isEmpty();

            ERR_Handler.processErrorsOnly(errorResult, context);
        }
    }
}
