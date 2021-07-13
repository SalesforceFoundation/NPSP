public inherited sharing class HouseholdsApp {

    @TestVisible
    private static ContactAndOrgSettings contactAndOrgSettingsInst {
        get {
            if (contactAndOrgSettingsInst == null) {
                contactAndOrgSettingsInst = new ContactAndOrgSettings();
            }
            return contactAndOrgSettingsInst;
        }
        set;
    }

    @TestVisible
    private ContactSelector contactSelector {
        get {
            if (contactSelector == null) {
                contactSelector = new ContactSelector();
            }
            return contactSelector;
        }
        set;
    }

    @TestVisible
    private HouseholdAccountSelector householdAccountRepository {
        get {
            if (householdAccountRepository == null) {
                householdAccountRepository =
                        new HouseholdAccountSelector();
            }
            return householdAccountRepository;
        }
        set;
    }

    public void onBeforeInsertOf(Contacts contacts) {
        contacts.resetDeprecatedFields();

        HouseholdAccounts.createOneToOneAndHouseholdAccountsFor(
                //todo: pull out settings check
                (List<Contact>) contacts.contactsAndOneToOneContacts_insertContext()
                        .getRecords());

        if (contactAndOrgSettingsInst.isBucketAccountEnabled()) {
            attachToBucketAccount(
                    contacts.contactsWithoutAccounts());
        }
    }

    public void onAfterInsertOf(Contacts contacts, TDTM_Runnable.DmlWrapper dmlWrapper) {
        List<Contact> contactsWithAccountAndAddressFields =
                getContactsWithAccountAndAddressFields(contacts);

        Households.updatePrimaryContactOnAccountsAfterInsert(
                dmlWrapper, contactsWithAccountAndAddressFields);

        HouseholdAccounts.renameHouseholdAccountsAfterInsert(
                contactsWithAccountAndAddressFields);
    }

    /**
     * @description In the before update trigger context, ensure accounts are created for the contacts that need them.
     */
    public void onBeforeUpdateOf(Contacts contacts) {
        Households.handleContactsBeforeUpdate(contacts);
    }

    public void onAfterUpdateOf(Contacts contacts, TDTM_Runnable.DmlWrapper dmlWrapper) {
        List<Contact> contactsWithAccountAndAddressFields =
                new ContactSelector().getContactsWithAccountAndAddressFields(
                        contacts.getRecords());
        Households.handleContactsAfterUpdate(
                new Contacts(contactsWithAccountAndAddressFields, contacts.oldMap.values()),
                dmlWrapper);
    }

    /**
     * @description Determines whether or not the contact needs a one to one account assigned.
     * @param  The contact record to verify.
     * @param  The existing account record assocatied with the contact.
     * @return Boolean - true when the contact needs a one to one account.
     */
    public static Boolean isMissingAccount(Contact contactRecord) {
        return contactRecord.npe01__Private__c != true
                && contactRecord.AccountId == null;
    }

    /**
     * @description Determines whether or not the contact needs a one to one account assigned.
     * @param  The contact record to verify.
     * @param  The existing account record assocatied with the contact.
     * @return Boolean - true when the contact needs a one to one account.
     */
    public static Boolean isOrganizationContact(Contact contactRecord, Account accountRecord) {
        return contactRecord.npe01__Private__c != true
                && (accountRecord != null
                && accountRecord.npe01__SYSTEM_AccountType__c == CAO_Constants.ONE_TO_ONE_ORGANIZATION_TYPE);
    }

    /*******************************************************************************************************
    * @description Updates Contacts to relate to a single Individual Account
    * @param contacts the list of Contacts that need updating.
    */
    public static void attachToBucketAccount(List<Contact> contactsWithoutBucketAccount){
        if (contactsWithoutBucketAccount.isEmpty()) {
            return;
        }

        Id individualAccountId = CAO_Constants.getIndividualAccountId();

        if (individualAccountId != null) {
            for (Contact contactRecord : contactsWithoutBucketAccount) {
                //connect all Contacts to the bucket Account
                contactRecord.AccountId = individualAccountId;
            }
        } else {
            //if there is no bucket Account, the bucket model won't function unless we create one
            Account individual = new Account();
            individual.Name = CAO_Constants.BUCKET_ACCOUNT_NAME;
            //flag the account as an individual account
            individual.npe01__SYSTEMIsIndividual__c = true;
            //individual.Type = CAO_Constants.BUCKET_ORGANIZATION_TYPE;
            individual.npe01__SYSTEM_AccountType__c = CAO_Constants.BUCKET_ORGANIZATION_TYPE;
            UTIL_DMLService.insertRecord(individual);

            for (Contact contactRecord : contactsWithoutBucketAccount) {
                //connect Contact to bucket Account
                contactRecord.AccountId = individual.Id;
            }
        }
    }

    private List<Contact> getContactsWithAccountAndAddressFields(Contacts contacts) {
        List<Contact> contactsWithAccountAndAddressFields =
                contactSelector.getContactsWithAccountAndAddressFields(contacts.getRecords());
        return contactsWithAccountAndAddressFields;
    }

    public void onAfterDeleteOf(Contacts contacts, TDTM_Runnable.DmlWrapper dmlWrapper) {
        HouseholdAccounts householdAccounts = getHouseholdsFor(contacts.accountIds());
        householdAccounts.handleContactDeletion(dmlWrapper);
    }

    private HouseholdAccounts getHouseholdsFor(Set<Id> ids) {
        return householdAccountRepository.findByIdWithOneContactAndGift(ids);
    }

    public void onAfterUndeleteOf(Contacts contacts, TDTM_Runnable.DmlWrapper dmlWrapper) {
        List<Contact> contactsWithAccountAndAddressFields =
                getContactsWithAccountAndAddressFields(contacts);

        Households.updatePrimaryContactOnAccountsAfterInsert(
                dmlWrapper, contactsWithAccountAndAddressFields);

        HouseholdAccounts.renameHouseholdAccountsAfterInsert(
                contactsWithAccountAndAddressFields);
    }
}