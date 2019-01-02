/*
    Copyright (c) 2018, Salesforce.org
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
* @date 2018
* @group Cascade Delete
* @description Tests for cascade delete of Payments
*/
@isTest
private class PMT_CascadeDeleteLookups_TEST {

    /*********************************************************************************************************
    * @description Deletes the Opportunities which deletes the related Allocations. 
    * Then undeletes the Opportunities, which undeletes the Allocations.
    * Verifies results: All the Allocations should be deleted after the Opportunities are deleted.
    * Then the Allocations will be undeleted after the Opportunities are undeleted.
    */
    static testMethod void testPaymentCascade() {
        General_Accounting_Unit__c defaultAccountingUnit = 
          new General_Accounting_Unit__c(Name = 'DEFAULT_GAU');
        insert defaultAccountingUnit;
        
        // Setup Default GAU and Payment allocations
        Allocations_Settings__c alloSettings = UTIL_CustomSettingsFacade.getOrgAllocationsSettings();
        alloSettings.Default__c = defaultAccountingUnit.Id;
        alloSettings.Default_Allocations_Enabled__c = true;
        alloSettings.Payment_Allocations_Enabled__c = true;
        UTIL_CustomSettingsFacade.getAllocationsSettingsForTests(alloSettings);

        Integer maxRecords = 2;

        List<Account> accounts = CDL_CascadeDeleteLookups_TEST.buildAccounts(maxRecords);
        insert accounts;

        List<Opportunity> opportunities = CDL_CascadeDeleteLookups_TEST.buildOpportunities(accounts);
        opportunities[0].StageName = UTIL_UnitTestData_TEST.getClosedWonStage();
        opportunities[1].StageName = UTIL_UnitTestData_TEST.getClosedWonStage();
        insert opportunities;

        List<npe01__OppPayment__c> payments = [SELECT Id FROM npe01__OppPayment__c WHERE IsDeleted = false];
        System.assertEquals(maxRecords, payments.size(), 'A Payment should have been created for each Closed Won Opportunity');

        List<Allocation__c> paymentAllocations = [SELECT Id FROM Allocation__c WHERE Payment__c != null AND IsDeleted = false];
        System.assertEquals(maxRecords, paymentAllocations.size(), 'Each Payment should have the same Allocation ratio as its Opportunity');

        Set<Id> allocationIds = new Set<Id>();
        for(Allocation__c allo : paymentAllocations){
          allocationIds.add(allo.Id);
        }

        Test.startTest();
        delete payments;
        Test.stopTest();

        List<Allocation__c> deletedAllocations = [SELECT Id FROM Allocation__c WHERE Id in :allocationIds AND IsDeleted = true ALL ROWS];
        System.assertEquals(paymentAllocations.size(), deletedAllocations.size(), 'Allocations should be cascade deleted when the Payment is deleted.');

        undelete payments;

        List<Allocation__c> undeletedAllocations = CDL_CascadeDeleteLookups_TEST.getNonDeletedAllocations();
        System.assertEquals(maxRecords*2, undeletedAllocations.size(), 'Allocations should be cascade undeleted when the Payment is undeleted.');
    }
}