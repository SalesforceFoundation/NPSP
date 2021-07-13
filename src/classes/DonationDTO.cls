public with sharing class DonationDTO {

    public List<Object> unpaidPayments;
    public Object opportunity;

    public DonationDTO(Donation donation) {
        this.opportunity = donation.opportunity();
        this.unpaidPayments = donation.unpaidPayments();
    }
}
