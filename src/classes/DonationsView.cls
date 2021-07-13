public inherited sharing class DonationsView {

    @AuraEnabled public List<DonationView> donations = new List<DonationView>();

    public DonationsView(DonationsDTO donationsDTO) {
        for (DonationDTO donationDTO : donationsDTO.donationDTOs) {
            donations.add(new DonationView(donationDTO));
        }
    }
}
