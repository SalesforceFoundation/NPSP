/*
    Copyright (c) 2016, Salesforce.org
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
* @date 2016
* @group Utilities
* @description Tests for cascade delete of Account
*/
@isTest
private class ACCT_CascadeDeleteLookups_TEST {

    /*********************************************************************************************************
    * @description Test the merge of 2 Accounts. Deleted Account should no cascade delete the child records
    * Verifies result: The losing account in a merge operation doesn't get child records cascade deleted.
    */
    static testMethod void testAccountMergeNoCascade() {
        List<Contact> testContacts = createContacts(2);
        insert testContacts;

        //Retrieve auto created HH Accounts
        List<Account> testAccounts = [
            SELECT Name 
            FROM Account 
            WHERE Id IN (SELECT AccountId FROM Contact WHERE Id = :testContacts)
        ];

        List<npe03__Recurring_Donation__c> testRecurringDonations = new List<npe03__Recurring_Donation__c>();
        testRecurringDonations.addAll(createContactRDs(testContacts));
        testRecurringDonations.addAll(createOrganizationalRDs(testAccounts));
        insert testRecurringDonations;

        General_Accounting_Unit__c testGAU = new General_Accounting_Unit__c(Name = 'TEST_GAU');
        insert testGAU;
        List<Opportunity> testOpportunities = createOpportunities(testAccounts);
        insert testOpportunities;

        List<Allocation__c> testAllocations = new List<Allocation__c>();
        testAllocations.addAll(createRDAllocations(testGAU, testRecurringDonations));
        testAllocations.addAll(createOpportunityAllocations(testGAU, testOpportunities));
        insert testAllocations;

        List<npe4__Relationship__c> testRelationships = createRelationships(testContacts);
        insert testRelationships;

        Test.startTest();
        merge testAccounts[0] testAccounts[1];
        Test.stopTest();

        List<Error__c> errors = [
            SELECT Id, Object_Type__c, Full_Message__c, Stack_Trace__c 
            FROM Error__c
        ];
        System.assertEquals(0, errors.size(), errors);

        List<npe03__Recurring_Donation__c> deletedRecurringDonations = [
            SELECT Id 
            FROM npe03__Recurring_Donation__c
            WHERE IsDeleted = true 
            ALL ROWS
        ];
        System.assertEquals(0, deletedRecurringDonations.size(), 'Recurring Donations should not be deleted as the result of losing a merge.');

        List<Allocation__c> deletedAllocations = [
            SELECT Id 
            FROM Allocation__c 
            WHERE IsDeleted = true 
            ALL ROWS
        ];
        System.assertEquals(0, deletedAllocations.size(), 'Allocations should not be deleted as the result of losing a merge.');

        List<npe4__Relationship__c> deletedRelationships = [
            SELECT Id 
            FROM npe4__Relationship__c
            WHERE IsDeleted = true 
            ALL ROWS 
        ];
        System.assertEquals(0, deletedRelationships.size(), 'relationships should not be deleted as the result of losing a merge.');
    }

