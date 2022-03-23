/*
    Copyright (c) 2022, Salesforce.org
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
* @date 2022
* @group Settings
* @description Batch Class to recalculate the All Household Members Deceased flag on Household Accounts.
*/
public class DeceasedBatch implements Database.Batchable<sObject> {

    final String HH_ACCOUNT_TYPE = CAO_Constants.HH_ACCOUNT_TYPE;

    public Database.QueryLocator start(Database.BatchableContext info) {
        return Database.getQueryLocator(
            'SELECT AccountId, Account.All_Members_Deceased__c ' +
                'FROM Contact ' +
                'WHERE npe01__Organization_Type__c = :HH_ACCOUNT_TYPE ' +
                'AND (Deceased__c = TRUE OR Account.All_Members_Deceased__c = TRUE) ' +
                'ORDER BY AccountId'
        );
    }

    public void execute(Database.BatchableContext BC, List<Contact> scope) {
        Map<Id, Boolean> allMembersDeceasedById = getAllMembersDeceasedById(scope);
        List<Contact> contacts = getContacts(allMembersDeceasedById.keySet());
        if (allMembersDeceasedById.isEmpty() || contacts.isEmpty()) {
            return;
        }

        List<Account> allMembersDeceasedUpdates = getAllMembersDeceasedUpdates(contacts, allMembersDeceasedById);
        updateModifiedAccounts(allMembersDeceasedUpdates);
    }

    @TestVisible
    private Map<Id, Boolean> getAllMembersDeceasedById(List<Contact> scope) {
        Map<Id, Boolean> allMembersDeceasedById = new Map<Id, Boolean>();
        for (Contact householdMember : scope) {
            if (!allMembersDeceasedById.containsKey(householdMember.AccountId)) {
                allMembersDeceasedById.put(householdMember.AccountId, householdMember.Account.All_Members_Deceased__c);
            }
        }
        return allMembersDeceasedById;
    }

    private List<Contact> getContacts(Set<Id> accountIds) {
        List<Contact> contacts = [
            SELECT AccountId, Deceased__c
            FROM Contact
            WHERE AccountId IN :accountIds
            ORDER BY AccountId
        ];
        return contacts;
    }

    @TestVisible
    private List<Account> getAllMembersDeceasedUpdates(List<Contact> contacts, Map<Id, Boolean> allMembersDeceasedById) {
        Id previousAccount;
        Boolean currentAllMembersDeceasedValue;
        Boolean calculatedDeceasedValue;
        List<Account> deceasedUpdates = new List<Account>();

        for (Contact householdMember : contacts) {
            if (!allMembersDeceasedById.containsKey(householdMember.AccountId)) {
                continue;
            }

            if (previousAccount != householdMember.AccountId) {
                if (currentAllMembersDeceasedValue != calculatedDeceasedValue) {
                    deceasedUpdates.add(newUpdatedAccount(previousAccount, calculatedDeceasedValue));
                }
                previousAccount = householdMember.AccountId;
                currentAllMembersDeceasedValue = allMembersDeceasedById.get(householdMember.AccountId);
                calculatedDeceasedValue = true;
            }

            if (householdMember.Deceased__c != true) {
                calculatedDeceasedValue = false;
            }
        }

        if (currentAllMembersDeceasedValue != calculatedDeceasedValue) {
            deceasedUpdates.add(newUpdatedAccount(previousAccount, calculatedDeceasedValue));
        }

        return deceasedUpdates;
    }

    private Account newUpdatedAccount(Id previousAccountId, Boolean calculatedAllMembersDeceasedSetting) {
        return new Account(
            Id = previousAccountId,
            All_Members_Deceased__c = calculatedAllMembersDeceasedSetting
        );
    }

    private void updateModifiedAccounts(List<Account> allMembersDeceasedUpdates) {
        TDTM_Config_API.disableAllTriggers();
        Database.update(allMembersDeceasedUpdates, false);
    }

    public void finish(Database.BatchableContext info) {
        List<Account> emptyDeceasedAccounts = getEmptyDeceasedHouseholdAccounts();
        if (!emptyDeceasedAccounts.isEmpty()) {
            for (Account deceasedAccount : emptyDeceasedAccounts) {
                deceasedAccount.All_Members_Deceased__c = false;
            }
            TDTM_Config_API.disableAllTriggers();
            Database.update(emptyDeceasedAccounts, false);
        }
    }

    private List<Account> getEmptyDeceasedHouseholdAccounts() {
        return [
            SELECT Id, All_Members_Deceased__c
            FROM Account
            WHERE npe01__SYSTEM_AccountType__c = :HH_ACCOUNT_TYPE
            AND Number_of_Household_Members__c = 0
            AND All_Members_Deceased__c = TRUE
            LIMIT 10000
        ];
    }
}