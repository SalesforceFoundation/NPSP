public with sharing class SoftCreditsDTO {

    public List<Object> softCredits;

    public SoftCreditsDTO(SoftCredits softCredits) {
        this.softCredits = softCredits.all();
    }
}
