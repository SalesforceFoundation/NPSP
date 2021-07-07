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
* @description Domain class for Households in NPSP.
*/
public inherited sharing class Households extends fflib_SObjects {

    private Map<Id, npo02__Household__c> oldMap;
    @TestVisible
    private HouseholdNamingService householdNamingServiceInst {
        get {
            if (householdNamingServiceInst == null) {
                householdNamingServiceInst = new HouseholdNamingService();
            }
            return householdNamingServiceInst;
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

    public Households(Set<Id> ids, HouseholdSelector selector) {
        this(selector.getHouseholdsWithMembersById(ids), null);
    }

    public Households(List<npo02__Household__c> records) {
        this(records, null);
    }

    public Households(List<npo02__Household__c> records, List<npo02__Household__c> oldlist) {
        super(records, npo02__Household__c.SObjectType);
        oldMap = oldlist == null ? new Map<Id, npo02__Household__c>() : new Map<Id,
                npo02__Household__c>(oldlist);
    }

    public void onBeforeUpdate() {
        if (!isHouseholdTriggerContext() && isAdvancedHouseholdNamingEnabled()) {
            setCustomNamingField();
            setNameAndGreetingsToReplacementText();
        }
    }

    public void onAfterUpdate() {
        if (!isHouseholdTriggerContext() && isAdvancedHouseholdNamingEnabled()) {
            renameHouseholdAccountsNeedingNameUpdates();
        }
    }

    public void deleteEmptyHouseholds() {
        delete emptyHouseholds().getRecords();
    }

    public Households emptyHouseholds() {
        List<npo02__Household__c> emptyHouseholds = new List<npo02__Household__c>();
        for (npo02__Household__c household : (List<npo02__Household__c>) getRecords()) {
            if (household.npo02__Contacts__r.isEmpty()) {
                emptyHouseholds.add(household);
            }
        }
        return new Households(emptyHouseholds);
    }

    public Households nonEmptyHouseholds() {
        List<npo02__Household__c> nonEmptyHouseholds = new List<npo02__Household__c>();
        for (npo02__Household__c household : (List<npo02__Household__c>) getRecords()) {
            if (!household.npo02__Contacts__r.isEmpty()) {
                nonEmptyHouseholds.add(household);
            }
        }
        return new Households(nonEmptyHouseholds);
    }

    public Map<Id, Integer> getHouseholdCountMap() {
        Map<Id, Integer> householdCountMap = new Map<Id, Integer>();
        for (npo02__Household__c household : (List<npo02__Household__c>) getRecords()) {
            householdCountMap.put(household.Id, household.npo02__Contacts__r.size());
        }
        return householdCountMap;
    }

    public void calculateLegacyHouseholdRollups() {
        Households nonEmptyHouseholds =
                nonEmptyHouseholds();
        if (nonEmptyHouseholds.ids().size() > 0) {
            if (rollupsShouldRunSynchronously(nonEmptyHouseholds.ids())) {
                RLLP_OppRollup rg = new RLLP_OppRollup();
                rg.rollupHouseholds(getHouseholdMap(nonEmptyHouseholds.ids()));
            } else {
                RLLP_OppRollup.rollupHouseholdsFuture(nonEmptyHouseholds.ids());
            }
        }
    }

    public void updateHouseholdNameAndMemberCount() {
        if (isFutureEligible()) {
            HouseholdNamingService.updateHouseholdNameAndMemberCountAsynchronously(
                    new List<Id>(ids()));
        } else {
            HouseholdNamingService householdNamingService = new HouseholdNamingService();
            householdNamingService.updateHouseholdNameAndMemberCount(new List<Id>(ids()));
        }
    }

    public Set<Id> ids() {
        return getIdFieldValues(npo02__Household__c.Id);
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

    /**
     * @description Determines whether or not the contact needs a one to one account assigned.
     * @param  The contact record to verify.
     * @param  The existing account record assocatied with the contact.
     * @return Boolean - true when the contact needs a one to one account.
     */
    //todo: fix
    public static Boolean needsOneToOneAccount(Contact contactRecord, Account accountRecord) {
        return contactRecord.npe01__Private__c != true
                && (contactRecord.AccountId == null
                || (accountRecord != null
                && accountRecord.npe01__SYSTEM_AccountType__c == CAO_Constants.ONE_TO_ONE_ORGANIZATION_TYPE));
    }

    public static List<Contact> contactsWithoutAccounts(Contacts contactsInstance, Map<Id, Contact> oldContactById) {
        List<Contact> contactsWithoutAccounts2 = new List<Contact>();
        Map<Id, Account> accountsByIds = contactsInstance.accountById;
        for (Contact contactRecord : (List<Contact>) contactsInstance.getRecords()) {
            Account account = accountsByIds.get(contactRecord.AccountId);
            if (Households.needsOneToOneAccount(contactRecord,
                    account)) {

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

    private void setNameAndGreetingsToReplacementText() {
        householdNamingServiceInst.setNameAndGreetingsToReplacementText(getRecords());
    }

    private void setCustomNamingField() {
        householdNamingServiceInst.setCustomNamingField(getRecords(), oldMap);
    }

    private Boolean isAdvancedHouseholdNamingEnabled() {
        return settings.isAdvancedHouseholdNaming();
    }

    private void renameHouseholdAccountsNeedingNameUpdates() {
        householdNamingServiceInst.renameHouseholdAccounts(getHouseholdsNeedingNameUpdates());
    }

    private List<Id> getHouseholdsNeedingNameUpdates() {
        List<Id> householdsNeedingNameUpdates =
                householdNamingServiceInst.getHouseholdsNeedingNameUpdates(
                        getRecords(), oldMap
                );
        return householdsNeedingNameUpdates;
    }

    private Boolean isHouseholdTriggerContext() {
        return TDTM_ProcessControl.isRecursive(TDTM_ProcessControl.flag.HH);
    }

    private Boolean isFutureEligible() {
        return settings.isAsyncEnabled()
                && !System.isFuture() && !System.isBatch();
    }

    private Map<Id, npo02__Household__c> getHouseholdMap(Set<Id> householdIds) {
        RLLP_OppRollup_UTIL oppRollupUtil = new RLLP_OppRollup_UTIL();
        Map<Id, npo02__Household__c> hhmap = new Map<Id, npo02__Household__c>(
                (List<npo02__Household__c>) Database.query(oppRollupUtil.buildHouseholdQuery() +
                        ' WHERE Id IN :householdIds'));
        return hhmap;
    }

    private Boolean rollupsShouldRunSynchronously(Set<Id> householdIds) {
        return System.isFuture() || System.isBatch() || householdIds.size() <= 2;
    }

}