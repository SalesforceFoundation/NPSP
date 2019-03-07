/*
    Copyright (c) 2019, Salesforce.org
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
* @date 2019
* @group API
* @description Unit Tests for the Customizable Rollups Api Service class
*/
@IsTest(IsParallel=true)
private class CRLP_ApiService_TEST {

    /**
     * @description Validate the getRollupDefsForRollupType returns the expected collection of CRLP_Rollup instances
     */
    @IsTest
    static void validateGetRollupDefsForRollupTypeReturnValues() {
        // Call the mocking utilities to build a bunch of rollup definitions and filter groups/rules fo
        mockRollupDefinitions();

        CRLP_ApiService crlpApiSvc = new CRLP_ApiService();

        Test.startTest();

        // These first three have mocked CMT's for rollup definitions
        List<CRLP_Rollup> rollups = crlpApiSvc.getRollupDefsForRollupType(CRLP_RollupProcessingOptions.RollupType.AccountHardCredit.name());
        System.assertEquals(1, rollups.size(), 'The collection of returned rollups should contain exactly 1 instance for AccountHardCredit');
        System.assertEquals(2, rollups[0].rollupsMdt.size(), 'There should be two Rollup__mdt records associated with the CRLP_Rollup instance');

        rollups = crlpApiSvc.getRollupDefsForRollupType(CRLP_RollupProcessingOptions.RollupType.ContactHardCredit.name());
        System.assertEquals(1, rollups.size(), 'The collection of returned rollups should contain exactly 1 instance for ContactHardCredit');
        System.assertEquals(2, rollups[0].rollupsMdt.size(), 'There should be two Rollup__mdt records associated with the CRLP_Rollup instance');

        rollups = crlpApiSvc.getRollupDefsForRollupType(CRLP_RollupProcessingOptions.RollupType.AccountSoftCredit.name());
        System.assertEquals(1, rollups.size(), 'The collection of returned rollups should contain exactly 1 instance for AccountSoftCredit');
        System.assertEquals(2, rollups[0].rollupsMdt.size(), 'There should be two Rollup__mdt records associated with the CRLP_Rollup instance');

        rollups = crlpApiSvc.getRollupDefsForRollupType(CRLP_RollupProcessingOptions.RollupType.AccountContactSoftCredit.name());
        System.assertEquals(1, rollups.size(), 'The collection of returned rollups should contain exactly 1 instance for AccountContactSoftCredit');
        System.assertEquals(2, rollups[0].rollupsMdt.size(), 'There should be two Rollup__mdt records associated with the CRLP_Rollup instance');

        rollups = crlpApiSvc.getRollupDefsForRollupType(CRLP_RollupProcessingOptions.RollupType.ContactSoftCredit.name());
        System.assertEquals(1, rollups.size(), 'The collection of returned rollups should contain exactly 1 instance for ContactSoftCredit');
        System.assertEquals(2, rollups[0].rollupsMdt.size(), 'There should be two Rollup__mdt records associated with the CRLP_Rollup instance');

        rollups = crlpApiSvc.getRollupDefsForRollupType(CRLP_RollupProcessingOptions.RollupType.RecurringDonations.name());
        System.assertEquals(1, rollups.size(), 'The collection of returned rollups should contain exactly 1 instance for RecurringDonations');
        System.assertEquals(2, rollups[0].rollupsMdt.size(), 'There should be two Rollup__mdt records associated with the CRLP_Rollup instance');

        rollups = crlpApiSvc.getRollupDefsForRollupType(CRLP_RollupProcessingOptions.RollupType.GAU.name());
        System.assertEquals(1, rollups.size(), 'The collection of returned rollups should contain exactly 1 instance for GAU');
        System.assertEquals(2, rollups[0].rollupsMdt.size(), 'There should be two Rollup__mdt records associated with the CRLP_Rollup instance');
    }

    /**
     * @description Validate the getRollupDefsForRollupType returns an exception if the RollupType is null or invalid
     */
    @IsTest
    static void validateGetRollupDefsForRollupTypeInvalidParameter() {
        CRLP_ApiService crlpApiSvc = new CRLP_ApiService();

        Test.startTest();
        try {
            crlpApiSvc.getRollupDefsForRollupType('NonExistentType');
            System.assert(false, 'This call should have failed due to an invalid parameter!');
        } catch (Exception ex) {
            System.assert(ex.getMessage().containsIgnoreCase('parameter'), 'The error should contain the word "parameter": ' + ex.getMessage());
        }

        try {
            crlpApiSvc.getRollupDefsForRollupType(null);
            System.assert(false, 'This call should have failed due to an invalid parameter!');
        } catch (Exception ex) {
            System.assert(ex.getMessage().containsIgnoreCase('parameter'), 'The error should contain the word "parameter": ' + ex.getMessage());
        }
    }

