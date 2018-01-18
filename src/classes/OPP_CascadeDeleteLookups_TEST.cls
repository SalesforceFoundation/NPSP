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
        Integer maxRecords = 200;

        List<Account> testAccounts = CDL_CascadeDeleteLookups_TEST.createAccounts(maxRecords);
        insert testAccounts;

        List<Opportunity> testOpportunities = CDL_CascadeDeleteLookups_TEST.createOpportunities(testAccounts);
        insert testOpportunities;

        General_Accounting_Unit__c testGAU = new General_Accounting_Unit__c(Name = 'TEST_GAU');
        insert testGAU;
        List<Allocation__c> testAllocations = new List<Allocation__c>();
        testAllocations.addAll(CDL_CascadeDeleteLookups_TEST.createOpportunityAllocations(testGAU, testOpportunities));
        insert testAllocations;

        Test.startTest();
        delete testOpportunities;
        Test.stopTest();

        List<Allocation__c> deletedAllocations = [
            SELECT Id 
            FROM Allocation__c
            WHERE IsDeleted = true 
            ALL ROWS
        ];
        System.assertEquals(testAllocations.size(), deletedAllocations.size(), 'Allocations should be cascade deleted when opportunities are deleted.');

        undelete testOpportunities;

        List<Allocation__c> undeletedAllocations = [
            SELECT Id 
            FROM Allocation__c 
            WHERE IsDeleted = false
        ];
        System.assertEquals(deletedAllocations.size(), undeletedAllocations.size(), 'Allocations should be cascade undeleted.');
    }
}