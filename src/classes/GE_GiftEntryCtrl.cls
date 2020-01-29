public with sharing class GE_GiftEntryCtrl {
    
    @auraEnabled
    public static void createDefaultTemplate() {
        GE_DefaultTemplate.createDefaultTemplate();
    }
}
