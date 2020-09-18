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
    * @description Payment Service Elevate API
    */
    @TestVisible
    private PS_ElevateAPI apiService {
        get {
            if (apiService == null) {
                apiService = new PS_ElevateAPI();
            }
            return apiService;
        }
        set;
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
            || rd.PaymentMethod__c != oldRd.PaymentMethod__c
            || rd.Status__c != oldRd.Status__c
            || rd.CommitmentId__c != oldRd.CommitmentId__c;

        if (!isChanged && !(new RD2_RecurringDonation(rd)).isClosed()) {
            isChanged = rd.ClosedReason__c != oldRd.ClosedReason__c;
        }

        if (!isChanged && isMultiCurrencyEnabled) {
            isChanged = (String) rd.get(CURRENCY_ISO_CODE_FIELD) != (String) oldRd.get(CURRENCY_ISO_CODE_FIELD);
        }

        // If any of the restricted fields has been changed, prevent the RD update
        return !isChanged;
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
    * @description Send Http Request to Elevate and close Closed RD's attached Commitments
    * @param trackedClosedRds Closed RDs with original Close Reason that will be process
    */
    public void closeCommitmentsInElevate(List<npe03__Recurring_Donation__c> trackedClosedRds) {

        List<PS_ElevateAPI.ResponseWrapper> responses = new List<PS_ElevateAPI.ResponseWrapper>();

        for (npe03__Recurring_Donation__c elevateClosedRd : trackedClosedRds) {
            HttpRequest request = new PS_ElevateAPI.RequestBuilder()
                .withCommitmentId(elevateClosedRd.CommitmentId__c)
                .withEndpoint(PS_ElevateAPI.ElevateEndpoint.COMMITMENT_CANCEL)
                .withMethod(PS_ElevateAPI.HttpRequestMethod.POST)
                .build();
            
            responses.add(apiService.sendRequest(request));
        }

        for (Integer i = 0; i < responses.size(); i ++) {
            if (responses[i].statusCode != 200) {
                //error handling, currently just populate the failing body onto the close reason
                trackedClosedRds[i].ClosedReason__c = responses[i].body;
            }
        }

        update trackedClosedRds;
    }
}