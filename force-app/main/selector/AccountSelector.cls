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
/*
* @author Salesforce.org
* @date 2021
* @description Selector class for Accounts in NPSP.
*/
public with sharing class AccountSelector {

    @TestVisible
    private static OrgConfig orgConfig {
        get {
            if (orgConfig == null) {
                orgConfig = new OrgConfig();
            }
            return orgConfig;
        }
        set;
    }

    public List<Account> getAccountsFor(Set<Id> accountIds) {
        return Database.query(buildAccountSoql(accountIds));
    }

    public List<Account> getHouseholdAndOrgAccountsFor(Set<Id> accountIds) {
        return Database.query(buildHouseholdAndOrgAccountsSoql(accountIds));
    }

    @TestVisible
    private String buildHouseholdAndOrgAccountsSoql(Set<Id> accountIds) {
        List<String> selectFields = getAccountFields();
        String whereClause = 'Id IN :accountIds AND npe01__SYSTEM_AccountType__c =' +
            ':CAO_Constants.ONE_TO_ONE_ORGANIZATION_TYPE OR (\n' +
                'npe01__SYSTEM_AccountType__c = :CAO_Constants.HH_ACCOUNT_TYPE \n' +
                'AND Number_of_Household_Members__c = 1 \n' +
                ')';
        return new UTIL_Query()
                .withSelectFields(selectFields)
                .withFrom(String.valueOf(Account.SObjectType))
                .withWhere(whereClause)
                .build();
    }

    @TestVisible
    private String buildAccountSoql(Set<Id> accountIds) {
        List<String> selectFields = getAccountFields();

        return new UTIL_Query()
                .withSelectFields(selectFields)
                .withFrom(String.valueOf(Account.SObjectType))
                .withWhere('Id IN :accountIds')
                .build();
    }

    public List<String> getAccountFields() {
        List<String> selectFields = new List<String> {
            String.valueOf(Account.Name),
            String.valueOf(Account.npe01__SYSTEM_AccountType__c)
        };

        if (orgConfig.isPersonAccountsEnabled()) {
            selectFields.add(String.valueOf('PersonContactId'));
        }

        return selectFields;
     }
}