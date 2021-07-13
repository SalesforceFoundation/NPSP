public inherited sharing class DonationView {

    @AuraEnabled public Map<String, Object> opportunity;
    @AuraEnabled public List<Map<String, Object>> unpaidPayments;
    @AuraEnabled public SoftCreditsView softCredits;

    public DonationView(DonationDTO donationDTO) {
        this.opportunity = (Map<String, Object>) JSON.deserializeUntyped(JSON.serialize(donationDTO.opportunity));
        this.unpaidPayments = new List<Map<String, Object>>();
        for (Object payment : donationDTO.unpaidPayments) {
            Map<String, Object> untyped = (Map<String, Object>) JSON.deserializeUntyped(JSON.serialize(payment));
            this.unpaidPayments.add(untyped);
        }
        this.softCredits = new SoftCreditsView(donationDTO.softCreditsDTO);
    }
}
