/**
* @description Configure all default NPSP Custom Settings by calling each of the "getOrg..." methods in the
* CustomSettingsFacade. In addition, this retrieves the Opportunity.Membership record type Id and populates
* that in the HouseholdSettings object.
* @author Michael Smith
* @date 2018-06-07
*/
public static void initializeNPSPSettings() {
    // When calling this code in a managed context, the string %%%NAMESPACE%%% will be replaced with
    // "NAMESPACE__" via the cumulusci task in cumulusci.tasks.apex.anon.AnonymousApexTask.
    // Similarly %%%NAMESPACED_RT%%% will be replaced by "NAMESPACE." for namespaced record type support

    %%%NAMESPACE%%%UTIL_CustomSettingsFacade.getOrgContactsSettings();
    %%%NAMESPACE%%%UTIL_CustomSettingsFacade.getOrgHouseholdsSettings();
    %%%NAMESPACE%%%UTIL_CustomSettingsFacade.getOrgRecurringDonationsSettings();
    %%%NAMESPACE%%%UTIL_CustomSettingsFacade.getOrgRelationshipSettings();
    %%%NAMESPACE%%%UTIL_CustomSettingsFacade.getOrgAffiliationsSettings();
    %%%NAMESPACE%%%UTIL_CustomSettingsFacade.getOrgHouseholdNamingSettings();
    %%%NAMESPACE%%%UTIL_CustomSettingsFacade.getOrgErrorSettings();
    %%%NAMESPACE%%%UTIL_CustomSettingsFacade.getOrgAddressVerificationSettings();
    %%%NAMESPACE%%%UTIL_CustomSettingsFacade.getOrgBDESettings();
    %%%NAMESPACE%%%UTIL_CustomSettingsFacade.getOrgAllocationsSettings();
    %%%NAMESPACE%%%UTIL_CustomSettingsFacade.getOrgDataImportSettings();

    Id rtId = [SELECT Id FROM RecordType WHERE SObjectType = 'Opportunity' AND DeveloperName = 'Membership' LIMIT 1].Id;

    npo02__Households_Settings__c hs = %%%NAMESPACE%%%UTIL_CustomSettingsFacade.getOrgHouseholdsSettings();
    hs.npo02__Membership_Record_Types__c = rtId;
    upsert hs;

    npe01__Contacts_And_Orgs_Settings__c cos = %%%NAMESPACE%%%UTIL_CustomSettingsFacade.getOrgContactsSettings();
    cos.%%%NAMESPACE%%%Honoree_Opportunity_Contact_Role__c = 'Honoree Contact';
    cos.%%%NAMESPACE%%%Notification_Recipient_Opp_Contact_Role__c = 'Notification Contact';
    cos.%%%NAMESPACE%%%Payments_Auto_Close_Stage_Name__c = getClosedWonStage();
    upsert cos;

    %%%NAMESPACE%%%Package_Settings__c pkg = %%%NAMESPACE%%%Package_Settings__c.getOrgDefaults();
    pkg.%%%NAMESPACE%%%Namespace_Prefix__c = %%%NAMESPACE%%%UTIL_Namespace.StrTokenNSPrefix('');
    upsert pkg;
}

private static String getClosedWonStage(){
    OpportunityStage closedWonStage = [SELECT MasterLabel FROM OpportunityStage
        WHERE IsActive = true AND IsWon = true LIMIT 1];
    return closedWonStage.MasterLabel;
}

