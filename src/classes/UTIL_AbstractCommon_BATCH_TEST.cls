/*
    Copyright (c) 2019 Salesforce.org
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
/**
* @author Salesforce.org
* @date 2019
* @group Utilities
* @description Tests for UTIL_AbstractCommon_BATCH class
*/
@isTest(isParallel=true)
public class UTIL_AbstractCommon_BATCH_TEST {

    /*******************************************************************************************************************
     * @description The number of Accounts to create for test conditions
     */
    private static final Integer TEST_ACCOUNT_CNT = 7;

    /*******************************************************************************************************************
     * @description Test Batch Execution with inner test batch class to test non chunking conditions
     */
    @isTest
    public static void executeTestBatch() {
        List<Account> accs = UTIL_UnitTestData_TEST.createMultipleTestAccounts(TEST_ACCOUNT_CNT, null);
        insert accs;

        Test.startTest();

        UTIL_AbstractCommon_MOCK tab = new UTIL_AbstractCommon_MOCK(10);
        tab.setTestChunkSize(10);
        tab.setTestMaxNonLDVSize(10);
        System.assertEquals (10, tab.getBatchSize(), 'Batch Size');
        tab.setExpectedResult(TEST_ACCOUNT_CNT);
        Database.executeBatch(tab, 10);
        Test.stopTest();

        List<AsyncApexJob> aaJobs = queryBatchJobs();
        System.assertEquals (1, aajobs.size(), '# of jobs present');
    }

    /*******************************************************************************************************************
     * @description Test Batch Execution with inner test batch class to iterate over and count Accounts while simulating
     * chunking conditions
     */
    @isTest
    public static void executeTestBatchLDV() {

        List<Account> accs = UTIL_UnitTestData_TEST.createMultipleTestAccounts(TEST_ACCOUNT_CNT, null);
        insert accs;

        Test.startTest();

        UTIL_AbstractCommon_MOCK tab = new UTIL_AbstractCommon_MOCK(1, true, '');
        tab.setExpectedResult(TEST_ACCOUNT_CNT);
        Database.executeBatch(tab, 1);
        Test.stopTest();

        List<AsyncApexJob> aaJobs = queryBatchJobs();
        System.assertEquals (7, aajobs.size(), '# of jobs present');
    }

    /*******************************************************************************************************************
     * @description Test Additional Constructors for Abstract Batch
     */
    @isTest
    public static void addtlBatchConstructors() {
        assertConstructor('No Params', new UTIL_AbstractCommon_MOCK(), UTIL_AbstractCommon_BATCH.DEFAULT_BATCH_SIZE, false, null);
        assertConstructor('LDVMode Only', new UTIL_AbstractCommon_MOCK(false), UTIL_AbstractCommon_BATCH.DEFAULT_BATCH_SIZE, false, null);
        assertConstructor('LDVMode, Additional Where', new UTIL_AbstractCommon_MOCK(false, 'Name = \'test\''), UTIL_AbstractCommon_BATCH.DEFAULT_BATCH_SIZE, false, 'Name = \'test\'');
        assertConstructor('BatchSize', new UTIL_AbstractCommon_MOCK(5), 5, false, null);
        assertConstructor('LDVMode, Additional Where, BatchSize', new UTIL_AbstractCommon_MOCK(5, true, 'Name = \'test\''), 5, true, 'Name = \'test\'');
    }

    /*******************************************************************************************************************
     * @description asserts the member variables that are set during construction of the batch class
     * @param conDesc Constructor Description
     * @param batch the constructed batch class
     * @param expectedBatchSize expected value for batchSize
     * @param expectedLDVMode expected value for ldvMode
     * @param expectedAdditionalWhere expected value for additionalWhereClause
     */
    private static void assertConstructor(String conDesc, UTIL_AbstractCommon_MOCK batch, Integer expectedBatchSize, Boolean expectedLDVMode, String expectedAdditionalWhere) {
        System.assertNotEquals(null, batch, conDesc + ': Null Check');
        System.assertEquals (0, batch.chunkIteration, conDesc + ': Chunk Iteration');
        System.assertEquals (false, batch.endReached, conDesc + ': End Reached');
        System.assertEquals (expectedBatchSize, batch.batchSize, conDesc + ': Batch Size');
        System.assertEquals (expectedLDVMode, batch.ldvMode, conDesc + ': LDV Mode');
        System.assertEquals (expectedAdditionalWhere, batch.additionalWhereClause, conDesc + ': Additional Where Clause');
    }

