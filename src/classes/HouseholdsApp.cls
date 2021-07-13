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

    public void handleContactsBeforeInsert(Contacts contacts) {
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

    /**
     * @description In the before update trigger context, ensure accounts are created for the contacts that need them.
     */
    public void handleContactsBeforeUpdate(Contacts contacts) {
        contacts.resetDeprecatedFields();
        contacts.keepPrivateContactsPrivate();
        HouseholdAccounts.createOneToOneAndHouseholdAccountsFor(
                contactsWithoutAccounts(contacts));

        if (contactAndOrgSettingsInst.isBucketAccountEnabled()) {
            attachToBucketAccount(
                    contacts.contactsWithoutAccounts()
            );
        }
    }

    private List<Contact> contactsWithoutAccounts(
            Contacts contacts) {
        List<Contact> contactsWithoutAccounts = new List<Contact>();

        if (contactAndOrgSettingsInst.isHouseholdAccountModelEnabled()) {
            contactsWithoutAccounts.addAll(contacts.contactsWithoutAccounts());
        }

        if (contactAndOrgSettingsInst.isOneToOneAccountsEnabled()) {
            contactsWithoutAccounts.addAll(
                    contactsWithoutAccounts(
                            contacts, contacts.oldMap));
        }
        return contactsWithoutAccounts;
    }

    public static List<Contact> contactsWithoutAccounts(Contacts contactsInstance, Map<Id, Contact> oldContactById) {
        List<Contact> contactsWithoutAccounts2 = new List<Contact>();
        Map<Id, Account> accountsByIds = contactsInstance.accountById;
        for (Contact contactRecord : (List<Contact>) contactsInstance.getRecords()) {
            Account account = accountsByIds.get(contactRecord.AccountId);
            if (isMissingAccount(contactRecord)) {
                Contact oldContact = oldContactById.get(contactRecord.Id);

                if (shouldClearExistingOneToOneAccount(contactRecord, oldContact,
                        account)) {
                    contactRecord.AccountId = null;
                }

                if (contactRecord.AccountId == null) {
                    contactsWithoutAccounts2.add(contactRecord);
                }

            }
        }
        return contactsWithoutAccounts2;
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

    /**
     * @description - Determine whether the account belongs to another contact and is not an deleted during an account merge.
     */
    private static Boolean shouldClearExistingOneToOneAccount(Contact contactRecord, Contact
            oldContact, Account accountRecord) {
        Boolean isExistingOneToOne = contactRecord.AccountId != null
                && accountRecord.npe01__One2OneContact__c != contactRecord.Id
                && accountRecord.npe01__One2OneContact__c != null
                && contactRecord.AccountId != oldContact.AccountId;

        if (!isExistingOneToOne) {
            return false;
        }

        Boolean isDeletedOldAccount = [SELECT COUNT() FROM Account WHERE Id =: oldContact.AccountId] == 0;

        return !isDeletedOldAccount;

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
}