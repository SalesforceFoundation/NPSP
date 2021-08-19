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

    public static final String LOG_TYPE_COMMITMENT_CREATE = 'payment.commitment.create';
    public static final String LOG_TYPE_COMMITMENT_EDIT = 'payment.commitment.edit';
    public static final String LOG_TYPE_COMMITMENT_CANCEL = 'payment.commitment.cancel';

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
    * @description Determines whether a Recurring Donation event is from the Elevate integration
    * @param rd Changed Recurring Donation
    * @param oldRd Old Recurring Donation
    * @return Boolean
    */
    public static Boolean isElevateEvent(RD2_RecurringDonation rd, RD2_RecurringDonation oldRd) {
        Integer newElevateEventVersion = returnElevateVersionAsInteger(rd);
        Integer oldElevateEventVersion = returnElevateVersionAsInteger(oldRd);

        Boolean isElevateEventChanged = newElevateEventVersion > oldElevateEventVersion;

        return isElevateEventChanged;
    }

    /***
    * @description Returns the Last Elevate Version Played as an Integer. If null, return -1
    * @return Integer
    */
    private static Integer returnElevateVersionAsInteger (RD2_RecurringDonation rd){
        return rd.getSObject().LastElevateVersionPlayed__c != null 
            ? Integer.valueOf(rd.getSObject().LastElevateVersionPlayed__c) : -1;
    }

    /***
     * @description Determines if the Recurring Donation can be changed
     * @param rd Changed Recurring Donation
     * @param oldRd Old Recurring Donation
     * @return Boolean
     */
    public Boolean hasUpdatePermissions(npe03__Recurring_Donation__c rd, npe03__Recurring_Donation__c oldRd) {
        if (String.isBlank(rd.CommitmentId__c)
            || !config.isIntegrationEnabled()
            || config.hasIntegrationPermissions()
        ) {
            return true;
        }

        // Check if any of the restricted fields has been changed
        Boolean isChanged = rd.npe03__Contact__c != oldRd.npe03__Contact__c
            || rd.npe03__Organization__c != oldRd.npe03__Organization__c
            || rd.npe03__Installments__c != oldRd.npe03__Installments__c
            || rd.npe03__Date_Established__c != oldRd.npe03__Date_Established__c
            || rd.StartDate__c != oldRd.StartDate__c
            || rd.RecurringType__c != oldRd.RecurringType__c;

        if (!isChanged) {
            String oldCommitmentId = oldRd.CommitmentId__c;

            isChanged = String.isNotBlank(oldCommitmentId)
                && rd.CommitmentId__c != oldCommitmentId;
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

}
