public inherited sharing class HouseholdService {

    @TestVisible
    private HouseholdSettings settings {
        get {
            if (settings == null) {
                settings = new HouseholdSettings();
            }
            return settings;
        }
        set;
    }

    public HouseholdService(){


    }

    private Set<String> householdNamingFields;
    public Set<String> fieldsUsedForHouseholdNaming() {
        if (householdNamingFields == null) {
            householdNamingFields = new HouseholdNamingService()
                    .getHouseholdNamingContactFields();
        }
        return householdNamingFields;
    }

    public void createHouseholdsForContacts(ContactsInLegacyHouseholds contactsInLegacyHouseholds) {

        if (contactsInLegacyHouseholds.allContactsGetHouseholds()) {
            contactsInLegacyHouseholds.insertHouseholdsForContactsThatDoNotHaveOne();
        }
        if (contactsInLegacyHouseholds.allIndividualContactsGetHouseholds()) {
            contactsInLegacyHouseholds.insertHouseholdsForContactsInIndividualAccounts();
        }
    }

}
