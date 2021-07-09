public with sharing class GiftDTO {

    public Map<String, Object> fields;
    public SoftCreditsDTO softCreditsDTO;

    public GiftDTO(Gift gift) {
        this.fields = gift.fieldsWithValues();
        this.softCreditsDTO = new SoftCreditsDTO(gift.softCredits());
    }
}
