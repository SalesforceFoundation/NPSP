/*
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
* @group Customizable Rollups Operations Services
* @description Unit Test for the Query Builder Class
*/
@IsTest(IsParallel=True)
private class CRLP_RollupQueryBuilder_TEST {

    static final List<Id> accountIds = UTIL_UnitTestData_TEST.mockIds(Account.SObjectType, 3);
    static final List<Id> contactIds = UTIL_UnitTestData_TEST.mockIds(Contact.SObjectType, 3);
    static final List<Id> rdIds = UTIL_UnitTestData_TEST.mockIds(npe03__Recurring_Donation__c.SObjectType, 3);

    @IsTest
    private static void shouldReturnQueryForSummaryRecordListAccountHardCredit() {
        assertQueryBuildResults(CRLP_RollupProcessingOptions.RollupType.AccountHardCredit);
    }

    @IsTest
    private static void shouldReturnQueryForSummaryRecordIdsAccountSoftCredit() {
        assertQueryBuildResults(CRLP_RollupProcessingOptions.RollupType.AccountSoftCredit);
    }

    @IsTest
    private static void shouldReturnQueryForSummaryRecordIdsAccountContactSoftCredit() {
        assertQueryBuildResults(CRLP_RollupProcessingOptions.RollupType.AccountContactSoftCredit);
    }

    @IsTest
    private static void shouldReturnQueryForSummaryRecordListContactHardCredit() {
        assertQueryBuildResults(CRLP_RollupProcessingOptions.RollupType.ContactHardCredit);
    }

    @IsTest
    private static void shouldReturnQueryForSummaryRecordListContactSoftCredit() {
        assertQueryBuildResults(CRLP_RollupProcessingOptions.RollupType.ContactSoftCredit);
    }

    @IsTest
    private static void shouldReturnQueryForSummaryRecordListRD() {
        assertQueryBuildResults(CRLP_RollupProcessingOptions.RollupType.RecurringDonations);
    }

    private static String assertQueryBuildResults(CRLP_RollupProcessingOptions.RollupType rollupType) {
        String detailObject = CRLP_Rollup_SVC.getDetailObjectType(rollupType).getDescribe().getName();
        String orderBy = CRLP_Rollup_SVC.getParentFieldNameForQuery(rollupType);
        SObjectType summaryObjectType = CRLP_Rollup_SVC.getSummaryObjectType(rollupType);
        Boolean includePayments = false;
        Boolean useWithSummaryRecordIds = false;
        String varName = summaryObjectType.getDescribe().getName() + 'Ids';

        switch on (rollupType) {
            when AccountHardCredit, ContactHardCredit {
                includePayments = false;
            }
            when RecurringDonations {
                varName = 'rdIds';
            }
            when AccountSoftCredit {
                useWithSummaryRecordIds = true;
            }
        }

        List<SObject> summaryRecords = setupTestingData(summaryObjectType);

        Test.startTest();

        CRLP_RollupQueryBuilder queryBuilder = new CRLP_RollupQueryBuilder()
            .withRollupType(rollupType)
            .withSummaryRecordIdsVar(varName)
            .withOrderBy(orderBy);

        if (useWithSummaryRecordIds) {
            queryBuilder.withSummaryRecordIds(new Set<Id>(accountIds));
        } else {
            queryBuilder.withSummaryRecords(summaryRecords);
        }

        if (includePayments) {
            queryBuilder.includePaymentRecords();
        }

        String detailsQuery = queryBuilder.buildDetailsQuery();
        System.assert(detailsQuery.containsIgnoreCase('FROM ' + detailObject),
                'The query should query the expected "' + detailObject + '" object: ' + detailsQuery);
        System.assert(detailsQuery.containsIgnoreCase(varName),
                'The query should include the referenced "' + varName + '" var: ' + detailsQuery);
        System.assert(detailsQuery.containsIgnoreCase('ORDER BY ' + orderBy),
                'The query should include the specified Order By: ' + detailsQuery);
        if (includePayments) {
            System.assert(detailsQuery.containsIgnoreCase(' FROM npe01__OppPayment__r'),
                    'The query should include a child query on Payments: ' + detailsQuery);

        }

        List<SObject> detailRecords = Database.query(detailsQuery);
        System.assert(true, 'The query should have succeeded: ' + detailsQuery);

        return detailsQuery;
    }


    // **************************** HELPER METHODS ****************************

    /**
     * @description Mock a set of rollup definitions for each rollup type and intantiate a set of
     * Account SObjects to use for testing
     * @return List<SObject> - mocked Account SObject records
     */
    private static List<SObject> setupTestingData(SObjectType objType) {
        UTIL_CustomSettingsFacade.getRollupSettingsForTests(new Customizable_Rollup_Settings__c (
                Customizable_Rollups_Enabled__c = true
        ));
        mockRollupDefinitions();

        List<SObject> summaryRecords;
        if (objType == Account.SObjectType) {
            summaryRecords = new List<SObject>{
                new Account(Id = accountIds[0], Name = 'Account 1'),
                new Account(Id = accountIds[0], Name = 'Account 2'),
                new Account(Id = accountIds[0], Name = 'Account 3')
            };

        } else if (objType == Contact.SObjectType) {
            summaryRecords = new List<SObject>{
                    new Contact(Id = contactIds[0], LastName = 'LastName 1'),
                    new Contact(Id = contactIds[0], LastName = 'LastName 2'),
                    new Contact(Id = contactIds[0], LastName = 'LastName 3')
            };

        } else if (objType == npe03__Recurring_Donation__c.SObjectType) {
            summaryRecords = new List<SObject>{
                    new npe03__Recurring_Donation__c(Id = rdIds[0], Name = 'GAU 1'),
                    new npe03__Recurring_Donation__c(Id = rdIds[0], Name = 'GAU 2'),
                    new npe03__Recurring_Donation__c(Id = rdIds[0], Name = 'GAU 3')
            };

        }

        return summaryRecords;
    }

