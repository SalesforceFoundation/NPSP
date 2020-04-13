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

    /**
    * @description Map of CommitmentId to a specific RecordId (Opp or RD).
    */
    private Map<String, Id> commitmentIdToRecordId = new Map<String, Id>();

    /**
    * @description Pass the map of CommitmentId to RecordId (Opp or RD)
    * @param commitmentIdToRecordId Map by CommitmentId
    * @return this
    */
    public RD2_ElevateIntegrationService withCommitmentIdMap(Map<String, Id> commitmentIdToRecordId) {
        this.commitmentIdToRecordId = commitmentIdToRecordId;
        return this;
    }

    /**
    * @description For each CommitmentId, find any existing Opportunities with the matching Commitmentid
    * and update the RecuringDonation lookup field (only if null).
    */
    public void matchRecurringDonationsToOpps() {
        if (commitmentIdToRecordId == null || commitmentIdToRecordId.isEmpty()) {
            return;
        }

        // Skip the process if the Id does not point to a RecurringDonation record
        if (commitmentIdToRecordId.values()[0].getSobjectType() != npe03__Recurring_Donation__c.SObjectType) {
            return;
        }

        List<Opportunity> oppsToUpdate = new List<Opportunity>();
        for (Opportunity opp : [SELECT Id, npe03__Recurring_Donation__c, CommitmentId__c
            FROM Opportunity
            WHERE CommitmentId__c IN :commitmentIdToRecordId.keySet()
        ]) {
            if (opp.CommitmentId__c == null || opp.npe03__Recurring_Donation__c != null) {
                continue;
            }
            opp.npe03__Recurring_Donation__c = commitmentIdToRecordId.get(opp.CommitmentId__c);
            oppsToUpdate.add(opp);
        }

        if (!oppsToUpdate.isEmpty()) {
            UTIL_DMLService.updateRecordBatchAndLogErrors(oppsToUpdate, 'RD_Elevate');
        }
    }

    /**
    * @description For each CommitmentId, find the matching RecurringDonation with the same CommitmentId
    * and update the RecurringDonation lookup field on the Opp.
    */
    public void matchOppsToRecurringDonations() {
        if (commitmentIdToRecordId == null || commitmentIdToRecordId.isEmpty()) {
            return;
        }

        // Skip the process if the Id does not point to an Opportunity record
        if (commitmentIdToRecordId.values()[0].getSobjectType() != Opportunity.SObjectType) {
            return;
        }

        List<Opportunity> oppsToUpdate = new List<Opportunity>();
        for (npe03__Recurring_Donation__c rd : [SELECT Id, CommitmentId__c
            FROM npe03__Recurring_Donation__c
            WHERE CommitmentId__c IN :commitmentIdToRecordId.keySet()
        ]) {
            if (rd.CommitmentId__c == null) {
                continue;
            }
            Opportunity opp = new Opportunity(
                Id = commitmentIdToRecordId.get(rd.CommitmentId__c),
                npe03__Recurring_Donation__c = rd.Id
            );
            oppsToUpdate.add(opp);
        }

        if (!oppsToUpdate.isEmpty()) {
            UTIL_DMLService.updateRecordBatchAndLogErrors(oppsToUpdate, 'RD_Elevate');
        }
    }
}