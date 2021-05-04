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
* @description Unit Tests to validate skew vs nonskew mode query selection thresholds
*/
@IsTest(isParallel=true)
private class CRLP_RollupBatch_TEST {

    @IsTest
    private static void shouldReturnWhereClauseForSkewModeWhenContactHardCredit() {
        String whereClause = CRLP_RollupBatch_SVC.getSkewWhereClause(
            CRLP_RollupProcessingOptions.RollupType.ContactHardCredit,
            CRLP_RollupProcessingOptions.BatchJobMode.SkewMode
        );

        System.assert(whereClause.contains('npo02__NumberOfClosedOpps__c'),
            'Expected field npo02__NumberOfClosedOpps__c missing from skew mode where clause');
        System.assert(whereClause.contains('npo02__NumberOfMembershipOpps__c'),
            'Expected field npo02__NumberOfMembershipOpps__c missing from skew mode where clause');
        System.assertEquals(2, whereClause.countMatches('>='),
            'Expected >= missing from skew mode where clause');
    }

    @IsTest
    private static void shouldReturnWhereClauseForNonSkewModeWhenContactHardCredit() {
        String whereClause = CRLP_RollupBatch_SVC.getSkewWhereClause(
            CRLP_RollupProcessingOptions.RollupType.ContactHardCredit,
            CRLP_RollupProcessingOptions.BatchJobMode.NonSkewMode
        );

        System.assert(whereClause.contains('npo02__NumberOfClosedOpps__c'),
            'Expected field npo02__NumberOfClosedOpps__c missing from skew mode where clause');
        System.assert(whereClause.contains('npo02__NumberOfMembershipOpps__c'),
            'Expected field npo02__NumberOfMembershipOpps__c missing from skew mode where clause');
        System.assertEquals(2, whereClause.countMatches('<'),
            'Expected < missing from skew mode where clause');
    }

    @IsTest
    private static void shouldReturnWhereClauseForSkewModeWhenAccountHardCredit() {
        String whereClause = CRLP_RollupBatch_SVC.getSkewWhereClause(
            CRLP_RollupProcessingOptions.RollupType.AccountHardCredit,
            CRLP_RollupProcessingOptions.BatchJobMode.SkewMode
        );

        System.assert(whereClause.contains('npo02__NumberOfClosedOpps__c'),
            'Expected field npo02__NumberOfClosedOpps__c missing from skew mode where clause');
        System.assert(whereClause.contains('npo02__NumberOfMembershipOpps__c'),
            'Expected field npo02__NumberOfMembershipOpps__c missing from skew mode where clause');
        System.assertEquals(2, whereClause.countMatches('>='),
            'Expected >= missing from skew mode where clause');
    }

    @IsTest
    private static void shouldReturnWhereClauseForNonSkewModeWhenAccountHardCredit() {
        String whereClause = CRLP_RollupBatch_SVC.getSkewWhereClause(
            CRLP_RollupProcessingOptions.RollupType.AccountHardCredit,
            CRLP_RollupProcessingOptions.BatchJobMode.NonSkewMode
        );

        System.assert(whereClause.contains('npo02__NumberOfClosedOpps__c'),
            'Expected field npo02__NumberOfClosedOpps__c missing from skew mode where clause');
        System.assert(whereClause.contains('npo02__NumberOfMembershipOpps__c'),
            'Expected field npo02__NumberOfMembershipOpps__c missing from skew mode where clause');
        System.assertEquals(2, whereClause.countMatches('<'),
            'Expected < missing from skew mode where clause');
    }

    @IsTest
    private static void shouldReturnWhereClauseForSkewModeWhenContactSoftCredit() {
        String whereClause = CRLP_RollupBatch_SVC.getSkewWhereClause(
            CRLP_RollupProcessingOptions.RollupType.ContactSoftCredit,
            CRLP_RollupProcessingOptions.BatchJobMode.SkewMode
        );

        System.assert(whereClause.contains('Number_of_Soft_Credits__c'),
            'Expected field Number_of_Soft_Credits__c missing from skew mode where clause');
        System.assertEquals(1, whereClause.countMatches('>='),
            'Expected >= missing from skew mode where clause');
    }

    @IsTest
    private static void shouldReturnWhereClauseForNonSkewModeWhenContactSoftCredit() {
        String whereClause = CRLP_RollupBatch_SVC.getSkewWhereClause(
            CRLP_RollupProcessingOptions.RollupType.ContactSoftCredit,
            CRLP_RollupProcessingOptions.BatchJobMode.NonSkewMode
        );

        System.assert(whereClause.contains('Number_of_Soft_Credits__c'),
            'Expected field Number_of_Soft_Credits__c missing from skew mode where clause');
        System.assertEquals(1, whereClause.countMatches('<'),
            'Expected < missing from skew mode where clause');
    }

