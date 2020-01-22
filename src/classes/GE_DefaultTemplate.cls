public with sharing class GE_DefaultTemplate {

    public GE_DefaultTemplate() {

    }

    public static void createDefaultTemplate() {
        if (!hasDefaultTemplate()) {
            Form_Template__c newDefaultTemplate = buildDefaultTemplate();

            insert newDefaultTemplate;

            Gift_Entry_Settings__c giftEntryCustomSetting = UTIL_CustomSettingsFacade.getGiftEntrySettings();
            giftEntryCustomSetting.Default_Single_Gift_Entry_Template__c = newDefaultTemplate.Id;

            update giftEntryCustomSetting;
        }
    }

    
    private static boolean hasDefaultTemplate() {
            
        // Check to see if there is a default template already. 
        Gift_Entry_Settings__c giftEntryCustomSetting = UTIL_CustomSettingsFacade.getGiftEntrySettings();
        Boolean hasDefaultTemplate = false;

        if (giftEntryCustomSetting.Default_Single_Gift_Entry_Template__c != null && giftEntryCustomSetting.Default_Single_Gift_Entry_Template__c != '') {
            // Get ALL the templates (This might be an issue if they have over )
            List<Form_Template__c> templateList = [SELECT Id, Name 
                                                    FROM Form_Template__c 
                                                    WHERE Id =: giftEntryCustomSetting.Default_Single_Gift_Entry_Template__c];

            if (!templateList.isEmpty()){ 
                hasDefaultTemplate = true;
            }
        }

        return hasDefaultTemplate;
    }

    public static Form_Template__c buildDefaultTemplate() {
        Form_Template__c newDefaultTemplate = new Form_Template__c();



        return newDefaultTemplate;
    }
}
