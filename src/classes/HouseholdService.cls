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

        if (allContactsGetHouseholds()) {
            insertHouseholdsForContactsThatDoNotHaveOne(contactsInLegacyHouseholds);
        }
        if (allIndividualContactsGetHouseholds()) {
            insertHouseholdsForContactsInIndividualAccounts(contactsInLegacyHouseholds);
        }
    }

    public void insertHouseholdsForContactsInIndividualAccounts(ContactsInLegacyHouseholds contactsInLegacyHouseholds) {
        List<Contact> contactsThatDoNotHaveAHouseholdRecord =
                contactsInLegacyHouseholds.contactsWithoutHouseholds();
        if (contactsThatDoNotHaveAHouseholdRecord.size() > 0) {
            insertHouseholdsForContacts(
                    contactsInLegacyHouseholds.getContactsInIndividualAccounts(
                            contactsThatDoNotHaveAHouseholdRecord),
                    true);
        }
    }

    public Boolean allIndividualContactsGetHouseholds() {
        return settings.isAllIndividualsProcessor();
    }

    public Boolean allContactsGetHouseholds() {
        return settings.isAllProcessor();
    }

    public void insertHouseholdsForContactsThatDoNotHaveOne(ContactsInLegacyHouseholds contactsInLegacyHouseholds) {
        List<Contact> householdInserts = contactsInLegacyHouseholds
                .contactsWithoutHouseholds();
        if (householdInserts.size() > 0) {
            insertHouseholdsForContacts(householdInserts, true);
        }
    }

    /*******************************************************************************************************
    * @description Creates a new Household Object for each contact, unless excluded by recordType
    * @param contacts List of Contacts
    * @param isInsertTrigger Whether called from the afterInsert trigger (vs. afterUpdate trigger) on Contacts
    * @return void
    ********************************************************************************************************/
    public void insertHouseholdsForContacts(List<Contact> contacts, Boolean isInsertTrigger) {
        List<npo02__Household__c> householdInserts = getHouseholdsForInsert(contacts);
        if (householdInserts.size() > 0) {
            Database.SaveResult[] householdSaveResults = insertHouseholds(householdInserts);
            putHouseholdIdOntoContacts(contacts, householdSaveResults);
            if (isInsertTrigger) {
                updateNamesAfterHouseholdInsert(householdSaveResults);
            }
        }
    }

    private Database.SaveResult[] insertHouseholds(
            List<npo02__Household__c> householdInserts) {
        Database.SaveResult[] householdSaveResults =
                UTIL_DMLService.insertRecords(householdInserts, false);
        return householdSaveResults;
    }

    private void putHouseholdIdOntoContacts(List<Contact> contacts,
            Database.SaveResult[] householdSaveResults) {
        List<Contact> contactsToBeUpdatedWithHouseholdId =
                processHouseholdSaveResults(contacts, householdSaveResults);
        update contactsToBeUpdatedWithHouseholdId;
    }

    private void updateNamesAfterHouseholdInsert(Database.SaveResult[] lsr) {
        List<Id> householdIdsNeedingNamesUpdated = getHouseholdIdsNeedingNamesUpdatedFromSaveResult(lsr);
        if (!householdIdsNeedingNamesUpdated.isEmpty()) {
            Households households = new Households(new Set<Id>
                    (householdIdsNeedingNamesUpdated));
            households.updateHouseholdNameAndMemberCount();
        }
    }

    private List<Id> getHouseholdIdsNeedingNamesUpdatedFromSaveResult(Database.SaveResult[] lsr) {
        List<Id> householdIdsNeedingNamesUpdated = new List<Id>();
        for (Database.SaveResult sr : lsr) {
            if (sr.isSuccess()) {
                householdIdsNeedingNamesUpdated.add(sr.getID());
            }
        }
        return householdIdsNeedingNamesUpdated;
    }

    private List<Contact> processHouseholdSaveResults(List<Contact> contacts,
            Database.SaveResult[] householdSaveResults) {
        List<Contact> contactsToBeUpdatedWithHouseholdId = new List<Contact>();
        Integer i = 0;
        for (Contact con : contacts) {
            if (shouldExcludeForNewHHAccount(con)) {
                Database.SaveResult saveResult = householdSaveResults[i];
                if (saveResult.isSuccess() == true) {
                    //write the new Household Ids to the Contacts
                    Contact cloneContact = con.Clone(true, false);
                    cloneContact.npo02__household__c = saveResult.getId();
                    contactsToBeUpdatedWithHouseholdId.add(cloneContact);
                } else {
                    Database.Error err = saveResult.getErrors()[0];
                    con.addError(err.getMessage());
                }
                i += 1;
            }
        }
        return contactsToBeUpdatedWithHouseholdId;
    }

    private List<npo02__Household__c> getHouseholdsForInsert(List<Contact> contacts) {
        List<npo02__household__c> households = new List<npo02__household__c>();
        for (Contact con : contacts) {
            if (shouldExcludeForNewHHAccount(con)) {
                households.add(getHouseholdForInsertFromContact(con));
            }
        }
        return households;
    }

    private npo02__Household__c getHouseholdForInsertFromContact(Contact con) {
        npo02__household__c household =
                new npo02__household__c(Name = getDefaultHouseholdName(con));
        syncPrimaryAddressBlock(household, con);
        return household;
    }

    private void syncPrimaryAddressBlock(npo02__Household__c household, Contact con) {
        household.npo02__MailingStreet__c = con.MailingStreet;
        household.npo02__MailingCity__c = con.MailingCity;
        household.npo02__MailingState__c = con.MailingState;
        household.npo02__MailingPostalCode__c = con.MailingPostalCode;
        household.npo02__MailingCountry__c = con.MailingCountry;
        household.npo02__HouseholdPhone__c = con.HomePhone;
        household.npo02__HouseholdEmail__c = con.Email;
    }

    private String getDefaultHouseholdName(Contact con) {
        String hName = con.LastName;
        return hName += ' ' + System.Label.npo02.DefaultHouseholdName;
    }

    private Boolean shouldExcludeForNewHHAccount(Contact con) {
        return !isRecordTypesOnContacts()
                || !settings.contactRecordTypesToExclude().contains(recordTypeIdFor(con));
    }

    private final String RECORD_TYPE_ID = 'RecordTypeId';
    private Id recordTypeIdFor(Contact con) {
        return (Id) con.get(RECORD_TYPE_ID);
    }

    private Boolean isRecordTypesOnContacts() {
        return Schema.sObjectType.Contact.fields.getMap().get(RECORD_TYPE_ID) != null;
    }

    public void insertHouseholds(ContactsInLegacyHouseholds contactsInLegacyHouseholds) {
        List<Contact> contactsThatDoNotHaveAHousehold = contactsInLegacyHouseholds
                .contactsWithoutHouseholds();
        List<Contact> contactsNeedingHouseholds = new List<Contact>();
        if (settings.isAllProcessor()) {
            contactsNeedingHouseholds.addAll(contactsThatDoNotHaveAHousehold);
        }
        if (settings.isAllIndividualsProcessor()) {
            contactsNeedingHouseholds.addAll(
                    contactsInLegacyHouseholds.getContactsInIndividualAccounts(
                            contactsThatDoNotHaveAHousehold));
        }
        insertHouseholdsForContacts(contactsNeedingHouseholds, false);
    }

    public void deleteEmptyHouseholds(ContactsInLegacyHouseholds contactsInLegacyHouseholds) {
        Households oldHouseholds = new Households(new Set<Id>(contactsInLegacyHouseholds
                .oldHouseholdIds()));
        oldHouseholds.deleteEmptyHouseholds();
    }


    /**
     * @description Static flag used to prevent hitting governor limits when this method
     * runs multiple times during Contact merges.
     */
    private static Integer numberOfTimesUpdateHouseholdNamesHasRun = 0;
    public void updateHouseholdNames(ContactsInLegacyHouseholds contactsInLegacyHouseholds) {
        List<Id> householdsNeedingNameAndMemberCountRefresh =
                contactsInLegacyHouseholds.getHouseholdsWithMembershipOrNamingFieldChanges();
        if (householdsNeedingNameAndMemberCountRefresh.size() > 0 && numberOfTimesUpdateHouseholdNamesHasRun < 2) {
            Households households =
                    new Households(new Set<Id>(householdsNeedingNameAndMemberCountRefresh));
            households.updateHouseholdNameAndMemberCount();
            numberOfTimesUpdateHouseholdNamesHasRun++;
        }
    }

    public void fireRollups(ContactsInLegacyHouseholds contactsInLegacyHouseholds) {
        Households householdsWithMembershipChanges =
                new Households(contactsInLegacyHouseholds.householdIdsWithMembershipChanges
                        ());
        householdsWithMembershipChanges.calculateLegacyHouseholdRollups();
    }

    public void processOldHouseholdsAfterDeletingContacts(ContactsInLegacyHouseholds contactsInLegacyHouseholds) {

        Households oldHouseholds = new Households(contactsInLegacyHouseholds.householdIds());
        oldHouseholds.deleteEmptyHouseholds();
        oldHouseholds.updateHouseholdNameAndMemberCount();
    }

}
