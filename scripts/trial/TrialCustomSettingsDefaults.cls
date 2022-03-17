/**
* @description Creates default values from different custom settings objects in a trial org setup
*/
List<SObject> settingsToUpdate = new List<SObject>

public static void updateCustomSettingsDefaults() {
    setContactsAndOrgDefaults();
    setRelationshipDefaults();
    setRecurringDonationDefaults();
    setErrorNotificationDefaults();

    update settingsToUpdate;
}
public static void setContactsAndOrgDefaults() {
    npe01__Contacts_And_Orgs_Settings__c contactSettings = UTIL_CustomSettingsFacade.getContactsSettings();
    contactSettings.Honoree_Opportunity_Contact_Role__c = 'Honoree';
    contactSettings.Notification_Recipient_Opp_Contact_Role__c = 'Notification Recipient';

    settingsToUpdate.add(contactSettings);
}

public static void setRelationshipDefaults() {
    npe4__Relationship_Settings__c relationshipSettings = UTIL_CustomSettingsFacade.getRelationshipSettings();
    relationshipSettings.npe4__Gender_Field__c = String.valueOf(Contact.Gender__c);

    settingsToUpdate.add(relationshipSettings);
}

public static void setRecurringDonationDefaults() {
    npe03__Recurring_Donations_Settings__c recurringDonationsSettings =
        UTIL_CustomSettingsFacade.getRecurringDonationsSettings();

    recurringDonationsSettings.RecurringDonationNameFormat__c = '{!npe03__Donor_Name__c} {!npe03__Amount__c} - ' +
            'Recurring';

    settingsToUpdate.add(recurringDonationsSettings);
}

public static void setErrorNotificationDefaults() {
    npe03__Recurring_Donations_Settings__c errorSettings = UTIL_CustomSettingsFacade.getErrorSettings();
    errorSettings.Respect_Duplicate_Rule_Settings__c = true;

    settingsToUpdate.add(errorSettings);
}


