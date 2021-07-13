public inherited sharing class DonationsDTO {

    public List<DonationDTO> donationDTOs = new List<DonationDTO>();

    public DonationsDTO(Donations donations) {
        for (Donation donation : donations.all()) {
            donationDTOs.add(new DonationDTO(donation));
        }
    }
}
