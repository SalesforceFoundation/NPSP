public with sharing class DonationDTO {

    public List<Object> unpaidPayments;
    public Object opportunity;
    public SoftCreditsDTO softCreditsDTO;

    public DonationDTO(Donation donation) {
        this.opportunity = donation.opportunity();
        this.unpaidPayments = donation.unpaidPayments();
        this.softCreditsDTO = new SoftCreditsDTO(donation.softCredits());
    }
}