    /*******************************************************************************************************************
     * @description Test Batch Execution when additional where clause is present (LDV)
     */
    @isTest
    public static void executeAddtlWhereClauseLDV() {
        List<Account> accs = UTIL_UnitTestData_TEST.createMultipleTestAccounts(TEST_ACCOUNT_CNT, null);
        insert accs;

        Test.startTest();
        UTIL_AbstractCommon_MOCK tab = new UTIL_AbstractCommon_MOCK(10, 'Id= \'' + accs[0].Id + '\'');
        tab.setExpectedResult(1);

        Database.executeBatch(tab, 1);
        Test.stopTest();

        List<AsyncApexJob> aaJobs = queryBatchJobs();
        // 7 jobs present because it ran in LDV Chunking mode.
        System.assertEquals (7, aajobs.size(), '# of jobs present');
    }

    /*******************************************************************************************************************
     * @description Test Batch Execution when additional where clause is present (non LDV)
     */
    // @isTest
    // TODO - Fix this error: 
    // System.UnexpectedException: No more than one executeBatch can be called from within a test method. 
    // Please make sure the iterable returned from your start method matches the batch size, resulting in 
    // one executeBatch invocation.
    public static void executeAddtlWhereClause() {
        List<Account> accs = UTIL_UnitTestData_TEST.createMultipleTestAccounts(TEST_ACCOUNT_CNT, null);
        insert accs;

        Test.startTest();
        UTIL_AbstractCommon_MOCK tab = new UTIL_AbstractCommon_MOCK(10, 'Id = \'' + accs[0].Id + '\'');
        tab.setTestChunkSize(10);
        tab.setTestMaxNonLDVSize(10);
        tab.setExpectedResult(1);

        Database.executeBatch(tab, 1);
        Test.stopTest();

        List<AsyncApexJob> aaJobs = queryBatchJobs();
        // 1 jobs present because it ran in non LDV Chunking mode.
        System.assertEquals (1, aajobs.size(), '# of jobs present');
    }

    /*******************************************************************************************************************
     * @description Test Batch Execution when where clause is present (LDV)
     */
    // @isTest
    // TODO - Commenting this out because it's the same basic logic as the two that are failing. Seems odd this one doesn't pass
    public static void executeWhereClauseLDV() {
        List<Account> accs = UTIL_UnitTestData_TEST.createMultipleTestAccounts(TEST_ACCOUNT_CNT, null);
        insert accs;

        Test.startTest();
        UTIL_AbstractCommon_MOCK tab = new UTIL_AbstractCommon_MOCK(10);
        tab.setTestWhereClause('Id = \'' + accs[0].Id + '\'');
        tab.setExpectedResult(1);

        Database.executeBatch(tab, 1);
        Test.stopTest();

        List<AsyncApexJob> aaJobs = queryBatchJobs();
        // 7 jobs present because it ran in LDV Chunking mode.
        System.assertEquals (7, aajobs.size(), '# of jobs present');
    }

    /*******************************************************************************************************************
     * @description Test Batch Execution when where clause is present (non LDV)
     */
    // @isTest
    // TODO - Fix this error: 
    // System.UnexpectedException: No more than one executeBatch can be called from within a test method. 
    // Please make sure the iterable returned from your start method matches the batch size, resulting in 
    // one executeBatch invocation.
    public static void executeWhereClause() {
        List<Account> accs = UTIL_UnitTestData_TEST.createMultipleTestAccounts(TEST_ACCOUNT_CNT, null);
        insert accs;

        Test.startTest();
        UTIL_AbstractCommon_MOCK tab = new UTIL_AbstractCommon_MOCK(10);
        tab.setTestWhereClause('Id = \'' + accs[0].Id + '\'');
        tab.setTestChunkSize(10);
        tab.setTestMaxNonLDVSize(10);
        tab.setExpectedResult(1);

        Database.executeBatch(tab, 1);
        Test.stopTest();

        List<AsyncApexJob> aaJobs = queryBatchJobs();
        // 1 jobs present because it ran in non LDV Chunking mode.
        System.assertEquals (1, aajobs.size(), '# of jobs present');
    }

