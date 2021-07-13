public inherited sharing class DonationView {

    @AuraEnabled public Object opportunity;
    @AuraEnabled public List<Object> unpaidPayments;
    @AuraEnabled public SoftCreditsView softCredits;

    public DonationView(DonationDTO donationDTO) {
        this.opportunity = donationDTO.opportunity;
        this.unpaidPayments = donationDTO.unpaidPayments;
        this.softCredits = new SoftCreditsView(donationDTO.softCreditsDTO);
    }
}
