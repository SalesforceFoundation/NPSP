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
* @description Domain class for Accounts in NPSP.
*/
public with sharing class Accounts extends fflib_SObjects {

    List<Account> accounts = new List<Account>();
    Map<Id, Account> oldMap = new Map<Id, Account>();
    List<Account> newHouseholdAccounts = new List<Account>();
    List<Account> oldHouseholdAccounts = new List<Account>();

    HH_HouseholdNaming service = new HH_HouseholdNaming();
    ID recordTypeIdForHouseholdAccount = ACCT_IndividualAccounts_TDTM.rtIdForAccountModel(true);
    ID recordTypeIdForOneToOneAccount = ACCT_IndividualAccounts_TDTM.rtIdForAccountModel(false);

    public Accounts(List<Account> records) {
        super(records);
        this.accounts = records;
    }

    public Accounts(List<Account> records, List<Account> oldlist) {
        super(records);
        this.accounts = records;
        this.oldMap = new Map<Id, Account>(oldlist);
    }

    public void onBeforeInsert() {
        setAccountTypeAndIndividualFieldValues();
    }

    public void onBeforeUpdate() {
        setAccountTypeAndIndividualFieldValues();
        setSystemFieldValues();
        if (shouldSetHouseholdNameFields()) {
            setHouseholdNameFields();
        }
    }

    public void onAfterUpdate() {
        if (isEnabledAdvancedHouseholdNaming()) {
            renameHouseholdsNeedingNameUpdates();
        }
    }

    private Boolean isEnabledAdvancedHouseholdNaming() {
        return service.isAdvancedHouseholdNaming();
    }

    private Boolean shouldSetHouseholdNameFields() {
        return !isHouseholdTriggerContext() && isEnabledAdvancedHouseholdNaming();
    }

    private void setHouseholdNameFields() {
        buildHouseholdAccountLists();
        service.setHouseholdNameFields(newHouseholdAccounts, oldMap);
    }

    private void renameHouseholdsNeedingNameUpdates() {
        buildHouseholdAccountLists();
        service.renameHouseholdAccounts(getHouseholdsNeedingNameUpdates());
    }

    private List<Id> getHouseholdsNeedingNameUpdates() {
        return service.getHouseholdsNeedingNameUpdates(
                newHouseholdAccounts, oldMap
        );
    }

    public void setSystemFieldValues() {
        for (Account acc : accounts) {
            if (shouldResetAccountTypeAndIndividualFields(acc)) {
                resetAccountTypeAndIndividualFields(acc);
            }
        }
    }

    private void resetAccountTypeAndIndividualFields(Account acc) {
        acc.npe01__SYSTEMISINDIVIDUAL__c = false;
        acc.npe01__SYSTEM_AccountType__c = null;
    }

    private Boolean shouldResetAccountTypeAndIndividualFields(Account acc) {
        return isRecordTypeIdChanged(acc)
                && !isHouseholdAccount(acc)
                && !isOneToOneAccount(acc)
                && !isBucketAccount(acc);
    }

    private Boolean isRecordTypeIdChanged(Account acc) {
        return acc.RecordTypeId != oldVersionOf(acc).RecordTypeId;
    }

    public void setAccountTypeAndIndividualFieldValues() {
        for (Account acc : accounts) {
            if (needsTypeAndIndividualFieldsSet(acc)) {
                setTypeAndIndividualFields(acc);
            }
        }
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
        acc.npe01__SYSTEMISINDIVIDUAL__c = true;
    }

    private void setTypeAndIndividualFieldsForHouseholdAccount(Account acc) {
        acc.npe01__SYSTEM_AccountType__c = CAO_Constants.HH_ACCOUNT_TYPE;
        acc.Type = CAO_Constants.HH_TYPE;
        acc.npe01__SYSTEMISINDIVIDUAL__c = true;
    }

    private Boolean needsTypeAndIndividualFieldsSet(Account acc) {
        return isMissingAccountType(acc) || isNotIndividualAccount(acc);
    }

    private Boolean isNotIndividualAccount(Account acc) {
        return acc.npe01__SYSTEMISINDIVIDUAL__c != true;
    }

    private Boolean isMissingAccountType(Account acc) {
        return acc.npe01__SYSTEM_AccountType__c == null;
    }

    private void buildHouseholdAccountLists() {
        for (Account account : accounts) {
            if (isHouseholdAccountType(account)) {
                newHouseholdAccounts.add(account);
                oldHouseholdAccounts.add(oldVersionOf(account));
            }
        }
    }

    private Account oldVersionOf(Account a) {
        return oldMap.get(a.Id);
    }

    private Boolean isHouseholdAccountType(Account acc) {
        return acc.npe01__SYSTEM_AccountType__c == CAO_Constants.HH_ACCOUNT_TYPE;
    }

    private Boolean isOneToOneAccount(Account acc) {
        return acc.RecordTypeId == recordTypeIdForOneToOneAccount && acc.RecordTypeId != null;
    }

    private Boolean isHouseholdAccount(Account acc) {
        return acc.RecordTypeId == recordTypeIdForHouseholdAccount && acc.RecordTypeId != null;
    }

    private Boolean isBucketAccount(Account acc) {
        return (CAO_Constants.isBucketModel() && acc.Name == CAO_Constants.BUCKET_ACCOUNT_NAME);
    }

    private Boolean isHouseholdTriggerContext() {
        return TDTM_ProcessControl.isRecursive(TDTM_ProcessControl.flag.HH);
    }
}