    /*********************************************************************************************************
    * @description Tests cascade delete: deletes accounts, which deletes recurring dontations allocations 
    * and relationships. 
    * Verifies results. Then undeletes accounts, which undeletes recurring donations and allocations. Verifies
    * results.
    */
    static testMethod void testAccountsCascadeGrandchildren() {
        Integer maxRecords = 200;

        List<Contact> testContacts = createContacts(maxRecords);
        insert testContacts;

        //Retrieve auto created HH Accounts
        List<Account> testAccounts = [
            SELECT Name 
            FROM Account 
            WHERE Id IN (SELECT AccountId FROM Contact WHERE Id = :testContacts)
        ];

        List<npe03__Recurring_Donation__c> testRecurringDonations = new List<npe03__Recurring_Donation__c>();
        testRecurringDonations.addAll(createContactRDs(testContacts));
        testRecurringDonations.addAll(createOrganizationalRDs(testAccounts));
        insert testRecurringDonations;

        General_Accounting_Unit__c testGAU = new General_Accounting_Unit__c(Name = 'TEST_GAU');
        insert testGAU;
        List<Opportunity> testOpportunities = createOpportunities(testAccounts);
        insert testOpportunities;

        List<Allocation__c> testAllocations = new List<Allocation__c>();
        testAllocations.addAll(createRDAllocations(testGAU, testRecurringDonations));
        testAllocations.addAll(createOpportunityAllocations(testGAU, testOpportunities));
        insert testAllocations;

        List<npe4__Relationship__c> testRelationships = createRelationships(testContacts);
        insert testRelationships;

        Test.startTest();
        delete testAccounts;
        Test.stopTest();

        List<Error__c> errors = [
            SELECT Id, Object_Type__c, Full_Message__c, Stack_Trace__c 
            FROM Error__c
        ];
        System.assertEquals(0, errors.size(), errors);

        List<npe03__Recurring_Donation__c> deletedRecurringDonations = [
            SELECT Id 
            FROM npe03__Recurring_Donation__c
            WHERE IsDeleted = true 
            ALL ROWS
        ];
        System.assertEquals(testRecurringDonations.size(), deletedRecurringDonations.size(), 'Contact and Account Recurring Donation should be cascade deleted when Account is deleted.');

        List<Allocation__c> deletedAllocations = [
            SELECT Id 
            FROM Allocation__c 
            WHERE IsDeleted = true 
            ALL ROWS
        ];
        System.assertEquals(testAllocations.size(), deletedAllocations.size(), 'Allocation should be cascade deleted when recurring donation is deleted.');

        List<npe4__Relationship__c> deletedRelationships = [
            SELECT Id 
            FROM npe4__Relationship__c
            WHERE IsDeleted = true 
            ALL ROWS 
        ];
        System.assertEquals(testRelationships.size() * 2, deletedRelationships.size(), 'The two relationships created for each Contact should be deleted');

        undelete testAccounts;

        errors = [
            SELECT Id, Object_Type__c, Full_Message__c, Stack_Trace__c 
            FROM Error__c
        ];
        System.assertEquals(0, errors.size(), errors);

        List<npe03__Recurring_Donation__c> undeletedRecurringDonations = [
            SELECT Id 
            FROM npe03__Recurring_Donation__c 
            WHERE IsDeleted = false 
            ALL ROWS];
        System.assertEquals(deletedRecurringDonations.size(), undeletedRecurringDonations.size(), 'Contacts and Accounts Recurring Donations should be cascade undeleted when Account is undeleted.');

        List<Allocation__c> undeletedAllocations = [
            SELECT Id 
            FROM Allocation__c
            WHERE IsDeleted = false 
            ALL ROWS
        ];
        System.assertEquals(deletedAllocations.size(), undeletedAllocations.size(), 'Allocations should be cascade undeleted.');

        List<npe4__Relationship__c> undeletedRelationships = [
            SELECT Id 
            FROM npe4__Relationship__c
        ];
        System.assertEquals(deletedRelationships.size(), undeletedRelationships.size(), 'Both relationships for each Contact should be undeleted when account is undeleted.');
    }

    /*******************************************************************************************************
    * @description Create Contacts
    * @param Integer The maximum records to create
    * @return List<Contact> The created Contacts
    ********************************************************************************************************/
    private static List<Contact> createContacts(Integer maxRecords) {
        List<Contact> result = new List<Contact>();
        for (Integer i = 0; i < maxRecords; i++) {
            result.add(new Contact(LastName = 'CONTACT' + i));
        }
        return result;
    }

    /*******************************************************************************************************
    * @description Create Contact Recurring Donations
    * @param List<Contact> The Contacts records that are used to create the Recurring Donations
    * @return List<npe03__Recurring_Donation__c> The created Contact Recurring Donations
    ********************************************************************************************************/
    private static List<npe03__Recurring_Donation__c> createContactRDs(List<Contact> testContacts) {
        List<npe03__Recurring_Donation__c> result = new List<npe03__Recurring_Donation__c>();
        for (Contact testContact : testContacts) {
            result.add(
                new npe03__Recurring_Donation__c(
                    Name = 'CON_RD',
                    npe03__Installments__c = 2,
                    npe03__Amount__c = 1,
                    npe03__Installment_Period__c = System.Label.npe03.RecurringDonationInstallmentPeriodYearly,
                    npe03__Date_Established__c = Date.newinstance(1970,6,12),
                    npe03__Schedule_Type__c = System.Label.npe03.RecurringDonationMultiplyValue,
                    npe03__Contact__c = testContact.Id
                )
            );
        }
        return result;
    }