    /**
     * @description Mock the Rollup__mdt records for use within this unit test class
     */
    static void mockRollupDefinitions() {

        String filterGroupId1 = CMT_UnitTestData_TEST.getNewRecordId();

        // Create two Rollup Definition per Rollup Type that will be grouped into a single CRLP_Rollup instance.
        // The FilterGroup itself doesn't need to exist for this test, but an Id is needed.
        String rollupsJSON = '[' +

                // Contact Hard Credit
                CMT_UnitTestData_TEST.createRollupRecord('Total Donations All Time', filterGroupId1,
                        CMT_UnitTestData_TEST.RollupRecordType.OppToContact,
                        'npo02__TotalOppAmount__c', CRLP_Operation.RollupType.Sum, 'Amount') + ',' +

                CMT_UnitTestData_TEST.createRollupRecord('Count Donations All Year', filterGroupId1,
                        CMT_UnitTestData_TEST.RollupRecordType.OppToContact,
                        'npo02__NumberOfClosedOpps__c', CRLP_Operation.RollupType.Count, 'Amount') + ',' +

                // Account Hard Credit
                CMT_UnitTestData_TEST.createRollupRecord('Total Donations All Time', filterGroupId1,
                        CMT_UnitTestData_TEST.RollupRecordType.OppToAcct,
                        'npo02__TotalOppAmount__c', CRLP_Operation.RollupType.Sum, 'Amount') + ',' +

                CMT_UnitTestData_TEST.createRollupRecord('Count Donations All Year', filterGroupId1,
                        CMT_UnitTestData_TEST.RollupRecordType.OppToAcct,
                        'npo02__NumberOfClosedOpps__c', CRLP_Operation.RollupType.Count, 'Amount') + ',' +

                // Account Contact Soft Credit
                CMT_UnitTestData_TEST.createRollupRecord('Account: Soft Credits - Total', filterGroupId1,
                        CMT_UnitTestData_TEST.RollupRecordType.ContactSoftCreditToAccount,
                        'npo02__TotalOppAmount__c', CRLP_Operation.RollupType.Sum, 'Amount__c') + ',' +

                CMT_UnitTestData_TEST.createRollupRecord('Count Donations All Year', filterGroupId1,
                        CMT_UnitTestData_TEST.RollupRecordType.ContactSoftCreditToAccount,
                        'npo02__NumberOfClosedOpps__c', CRLP_Operation.RollupType.Count, 'Amount') + ',' +

                // Account Soft Credit
                CMT_UnitTestData_TEST.createRollupRecord('Total Account Soft Credits', filterGroupId1,
                        CMT_UnitTestData_TEST.RollupRecordType.AccountSoftCreditToAccount, 'Matching_Gift_Amount_Max__c',
                        CRLP_Operation.RollupType.Sum, 'Amount__c') + ',' +

                CMT_UnitTestData_TEST.createRollupRecord('Count Donations All Year', filterGroupId1,
                        CMT_UnitTestData_TEST.RollupRecordType.AccountSoftCreditToAccount,
                        'npo02__NumberOfClosedOpps__c', CRLP_Operation.RollupType.Count, 'Amount') + ',' +

                // Contact Soft Credit
                CMT_UnitTestData_TEST.createRollupRecord('Contact: Soft Credits - Total', filterGroupId1,
                        CMT_UnitTestData_TEST.RollupRecordType.SoftCreditToContact,
                        'npo02__Soft_Credit_Total__c', CRLP_Operation.RollupType.Sum, 'Amount__c') + ',' +

                CMT_UnitTestData_TEST.createRollupRecord('Count Donations All Year', filterGroupId1,
                        CMT_UnitTestData_TEST.RollupRecordType.SoftCreditToContact,
                        'npo02__NumberOfClosedOpps__c', CRLP_Operation.RollupType.Count, 'Amount') + ',' +

                // GAU
                CMT_UnitTestData_TEST.createRollupRecord('Total Allocations All Time', filterGroupId1,
                        CMT_UnitTestData_TEST.RollupRecordType.GAU,
                        'Total_Allocations__c', CRLP_Operation.RollupType.Sum, 'Amount__c',
                        CRLP_Operation.TimeBoundOperationType.All_Time, 0) + ',' +

                CMT_UnitTestData_TEST.createRollupRecord('Count Donations All Year', filterGroupId1,
                        CMT_UnitTestData_TEST.RollupRecordType.GAU,
                        'Total_Number_of_Allocations__c', CRLP_Operation.RollupType.Count, 'Amount') + ',' +

                // Recurring Donations
                CMT_UnitTestData_TEST.createRollupRecord('RD Next Payment Date', filterGroupId1,
                        CMT_UnitTestData_TEST.RollupRecordType.OppToRD,
                        'npe03__Next_Payment_Date__c', CRLP_Operation.RollupType.First, 'CloseDate') + ',' +

                CMT_UnitTestData_TEST.createRollupRecord('Count Donations All Year', filterGroupId1,
                        CMT_UnitTestData_TEST.RollupRecordType.OppToRD,
                        'npe03__Total_Paid_Installments__c', CRLP_Operation.RollupType.Count, 'Amount') +

                ']';

        // Deserialize the rollups to use for testing
        CRLP_Rollup_SEL.cachedRollups = (List<Rollup__mdt>) JSON.deserialize(rollupsJSON, List<Rollup__mdt>.class);

    }
}