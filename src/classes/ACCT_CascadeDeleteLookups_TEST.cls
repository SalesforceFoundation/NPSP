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
* @description Tests for cascade delete of Accounts
*/
@isTest
private class ACCT_CascadeDeleteLookups_TEST {

    /*********************************************************************************************************
    * @description Tests cascade delete: deletes accounts, which deletes recurring dontations allocations 
    * and relationships. 
    * Verifies results. Then undeletes accounts, which undeletes recurring donations allocations and relationships.
    */
    static testMethod void testAccountsCascadeGrandchildren() {
        Integer maxRecords = 1;

        List<Contact> testContacts = CDL_CascadeDeleteLookups_TEST.createContacts(maxRecords);
        insert testContacts;

        //Retrieve auto created HH Accounts
        List<Account> testAccounts = [
            SELECT Name 
            FROM Account 
            WHERE Id IN (SELECT AccountId FROM Contact WHERE Id IN :testContacts)
        ];

        List<npe03__Recurring_Donation__c> testRecurringDonations = new List<npe03__Recurring_Donation__c>();
        testRecurringDonations.addAll(CDL_CascadeDeleteLookups_TEST.createContactRDs(testContacts));
        testRecurringDonations.addAll(CDL_CascadeDeleteLookups_TEST.createOrganizationalRDs(testAccounts));
        insert testRecurringDonations;

        General_Accounting_Unit__c testGAU = new General_Accounting_Unit__c(Name = 'TEST_GAU');
        insert testGAU;
        List<Opportunity> testOpportunities = CDL_CascadeDeleteLookups_TEST.createOpportunities(testAccounts);
        insert testOpportunities;

        List<Allocation__c> testAllocations = new List<Allocation__c>();
        testAllocations.addAll(CDL_CascadeDeleteLookups_TEST.createRDAllocations(testGAU, testRecurringDonations));
        testAllocations.addAll(CDL_CascadeDeleteLookups_TEST.createOpportunityAllocations(testGAU, testOpportunities));
        insert testAllocations;

        List<npe4__Relationship__c> testRelationships = CDL_CascadeDeleteLookups_TEST.createRelationships(testContacts);
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
        System.assertEquals(testRecurringDonations.size(), deletedRecurringDonations.size(), 'Recurring Donations should be cascade deleted when Account is deleted.');

        List<Allocation__c> deletedAllocations = [
            SELECT Id 
            FROM Allocation__c 
            WHERE IsDeleted = true 
            ALL ROWS
        ];
        System.assertEquals(testAllocations.size(), deletedAllocations.size(), 'Allocation should be cascade deleted when Account is deleted.');

        List<npe4__Relationship__c> deletedRelationships = [
            SELECT Id 
            FROM npe4__Relationship__c
            WHERE IsDeleted = true 
            ALL ROWS 
        ];
        System.assertEquals(testRelationships.size() * 2, deletedRelationships.size(), 'The two relationships created for the Contact should be deleted');

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
        ];
        System.assertEquals(deletedRecurringDonations.size(), undeletedRecurringDonations.size(), 'Recurring Donations should be cascade undeleted when Account is undeleted.');

        List<Allocation__c> undeletedAllocations = [
            SELECT Id 
            FROM Allocation__c
            WHERE IsDeleted = false
        ];
        System.assertEquals(deletedAllocations.size(), undeletedAllocations.size(), 'Allocations should be cascade undeleted when Account is undeleted.');

        List<npe4__Relationship__c> undeletedRelationships = [
            SELECT Id 
            FROM npe4__Relationship__c
            WHERE IsDeleted = false
        ];
        System.assertEquals(deletedRelationships.size(), undeletedRelationships.size(), 'Both relationships for the Contact should be undeleted when Account is undeleted.');
    }

    /*********************************************************************************************************
    * @description Tests the merge of 2 Accounts. Deleted Account should not cascade delete the child records
    * Verifies results: The losing account in a merge operation doesn't get child records cascade deleted.
    */
    static testMethod void testAccountMergeNoCascade() {
        List<Contact> testContacts = CDL_CascadeDeleteLookups_TEST.createContacts(2);
        insert testContacts;

        //Retrieve auto created HH Accounts
        List<Account> testAccounts = [
            SELECT Name 
            FROM Account 
            WHERE Id IN (SELECT AccountId FROM Contact WHERE Id = :testContacts)
        ];

        List<npe03__Recurring_Donation__c> testRecurringDonations = new List<npe03__Recurring_Donation__c>();
        testRecurringDonations.addAll(CDL_CascadeDeleteLookups_TEST.createContactRDs(testContacts));
        testRecurringDonations.addAll(CDL_CascadeDeleteLookups_TEST.createOrganizationalRDs(testAccounts));
        insert testRecurringDonations;

        General_Accounting_Unit__c testGAU = new General_Accounting_Unit__c(Name = 'TEST_GAU');
        insert testGAU;
        List<Opportunity> testOpportunities = CDL_CascadeDeleteLookups_TEST.createOpportunities(testAccounts);
        insert testOpportunities;

        List<Allocation__c> testAllocations = new List<Allocation__c>();
        testAllocations.addAll(CDL_CascadeDeleteLookups_TEST.createRDAllocations(testGAU, testRecurringDonations));
        testAllocations.addAll(CDL_CascadeDeleteLookups_TEST.createOpportunityAllocations(testGAU, testOpportunities));
        insert testAllocations;

        List<npe4__Relationship__c> testRelationships = CDL_CascadeDeleteLookups_TEST.createRelationships(testContacts);
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
        System.assertEquals(0, deletedRelationships.size(), 'Relationships should not be deleted as the result of losing a merge.');
    }
}