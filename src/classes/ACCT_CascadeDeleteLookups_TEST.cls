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
* @group Cascade Delete
* @description Tests for cascade delete of Accounts
*/
@isTest
private class ACCT_CascadeDeleteLookups_TEST {

    /*********************************************************************************************************
    * @description Tests cascade delete: deletes accounts, which deletes recurring donations allocations 
    * and relationships. 
    * Verifies results. Then undeletes accounts, which undeletes recurring donations allocations and relationships.
    */
    static testMethod void testAccountCascadeGrandchildren() {
        Integer maxRecords = 1;

        List<Contact> contacts = CDL_CascadeDeleteLookups_TEST.buildContacts(maxRecords);
        insert contacts;

        //Retrieve auto created HH Accounts
        List<Account> accounts = [
            SELECT Name 
            FROM Account 
            WHERE Id IN (SELECT AccountId FROM Contact WHERE Id IN :contacts)
        ];

        List<npe03__Recurring_Donation__c> recurringDonations = new List<npe03__Recurring_Donation__c>();
        recurringDonations.addAll(CDL_CascadeDeleteLookups_TEST.buildContactRDs(contacts));
        recurringDonations.addAll(CDL_CascadeDeleteLookups_TEST.buildOrganizationalRDs(accounts));
        insert recurringDonations;

        General_Accounting_Unit__c generalAccountingUnit = new General_Accounting_Unit__c(Name = 'TEST_GAU');
        insert generalAccountingUnit;
        List<Opportunity> opportunities = CDL_CascadeDeleteLookups_TEST.buildOpportunities(accounts);
        insert opportunities;

        List<Allocation__c> allocations = new List<Allocation__c>();
        allocations.addAll(CDL_CascadeDeleteLookups_TEST.buildRDAllocations(generalAccountingUnit, recurringDonations));
        allocations.addAll(CDL_CascadeDeleteLookups_TEST.buildOpportunityAllocations(generalAccountingUnit, opportunities));
        insert allocations;

        List<npe4__Relationship__c> relationships = CDL_CascadeDeleteLookups_TEST.buildRelationships(contacts);
        insert relationships;

        Test.startTest();
        delete accounts;
        Test.stopTest();

        List<Error__c> errors = CDL_CascadeDeleteLookups_TEST.getErrors();
        System.assertEquals(0, errors.size(), errors);

        List<npe03__Recurring_Donation__c> deletedRecurringDonations = CDL_CascadeDeleteLookups_TEST.getDeletedRecurringDonations();
        System.assertEquals(recurringDonations.size(), deletedRecurringDonations.size(), 'Recurring Donations should be cascade deleted when Account is deleted.');

        List<Allocation__c> deletedAllocations = CDL_CascadeDeleteLookups_TEST.getDeletedAllocations();
        System.assertEquals(allocations.size(), deletedAllocations.size(), 'Allocation should be cascade deleted when Account is deleted.');

        List<npe4__Relationship__c> deletedRelationships = CDL_CascadeDeleteLookups_TEST.getDeletedRelationships();
        System.assertEquals(relationships.size() * 2, deletedRelationships.size(), 'The two relationships created for the Contact should be deleted');

        undelete accounts;

        errors = CDL_CascadeDeleteLookups_TEST.getErrors();
        System.assertEquals(0, errors.size(), errors);

        List<npe03__Recurring_Donation__c> undeletedRecurringDonations = CDL_CascadeDeleteLookups_TEST.getNonDeletedRecurringDonations();
        System.assertEquals(deletedRecurringDonations.size(), undeletedRecurringDonations.size(), 'Recurring Donations should be cascade undeleted when Account is undeleted.');

        List<Allocation__c> undeletedAllocations = CDL_CascadeDeleteLookups_TEST.getNonDeletedAllocations();
        System.assertEquals(deletedAllocations.size(), undeletedAllocations.size(), 'Allocations should be cascade undeleted when Account is undeleted.');

        List<npe4__Relationship__c> undeletedRelationships = CDL_CascadeDeleteLookups_TEST.getNonDeletedRelationships();
        System.assertEquals(deletedRelationships.size(), undeletedRelationships.size(), 'Both relationships for the Contact should be undeleted when Account is undeleted.');
    }

    /*********************************************************************************************************
    * @description Tests the merge of 2 Accounts. Deleted Account should not cascade delete the child records
    * Verifies results: The losing account in a merge operation doesn't get child records cascade deleted.
    */
    static testMethod void testAccountMergeNoCascade() {
        List<Contact> contacts = CDL_CascadeDeleteLookups_TEST.buildContacts(2);
        insert contacts;

        //Retrieve auto created HH Accounts
        List<Account> accounts = [
            SELECT Name 
            FROM Account 
            WHERE Id IN (SELECT AccountId FROM Contact WHERE Id = :contacts)
        ];

        List<npe03__Recurring_Donation__c> recurringDonations = new List<npe03__Recurring_Donation__c>();
        recurringDonations.addAll(CDL_CascadeDeleteLookups_TEST.buildContactRDs(contacts));
        recurringDonations.addAll(CDL_CascadeDeleteLookups_TEST.buildOrganizationalRDs(accounts));
        insert recurringDonations;

        General_Accounting_Unit__c generalAccountingUnit = new General_Accounting_Unit__c(Name = 'TEST_GAU');
        insert generalAccountingUnit;
        List<Opportunity> opportunities = CDL_CascadeDeleteLookups_TEST.buildOpportunities(accounts);
        insert opportunities;

        List<Allocation__c> allocations = new List<Allocation__c>();
        allocations.addAll(CDL_CascadeDeleteLookups_TEST.buildRDAllocations(generalAccountingUnit, recurringDonations));
        allocations.addAll(CDL_CascadeDeleteLookups_TEST.buildOpportunityAllocations(generalAccountingUnit, opportunities));
        insert allocations;

        List<npe4__Relationship__c> relationships = CDL_CascadeDeleteLookups_TEST.buildRelationships(contacts);
        insert relationships;

        Test.startTest();
        merge accounts[0] accounts[1];
        Test.stopTest();

        List<Error__c> errors = CDL_CascadeDeleteLookups_TEST.getErrors();
        System.assertEquals(0, errors.size(), errors);

        List<npe03__Recurring_Donation__c> deletedRecurringDonations = CDL_CascadeDeleteLookups_TEST.getDeletedRecurringDonations();
        System.assertEquals(0, deletedRecurringDonations.size(), 'Recurring Donations should not be deleted as the result of losing a merge.');

        List<Allocation__c> deletedAllocations = CDL_CascadeDeleteLookups_TEST.getDeletedAllocations();
        System.assertEquals(0, deletedAllocations.size(), 'Allocations should not be deleted as the result of losing a merge.');

        List<npe4__Relationship__c> deletedRelationships = CDL_CascadeDeleteLookups_TEST.getDeletedRelationships();
        System.assertEquals(0, deletedRelationships.size(), 'Relationships should not be deleted as the result of losing a merge.');
    }
}