    /*******************************************************************************************************
    * @description Create Organizational Recurring Donations
    * @param List<Account> The Accounts records that are used to create the Recurring Donations
    * @return List<npe03__Recurring_Donation__c> The created Organizational Recurring Donations
    ********************************************************************************************************/
    private static List<npe03__Recurring_Donation__c> createOrganizationalRDs(List<Account> testAccounts) {
        List<npe03__Recurring_Donation__c> result = new List<npe03__Recurring_Donation__c>();
        for (Account testAccount : testAccounts) {
            result.add(
                new npe03__Recurring_Donation__c(
                    Name = 'ORG_RD' + testAccount.Name,
                    npe03__Installments__c = 2,
                    npe03__Amount__c = 1,
                    npe03__Installment_Period__c = System.Label.npe03.RecurringDonationInstallmentPeriodYearly,
                    npe03__Date_Established__c = Date.newinstance(1970,6,12),
                    npe03__Schedule_Type__c = System.Label.npe03.RecurringDonationMultiplyValue,
                    npe03__Organization__c = testAccount.Id
                )
            );
        }
        return result;
    }

    /*******************************************************************************************************
    * @description Create Opportunities
    * @param List<Account> The Accounts records that are used to create the Opportunities
    * @return List<Opportunity> The created Opportunities
    ********************************************************************************************************/
    private static List<Opportunity> createOpportunities(List<Account> testAccounts) {
        List<Opportunity> result = new List<Opportunity>();
        for (Account testAccount : testAccounts) {
            result.add(
                new Opportunity(
                    Name = 'OPP_' + testAccount.Name,
                    Amount = 8,
                    AccountId = testAccount.Id,
                    StageName = UTIL_UnitTestData_TEST.getClosedLostStage(),
                    CloseDate = System.today()
                )
            );
        }
        return result;
    }

    /*******************************************************************************************************
    * @description Create Recurring Donation Allocations
    * @param General_Accounting_Unit__c The General Accounting Unit record that is used to create the Allocations
    * @param List<npe03__Recurring_Donation__c> The Recurring Donations records that are used to create the Allocations
    * @return List<Allocation__c> The created Allocations
    ********************************************************************************************************/
    private static List<Allocation__c> createRDAllocations(General_Accounting_Unit__c testGAU,  List<npe03__Recurring_Donation__c> testRecurringDonations) {
        List<Allocation__c> result = new List<Allocation__c>();
        for (npe03__Recurring_Donation__c testRecurringDonation : testRecurringDonations) {
            result.add(
                new Allocation__c(
                    Amount__c = 4, 
                    Recurring_Donation__c = testRecurringDonation.Id,
                    General_Accounting_Unit__c = testGAU.Id
                )
            );
        }
        return result;
    }

    /*******************************************************************************************************
    * @description Create Opportunity Allocations
    * @param General_Accounting_Unit__c The General Accounting Unit record that is used to create the Allocations
    * @param List<Opportunity> The Opportunities records that are used to create the Allocations
    * @return List<Allocation__c> The created Allocations
    ********************************************************************************************************/
    private static List<Allocation__c> createOpportunityAllocations(General_Accounting_Unit__c testGAU,  List<Opportunity> testOpportunities) {
        List<Allocation__c> result = new List<Allocation__c>();
        for (Opportunity testOpportunity : testOpportunities) {
            result.add(
                new Allocation__c(
                    Amount__c = 4, 
                    Opportunity__c = testOpportunity.Id,
                    General_Accounting_Unit__c = testGAU.Id
                )
            );
        }
        return result;
    }

    /*******************************************************************************************************
    * @description Create Relationships
    * @param List<Contact> The Contacts records that are used to create the Relationships
    * @return List<npe4__Relationship__c> The created Relationships
    ********************************************************************************************************/
    private static List<npe4__Relationship__c> createRelationships(List<Contact> testContacts) {
        List<npe4__Relationship__c> result = new List<npe4__Relationship__c>();

        Map<Id, Contact> testContactsWithFriends = new Map<Id, Contact>();
        for (Contact testContact : testContacts) {
            testContactsWithFriends.put(testContact.Id, new Contact(LastName = 'FRIEND_OF_' + testContact.LastName));
        }
        insert testContactsWithFriends.values();

        for (Contact testContact : testContacts) {
            result.add(
                new npe4__Relationship__c(
                    npe4__contact__c = testContact.Id, 
                    npe4__relatedcontact__c = testContactsWithFriends.get(testContact.Id).Id, 
                    npe4__Type__c = 'Friend',
                    npe4__Status__c = 'Active'
                )
            );
        }
        return result;
    }
}