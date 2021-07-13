public inherited sharing class Donation {
    private List<npe01__OppPayment__c> unpaidPayments;
    private Boolean hasNonWrittenOffPayments;
    private Opportunity opportunity;
    private SoftCredits softCredits;

    public Donation(Opportunity opportunity) {
        this.opportunity = opportunity;
        initialize();
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
}
