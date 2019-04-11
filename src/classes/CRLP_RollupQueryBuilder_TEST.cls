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
* @description Unit Tests for the Query Builder Class
*/
@IsTest(IsParallel=true)
private class CRLP_RollupQueryBuilder_TEST {

    static final List<Id> accountIds = UTIL_UnitTestData_TEST.mockIds(Account.SObjectType, 3);
    static final List<Id> contactIds = UTIL_UnitTestData_TEST.mockIds(Contact.SObjectType, 3);
    static final List<Id> rdIds = UTIL_UnitTestData_TEST.mockIds(npe03__Recurring_Donation__c.SObjectType, 3);

    /** @description Test the Details Query Builder for an AccountHardCredit NonSkew rollup */
    @IsTest
    private static void shouldReturnQueryForSummaryRecordListAccountHardCredit() {
        assertQueryBuildResults(CRLP_RollupProcessingOptions.RollupType.AccountHardCredit);
    }

    /** @description Test the Details Query Builder for an AccountSoftCredit NonSkew rollup */
    @IsTest
    private static void shouldReturnQueryForSummaryRecordIdsAccountSoftCredit() {
        assertQueryBuildResults(CRLP_RollupProcessingOptions.RollupType.AccountSoftCredit);
    }

    /** @description Test the Details Query Builder for an AccountContactSoftCredit NonSkew rollup */
    @IsTest
    private static void shouldReturnQueryForSummaryRecordIdsAccountContactSoftCredit() {
        assertQueryBuildResults(CRLP_RollupProcessingOptions.RollupType.AccountContactSoftCredit);
    }

    /** @description Test the Details Query Builder for a ContactHardCredit NonSkew rollup */
    @IsTest
    private static void shouldReturnQueryForSummaryRecordListContactHardCredit() {
        assertQueryBuildResults(CRLP_RollupProcessingOptions.RollupType.ContactHardCredit);
    }

    /** @description Test the Details Query Builder for a ContactSoftCredit NonSkew rollup */
    @IsTest
    private static void shouldReturnQueryForSummaryRecordListContactSoftCredit() {
        assertQueryBuildResults(CRLP_RollupProcessingOptions.RollupType.ContactSoftCredit);
    }

    /** @description Test the Details Query Builder for a RecurringDonation NonSkew rollup */
    @IsTest
    private static void shouldReturnQueryForSummaryRecordListRD() {
        assertQueryBuildResults(CRLP_RollupProcessingOptions.RollupType.RecurringDonations);
    }

    /**
     * @description Validates the QueryBuilder functionality specifically to build a Details Query
     * for the specified Rollup Type. Note that currently the QueryBuilder only handles building the
     * details query in a NonSKew job. Skew Mode batch jobs operate in differently, such that the
     * query against the detail object is actually the batch QueryLocator. Builds of that query are
     * handled elsewhere currently.
     * This method validates that the query is built properly - querying the expected object
     * with the expected sub-queries, order by, and filters.
     * @param rollupType
     * @return Resulting Query String
     */
    private static String assertQueryBuildResults(CRLP_RollupProcessingOptions.RollupType rollupType) {
        String detailObject = CRLP_Rollup_SVC.getDetailObjectType(rollupType).getDescribe().getName();
        String orderBy = CRLP_Rollup_SVC.getParentFieldNameForQuery(rollupType);
        SObjectType summaryObjectType = CRLP_Rollup_SVC.getSummaryObjectType(rollupType);
        Boolean includePayments = false;
        Boolean useWithSummaryRecordIds = false;
        String varName = summaryObjectType.getDescribe().getName() + 'Ids';

        // Additional variations for the QueryBuilder testing
        switch on (rollupType) {
            when AccountHardCredit, ContactHardCredit {
                includePayments = true;
            }
            when RecurringDonations {
                varName = 'rdIds';
            }
            when AccountSoftCredit {
                useWithSummaryRecordIds = true;
            }
        }

        // Instantiates 3 summary record SObjects and mocks Rollup__mdt records
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
        System.assert(detailsQuery.containsIgnoreCase(' FROM ' + detailObject),
                'The query should query the expected "' + detailObject + '" object: ' + detailsQuery);
        System.assert(detailsQuery.containsIgnoreCase(':' + varName),
                'The query should include the referenced "' + varName + '" var: ' + detailsQuery);
        System.assert(detailsQuery.containsIgnoreCase(' ORDER BY ' + orderBy),
                'The query should include the specified Order By: ' + detailsQuery);
        if (includePayments) {
            System.assert(detailsQuery.containsIgnoreCase(' FROM npe01__OppPayment__r)'),
                    'The query should include a child query on Payments: ' + detailsQuery);
        }

        List<SObject> detailRecords = Database.query(detailsQuery);
        System.assertEquals(0, detailRecords.size(), 'The query should have succeeded and returned zero records');

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

        CMT_UnitTestData_TEST.mockFullSetOfRollupDefinitions();

        List<SObject> summaryRecords;
        if (objType == Account.SObjectType) {
            summaryRecords = new List<SObject>{
                new Account(Id = accountIds[0], Name = 'Account 1'),
                new Account(Id = accountIds[1], Name = 'Account 2'),
                new Account(Id = accountIds[2], Name = 'Account 3')
            };

        } else if (objType == Contact.SObjectType) {
            summaryRecords = new List<SObject>{
                    new Contact(Id = contactIds[0], LastName = 'LastName 1'),
                    new Contact(Id = contactIds[1], LastName = 'LastName 2'),
                    new Contact(Id = contactIds[2], LastName = 'LastName 3')
            };

        } else if (objType == npe03__Recurring_Donation__c.SObjectType) {
            summaryRecords = new List<SObject>{
                    new npe03__Recurring_Donation__c(Id = rdIds[0], Name = 'GAU 1'),
                    new npe03__Recurring_Donation__c(Id = rdIds[1], Name = 'GAU 2'),
                    new npe03__Recurring_Donation__c(Id = rdIds[2], Name = 'GAU 3')
            };

        }

        return summaryRecords;
    }
}