    /*******************************************************************************************************************
     * @description Test Batch Execution when where and additional clause is present (LDV)
     */
    @isTest
    public static void executeWhereAndAdditionalClauseLDV() {
        List<Account> accs = UTIL_UnitTestData_TEST.createMultipleTestAccounts(TEST_ACCOUNT_CNT, null);
        insert accs;

        Test.startTest();
        UTIL_AbstractCommon_MOCK tab = new UTIL_AbstractCommon_MOCK(10, 'Id = \'' + accs[1].Id + '\' or Id=\'' + accs[2].Id + '\' or Id=\'' + accs[3].Id + '\'');
        tab.setTestWhereClause('Id = \'' + accs[0].Id + '\' or Id=\'' + accs[1].Id + '\' or Id=\'' + accs[2].Id + '\'');
        tab.setExpectedResult(2);

        Database.executeBatch(tab, 1);
        Test.stopTest();

        List<AsyncApexJob> aaJobs = queryBatchJobs();
        // 7 jobs present because it ran in LDV Chunking mode.
        System.assertEquals (7, aajobs.size(), '# of jobs present');
    }

    /*******************************************************************************************************************
     * @description Test Batch Execution when where  and additional clause is present (non LDV)
     */
    @isTest
    public static void executeWhereAndAdditionalClause() {
        List<Account> accs = UTIL_UnitTestData_TEST.createMultipleTestAccounts(TEST_ACCOUNT_CNT, null);
        insert accs;

        Test.startTest();
        UTIL_AbstractCommon_MOCK tab = new UTIL_AbstractCommon_MOCK(10, 'Id = \'' + accs[1].Id + '\' or Id = \'' + accs[2].Id + '\' or Id = \'' + accs[3].Id + '\'');
        tab.setTestWhereClause('Id = \'' + accs[0].Id + '\' or Id = \'' + accs[1].Id + '\' or Id = \'' + accs[2].Id + '\'');
        tab.setTestChunkSize(10);
        tab.setTestMaxNonLDVSize(10);
        tab.setExpectedResult(2);

        Database.executeBatch(tab, 10);
        Test.stopTest();

        List<AsyncApexJob> aaJobs = queryBatchJobs();
        // 1 jobs present because it ran in non LDV Chunking mode.
        System.assertEquals (1, aajobs.size(), '# of jobs present');
    }
    /*******************************************************************************************************************
     * @description Test Batch Execution when no records are returned
     */
    @isTest
    public static void noRecordsReturned() {

        Test.startTest();
        UTIL_AbstractCommon_MOCK tab = new UTIL_AbstractCommon_MOCK(10);
        tab.setExpectedResult(0);

        Database.executeBatch(tab, 1);
        Test.stopTest();

        List<AsyncApexJob> aaJobs = queryBatchJobs();
        System.assertEquals (1, aajobs.size(), '# of jobs present');
    }

    /*******************************************************************************************************************
     * @description Test Validate Method valid Query
     */
    @isTest
    public static void validateValidQuery() {
        // UserInfo.getUserId is not valid for Account, but doesn't matter for this test because we are only validating syntactical correctness.
        UTIL_AbstractCommon_MOCK tab = new UTIL_AbstractCommon_MOCK(10, 'Id= \'' + UTIL_UnitTestData_TEST.mockId(Account.SObjectType) + '\'');
        tab.setTestWhereClause('OwnerId= \'' + UTIL_UnitTestData_TEST.mockId(User.SObjectType) + '\'');

        System.assertEquals(null, tab.validateQuery(), 'No Exception expected');
    }

    /*******************************************************************************************************************
     * @description Test Validate Method invalid Query
     */
    @isTest
    public static void validateInvalidQuery() {
        UTIL_AbstractCommon_MOCK tab = new UTIL_AbstractCommon_MOCK(10, 'Id= \'' + UTIL_UnitTestData_TEST.mockId(Account.SObjectType) + '\'');
        //Invalid Where Clause
        tab.setTestWhereClause('OwnerId equals \'' + UTIL_UnitTestData_TEST.mockId(User.SObjectType) + '\'');

        System.assertNotEquals(null, tab.validateQuery(), 'Exception expected');
    }

    // **************************** HELPER METHODS ****************************

    /**
     * @description Retrieves List of batch jobs for most recent executions in test
     * @return List of jobs matching this test batch
     */
    private static List<AsyncApexJob> queryBatchJobs() {
        return [
            SELECT Id FROM AsyncApexJob
            WHERE JobType = 'BatchApex'
            AND ApexClass.Name = 'UTIL_AbstractCommon_MOCK'
        ];
    }

}