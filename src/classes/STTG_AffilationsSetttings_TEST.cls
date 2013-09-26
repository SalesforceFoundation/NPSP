@isTest
public with sharing class STTG_AffilationsSetttings_TEST {
     
     public static testMethod void TEST_affiliationsSettings() {
        
        Test.setCurrentPageReference(new PageReference('Page.npe5__affiliationsSettings'));
        
        //pass the controller into the extension
        STTG_AffiliationsSettings_CTRL controller = new STTG_AffiliationsSettings_CTRL(); 
        controller.getSettingsFirstTime(); 
        system.assertNotEquals(null,controller.getSettings());
        controller.updateSettings();       
    }
}