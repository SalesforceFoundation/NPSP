/*
    Copyright (c) 2021 Salesforce.org
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
* @date 2021
* @description Donation domain class.
*/
public inherited sharing class Donation {
    private List<npe01__OppPayment__c> unpaidPayments;
    private Boolean hasNonWrittenOffPayments;
    private Opportunity opportunity;
    private SoftCredits softCredits;

    @TestVisible
    private DonationSelector donationSelector {
        get {
            if (donationSelector == null) {
                donationSelector = new DonationSelector();
            }
            return donationSelector;
        }
        set;
    }

    public Donation(Opportunity opportunity) {
        this.opportunity = opportunity;
        initialize();
    }

    public Donation(Id opportunityId) {
        List<Opportunity> foundOpportunities =
            donationSelector.getDonation(opportunityId);
        if (foundOpportunities?.size() > 0) {
            this.opportunity = foundOpportunities[0];
            initialize();
        } else {
            throw new DonationException('No opportunity found.');
        }
    }

    public Opportunity opportunity() {
        return this.opportunity;
    }

    public List<npe01__OppPayment__c> unpaidPayments() {
        return this.unpaidPayments;
    }

    public SoftCredits softCredits() {
        return this.softCredits;
    }

    private void initialize() {
        softCredits = new SoftCredits(opportunity.OpportunityContactRoles);

        if (unpaidPayments == null) {
            unpaidPayments = new List<npe01__OppPayment__c>();
        }

        if (opportunity.npe01__OppPayment__r.isEmpty()) {
            hasNonWrittenOffPayments = false;
            return;
        }

        for (npe01__OppPayment__c oppPayment : opportunity.npe01__OppPayment__r) {
            if (hasNonWrittenOffPayments == null
                    && oppPayment.npe01__Written_Off__c == false) {
                hasNonWrittenOffPayments = true;
            }

            if (isAvailableForUpdate(oppPayment)) {
                unpaidPayments.add(oppPayment);
            } else {
                continue;
            }
        }

        //If hasNonWrittenOffPayments is null after looping all of the Payments,
        //then all of the Opp's Payments are written-off, and hasNonWrittenOffPayments can
        //be set to false, as this Opp should be treated in the BGE Donation Selector UI
        //as if it has 0 Payments.
        if (hasNonWrittenOffPayments == null) {
            hasNonWrittenOffPayments = false;
        }
    }

    private Boolean isAvailableForUpdate(npe01__OppPayment__c oppPayment) {
        if (oppPayment.npe01__Paid__c || oppPayment.npe01__Written_Off__c) {
            return false;
        } else {
            return true;
        }
    }

    public class DonationException extends Exception{}
}
