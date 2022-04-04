/*
    Copyright (c) 2021 Salesforce.org
    All rights reserved.

    Redistribution and use in source and binary forms, with or without
    modification, are permitted provided that the following conditions are met:

    * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution.
    * Neither the name of Salesforce.org nor the names of
      its contributors may be used to endorse or promote products derived
      from this software without specific prior written permission.

    THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
    "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
    LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
    FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE
    COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
    INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
    BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
    LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
    CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
    LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN
    ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
    POSSIBILITY OF SUCH DAMAGE.
*/
/**
* @author Salesforce.org
* @date 2021
* @description The ContactAdapter's role is to provide clients with a single Type
* that will handle DML on Contacts and call the appropriate method on Domains.
*/
public inherited sharing class ContactAdapter extends fflib_SObjects2 {

    public Map<Id, Contact> oldMap;

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
    private HouseholdSelector householdSelector {
        get {
            if (householdSelector == null) {
                householdSelector = new HouseholdSelector();
            }
            return householdSelector;
        }
        set;
    }

    @TestVisible
    private HouseholdService householdServiceInstance {
        get {
            if (householdServiceInstance == null) {
                householdServiceInstance = new HouseholdService();
            }
            return householdServiceInstance;
        }
        set;
    }

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

    public ContactAdapter(List<Contact> records) {
        this(records, null);
    }

    public ContactAdapter(List<Contact> records, List<Contact> oldList) {
        super(records, Contact.SObjectType);
        this.oldMap = oldList != null ?
                new Map<Id, Contact>(oldList) : new Map<Id, Contact>();
    }

    public void onBeforeInsert() {
        NamingExclusions namingExclusions = new NamingExclusions(getRecords());
        namingExclusions.synchronizeNamingExclusionsBeforeInsert();
    }

    public void onBeforeInsert(List<Contact> newSObjects) {
        AccountAdapter.enableHouseholdDeceasedUpdate(true);

        Contacts contacts = new Contacts(newSObjects);
        contacts.resetDeprecatedFields();
        contacts.resetSustainerFields();

        if (CAO_Constants.isHHAccountModel()) {
            householdServiceInstance.createOneToOneAndHouseholdAccountsFor(
                    contacts.publicContactsWithNonNullAccountIds());
        } else {
            if (CAO_Constants.isOneToOne()) {
                householdServiceInstance.createOneToOneAndHouseholdAccountsFor(
                        (List<Contact>) contacts.legacyHouseholdAndOrganizationContactsNeedingOneToOneAccounts()
                                .getRecords());
            }

            if (CAO_Constants.isBucketModel()) {
                LegacyHouseholds.attachToBucketAccount(
                        contacts.publicContactsWithNonNullAccountIds());
            }
        }

    }

    public void onAfterInsert() {
        createAddressesForContacts();
    }

    public void onAfterInsert(TDTM_Runnable.DmlWrapper dmlWrapper) {
        List<Contact> contactsWithAccountAndAddressFields =
                getContactsWithAccountAndAddressFields();

        LegacyHouseholds.updatePrimaryContactOnAccountsAfterInsert(
                dmlWrapper, contactsWithAccountAndAddressFields);

        Households.renameHouseholdAccountsAfterInsert(
                contactsWithAccountAndAddressFields);
    }

    public void onBeforeUpdate() {
        AccountAdapter.enableHouseholdDeceasedUpdate(true);

        handleContactsBeforeUpdate(
                new Contacts(getRecords(), oldMap.values()));
    }

    public void onBeforeUpdate_HH_Households_TDTM() {
        NamingExclusions namingExclusions = new NamingExclusions(getRecords(), oldMap);
        namingExclusions.synchronizeNamingExclusionsBeforeUpdate();
    }

    /**
     * @description ADDR_Contact_TDTM was refactored and its logic was moved down into this
     * class and supporting entity classes like NPSP_Contact and NPSP_Address.  However, there
     * is already a Trigger Handler (HH_Households_TDTM) running in the
     * before update context for Contacts, and that handler calls the onBeforeUpdate method.
     * Secondary Trigger Handlers running in
     * the same context will have to use specific trigger context entry point methods, like
     * this one (or call other public methods directly) until NPSP is able to merge down
     * Trigger Handlers so that there is only one per Trigger Context for each object.  At
     * that point the logic in this method will be moved into the onBeforeUpdate method and
     * this method will be removed.
     */
    public void onBeforeUpdate_FromAddrContactTDTM() {
        normalizeLineBreaksForContactsWithChangedAddresses();
        Map<Id, Boolean> isOverrideByAddressId = getIsOverrideByAddressId();
        isOverrideByAddressId.putAll(getIsOverrideByAddressIdFromAddressOverrideChanges());

        // set the mailing address for contacts who specify an address lookup or override
        List<Contact> consNeedingAddressFieldsPopulated = consWhoseAddressChanged();
        if (consNeedingAddressFieldsPopulated.size() > 0) {
            // to avoid pushing these address changes to the HH.
            setRecursionFlags();
            setContactAddressFromCurrentAddress(consNeedingAddressFieldsPopulated);
            deactivateAddrRecursionFlag();
        }

        // reset the mailing address for contacts who no longer have an address override
        List<Contact> addressRefreshQueue =
                consWhoseAccountChangedAndDontHaveAddressOverrides();
        addressRefreshQueue.addAll(consHavingAddressOverridesRemoved());
        if (addressRefreshQueue.size() > 0) {
            // to avoid pushing these address changes to the HH.
            setRecursionFlags();
            HouseholdMembers householdMembersForAddressRefresh =
                    new HouseholdMembers(addressRefreshQueue);
            householdMembersForAddressRefresh.resetAddressUsingHouseholdAddress();
            deactivateAddrRecursionFlag();
        }

        // create any new Default Address objects
        Set<Contact> addressCreationQueue = getAddressCreationQueueBeforeUpdate();
        createAddressFromContactAndSetCurrentAddressLookupId(new List<Contact>(addressCreationQueue));

        // update the Latest date fields on any address overrides
        Addresses.updateAddrIsOverride(isOverrideByAddressId);
    }

    public void onAfterUpdate() {
        createAddressesForContacts();
    }

    public void onAfterUpdate(TDTM_Runnable.DmlWrapper dmlWrapper) {
        List<Contact> contactsWithAccountAndAddressFields =
                new ContactSelector().getContactsWithAccountAndAddressFields(getRecords());
        LegacyHouseholds.handleContactsAfterUpdate(
                new Contacts(contactsWithAccountAndAddressFields, oldMap.values()),
                dmlWrapper);
    }

    public void onAfterDelete() {
        fireRollupsForMergedContacts();
        if (!contactsInHouseholds().isEmpty()) {
            LegacyHouseholdMembers legacyHouseholdMembers =
                    new LegacyHouseholdMembers(contactsInHouseholds().getRecords());
            legacyHouseholdMembers.onAfterDelete();
        }
    }

    public void onAfterDelete(TDTM_Runnable.DmlWrapper dmlWrapper) {
        AccountAdapter.enableHouseholdDeceasedUpdate(true);

        Households households = getHouseholdsFor(accountIds());
        households.handleContactDeletion(dmlWrapper);
    }

    public void onAfterUndelete(TDTM_Runnable.DmlWrapper dmlWrapper) {
        AccountAdapter.enableHouseholdDeceasedUpdate(true);

        List<Contact> contactsWithAccountAndAddressFields =
                getContactsWithAccountAndAddressFields();

        LegacyHouseholds.updatePrimaryContactOnAccountsAfterInsert(
                dmlWrapper, contactsWithAccountAndAddressFields);

        Households.renameHouseholdAccountsAfterInsert(
                contactsWithAccountAndAddressFields);
    }

    /**
     * @description In the before update trigger context, ensure accounts are created for the contacts that need them.
     */
    private void handleContactsBeforeUpdate(Contacts contacts) {
        contacts.resetDeprecatedFields();
        contacts.keepPrivateContactsPrivate();
        householdServiceInstance.createOneToOneAndHouseholdAccountsFor(
                contactsWithoutAccounts(contacts));

        if (contactAndOrgSettingsInst.isBucketAccountEnabled()) {
            LegacyHouseholds.attachToBucketAccount(
                    contacts.publicContactsWithNonNullAccountIds()
            );
        }

        if (RD2_SustainerEvaluationService.isSustainerUpdateEnabled == false) {
            contacts.resetSustainerFields();
        }
    }

    private List<Contact> getContactsWithAccountAndAddressFields() {
        List<Contact> contactsWithAccountAndAddressFields =
                contactSelector.getContactsWithAccountAndAddressFields(getRecords());
        return contactsWithAccountAndAddressFields;
    }

    public Contact oldVersionOf(Contact con) {
        return oldMap.get(con.Id);
    }

    public Boolean accountHasAddresses(Contact con) {
        return (accountsByIds().containsKey(con.AccountId)
                && accountsByIds().get(con.AccountId).Addresses__r.size() > 0);
    }

    public Set<Id> accountIds() {
        return getIdFieldValues(Contact.AccountId).getIds();
    }

    private Map<Id, Account> accountsById;
    public Map<Id, Account> accountsByIds() {
        if (accountsById == null) {
            accountsById = new Map<Id, Account>([
                    SELECT Id, npe01__SYSTEM_AccountType__c, (SELECT Id FROM Addresses__r)
                    FROM Account
                    WHERE Id IN :accountIds()
            ]);
        }
        return accountsById;
    }

    private Account accountFor(NPSP_Contact npspContact) {
        return accountsByIds().get(npspContact.accountId());
    }

    private Boolean isAnAccountOfTypeHousehold(Account a) {
        if (a == null) {
            return false;
        }
        return a.npe01__SYSTEM_AccountType__c == CAO_Constants.HH_ACCOUNT_TYPE;
    }

    private List<NPSP_Contact> npspContactsInHouseholdAccounts() {
        List<NPSP_Contact> contactsInHouseholdAccounts = new List<NPSP_Contact>();
        for (SObject so : getRecords()) {
            NPSP_Contact npspContact = new NPSP_Contact((Contact) so, oldVersionOf(
                    (Contact) so));
            if (isAnAccountOfTypeHousehold(accountFor(npspContact))) {
                contactsInHouseholdAccounts.add(npspContact);
            }
        }
        return contactsInHouseholdAccounts;
    }

    private Boolean isEligibleForRefresh(NPSP_Contact npspContact) {
        return !npspContact.hasAddressOverride() && !npspContact.isAddressChanged();
    }

    private Map<Id, Boolean> getIsOverrideByAddressIdFromAddressOverrideChanges() {
        Map<Id, Boolean> isOverrideByAddressId = new Map<Id, Boolean>();
        // we only support address management with HH Accounts being used
        for (NPSP_Contact npspContact : npspContactsInHouseholdAccounts()) {

            // new highest priority! if Account changes...
            if (!npspContact.accountChanged()) {
                // second priority.  if they are clearing isAddressOverride, and no address fields change, refill from the Default Address
                if (npspContact.isClearingAddressOverride() &&
                        npspContact.noAddressFieldsChanged()) {
                    // track which address's need their dates updated
                    isOverrideByAddressId.put(npspContact.oldVersion().currentAddress(), false);
                }

                // third priority.  if MailingAddress fields changed, update the existing address object or create a new one.
                // this is handled in the next block, since we do it for both new contacts and updated contacts.
            }
        }
        return isOverrideByAddressId;
    }

    private List<Contact> consHavingAddressOverridesRemoved() {
        List<Contact> addressRefreshQueue = new List<Contact>();
        // we only support address management with HH Accounts being used
        for (NPSP_Contact npspContact : npspContactsInHouseholdAccounts()) {

            // new highest priority! if Account changes...
            if (!npspContact.accountChanged()) {
                // second priority.  if they are clearing isAddressOverride, and no address fields change, refill from the Default Address
                if (npspContact.isClearingAddressOverride() &&
                        !npspContact.isAddressChanged()) {
                    addressRefreshQueue.add(npspContact.getRecord());
                }

                // third priority.  if MailingAddress fields changed, update the existing address object or create a new one.
                // this is handled in the next block, since we do it for both new contacts and updated contacts.
            }
        }
        return addressRefreshQueue;
    }

    private List<Contact> consWhoseAddressChanged() {
        List<Contact> useCurrentAddressQueue = new List<Contact>();
        // we only support address management with HH Accounts being used
        for (NPSP_Contact npspContact : npspContactsInHouseholdAccounts()) {

            // new highest priority! if Account changes...
            if (!npspContact.accountChanged()) {
                // highest priority. if they are changing to a new Current Address, refill from it.
                if (npspContact.isCurrentAddressChanged()) {
                    useCurrentAddressQueue.add(npspContact.getRecord());
                }
            }
        }
        return useCurrentAddressQueue;
    }

    private Map<Id, Boolean> getIsOverrideByAddressId() {
        Map<Id, Boolean> isOverrideByAddressId = new Map<Id, Boolean>();
        // we only support address management with HH Accounts being used
        for (NPSP_Contact npspContact : npspContactsInHouseholdAccounts()) {

            // new highest priority! if Account changes...
            if (!npspContact.accountChanged()) {
                // highest priority. if they are changing to a new Current Address, refill from it.
                if (npspContact.isChangingToANewCurrentAddress()) {
                    // track which address's need their dates updated
                    isOverrideByAddressId.put(npspContact.currentAddress(), true);
                }
            }
        }
        return isOverrideByAddressId;
    }

    private List<Contact> consWhoseAccountChangedAndDontHaveAddressOverrides() {
        List<Contact> addressRefreshQueue = new List<Contact>();
        // we only support address management with HH Accounts being used
        for (NPSP_Contact npspContact : npspContactsInHouseholdAccounts()) {

            // new highest priority! if Account changes...
            if (npspContact.accountChanged()) {
                // if no override, refill from the Default Address
                if (isEligibleForRefresh(npspContact)) {
                    if (accountHasAddresses(npspContact.getRecord())) { //
                        // refresh address if the contact does not have one and account does
                        addressRefreshQueue.add(npspContact.getRecord());
                    }
                }
            }
        }
        return addressRefreshQueue;
    }

    private Id householdIdFor(Contact con) {
        return con.npo02__Household__c;
    }

    private Contacts contactsInHouseholds() {
        List<Contact> consInHouseholds = new List<Contact>();
        for (Contact con : (List<Contact>) getRecords()) {
            if (householdIdFor(con) != null) {
                consInHouseholds.add(con);
            }
        }
        return new Contacts(consInHouseholds);
    }

    private Boolean shouldUseAccountAddress(NPSP_Contact npspContact) {
        return npspContact.isAddressEmpty() && accountHasAddresses(npspContact.getRecord());
    }

    private Boolean hasCurrentAddress(NPSP_Contact npspContact) {
        return npspContact.currentAddress() != null;
    }

    private void deactivateAddrRecursionFlag() {
        TDTM_ProcessControl.setRecursionFlag(TDTM_ProcessControl.flag.ADDR_hasRunTrigger, false);
    }

    private Contacts contactsNeedingHouseholdAddressApplied() {
        List<Contact> addressRefreshQueue = new List<Contact>();
        for (NPSP_Contact npspContact : npspContactsInHouseholdAccounts()) {
            if (shouldUseAccountAddress(npspContact)) {
                // if the contact has no address specified and the household has a default address, pick up the hh default.
                addressRefreshQueue.add(npspContact.getRecord());
            }
        }
        return new Contacts(addressRefreshQueue);
    }

    private Map<Id, Boolean> getIsOverrideByAddressIdBeforeInsert() {
        Map<Id, Boolean> isOverrideByAddressId = new Map<Id, Boolean>();
        for (NPSP_Contact npspContact : npspContactsInHouseholdAccounts()) {
            if (hasCurrentAddress(npspContact) && npspContact.hasAddressOverride()) {
                // track which address's need their dates updated
                isOverrideByAddressId.put(npspContact.currentAddress(), true);
            }
        }
        return isOverrideByAddressId;
    }

    private List<Contact> consThatHaveARelatedAddress() {
        List<Contact> useCurrentAddressQueue = new List<Contact>();
        for (NPSP_Contact npspContact : npspContactsInHouseholdAccounts()) {
            if (hasCurrentAddress(npspContact)) {
                // remember which contacts will need their address set
                useCurrentAddressQueue.add(npspContact.getRecord());
            }
        }
        return useCurrentAddressQueue;
    }

    @TestVisible
    private ContactService contactService {
        get {
            if (contactService == null) {
                contactService = new ContactService();
            }
            return contactService;
        }
        set;
    }

    public void normalizeLineBreaksForContactsWithChangedAddresses() {
        for (Integer i = 0; i < getRecords().size(); i++) {
            Contact newRecord = (Contact) getRecords()[i];

            if (new NPSP_Contact(newRecord, oldVersionOf(newRecord)).isAddressChanged()) {
                UTIL_Address.normalizeLineBreak(newRecord);
            }
        }
    }

    public void normalizeLineBreaks() {
        for (Integer i = 0; i < getRecords().size(); i++) {
            Contact newRecord = (Contact) getRecords()[i];
            UTIL_Address.normalizeLineBreak(newRecord);
        }
    }

    /**
     * @description ADDR_Contact_TDTM was refactored and its logic was moved down into this
     * class and supporting entity classes like NPSP_Contact and NPSP_Address.  However, there
     * is already a Trigger Handler (HH_Households_TDTM) running in the
     * before insert context for Contacts, and that handler calls the onBeforeInsert method.
     * Secondary Trigger Handlers running in
     * the same context will have to use specific trigger context entry point methods, like
     * this one (or call other public methods directly) until NPSP is able to merge down
     * Trigger Handlers so that there is only one per Trigger Context for each object.  At
     * that point the logic in this method will be moved into the onBeforeInsert method and
     * this method will be removed.
     */
    public void onBeforeInsert_FromAddrContactTDTM() {
        normalizeLineBreaks();

        List<Contact> consThatHaveARelatedAddress = consThatHaveARelatedAddress();
        if (consThatHaveARelatedAddress.size() > 0) {
            // to avoid pushing these address changes to the HH.
            setRecursionFlags();
            // set the mailing address for contacts who specify an address lookup or override
            setContactAddressFromCurrentAddress(consThatHaveARelatedAddress);
        }

        Contacts contactsNeedingHouseholdAddressApplied = contactsNeedingHouseholdAddressApplied();
        if (contactsNeedingHouseholdAddressApplied.getRecords().size() > 0) {
            // to avoid pushing these address changes to the HH.
            setRecursionFlags();
            // reset the mailing address for contacts who no longer have an address override
            HouseholdMembers householdMembers =
                    new HouseholdMembers(contactsNeedingHouseholdAddressApplied.getRecords());
            householdMembers.resetAddressUsingHouseholdAddress();
        }

        // create any new Default Address objects
        createAddressFromContactAndSetCurrentAddressLookupId(
                new List<Contact>(contactsWithAddressChanges()));

        // update the Latest date fields on any address overrides
        Addresses.updateAddrIsOverride(getIsOverrideByAddressIdBeforeInsert());

        if (consThatHaveARelatedAddress.size() > 0 ||
                contactsNeedingHouseholdAddressApplied.getRecords().size() > 0) {
            deactivateAddrRecursionFlag();
        }
    }

    /*******************************************************************************************************
    * @description for each contact, refresh its mailing address from its Address lookup
    * @param listCon the list of Contacts to update
    ********************************************************************************************************/
    public void setContactAddressFromCurrentAddress(List<Contact> listCon) {
        List<Contact> listConCreateAddr = new List<Contact>();
        Set<Id> setAddrId = new Set<Id>();
        for (Contact con : listCon) {
            if (con.Current_Address__c != null) {
                setAddrId.add(con.Current_Address__c);
            }
        }

        Map<Id, Address__c> currentAddressRecordsById = new Map<Id, Address__c>([SELECT Id, Address_Type__c,
                Household_Account__c, MailingStreet__c, MailingStreet2__c, MailingCity__c,
                MailingState__c, Geolocation__Latitude__s, Geolocation__Longitude__s,
                MailingPostalCode__c, MailingCountry__c
        FROM Address__c
        WHERE Id IN :setAddrId]
        );

        for (Contact con : listCon) {
            Address__c currentAddressRecord = currentAddressRecordsById.get(con.Current_Address__c);
            NPSP_Address currentAddressAsNpspAddress = new NPSP_Address(currentAddressRecord);
            NPSP_Contact npspContact = new NPSP_Contact(con);
            ContactAddress contactAddress = new ContactAddress(con);
            if (contactAddress.hasAddress() // Shoutout: K. Bromer
                    && npspContact.mailingAddressIsDifferentFrom(currentAddressAsNpspAddress)) {
                npspContact.mailingAddress(currentAddressAsNpspAddress);
                // deal with any address coming from a different account,
                // which we need to treat as a creation instead.
                if (currentAddressAsNpspAddress.householdId() != npspContact.accountId()) {
                    listConCreateAddr.add(npspContact.getRecord());
                }
            }
        }

        createAddressFromContactAndSetCurrentAddressLookupId(listConCreateAddr);
    }

    private void insertContactAddresses(Map<Contact, Address__c> contactAddressesToInsertByContact) {
        if (contactAddressesToInsertByContact.size() == 0) {
            return;
        }
        UTIL_DMLService.insertRecords(contactAddressesToInsertByContact.values());
        // Since we're inserting new Addresses in a Before Insert/Update scenario, set the flag to
        // prevent the After Insert/Update Contact logic from executing when it's eventually called.
        TDTM_ProcessControl.setRecursionFlag(TDTM_ProcessControl.flag.ADDR_hasRunContactOnBefore, true);

        for (Contact contact : contactAddressesToInsertByContact.keySet()) {
            Address__c contactAddress = contactAddressesToInsertByContact.get(contact);
            contact.Current_Address__c = contactAddress.Id;
        }
    }

    private void updateContactAddressFromExistingAddress(Contact contact, Address__c existingAddressFromContact) {
        contact.Current_Address__c = existingAddressFromContact.Id;
        contact.Undeliverable_Address__c = existingAddressFromContact.Undeliverable__c;

        //reset the Primary Address Type only; resetting other fields on Contact will create a new Address
        resetContactPrimaryAddressType(contact, existingAddressFromContact);
    }

    private void resetContactPrimaryAddressType(Contact contact, Address__c existingAddressFromContact) {
        contact.npe01__Primary_Address_Type__c = contact.npe01__Primary_Address_Type__c == null
                ? existingAddressFromContact.Address_Type__c
                : contact.npe01__Primary_Address_Type__c;
    }

    private Boolean contactAddressHasAddressMatch(Address__c existingAddressFromContact) {
        return existingAddressFromContact != null;
    }

    private Map<Contact, Address__c> getContactAddressesByContact(List<Contact> contacts) {
        Map<Contact, Address__c> addressesByContact = new Map<Contact, Address__c>();
        for (Contact contact : contacts) {
            NPSP_Address npspAddressFromContact = new NPSP_Address(contact);
            addressesByContact.put(contact, npspAddressFromContact.getRecord());
        }
        return addressesByContact;
    }

    /*******************************************************************************************************
    * @description Creates a new address or matches an existing one, for each Contact.
    * This routine is called both by BeforeInsert/Update and AfterInsert/Update.
    * when pushing a new default address, we need to do it in the AfterInsert/Update.
    * otherwise we want to do it in the BeforeInsert/Update so we can update the contacts' info now.
    * @param contacts the list of Contacts
    ********************************************************************************************************/
    public void createAddressFromContactAndSetCurrentAddressLookupId(List<Contact> contacts) {
        if (contacts.isEmpty()) {
            return;
        }
        // Strategy:
        // create a new (unsaved) address for each contact.
        // see if there is an existing address that matches each new address.
        //
        // for existing addresses we match
        //     process during BeforeInsert/Update
        //     update appropriate fields on contact
        //
        // for new addresses that won't be a default (ie, the contact has override set)
        //     process during BeforeInsert/Update
        //     create the address now
        //     update appropriate fields on contact
        //
        // for new addresses that will be a default address
        //     process during AfterInsert/Update
        //     mark the new address as default
        //     put it on dmlWrapper
        //

        Map<Contact, Address__c> contactAddressesByContact = getContactAddressesByContact(contacts);

        // look for duplicates for our proposed new addresses
        Map<Address__c, Address__c> existingAddressesByAddress =
                Addresses.getExistingAddresses(contactAddressesByContact.values());

        // maps & lists to keep track of the addresses we must insert or update
        Map<Contact, Address__c> contactAddressesToInsertByContact = new Map<Contact, Address__c>();

        for (Contact contact : contacts) {
            Address__c newAddressFromContact = contactAddressesByContact.get(contact);
            Address__c existingAddressFromContact = existingAddressesByAddress.get(newAddressFromContact);

            // if found a match
            if (contactAddressHasAddressMatch(existingAddressFromContact)) {
                updateContactAddressFromExistingAddress(contact, existingAddressFromContact);

                // Prevent an address that was just inserted by the BeforeInsert trigger from being udpated
                // a second time by the AfterInsert trigger.
            }

            // no match found, and its an override just for this contact
            else if (contact.is_Address_Override__c) {
                // put it on the list of addresss to create now
                contactAddressesToInsertByContact.put(contact, newAddressFromContact);
            }
        }

        insertContactAddresses(contactAddressesToInsertByContact);
    }

    private Set<Contact> getAddressCreationQueueBeforeUpdate() {
        if (isRecursive()) {
            UTIL_Debug.debug('**** RECURSION: Stop Addr Trigger recursion in ADDR_Contact_TDTM');
            return new Set<Contact>();
        } else {
            return consWithAddressChanges();
        }
    }

    private void setRecursionFlags() {
        TDTM_ProcessControl.setRecursionFlag(TDTM_ProcessControl.flag.ADDR_hasRunTrigger, true);
        // set this flag to true to prevent the AfterUpdate trigger on the Contact from processing changes
        // to the Contact's address that are being made by this BeforeUpdate trigger.
        TDTM_ProcessControl.setRecursionFlag(TDTM_ProcessControl.flag.ADDR_hasRunContactOnBefore, true);
    }

    private Set<Contact> contactsWithAddressChanges() {
        Set<Contact> addressCreationQueue = new Set<Contact>();
        if (isRecursive()) {
            UTIL_Debug.debug('**** RECURSION: Stop Addr Trigger recursion in ADDR_Contact_TDTM');
            addressCreationQueue = new Set<Contact>();
        } else {
            addressCreationQueue = consWithAddressChanges();
        }
        return addressCreationQueue;
    }

    private Boolean isLosingRecordInMergeOperation(Contact con) {
        return con.MasterRecordId != null;
    }

    private void fireRollupsForMergedContacts() {
        Set<Id> mergedWinningContact = getMergedWinningContactIds();
        if (mergedWinningContact.size() > 0) {
            // this fires off opp rollups, which we aren't going to move to dmlWrapper!
            rollupContactsAndHouseholdsAfterMerge(mergedWinningContact);
        }
    }

    private Set<Id> getMergedWinningContactIds() {
        Set<Id> mergedWinningContactIds = new Set<Id>();
        for (Contact con : (List<Contact>) getRecords()) {
            if (isLosingRecordInMergeOperation(con)) {
                mergedWinningContactIds.add(con.MasterRecordId);
            }
        }
        return mergedWinningContactIds;
    }

    /*******************************************************************************************************
     * @description kicks off Opportunity Rollups after contacts have been merged, but only if NOT using
     * the Household Account model
     * @param winningContacts Set of Contact Id's
     ********************************************************************************************************/
    @TestVisible
    private static void rollupContactsAndHouseholdsAfterMerge(Set<Id> winningContacts) {
        if (contactAndOrgSettingsInst.isHouseholdAccountModelEnabled()) {
            return;
        }

        Set<Id> oppIds = getOppIdsForWinningContacts(winningContacts);
        if (!oppIds.isEmpty()) {
            if (System.isFuture() || System.isBatch()) {
                RLLP_OppRollup.rollupContactsandHouseholdsForTrigger(oppIds);
            } else {
                RLLP_OppRollup.rollupContactsandHouseholdsForTriggerFuture(oppIds);
            }
        }
    }

    private void createAddressesForContacts() {
        Set<Contact> addressCreationQueue = getAddressCreationQueue();

        // create any new Default Address objects
        if (addressCreationQueue.size() > 0) {
            HouseholdMembers householdMembers =
                    new HouseholdMembers(new List<Contact>(addressCreationQueue), oldMap);
            householdMembers.createAndUpdateHouseholdAddresses();
        }
        TDTM_ProcessControl.setRecursionFlag(TDTM_ProcessControl.flag.ADDR_hasRunContactOnBefore, false);
    }

    private static Set<Id> getOppIdsForWinningContacts(Set<Id> winningContacts) {
        Set<Id> oppIds = new Set<Id>();
        for (OpportunityContactRole ocr : [
                SELECT OpportunityId
                FROM OpportunityContactRole
                WHERE ContactId IN :winningContacts AND IsPrimary = TRUE
        ]
        ) {
            oppIds.add(ocr.OpportunityId);
        }
        return oppIds;
    }

    private Set<Contact> getAddressCreationQueue() {
        Set<Contact> addressCreationQueue = new Set<Contact>();

        if (isRecursive() || isRecursiveFromContact()) {
            if (isRecursive()) {
                UTIL_Debug.debug('**** RECURSION: Stop Addr Trigger recursion in ADDR_Contact_TDTM');
            }
            // If the Before Insert/Update trigger on the Contact has already executed and taken action
            // and this is an After Insert/Update trigger, simply reset the flag and exit out.
            if (isRecursiveFromContact()) {
                UTIL_Debug.debug('**** RECURSION: Stop BeforeContact Trigger recursion in ADDR_Contact_TDTM');
            }
            addressCreationQueue = new Set<Contact>();
        } else {
            addressCreationQueue = getAddressCreationQueueInAfterContext();
        }
        return addressCreationQueue;
    }

    private Boolean isRecursiveFromContact() {
        return TDTM_ProcessControl.isRecursive(TDTM_ProcessControl.flag.ADDR_hasRunContactOnBefore);
    }

    private Boolean isRecursive() {
        return TDTM_ProcessControl.isRecursive(TDTM_ProcessControl.flag.ADDR_hasRunTrigger);
    }

    private Set<Contact> consWithAddressChanges() {
        Set<Contact> consWithAddressChanges = getConsWithAddressChanges();
        Set<Contact> consMovingToANewHousehold = getConsMovingToANewHousehold();
        consWithAddressChanges.addAll(consMovingToANewHousehold);
        return consWithAddressChanges;
    }

    private Set<Contact> getConsWithAddressChanges() {
        Set<Contact> consWithAddressChanges = new Set<Contact>();
        // we only support address management with HH Accounts being used
        for (NPSP_Contact npspContact : npspContactsInAccounts()) {

            Account a = accountsByIds().get(npspContact.accountId());
            if (a.npe01__SYSTEM_AccountType__c != CAO_Constants.HH_ACCOUNT_TYPE) {
                continue;
            }
            // BEFORE UPDATE & AFTER UPDATE & BEFORE INSERT && AFTER INSERT
            // our functionality for dealing with contact address changes requires some trickery!
            // if the contact doesn't have an address override, we create (or match) a default address,
            // which requires us to do the work in the AfterUpdate (or else we can't propagate the default address).
            // but if the contact has an address override, we are supposed to create (or match) a non default address override.
            // in order to update the contact with the new address override's Id, we have to do it in the BeforeUpdate.
            // note that we detect whether the address change is coming from the address trigger,
            // in which case we don't want to create a new address.

            // if the contacts address changed or if the contact with an address moves to a new household remember the contact
            // if the Current_Address__c field is changing, the after update context will
            // handle syncing the address fields
            Boolean currentAddressChanged = false;
            if (npspContact.oldVersion() != null && npspContact.oldVersion().getRecord() != null) {
                Id oldCurrentAddress = npspContact.oldVersion().getRecord().Current_Address__c;
                Id currentAddress = npspContact.getRecord().Current_Address__c;
                if (currentAddress != oldCurrentAddress) {
                    currentAddressChanged = true;
                }
            }
            if (!currentAddressChanged && npspContact.isAddressChanged()) {
                consWithAddressChanges.add(npspContact.getRecord());
            }
        }
        return consWithAddressChanges;
    }

    private Set<Contact> getAddressCreationQueueInAfterContext() {
        Set<Contact> addressCreationQueue = new Set<Contact>();
        for (NPSP_Contact npspContact : npspContactsInAccounts()) {

            if (npspContact.householdAndAccountDiffer()) {
                continue;
            }

            if (npspContact.isAddressChanged() ||
                    npspContact.isMovingToANewHousehold() ||
                    (npspContact.isUndeliverableStatusChanged())) {

                addressCreationQueue.add(npspContact.getRecord());
            }
        }
        return addressCreationQueue;
    }

    private Set<Contact> getConsMovingToANewHousehold() {
        Set<Contact> consMovingToANewHousehold = new Set<Contact>();
        for (NPSP_Contact npspContact : npspContactsInAccounts()) {

            Account a = accountsByIds().get(npspContact.accountId());
            if (a.npe01__SYSTEM_AccountType__c != CAO_Constants.HH_ACCOUNT_TYPE) {
                continue;
            }
            // BEFORE UPDATE & AFTER UPDATE & BEFORE INSERT && AFTER INSERT
            // our functionality for dealing with contact address changes requires some trickery!
            // if the contact doesn't have an address override, we create (or match) a default address,
            // which requires us to do the work in the AfterUpdate (or else we can't propagate the default address).
            // but if the contact has an address override, we are supposed to create (or match) a non default address override.
            // in order to update the contact with the new address override's Id, we have to do it in the BeforeUpdate.
            // note that we detect whether the address change is coming from the address trigger,
            // in which case we don't want to create a new address.

            // if the contacts address changed or if the contact with an address moves to a new household remember the contact
            if (npspContact.isMovingToANewHousehold()) {
                consMovingToANewHousehold.add(npspContact.getRecord());
            }
        }
        return consMovingToANewHousehold;
    }

    private List<NPSP_Contact> npspContactsInAccounts;
    public List<NPSP_Contact> npspContactsInAccounts() {
        if (npspContactsInAccounts == null) {
            npspContactsInAccounts = new List<NPSP_Contact>();
            for (Contact con : (List<Contact>) getRecords()) {
                NPSP_Contact npspContact = new NPSP_Contact(con, oldVersionOf(con));
                if (!npspContact.hasAccount()) {
                    continue;
                }
                npspContactsInAccounts.add(npspContact);
            }
        }
        return npspContactsInAccounts;
    }

    private static List<Contact> contactsWithoutAccounts(Contacts contacts) {
        List<Contact> contactsWithoutAccounts = new List<Contact>();

        if (contactAndOrgSettingsInst.isHouseholdAccountModelEnabled()) {
            contactsWithoutAccounts.addAll(contacts.publicContactsWithNonNullAccountIds());
        }

        if (contactAndOrgSettingsInst.isOneToOneAccountsEnabled()) {
            contactsWithoutAccounts.addAll(
                    contactsWithoutAccountsAndOrganizationContacts(contacts));
        }
        return contactsWithoutAccounts;
    }

    private static List<Contact> contactsWithoutAccountsAndOrganizationContacts(Contacts contactsInstance) {
        List<Contact> contactsWithoutAccounts = new List<Contact>();
        Map<Id, Account> oldAccounts = new Map<Id, Account>([
                SELECT Id
                FROM Account
                WHERE Id = :contactsInstance.oldAccountIds()
        ]);

        for (Contact contactRecord : (List<Contact>) contactsInstance.getRecords()) {
            if (contactRecord.npe01__Private__c) {
                continue;
            }

            Account account = contactsInstance.accountById.get(contactRecord.AccountId);
            if (isWithoutAccount(contactRecord)
                    || isOrganizationAccount(account)) {

                Contact oldContact = contactsInstance.oldMap.get(contactRecord.Id);

                if (shouldClearExistingOneToOneAccount(contactRecord, oldContact, account, oldAccounts)) {
                    contactRecord.AccountId = null;
                }

                if (contactRecord.AccountId == null) {
                    contactsWithoutAccounts.add(contactRecord);
                }

            }
        }
        return contactsWithoutAccounts;
    }

    public static Boolean isWithoutAccount(Contact contactRecord) {
        return contactRecord.AccountId == null;
    }

    public static Boolean isOrganizationAccount(Account accountRecord) {
        return accountRecord != null
                && accountRecord.npe01__SYSTEM_AccountType__c == CAO_Constants.ONE_TO_ONE_ORGANIZATION_TYPE;
    }

    /**
     * @description - Determine whether the account belongs to another contact and is not
     * an deleted during an account merge.
     */
    private static Boolean shouldClearExistingOneToOneAccount(Contact contactRecord,
            Contact oldContact, Account accountRecord, Map<Id, Account> oldAccountsByIds) {
        Boolean isExistingOneToOne = contactRecord.AccountId != null
                && accountRecord.npe01__One2OneContact__c != contactRecord.Id
                && accountRecord.npe01__One2OneContact__c != null
                && contactRecord.AccountId != oldContact.AccountId;

        if (!isExistingOneToOne) {
            return false;
        }

        Boolean isDeletedOldAccount = oldAccountsByIds.get(oldContact.AccountId) == null;

        return !isDeletedOldAccount;

    }

    private Households getHouseholdsFor(Set<Id> ids) {
        return new Households(householdSelector.findByIds(ids));
    }

}