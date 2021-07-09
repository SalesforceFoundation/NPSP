public with sharing class SoftCreditsView {

    @AuraEnabled public List<Object> all;

    public SoftCreditsView(SoftCreditsDTO softCreditsDTO) {
        this.all = softCreditsDTO.softCredits;
    }
}
