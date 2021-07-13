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

    public DonationsView getDonationsView(Id donorId) {
        Donations donations = new Donations(donorId, this.donationSelector);
        DonationsDTO donationsDTO = new DonationsDTO(donations);
        return new DonationsView(donationsDTO);
    }
}
