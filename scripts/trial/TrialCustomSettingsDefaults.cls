/**
* @description Creates default values from different custom settings objects in a trial org setup
*/
List<SObject> settingsToUpdate = new List<SObject>();

public static void updateCustomSettingsDefaults() {
    setContactsAndOrgDefaults();
    setRelationshipDefaults();
    setRecurringDonationDefaults();
    setErrorNotificationDefaults();

    upsert settingsToUpdate;
}
private static void setContactsAndOrgDefaults() {
    npe01__Contacts_And_Orgs_Settings__c contactSettings = npe01__Contacts_And_Orgs_Settings__c.getOrgDefaults();
    contactSettings.%%%NAMESPACE%%%Honoree_Opportunity_Contact_Role__c = 'Honoree';
    contactSettings.%%%NAMESPACE%%%Notification_Recipient_Opp_Contact_Role__c = 'Notification Recipient';
    contactSettings.%%%NAMESPACE%%%Automatic_Campaign_Member_Management__c = true;
    contactSettings.%%%NAMESPACE%%%Simple_Address_Change_Treated_as_Update__c = true;
    contactSettings.%%%NAMESPACE%%%Opp_RecTypes_Excluded_for_Payments__c = getOppRecordType('InKindGift');

    settingsToUpdate.add(contactSettings);
}

private static void setRelationshipDefaults() {
    npe4__Relationship_Settings__c relationshipSettings = npe4__Relationship_Settings__c.getOrgDefaults();
    relationshipSettings.npe4__Gender_Field__c = 'Gender__c';

    settingsToUpdate.add(relationshipSettings);
}

private static void setRecurringDonationDefaults() {
    npe03__Recurring_Donations_Settings__c recurringDonationsSettings =
        npe03__Recurring_Donations_Settings__c.getOrgDefaults();

    recurringDonationsSettings.%%%NAMESPACE%%%RecurringDonationNameFormat__c =
            '{!npe03__Donor_Name__c} {!npe03__Amount__c} - Recurring';
    recurringDonationsSettings.%%%NAMESPACE%%%EnableAutomaticNaming__c = true;
    recurringDonationsSettings.npe03__Record_Type__c = getOppRecordType('Donation');
    recurringDonationsSettings.%%%NAMESPACE%%%StatusAutomationLapsedValue__c = 'Lapsed';
    recurringDonationsSettings.%%%NAMESPACE%%%StatusAutomationClosedValue__c = 'Closed';
    settingsToUpdate.add(recurringDonationsSettings);
}

private static void setErrorNotificationDefaults() {
    %%%NAMESPACE%%%Error_Settings__c errorSettings = %%%NAMESPACE%%%Error_Settings__c.getOrgDefaults();
    errorSettings.%%%NAMESPACE%%%Respect_Duplicate_Rule_Settings__c = true;

    settingsToUpdate.add(errorSettings);
}

/**
 * @description Retrieve the specified record type, or the first active RT if that fails
 */
private static String getOppRecordType(String rtDevName) {
    Recordtypeinfo oppRt = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get(rtDevName);
    if (oppRt == null) {
        oppRt = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('NPSP_Default');
    }
    return oppRt.getRecordTypeId();
}


