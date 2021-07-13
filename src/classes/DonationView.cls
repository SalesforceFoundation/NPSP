public inherited sharing class DonationView {

    @AuraEnabled public Object opportunity;
    @AuraEnabled public List<Object> unpaidPayments;

    public DonationView(DonationDTO donationDTO) {
        this.opportunity = donationDTO.opportunity;
        this.unpaidPayments = donationDTO.unpaidPayments;
    }
}
