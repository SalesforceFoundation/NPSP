public with sharing class SoftCredits {

    private List<OpportunityContactRole> opportunityContactRoles;

    public SoftCredits(List<OpportunityContactRole> opportunityContactRoles) {
        this.opportunityContactRoles = opportunityContactRoles;
    }

    public List<OpportunityContactRole> all() {
        return opportunityContactRoles;
    }

    public Integer size() {
        return opportunityContactRoles.size();
    }

    public void add(OpportunityContactRole opportunityContactRole) {
        this.opportunityContactRoles.add(opportunityContactRole);
    }

    public void addAll(List<OpportunityContactRole> moreOpportunityContacRoles) {
        this.opportunityContactRoles.addAll(moreOpportunityContacRoles);
    }

    public List<OpportunityContactRole> unprocessed() {
        List<OpportunityContactRole> unprocessed = new List<OpportunityContactRole>();
        for (OpportunityContactRole ocr : this.opportunityContactRoles) {
            if (ocr.id == null) {
                unprocessed.add(ocr);
            }
        }
        return unprocessed;
    }
}
