public with sharing class GiftDTO {

    public Map<String, Object> fields;
    public List<OpportunityContactRole> softCredits;

    public GiftDTO(Gift gift) {
        this.fields = gift.fieldsWithValues();
        this.softCredits = gift.softCredits().all();
    }
}