    @IsTest
    private static void shouldReturnWhereClauseForSkewModeWhenAccountContactSoftCredit() {
        String whereClause = CRLP_RollupBatch_SVC.getSkewWhereClause(
            CRLP_RollupProcessingOptions.RollupType.AccountContactSoftCredit,
            CRLP_RollupProcessingOptions.BatchJobMode.SkewMode
        );

        System.assert(whereClause.contains('npo02__NumberOfClosedOpps__c'),
            'Expected field npo02__NumberOfClosedOpps__c missing from skew mode where clause');
        System.assertEquals(1, whereClause.countMatches('>='),
            'Expected >= missing from skew mode where clause');
    }

    @IsTest
    private static void shouldReturnWhereClauseForNonSkewModeWhenAccountContactSoftCredit() {
        String whereClause = CRLP_RollupBatch_SVC.getSkewWhereClause(
            CRLP_RollupProcessingOptions.RollupType.AccountContactSoftCredit,
            CRLP_RollupProcessingOptions.BatchJobMode.NonSkewMode
        );

        System.assert(whereClause.contains('npo02__NumberOfClosedOpps__c'),
            'Expected field npo02__NumberOfClosedOpps__c missing from skew mode where clause');
        System.assertEquals(1, whereClause.countMatches('<'),
            'Expected < missing from skew mode where clause');
    }

    @IsTest
    private static void shouldReturnWhereClauseForSkewModeWhenAccountSoftCredit() {
        String whereClause = CRLP_RollupBatch_SVC.getSkewWhereClause(
            CRLP_RollupProcessingOptions.RollupType.AccountSoftCredit,
            CRLP_RollupProcessingOptions.BatchJobMode.SkewMode
        );

        System.assert(whereClause.contains('npo02__NumberOfClosedOpps__c'),
            'Expected field npo02__NumberOfClosedOpps__c missing from skew mode where clause');
        System.assertEquals(1, whereClause.countMatches('>='),
            'Expected >= missing from skew mode where clause');
    }

    @IsTest
    private static void shouldReturnWhereClauseForNonSkewModeWhenAccountSoftCredit() {
        String whereClause = CRLP_RollupBatch_SVC.getSkewWhereClause(
            CRLP_RollupProcessingOptions.RollupType.AccountSoftCredit,
            CRLP_RollupProcessingOptions.BatchJobMode.NonSkewMode
        );

        System.assert(whereClause.contains('npo02__NumberOfClosedOpps__c'),
            'Expected field npo02__NumberOfClosedOpps__c missing from skew mode where clause');
        System.assertEquals(1, whereClause.countMatches('<'),
            'Expected < missing from skew mode where clause');
    }

    @IsTest
    private static void shouldReturnWhereClauseForSkewModeWhenGAU() {
        String whereClause = CRLP_RollupBatch_SVC.getSkewWhereClause(
            CRLP_RollupProcessingOptions.RollupType.GAU,
            CRLP_RollupProcessingOptions.BatchJobMode.SkewMode
        );

        System.assertEquals(0, whereClause.countMatches('>='),
            'Expected >= missing from skew mode where clause');
        System.assertEquals(0, whereClause.countMatches('<'),
            'Expected < missing from skew mode where clause');
    }

    @IsTest
    private static void shouldReturnWhereClauseForSkewModeWhenRecurringDonations() {
        String whereClause = CRLP_RollupBatch_SVC.getSkewWhereClause(
            CRLP_RollupProcessingOptions.RollupType.RecurringDonations,
            CRLP_RollupProcessingOptions.BatchJobMode.SkewMode
        );

        System.assert(whereClause.contains('npe03__Total_Paid_Installments__c'),
            'Expected field npe03__Total_Paid_Installments__c missing from skew mode where clause');
        System.assertEquals(1, whereClause.countMatches('>='),
            'Expected >= missing from skew mode where clause');
    }

    @IsTest
    private static void shouldReturnWhereClauseForNonSkewModeWhenRecurringDonations() {
        String whereClause = CRLP_RollupBatch_SVC.getSkewWhereClause(
            CRLP_RollupProcessingOptions.RollupType.RecurringDonations,
            CRLP_RollupProcessingOptions.BatchJobMode.NonSkewMode
        );

        System.assert(whereClause.contains('npe03__Total_Paid_Installments__c'),
            'Expected field npe03__Total_Paid_Installments__c missing from skew mode where clause');
        System.assertEquals(1, whereClause.countMatches('<'),
            'Expected < missing from skew mode where clause');
    }
}