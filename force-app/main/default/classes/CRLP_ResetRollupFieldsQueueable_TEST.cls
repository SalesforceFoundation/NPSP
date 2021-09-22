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
* @group Rollups
* @group-content ../../ApexDocContent/Rollups2.htm
* @description Tests for queueable job to clear rollup values for records with no associated details
* which have been previously calculated in skew mode.
*/
@isTest(IsParallel=true)
private class CRLP_ResetRollupFieldsQueueable_TEST {

    @IsTest
    private static void shouldClearGAUTotalsWhenRecordIdIsUnhandled() {
        General_Accounting_Unit__c gau =
            new General_Accounting_Unit__c(Total_Allocations__c = 90, Total_Number_of_Allocations__c = 1);
        insert gau;

        CRLP_GAU_BATCH gauBatch = new CRLP_GAU_BATCH(new List<Id>{gau.Id}, null);

        Test.startTest();
        gauBatch.clearUnhandledRollupTotals();
        Test.stopTest();

        List<General_Accounting_Unit__c> generalAccountingUnits =
            [SELECT Id, Total_Allocations__c, Total_Number_of_Allocations__c FROM General_Accounting_Unit__c];

        System.assertEquals(0, generalAccountingUnits[0].Total_Allocations__c,
            'Total Allocations should be reset to 0');
        System.assertEquals(0, generalAccountingUnits[0].Total_Number_of_Allocations__c,
            'Total Number of Allocations should be reset to 0');
    }

    @IsTest
    private static void shouldNotClearGAUTotalsWhenRecordIdIsHandled() {
        General_Accounting_Unit__c gau =
            new General_Accounting_Unit__c(Total_Allocations__c = 90, Total_Number_of_Allocations__c = 1);
        insert gau;

        CRLP_GAU_BATCH gauBatch = new CRLP_GAU_BATCH(new List<Id>{gau.Id}, null);
        gauBatch.handledParentRecordIds.addAll(gauBatch.recordIds);

        Test.startTest();
        gauBatch.clearUnhandledRollupTotals();
        Test.stopTest();

        List<General_Accounting_Unit__c> generalAccountingUnits =
        [SELECT Id, Total_Allocations__c, Total_Number_of_Allocations__c FROM General_Accounting_Unit__c];

        System.assertNotEquals(0, generalAccountingUnits[0].Total_Allocations__c,
            'Total Allocations should not be reset to 0');
        System.assertNotEquals(0, generalAccountingUnits[0].Total_Number_of_Allocations__c,
            'Total Number of Allocations should not be reset to 0');
    }
}