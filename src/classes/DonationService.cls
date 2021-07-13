public with sharing class DonationService {

    @TestVisible
    public DonationSelector donationSelector {
        get {
            if (donationSelector == null) {
                donationSelector = new DonationSelector();
            }
            return donationSelector;
        }
        set;
    }

    public List<Donation> getOpenDonationsFor(Id donorId) {
        Donations donations = new Donations(donorId, this.donationSelector);
        return donations.areOpen();
    }
}
