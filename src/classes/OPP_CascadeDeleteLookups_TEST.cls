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
* @description Tests for cascade delete of Opportunities
*/
@isTest
private class OPP_CascadeDeleteLookups_TEST {

    /*********************************************************************************************************
    * @description Deletes the Opportunities which deletes the related Allocations. 
    * Then undeletes the Opportunities, which undeletes the Allocations.
    * Verifies results: All the Allocations should be deleted after the Opportunities are deleted.
    * Then the Allocations will be undeleted after the Opportunities are undeleted.
    */
    static testMethod void testOppCascade() {
        Integer maxRecords = 1;

        List<Account> accounts = CDL_CascadeDeleteLookups_TEST.buildAccounts(maxRecords);
        insert accounts;

        List<Opportunity> opportunities = CDL_CascadeDeleteLookups_TEST.buildOpportunities(accounts);
        insert opportunities;

        General_Accounting_Unit__c generalAccountingUnit = new General_Accounting_Unit__c(Name = 'TEST_GAU');
        insert generalAccountingUnit;
        List<Allocation__c> allocations = new List<Allocation__c>();
        allocations.addAll(CDL_CascadeDeleteLookups_TEST.buildOpportunityAllocations(generalAccountingUnit, opportunities));
        insert allocations;

        Test.startTest();
        delete opportunities;
        Test.stopTest();

        List<Allocation__c> deletedAllocations = CDL_CascadeDeleteLookups_TEST.getDeletedAllocations();
        System.assertEquals(allocations.size(), deletedAllocations.size(), 'Allocations should be cascade deleted when the Opportunity is deleted.');

        undelete opportunities;

        List<Allocation__c> undeletedAllocations = CDL_CascadeDeleteLookups_TEST.getNonDeletedAllocations();
        System.assertEquals(deletedAllocations.size(), undeletedAllocations.size(), 'Allocations should be cascade undeleted when the Opportunity is deleted.');
    }
}