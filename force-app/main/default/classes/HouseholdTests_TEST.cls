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
* @description Household domain tests.
*/
@IsTest
private class HouseholdTests_TEST {

    @IsTest
    private static void membersOfShouldReturnEmptyContactsWhenHouseholdHasNoMembers() {
        Account account = new Account(Name = 'AccountWithoutContacts');
        insert account;

        Households households = new Households(new Set<Id>{
                account.Id
        });

        HouseholdId householdId = new HouseholdId(account.Id);
        System.assertEquals(0, households.membersOf(householdId).getRecords().size());
    }

    @IsTest
    private static void memberContactsAreReturnedWhenHouseholdHasMembers() {
        Integer hhSize = 2;
        Integer contactSize = 2;
        ADDR_Addresses_TEST.createTestData(hhSize, contactSize);

        Households testHouseholds = new Households(
                UTIL_SObject.extractIds(ADDR_Addresses_TEST.testAccounts)
        );

        testAndAssertHouseholdMembers(testHouseholds, ADDR_Addresses_TEST.testAccounts, 
                ADDR_Addresses_TEST.testContacts);
    }

    static void testAndAssertHouseholdMembers(Households households, List<Account> accounts, 
            List<Contact> contacts) {
        Map<Id, Contact[]> contactsByAccountId = new Map<Id, Contact[]>();
        for (Contact c : contacts) {
            if (!contactsByAccountId.containsKey(c.AccountId)) {
                contactsByAccountId.put(c.AccountId, new Contact[0]);
            }
            contactsByAccountId.get(c.AccountId).add(c);
        }

        for (Account account : accounts) {
            Contact[] expectedContacts = contactsByAccountId.get(account.Id);
            Contacts actualMembers = households.membersOf(new HouseholdId(account.Id));

            System.assertEquals(UTIL_SObject.extractIds(expectedContacts), 
                    UTIL_SObject.extractIds(actualMembers.getRecords()));
        }
    }

}