    /**
     * @description Mock the Rollup__mdt records for use within this unit test class
     */
    private static void mockRollupDefinitions() {

        String filterGroupId = null;

        // Create two Rollup Definition per Rollup Type that will be grouped into a single CRLP_Rollup instance.
        // The FilterGroup itself doesn't need to exist for this test
        String rollupsJSON = '[' +

                // Contact Hard Credit
                CMT_UnitTestData_TEST.createRollupRecord('Total Donations All Time', filterGroupId,
                        CMT_UnitTestData_TEST.RollupRecordType.OppToContact,
                        'npo02__TotalOppAmount__c', CRLP_Operation.RollupType.Sum, 'Amount') + ',' +

                CMT_UnitTestData_TEST.createRollupRecord('Count Donations All Year', filterGroupId,
                        CMT_UnitTestData_TEST.RollupRecordType.OppToContact,
                        'npo02__NumberOfClosedOpps__c', CRLP_Operation.RollupType.Count, 'Amount') + ',' +

                // Account Hard Credit
                CMT_UnitTestData_TEST.createRollupRecord('Total Donations All Time', filterGroupId,
                        CMT_UnitTestData_TEST.RollupRecordType.OppToAcct,
                        'npo02__TotalOppAmount__c', CRLP_Operation.RollupType.Sum, 'Amount') + ',' +

                CMT_UnitTestData_TEST.createRollupRecord('Count Donations All Year', filterGroupId,
                        CMT_UnitTestData_TEST.RollupRecordType.OppToAcct,
                        'npo02__NumberOfClosedOpps__c', CRLP_Operation.RollupType.Count, 'Amount') + ',' +

                // Account Contact Soft Credit
                CMT_UnitTestData_TEST.createRollupRecord('Account: Soft Credits - Total', filterGroupId,
                        CMT_UnitTestData_TEST.RollupRecordType.ContactSoftCreditToAccount,
                        'npo02__TotalOppAmount__c', CRLP_Operation.RollupType.Sum, 'Amount__c') + ',' +

                CMT_UnitTestData_TEST.createRollupRecord('Count Donations All Year', filterGroupId,
                        CMT_UnitTestData_TEST.RollupRecordType.ContactSoftCreditToAccount,
                        'npo02__NumberOfClosedOpps__c', CRLP_Operation.RollupType.Count, 'Amount') + ',' +

                // Account Soft Credit
                CMT_UnitTestData_TEST.createRollupRecord('Total Account Soft Credits', filterGroupId,
                        CMT_UnitTestData_TEST.RollupRecordType.AccountSoftCreditToAccount, 'Matching_Gift_Amount_Max__c',
                        CRLP_Operation.RollupType.Sum, 'Amount__c') + ',' +

                CMT_UnitTestData_TEST.createRollupRecord('Count Donations All Year', filterGroupId,
                        CMT_UnitTestData_TEST.RollupRecordType.AccountSoftCreditToAccount,
                        'npo02__NumberOfClosedOpps__c', CRLP_Operation.RollupType.Count, 'Amount') + ',' +

                // Contact Soft Credit
                CMT_UnitTestData_TEST.createRollupRecord('Contact: Soft Credits - Total', filterGroupId,
                        CMT_UnitTestData_TEST.RollupRecordType.SoftCreditToContact,
                        'npo02__Soft_Credit_Total__c', CRLP_Operation.RollupType.Sum, 'Amount__c') + ',' +

                CMT_UnitTestData_TEST.createRollupRecord('Count Donations All Year', filterGroupId,
                        CMT_UnitTestData_TEST.RollupRecordType.SoftCreditToContact,
                        'npo02__NumberOfClosedOpps__c', CRLP_Operation.RollupType.Count, 'Amount') + ',' +

                // GAU
                CMT_UnitTestData_TEST.createRollupRecord('Total Allocations All Time', filterGroupId,
                        CMT_UnitTestData_TEST.RollupRecordType.GAU,
                        'Total_Allocations__c', CRLP_Operation.RollupType.Sum, 'Amount__c',
                        CRLP_Operation.TimeBoundOperationType.All_Time, 0) + ',' +

                CMT_UnitTestData_TEST.createRollupRecord('Count Donations All Year', filterGroupId,
                        CMT_UnitTestData_TEST.RollupRecordType.GAU,
                        'Total_Number_of_Allocations__c', CRLP_Operation.RollupType.Count, 'Amount') + ',' +

                // Recurring Donations
                CMT_UnitTestData_TEST.createRollupRecord('RD Next Payment Date', filterGroupId,
                        CMT_UnitTestData_TEST.RollupRecordType.OppToRD,
                        'npe03__Next_Payment_Date__c', CRLP_Operation.RollupType.First, 'CloseDate') + ',' +

                CMT_UnitTestData_TEST.createRollupRecord('Count Donations All Year', filterGroupId,
                        CMT_UnitTestData_TEST.RollupRecordType.OppToRD,
                        'npe03__Total_Paid_Installments__c', CRLP_Operation.RollupType.Count, 'Amount') +

                ']';

        // Deserialize the rollups to use for testing
        CRLP_Rollup_SEL.cachedRollups = (List<Rollup__mdt>) JSON.deserialize(rollupsJSON, List<Rollup__mdt>.class);
        // Clear any cached collections as well
        CRLP_Rollup_SEL.rollupsBySummaryType = null;
        CRLP_Rollup_SEL.rollupsByDetailType = null;
        CRLP_Rollup_SEL.rollupsByFilterGroup = null;
    }
}