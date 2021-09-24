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
@isTest(IsParallel=false)
private class CRLP_ResetRollupFieldsQueueable_TEST {

    @IsTest
    private static void shouldClearGAUTotalsWhenRecordIdIsUnhandled() {
        Integer amount = 90;
        Integer count = 1;

        General_Accounting_Unit__c gau =
            new General_Accounting_Unit__c(Total_Allocations__c = amount, Total_Number_of_Allocations__c = count);
        insert gau;

        mockRollupCMTValues();

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
        Integer amount = 90;
        Integer count = 1;

        General_Accounting_Unit__c gau =
            new General_Accounting_Unit__c(Total_Allocations__c = amount, Total_Number_of_Allocations__c = count);
        insert gau;

        mockRollupCMTValues();

        CRLP_GAU_BATCH gauBatch = new CRLP_GAU_BATCH(new List<Id>{gau.Id}, null);
        gauBatch.handledParentRecordIds.addAll(gauBatch.recordIds);

        Test.startTest();
        gauBatch.clearUnhandledRollupTotals();
        Test.stopTest();

        List<General_Accounting_Unit__c> generalAccountingUnits =
        [SELECT Id, Total_Allocations__c, Total_Number_of_Allocations__c FROM General_Accounting_Unit__c];

        System.assertEquals(amount, generalAccountingUnits[0].Total_Allocations__c,
            'Total Allocations should retain previous value');
        System.assertEquals(count, generalAccountingUnits[0].Total_Number_of_Allocations__c,
            'Total Number of Allocations should retain previous value');
    }

    @IsTest
    private static void shouldClearSkewModeFlagForContact() {
        List<Contact> contacts = new List<Contact>{new Contact(CustomizableRollups_UseSkewMode__c = true)};

        CRLP_ResetRollupFieldsQueueable resetQueueable =
            new CRLP_ResetRollupFieldsQueueable(CRLP_RollupProcessingOptions.RollupType.ContactHardCredit, null);
        List<Contact> updatedContacts = resetQueueable.clearSkewModeFlag(contacts);

        System.assertEquals(false, updatedContacts[0].CustomizableRollups_UseSkewMode__c,
            'Customizable Rollups Use Skew Mode flag should be set false');
    }

    @IsTest
    private static void shouldNotChangeSkewModeFlagForContact() {
        List<Contact> contacts = new List<Contact>{new Contact(CustomizableRollups_UseSkewMode__c = false)};

        CRLP_ResetRollupFieldsQueueable resetQueueable =
            new CRLP_ResetRollupFieldsQueueable(CRLP_RollupProcessingOptions.RollupType.ContactHardCredit, null);
        List<Contact> updatedContacts = resetQueueable.clearSkewModeFlag(contacts);

        System.assertEquals(false, updatedContacts[0].CustomizableRollups_UseSkewMode__c,
            'Customizable Rollups Use Skew Mode flag should remain false');
    }

    @IsTest
    private static void shouldClearSkewModeFlagForAccount() {
        List<Account> accounts = new List<Account>{new Account(CustomizableRollups_UseSkewMode__c = true)};

        CRLP_ResetRollupFieldsQueueable resetQueueable =
            new CRLP_ResetRollupFieldsQueueable(CRLP_RollupProcessingOptions.RollupType.AccountHardCredit, null);
        List<Account> updatedAccounts = resetQueueable.clearSkewModeFlag(accounts);

        System.assertEquals(false, updatedAccounts[0].CustomizableRollups_UseSkewMode__c,
            'Customizable Rollups Use Skew Mode flag should be set false');
    }

    @IsTest
    private static void shouldNotChangeSkewModeFlagForAccount() {
        List<Account> accounts = new List<Account>{new Account(CustomizableRollups_UseSkewMode__c = false)};

        CRLP_ResetRollupFieldsQueueable resetQueueable =
            new CRLP_ResetRollupFieldsQueueable(CRLP_RollupProcessingOptions.RollupType.AccountHardCredit, null);
        List<Account> updatedAccounts = resetQueueable.clearSkewModeFlag(accounts);

        System.assertEquals(false, updatedAccounts[0].CustomizableRollups_UseSkewMode__c,
            'Customizable Rollups Use Skew Mode flag should remain false');
    }

    /**
     * @description Create Rollup__mdt records to test rolling up from the Opp and Payment objects to the Account
     */
    private static void mockRollupCMTValues() {

        // Create a single Filter Group (no need for filter rules here)
        String filterGroupId1 = CMT_UnitTestData_TEST.getNewRecordId();
        String filterGroupId2 = CMT_UnitTestData_TEST.getNewRecordId();

        // Extremely simple Filter Rule for IsWon only
        String filterGroupsJSON = '[' +
            CMT_UnitTestData_TEST.createFilterGroupRecord(filterGroupId1, 'TestFilterGroup1-IsWon+Paid') + ',' +
            CMT_UnitTestData_TEST.createFilterGroupRecord(filterGroupId2, 'TestFilterGroup2-IsWon+WrittenOff') +
            ']';
        String filterRulesJSON = '[' +
            CMT_UnitTestData_TEST.createFilterRuleRecord(null, filterGroupId1, 'Group1.Rule1', 'Opportunity', 'IsWon', 'Equals', 'True') + ',' +
            CMT_UnitTestData_TEST.createFilterRuleRecord(null, filterGroupId1, 'Group1.Rule2', 'npe01__OppPayment__c', 'npe01__Paid__c', 'Equals', 'True') + ',' +
            CMT_UnitTestData_TEST.createFilterRuleRecord(null, filterGroupId2, 'Group2.Rule1', 'Opportunity', 'IsWon', 'Equals', 'True') + ',' +
            CMT_UnitTestData_TEST.createFilterRuleRecord(null, filterGroupId2, 'Group2.Rule2', 'npe01__OppPayment__c', 'npe01__Written_Off__c', 'Equals', 'True') +
            ']';

        // Deserialize the filter group and filter rule to use for the tests
        CMT_FilterRule_SEL.cachedFilterGroups = (List<Filter_Group__mdt>)JSON.deserialize(filterGroupsJSON, List<Filter_Group__mdt>.class);
        CMT_FilterRule_SEL.cachedFilterRules = (List<Filter_Rule__mdt>)JSON.deserialize(filterRulesJSON, List<Filter_Rule__mdt>.class);

        // Create a single Rollup that uses the above Filter Group
        String rollupsJSON = '[' +
            CMT_UnitTestData_TEST.createRollupRecord('Total Allocations All Time', filterGroupId1,
                CMT_UnitTestData_TEST.RollupRecordType.GAU,
                'Total_Allocations__c', CRLP_Operation.RollupType.Sum, 'Amount__c',
                CRLP_Operation.TimeBoundOperationType.All_Time, 0) + ',' +

            CMT_UnitTestData_TEST.createRollupRecord('Count Donations All Year', filterGroupId1,
                CMT_UnitTestData_TEST.RollupRecordType.GAU,
                'Total_Number_of_Allocations__c', CRLP_Operation.RollupType.Count, 'Amount__c') +
            ']';

        CRLP_Rollup_SEL.cachedRollups = (List<Rollup__mdt>) JSON.deserialize(rollupsJSON, List<Rollup__mdt>.class);
    }
}