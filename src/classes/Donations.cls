public with sharing class Donations {

    private List<Donation> donations = new List<Donation>();
    private String donorType;

    public Donations(Id donorId, DonationSelector selector) {
        this.donorType = donorId.getSObjectType().getDescribe().getName();

        String relationshipField;
        if (donorType == SObjectType.Account.Name) {
            relationshipField = SObjectType.Opportunity.fields.AccountId.Name;
        } else if (donorType == SObjectType.Contact.Name) {
            relationshipField = SObjectType.Opportunity.fields.Primary_Contact__c.Name;
        }

        for (Opportunity opportunity : selector.getOpenDonations(relationshipField, donorId)) {
            donations.add(new Donation(opportunity));
        }
    }

    public List<Donation> all() {
        return this.donations;
    }
}
