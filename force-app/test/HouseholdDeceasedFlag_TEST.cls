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
* @group Accounts
* @description Tests for HouseholdDeceasedFlag_TEST
*/
@isTest
private class HouseholdDeceasedFlag_TEST {

    @TestSetup
    private static void createDeceasedTestingContactsAndAccounts() {
        List<Contact> deceasedTestingContacts = UTIL_UnitTestData_TEST.getContacts(3);
        deceasedTestingContacts[0].Deceased__c = true;
        deceasedTestingContacts[1].Deceased__c = true;
        insert deceasedTestingContacts;
    }

    /**
     * @description Validate that Household is updated when Contact.Deceased__c is set on insert.
     */
    @IsTest
    private static void shouldSetAllMembersDeceasedOnDeceasedContactInsert() {
        Contact con = UTIL_UnitTestData_TEST.getContact();
        con.Deceased__c = true;

        Test.startTest();
        insert con;
        Test.stopTest();

        Contact queryContact = [SELECT Id, AccountId FROM Contact WHERE Id = :con.id];
        Account queryAccount = getAccount(queryContact);
        System.assertEquals(true, queryAccount.All_Members_Deceased__c,
            'All Members Deceased should be true when household is created with single deceased contact');
    }

    /**
     * @description Validate that All Members Deceased is updated when Contact.Deceased__c is set.
     */
    @IsTest
    private static void shouldSetAllMembersDeceasedOnDeceasedContactUpdate() {
        Contact queryContact =
        [SELECT Id, AccountId FROM Contact WHERE Deceased__c = FALSE];
        Account queryAccount = getAccount(queryContact);
        System.assertEquals(false, queryAccount.All_Members_Deceased__c,
            'All Members Deceased should be false when Contact Deceased flag is false');

        Test.startTest();
        queryContact.Deceased__c = true;
        update queryContact;
        Test.stopTest();

        queryAccount = getAccount(queryContact);
        System.assertEquals(true, queryAccount.All_Members_Deceased__c,
            'All Members Deceased should be true when Contact Deceased flag is updated to true');
    }

    /**
     * @description Validates that All Members Deceased is cleared when one member contact deceased is added to the
     * household.
     */
    @IsTest
    private static void shouldClearAllMembersDeceasedOnHouseholdUpdate() {
        Contact deceasedContact, notDeceasedContact;
        for (Contact con : [SELECT Id, AccountId, Deceased__c FROM Contact])
        {
            if (con.Deceased__c == true) {
                deceasedContact = con;
            } else {
                notDeceasedContact = con;
            }
        }

        Map<Id, Account> accounts =  getAccountsByIds(deceasedContact, notDeceasedContact);
        System.assertEquals(true, accounts.get(deceasedContact.AccountId).All_Members_Deceased__c,
            'All Members Deceased should be true when Contact Deceased flag is true');
        System.assertEquals(false, accounts.get(notDeceasedContact.AccountId).All_Members_Deceased__c,
            'All Members Deceased should be false when Contact Deceased flag is false');

        Test.startTest();
        deceasedContact.AccountId = notDeceasedContact.AccountId;
        update deceasedContact;
        Test.stopTest();

        accounts =  getAccountsByIds(deceasedContact, notDeceasedContact);
        System.assertEquals(false, accounts.get(deceasedContact.AccountId).All_Members_Deceased__c,
            'All Members Deceased should be false when Household includes both deceased and not deceased members');
        System.assertEquals(false, accounts.get(notDeceasedContact.AccountId).All_Members_Deceased__c,
            'All Members Deceased should be false when Household Account includes both deceased and non-deceased contacts');
    }

    /**
     * @description Validates that All Members Deceased does not change when an additional deceased contact is added
     * to the household.
     */
    @IsTest
    private static void shouldNotClearAllMembersDeceasedOnHouseholdUpdate() {
        Contact deceasedContact, deceasedContact2;
        for (Contact con : [SELECT Id, AccountId, Deceased__c FROM Contact])
        {
            if (con.Deceased__c == true && deceasedContact == null) {
                deceasedContact = con;
            } else if (con.Deceased__c == true && deceasedContact2 == null) {
                deceasedContact2 = con;
            }
        }

        Map<Id, Account> accounts =  getAccountsByIds(deceasedContact, deceasedContact2);
        System.assertEquals(true, accounts.get(deceasedContact.AccountId).All_Members_Deceased__c,
            'All Members Deceased should be true when Contact Deceased flag is true');
        System.assertEquals(true, accounts.get(deceasedContact2.AccountId).All_Members_Deceased__c,
            'All Members Deceased should be true when Contact Deceased flag is true');

        Test.startTest();
        deceasedContact.AccountId = deceasedContact2.AccountId;
        update deceasedContact;
        Test.stopTest();

        accounts =  getAccountsByIds(deceasedContact, deceasedContact2);
        System.assertEquals(true, accounts.get(deceasedContact.AccountId).All_Members_Deceased__c,
            'All Members Deceased should be true when Household Account includes 2 deceased members');
        System.assertEquals(true, accounts.get(deceasedContact2.AccountId).All_Members_Deceased__c,
            'All Members Deceased should be true when Household Account includes 2 deceased members');
    }

    /**
     * @description Validate that Account is not updated when direct update of All Members Deceased is attempted.
     */
    @IsTest
    private static void shouldNotUpdateAllMembersDeceasedOnDirectAccountUpdate() {
        Contact queryContact = [SELECT Id, AccountId FROM Contact WHERE Deceased__c = FALSE];
        Account queryAccount = getAccount(queryContact);
        System.assertEquals(false, queryAccount.All_Members_Deceased__c,
            'All Members Deceased should be false when Contact Deceased flag is false');

        Test.startTest();
        queryAccount.All_Members_Deceased__c = true;
        update queryAccount;
        Test.stopTest();

        queryAccount = getAccount(queryContact);
        System.assertEquals(false, queryAccount.All_Members_Deceased__c,
            'All Members Deceased should still be false when Account All_Members_Deceased__c is directly updated');
    }



    // Helpers
    ////////////

    public static Account getAccount(Contact queryContact) {
        return [SELECT Id, All_Members_Deceased__c FROM Account WHERE Id = :queryContact.AccountId];
    }

    public static Map<Id, Account> getAccountsByIds(Contact contact1, Contact contact2) {
        return new Map<Id, Account>([
            SELECT Id, All_Members_Deceased__c
            FROM Account
            WHERE Id IN (:contact1.AccountId, :contact2.AccountId)
        ]);
    }
}