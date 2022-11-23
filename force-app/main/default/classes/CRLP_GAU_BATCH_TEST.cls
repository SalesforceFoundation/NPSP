/*
    Copyright (c) 2021, Salesforce.org
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
* @group Customizable Rollups Operations Services
* @description Unit Tests for the GAU Batch class
*/
@IsTest(IsParallel=true)
private with sharing class CRLP_GAU_BATCH_TEST {

    @IsTest
    private static void shouldDetermineLastParentIdHasNoDetails() {
        String parentKeyField = 'General_Accounting_Unit__c';

        General_Accounting_Unit__c gau = new General_Accounting_Unit__c(
            Id = UTIL_UnitTestData_TEST.mockId(General_Accounting_Unit__c.SObjectType));
        General_Accounting_Unit__c gau2 = new General_Accounting_Unit__c(
            Id = UTIL_UnitTestData_TEST.mockId(General_Accounting_Unit__c.SObjectType));

        List<Allocation__c> detailRecords = new List<Allocation__c> {
            new Allocation__c(
                Id = UTIL_UnitTestData_TEST.mockId(Allocation__c.SObjectType),
                General_Accounting_Unit__c = gau.Id,
                General_Accounting_Unit__r = gau)
        };

        CRLP_GAU_BATCH gauBatch = new CRLP_GAU_BATCH(CRLP_RollupProcessingOptions.RollupTypeFilter.All);
        Id lastParentId = gau2.Id;
        System.assertEquals(false,
            gauBatch.hasLastParentDetails(lastParentId, null, detailRecords, parentKeyField));
    }
    
    @IsTest
    private static void shouldDetermineLastParentIdHasNoDetailsEmptyDetailRecords() {
        String parentKeyField = 'General_Accounting_Unit__c';

        General_Accounting_Unit__c gau = new General_Accounting_Unit__c(
            Id = UTIL_UnitTestData_TEST.mockId(General_Accounting_Unit__c.SObjectType));
        General_Accounting_Unit__c gau2 = new General_Accounting_Unit__c(
            Id = UTIL_UnitTestData_TEST.mockId(General_Accounting_Unit__c.SObjectType));

        List<Allocation__c> detailRecords = new List<Allocation__c>();

        CRLP_GAU_BATCH gauBatch = new CRLP_GAU_BATCH(CRLP_RollupProcessingOptions.RollupTypeFilter.All);
        Id lastParentId = gau2.Id;
        System.assertEquals(false,
            gauBatch.hasLastParentDetails(lastParentId, null, detailRecords, parentKeyField));
    }

    @IsTest
    private static void shouldDetermineLastParentIdHasDetails() {
        String parentKeyField = 'General_Accounting_Unit__c';

        General_Accounting_Unit__c gau = new General_Accounting_Unit__c(
            Id = UTIL_UnitTestData_TEST.mockId(General_Accounting_Unit__c.SObjectType));
        General_Accounting_Unit__c gau2 = new General_Accounting_Unit__c(
            Id = UTIL_UnitTestData_TEST.mockId(General_Accounting_Unit__c.SObjectType));

        List<Allocation__c> detailRecords = new List<Allocation__c> {
            new Allocation__c(
                Id = UTIL_UnitTestData_TEST.mockId(Allocation__c.SObjectType),
                General_Accounting_Unit__c = gau.Id,
                General_Accounting_Unit__r = gau),
            new Allocation__c(
                Id = UTIL_UnitTestData_TEST.mockId(Allocation__c.SObjectType),
                General_Accounting_Unit__c = gau2.Id,
                General_Accounting_Unit__r = gau2)
        };

        CRLP_GAU_BATCH gauBatch = new CRLP_GAU_BATCH();
        Id lastParentId = gau2.Id;
        System.assertEquals(true,
            gauBatch.hasLastParentDetails(lastParentId, null, detailRecords, parentKeyField));
    }
}