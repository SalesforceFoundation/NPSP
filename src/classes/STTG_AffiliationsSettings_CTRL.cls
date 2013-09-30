public with sharing class STTG_AffiliationsSettings_CTRL {

    public npe5__affiliations_Settings__c settingsToUpdate;
    public npe5__affiliations_Settings__c pageSettings = new npe5__affiliations_Settings__c();
    
    public STTG_AffiliationsSettings_CTRL(){
        
    }
    
    public npe5__affiliations_Settings__c getSettings() {
        pageSettings = AFFL_Affiliations.getAffiliationsSettings();
        return pageSettings;
    }
    //we can't do a DML in a getter, so I call it from the action of the page
    public PageReference getSettingsFirstTime() {
        pageSettings = AFFL_Affiliations.getAffiliationsSettings();
        return null;
    }
    
    
    private void showInfoMsg(String arg){
        ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.INFO,arg);
        ApexPages.addMessage(myMsg);
    }
    
    public void updateSettings(){
        
        update pageSettings;
        showInfoMsg('Affiliations Settings updated');
    }
}