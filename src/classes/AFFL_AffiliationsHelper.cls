public with sharing class AFFL_AffiliationsHelper {

    public static npe5__Affiliations_Settings__c affiliationsSettings;
    
    //get the settings. handles the case where the managed value doesn't exist yet
    public static npe5__Affiliations_Settings__c getAffiliationsSettings() {
        //if no settings exist, create defaults
        if (affiliationsSettings == null) {
            //first see if we already have settings
            affiliationsSettings = npe5__Affiliations_Settings__c.getOrgDefaults();
            system.debug(npe5__Affiliations_Settings__c.getOrgDefaults());
            if (affiliationsSettings.id == null) { 
                //affiliationsSettings = new npe5__Affiliations_Settings__c();
                affiliationsSettings.npe5__Automatic_Affiliation_Creation_Turned_On__c = true;
               
                affiliationsSettings.Setupownerid = UserInfo.getOrganizationId();

                insert affiliationsSettings;
            }
        }
        return affiliationsSettings;
    }
}