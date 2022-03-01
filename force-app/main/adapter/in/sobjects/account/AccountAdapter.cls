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
* @description The AccountsAdapter's role is to provide clients with a single Type
* that will handle DML on Accounts and call the appropriate method on Domains. Since many
* domain objects are persisted on the Accounts standard object, (Households,
* HouseholdAddresses, Organizations, OrganizationAddresses, etc.) the Adapter requests
* domain instances for each of them.
*/
public inherited sharing class AccountAdapter extends fflib_SObjects2 {

    public Map<Id, Account> oldMap = new Map<Id, Account>();

    @TestVisible
    private HouseholdNamingService householdNamingService {
        get {
            if (householdNamingService == null) {
                householdNamingService = new HouseholdNamingService();
            }
            return householdNamingService;
        }
        set;
    }

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

    @TestVisible
    private OrgConfig orgConfig {
        get {
            if (orgConfig == null) {
                orgConfig = new OrgConfig();
            }
            return orgConfig;
        }
        set;
    }

    public AccountAdapter(List<Account> records) {
        this(records, null);
    }

    public AccountAdapter(List<Account> records, List<Account> oldlist) {
        super(records, Account.SObjectType);
        this.oldMap = oldlist == null ? new Map<Id, Account>() : new Map<Id, Account>
                (oldlist);
    }

    public void onBeforeInsert() {
        setAccountTypeAndIndividualFieldValues();
        if (AddressService.isAddressManagementEnabled()) {
            normalizeLineBreaksFor(householdAccounts());
        }
        if (AddressService.isOrgAccountAddressesEnabled()) {
            normalizeLineBreaksFor(orgAccounts());
        }

        resetSustainerFields();
    }

    public void onBeforeUpdate_ACCT_Accounts_TDTM() {
        setAccountTypeAndIndividualFieldValues();
        setSystemAccountTypeAndIndividualFieldValues();
        if (shouldSetCustomNamingFieldAndReplaceGreetings()) {
            setCustomNamingField();
            setNameAndGreetingsToReplacementText();
        }

        if (!RD2_SustainerEvaluationService.isSustainerUpdateEnabled) {
            resetSustainerFields();
        }

        if (!isAllMembersDeceasedUpdateEnabled) {
            revertHouseholdDeceasedUpdate();
        }
    }

    public static Boolean isAllMembersDeceasedUpdateEnabled = false;
    public static void enableHouseholdDeceasedUpdate(Boolean enabled) {
        isAllMembersDeceasedUpdateEnabled = enabled;
    }

    private void revertHouseholdDeceasedUpdate() {
        List<Account> householdAccounts = householdAccounts();
        for (Integer i = 0; i < householdAccounts.size(); i++) {
            Account acc = householdAccounts[i];
            acc.All_Members_Deceased__c = oldVersionOf(acc).All_Members_Deceased__c;
        }
    }

    public void onBeforeUpdate_ADDR_Account_TDTM() {
        if (AddressService.isAddressManagementEnabled()) {
            normalizeLineBreaksFor(
                    withAddressChanges().householdAccounts()
            );
        }
        if (AddressService.isOrgAccountAddressesEnabled()) {
            normalizeLineBreaksFor(
                    withAddressChanges().orgAccounts()
            );
        }
    }

    public void onAfterUpdate(TDTM_Runnable.DmlWrapper dmlWrapper) {
        if (settings.isAdvancedHouseholdNaming()) {
            renameHouseholdsNeedingNameUpdate();
        }

        // note that we detect whether the change is coming from the address trigger,
        // in which case we don't want to create a new address.
        if (TDTM_ProcessControl.isRecursive(
                TDTM_ProcessControl.flag.ADDR_hasRunTrigger)) {
            UTIL_Debug.debug('**** RECURSION: ' +
                    'Stop Addr Trigger recursion in ADDR_Account_TDTM');
            return;
        }

        AccountAdapter updatedAccountsWithAddressesToCreateOrUpdate =
                updatedAccountsWithAddressesToCreateOrUpdate();

        if (updatedAccountsWithAddressesToCreateOrUpdate.getRecords().size() > 0) {
            createAddressesFor(
                    updatedAccountsWithAddressesToCreateOrUpdate,
                    dmlWrapper,
                    false);
        }
    }

    private void resetSustainerFields() {
        for (Account acc : (List<Account>) getRecords()) {
            acc.Sustainer__c = oldVersionOf(acc)?.Sustainer__c;
        }
    }

    /*******************************************************************************************************
    * @description For the list of Addresses, sees if there is already an existing Address in the Account that
    * matches. Creates only unique addresses from their respective household, and mark any existing matches
    * as Default if the caller specifies it on the new address.
    * @param addresses a list of Addresses to update
    * @param dmlWrapper the Addresses to update
    * @param includeAddressType whether to include comparing the AddressType field
    */
    private static void createAddressesFor(AccountAdapter accounts,
            TDTM_Runnable.DmlWrapper dmlWrapper, Boolean includeAddressType) {

        Map<Address__c, Address__c> existingAddressesByAddress = Addresses.getExistingAddresses(
                accounts.allAddresses());
        Map<Id, Account> accountsById = getAccountsById(accounts);

        for (Address__c newAddress : accounts.allAddresses()) {
            NPSP_Address npspNewAddress = new NPSP_Address(newAddress);
            Address__c existingAddress = existingAddressesByAddress.get(newAddress);
            NPSP_Address npspExistingAddress = new NPSP_Address(existingAddress);
            Boolean isAddressUpdated = false;

            if (existingAddress != null) {
                NPSP_HouseholdAccount npspExistingAddressHousehold = new NPSP_HouseholdAccount(
                        accountsById.get(npspExistingAddress.householdId()),
                        accounts.oldMap.get(npspExistingAddress.householdId())
                );
                // if it is a fuzzy match, not exact, then we want to update the existing address.
                if (!npspNewAddress.isEqualToIncludingAddressType(npspExistingAddress, includeAddressType)) {
                    npspExistingAddress.copyFrom(npspNewAddress);
                    if (npspNewAddress.isDefault()) {
                        npspExistingAddress.setAsDefault();
                    }
                    isAddressUpdated = true;
                } else if (npspNewAddress.isDefault() && !npspExistingAddress.isDefault()) {
                    npspExistingAddress.setAsDefault();
                    isAddressUpdated = true;
                } else if (npspExistingAddressHousehold.isUndeliverableStatusChanged()) {
                    npspExistingAddress.setUndeliverable(npspExistingAddressHousehold.undeliverableAddressStatus());
                    isAddressUpdated = true;
                }
                if (isAddressUpdated) {
                    dmlWrapper.objectsToUpdate.add(existingAddress);
                }
            } else {
                NPSP_HouseholdAccount npspHouseholdAccount = new NPSP_HouseholdAccount(
                        accountsById.get(npspNewAddress.householdId()),
                        accounts.oldMap.get(npspNewAddress.householdId())
                );
                if (npspHouseholdAccount.isUndeliverableStatusChanged()) {
                    npspNewAddress.setUndeliverable(npspHouseholdAccount.undeliverableAddressStatus());
                }
                dmlWrapper.objectsToInsert.add(npspNewAddress.getRecord());
            }
        }
    }

    private static Map<Id, Account> getAccountsById(AccountAdapter accounts) {
        Map<Id, Account> accountsById = new Map<Id, Account>();
        for (Account account : (List<Account>) accounts.getRecords()) {
            accountsById.put(account.Id, account);
        }

        return accountsById;
    }

    public void setAccountTypeAndIndividualFieldValues() {
        for (Account acc : (List<Account>) getRecords()) {
            if (needsTypeAndIndividualFieldsSet(acc)) {
                setTypeAndIndividualFields(acc);
            }
        }
    }

    public void setSystemAccountTypeAndIndividualFieldValues() {
        for (Account acc : (List<Account>) getRecords()) {
            if (shouldResetAccountTypeAndIndividualFields(acc)) {
                resetAccountTypeAndIndividualFields(acc);
            }
        }
    }

    public AccountAdapter withAddressChanges() {
        List<Account> accountsWithAddressChanges = new List<Account>();

        for (Integer i = 0; i < getRecords().size(); i++) {
            Account account = (Account) getRecords()[i];
            Account oldAccount = (oldMap.values() != null ? (Account) oldMap.values()[i] : null);
            NPSP_HouseholdAccount npspHousehold = new NPSP_HouseholdAccount(account, oldAccount);

            if (npspHousehold.isBillingAddressChanged() || npspHousehold.isUndeliverableStatusChanged()) {
                accountsWithAddressChanges.add(account);
            }
        }

        return new AccountAdapter(accountsWithAddressChanges, oldMap.values());
    }

    private void normalizeLineBreaksFor(List<SObject> listNew) {
        for (Integer i = 0; i < listNew.size(); i++) {
            Account newRecord = (Account) listNew[i];
            UTIL_Address.normalizeLineBreak(newRecord);
        }
    }

    private void setNameAndGreetingsToReplacementText() {
        householdNamingService.setNameAndGreetingsToReplacementText(householdAccounts());
    }

    private Boolean shouldSetCustomNamingFieldAndReplaceGreetings() {
        return !isHouseholdTriggerContext() && settings.isAdvancedHouseholdNaming();
    }

    private void setCustomNamingField() {
        householdNamingService.setCustomNamingField(householdAccounts(), oldMap);
    }

    private void renameHouseholdsNeedingNameUpdate() {
        Households.updateNameAndMemberCount(getHouseholdsNeedingNameUpdate());
    }

    private List<Id> getHouseholdsNeedingNameUpdate() {
        return householdNamingService.getHouseholdsNeedingNameUpdates(
                householdAccounts(), oldMap
        );
    }

    private void resetAccountTypeAndIndividualFields(Account acc) {
        acc.npe01__SYSTEMIsIndividual__c = false;
        acc.npe01__SYSTEM_AccountType__c = null;
    }

    private Boolean shouldResetAccountTypeAndIndividualFields(Account acc) {
        return isRecordTypeIdChanged(acc)
                && !isHouseholdAccount(acc)
                && !isOneToOneAccount(acc)
                && !isBucketAccount(acc);
    }

    public AccountAdapter updatedAccountsWithAddressesToCreateOrUpdate() {
        List<Account> updatedAccountsWithAddressesToCreate = new List<Account>();

        if (AddressService.isAddressManagementEnabled()) {
            updatedAccountsWithAddressesToCreate.addAll(withAddressChanges().householdAccounts());
        }

        if (AddressService.isOrgAccountAddressesEnabled()) {
            updatedAccountsWithAddressesToCreate.addAll(withAddressChanges().orgAccounts());
        }

        return new AccountAdapter(updatedAccountsWithAddressesToCreate, oldMap.values());
    }

    public AccountAdapter newAccountsWithAddressesToCreate() {
        List<Account> addressesToCreate = new List<Account>();

        if (AddressService.isAddressManagementEnabled()) {
            addressesToCreate.addAll(withAddresses().householdAccounts());
        }
        if (AddressService.isOrgAccountAddressesEnabled()) {
            addressesToCreate.addAll(withAddresses().orgAccounts());
        }

        return new AccountAdapter(addressesToCreate);
    }

    public List<Address__c> allAddresses() {
        List<Address__c> accountAddresses = new List<Address__c>();
        for (Account account : (List<Account>)getRecords()) {
            NPSP_HouseholdAccount npspHouseholdAccount = new NPSP_HouseholdAccount(account);
            NPSP_Address npspAddress = new NPSP_Address(npspHouseholdAccount);

            accountAddresses.add(npspAddress.getRecord());
        }
        return accountAddresses;
    }

    private Boolean isRecordTypeIdChanged(Account acc) {
        return acc.RecordTypeId != oldVersionOf(acc).RecordTypeId;
    }

    private void setTypeAndIndividualFields(Account acc) {
        if (isHouseholdAccount(acc)) {
            setTypeAndIndividualFieldsForHouseholdAccount(acc);
        } else if (isOneToOneAccount(acc)) {
            setTypeAndIndividualFieldsForOneToOneAccount(acc);
        }
    }

    private void setTypeAndIndividualFieldsForOneToOneAccount(Account acc) {
        acc.npe01__SYSTEM_AccountType__c = CAO_Constants.ONE_TO_ONE_ORGANIZATION_TYPE;
        acc.npe01__SYSTEMIsIndividual__c = true;
    }

    private void setTypeAndIndividualFieldsForHouseholdAccount(Account acc) {
        acc.npe01__SYSTEM_AccountType__c = CAO_Constants.HH_ACCOUNT_TYPE;
        acc.Type = CAO_Constants.HH_TYPE;
        acc.npe01__SYSTEMIsIndividual__c = true;
    }

    private Boolean needsTypeAndIndividualFieldsSet(Account acc) {
        return isMissingAccountType(acc) || isNotIndividualAccount(acc);
    }

    private Boolean isNotIndividualAccount(Account acc) {
        return acc.npe01__SYSTEMIsIndividual__c != true;
    }

    private Boolean isMissingAccountType(Account acc) {
        return acc.npe01__SYSTEM_AccountType__c == null;
    }

    public List<Account> householdAccounts() {
        return getRecordsByFieldValue(
                Account.npe01__SYSTEM_AccountType__c,
                CAO_Constants.HH_ACCOUNT_TYPE);
    }

    private Account oldVersionOf(Account acc) {
        return oldMap.get(acc.Id);
    }

    private Boolean isOneToOneAccount(Account acc) {
        return acc.RecordTypeId == ContactAndOrgSettings.rtIdForAccountModel(false)
                && acc.RecordTypeId != null;
    }

    private Boolean isHouseholdAccount(Account acc) {
        return acc.RecordTypeId == ContactAndOrgSettings.rtIdForAccountModel(true)
                && acc.RecordTypeId != null;
    }

    private Boolean isBucketAccount(Account acc) {
        return (CAO_Constants.isBucketModel() && acc.Name == CAO_Constants.BUCKET_ACCOUNT_NAME);
    }

    private Boolean isHouseholdTriggerContext() {
        return TDTM_ProcessControl.isRecursive(TDTM_ProcessControl.flag.HH);
    }

    public List<Account> orgAccounts() {
        List<Account> orgAccounts = new List<Account>();
        for (Integer i = 0; i < getRecords().size(); i++) {
            Account newRecord = (Account) getRecords()[i];
            if (!isIndividualAccount(newRecord)) {
                orgAccounts.add(newRecord);
            }
        }
        return orgAccounts;
    }

    /*******************************************************************************************************
    * @description utility to see if an address management is enabled
    * @param newRecord an Account
    * @return Boolean.  true if address management is enabled
    ********************************************************************************************************/
    private Boolean isIndividualAccount(Account newRecord) {
        if (newRecord.npe01__SYSTEMIsIndividual__c) {
            return true;
        }
        return false;
    }

    public AccountAdapter withAddresses() {
        List<Account> withAddresses = new List<Account>();
        for (Integer i = 0; i < getRecords().size(); i++) {
            Account newRecord = (Account) getRecords()[i];
            if (isAccountAddressSpecified(newRecord)) {
                withAddresses.add(newRecord);
            }
        }
        return new AccountAdapter(withAddresses);
    }

    /*******************************************************************************************************
    * @description utility to see if an address is specified
    * @param acc1 an Account
    * @return boolean.  true if an address is specified in any of the Account Billing fields
    ********************************************************************************************************/
    private Boolean isAccountAddressSpecified(Account acc1) {
        if (acc1 == null) {
            return false;
        }

        Boolean isSpecified =
                acc1.BillingStreet != null ||
                        acc1.BillingCity != null ||
                        acc1.BillingState != null ||
                        acc1.BillingPostalCode != null ||
                        // note that we decided to ignore country so that a default value won't create unnecessary address objects
                        (acc1.BillingCountry != null && !orgConfig.isStateCountryPicklistsEnabled()) ||
                        // only test StateCode if picklists enabled.
                        (orgConfig.isStateCountryPicklistsEnabled() && acc1.get('BillingStateCode') != null);

        return isSpecified;
    }

    public void onAfterInsert(TDTM_Runnable.DmlWrapper dmlWrapper) {
        createAddressesFromNewAccounts(dmlWrapper);
    }

    private void createAddressesFromNewAccounts(TDTM_Runnable.DmlWrapper dmlWrapper) {
        AccountAdapter accountsWithNewAddressesToCreate = newAccountsWithAddressesToCreate();
        if (accountsWithNewAddressesToCreate.getRecords().size() > 0) {
            createAddressesFor(accountsWithNewAddressesToCreate, dmlWrapper, false);
        }
    }

}