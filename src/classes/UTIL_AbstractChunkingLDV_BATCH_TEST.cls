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
* @description Tests for UTIL_AbstractChunkingLDV_BATCH class
*/
@isTest(isParallel=true)
public class UTIL_AbstractChunkingLDV_BATCH_TEST {

    /*******************************************************************************************************************
     * @description The number of Accounts to create for test conditions
     */
    private static final Integer TEST_ACCOUNT_CNT = 7;

    /*******************************************************************************************************************
     * @description A value larger than the largest possible distance between two ids, so that it will never fall back
     *              to LDV execution unexpectedly in a test when it is not supposed to.
     */
    private static final Integer TEST_NOLDV_DISTANCE_CHECK_VALUE = 2147483647;

    /*******************************************************************************************************************
     * @description Test Batch Setters
     */
    @isTest
    public static void shouldSetRuntimeParametersOnBatch() {
        UTIL_AbstractChunkingLDV_MOCK mockAbstractChunkingLDV = new UTIL_AbstractChunkingLDV_MOCK();

        System.assertEquals(UTIL_AbstractChunkingLDV_BATCH.DEFAULT_BATCH_SIZE, mockAbstractChunkingLDV.batchSize, 'Batch Size, Initial');
        mockAbstractChunkingLDV.setBatchSize(10);
        System.assertEquals(10, mockAbstractChunkingLDV.batchSize, 'Batch Size, Updated');

        System.assertEquals(null, mockAbstractChunkingLDV.ldvMode, 'LDV Mode, Initial');
        mockAbstractChunkingLDV.setLdvMode(true);
        System.assertEquals(true, mockAbstractChunkingLDV.ldvMode, 'LDV Mode, Updated');

        System.assertEquals('', mockAbstractChunkingLDV.additionalWhereClause, 'Additional Where Clause, Initial');
        mockAbstractChunkingLDV.setAdditionalWhereClause('AWC');
        System.assertEquals('AWC', mockAbstractChunkingLDV.additionalWhereClause, 'Additional Where Clause, Updated');

    }


    /*******************************************************************************************************************
     * @description Test Batch Execution with inner test batch class to test non chunking conditions
     */
    @isTest
    public static void shouldExecuteBatchToCountAccounts() {
        List<Account> accs = UTIL_UnitTestData_TEST.createMultipleTestAccounts(TEST_ACCOUNT_CNT, null);
        insert accs;

        Test.startTest();

        UTIL_AbstractChunkingLDV_MOCK mockAbstractChunkingLDV = new UTIL_AbstractChunkingLDV_MOCK();
        mockAbstractChunkingLDV.setBatchSize(10);
        mockAbstractChunkingLDV.setTestChunkSize(10);
        mockAbstractChunkingLDV.setTestMaxNonLDVSize(TEST_NOLDV_DISTANCE_CHECK_VALUE);

        System.assertEquals (10, mockAbstractChunkingLDV.getBatchSize(), 'Batch Size');
        mockAbstractChunkingLDV.setExpectedResult(TEST_ACCOUNT_CNT);
        mockAbstractChunkingLDV.setExpectedLdvMode(false);
        Database.executeBatch(mockAbstractChunkingLDV, 10);
        Test.stopTest();

        List<AsyncApexJob> aaJobs = queryBatchJobs();
        System.assertEquals (1, aajobs.size(), '# of jobs present');
    }

    /*******************************************************************************************************************
     * @description Test Batch Execution with inner test batch class to iterate over and count Accounts while simulating
     * chunking conditions
     */
    @isTest
    public static void shouldExecuteChunkingBatchToCountAccounts() {

        List<Account> accs = UTIL_UnitTestData_TEST.createMultipleTestAccounts(TEST_ACCOUNT_CNT, null);
        insert accs;

        Test.startTest();

        UTIL_AbstractChunkingLDV_MOCK mockAbstractChunkingLDV = new UTIL_AbstractChunkingLDV_MOCK();
        mockAbstractChunkingLDV.setBatchSize(1);
        mockAbstractChunkingLDV.setLdvMode(true);

        mockAbstractChunkingLDV.setExpectedResult(TEST_ACCOUNT_CNT);
        mockAbstractChunkingLDV.setExpectedLdvMode(true);
        Database.executeBatch(mockAbstractChunkingLDV, 1);
        Test.stopTest();

        List<AsyncApexJob> aaJobs = queryBatchJobs();
        System.assertEquals (7, aajobs.size(), '# of jobs present');
    }

    /*******************************************************************************************************************
     * @description Test Batch Execution when additional where clause is present (LDV)
     */
    @isTest
    public static void shouldExecuteChunkingBatchWithAddtlWhereClauseToCountAccounts() {
        List<Account> accs = UTIL_UnitTestData_TEST.createMultipleTestAccounts(TEST_ACCOUNT_CNT, null);
        insert accs;

        Test.startTest();
        UTIL_AbstractChunkingLDV_MOCK mockAbstractChunkingLDV = new UTIL_AbstractChunkingLDV_MOCK();
        mockAbstractChunkingLDV.setBatchSize(1);
        mockAbstractChunkingLDV.setAdditionalWhereClause('Id= \'' + accs[0].Id + '\'');

        mockAbstractChunkingLDV.setExpectedResult(1);
        mockAbstractChunkingLDV.setExpectedLdvMode(true);

        Database.executeBatch(mockAbstractChunkingLDV, 1);
        Test.stopTest();

        List<AsyncApexJob> aaJobs = queryBatchJobs();
        // 7 jobs present because it ran in LDV Chunking mode.
        System.assertEquals (7, aajobs.size(), '# of jobs present');
    }

    /*******************************************************************************************************************
     * @description Test Batch Execution when additional where clause is present (non LDV)
     */
    @isTest
    public static void shouldExecuteBatchWithAddtlWhereClauseToCountAccounts() {
        List<Account> accs = UTIL_UnitTestData_TEST.createMultipleTestAccounts(TEST_ACCOUNT_CNT, null);
        insert accs;

        Test.startTest();
        UTIL_AbstractChunkingLDV_MOCK mockAbstractChunkingLDV = new UTIL_AbstractChunkingLDV_MOCK();
        mockAbstractChunkingLDV.setBatchSize(10);
        mockAbstractChunkingLDV.setAdditionalWhereClause('Id= \'' + accs[0].Id + '\'');

        mockAbstractChunkingLDV.setTestMaxNonLDVSize(TEST_NOLDV_DISTANCE_CHECK_VALUE);
        mockAbstractChunkingLDV.setExpectedResult(1);
        mockAbstractChunkingLDV.setExpectedLdvMode(false);
        Database.executeBatch(mockAbstractChunkingLDV, 1);
        Test.stopTest();

        List<AsyncApexJob> aaJobs = queryBatchJobs();
        // 1 jobs present because it ran in non LDV Chunking mode.
        System.assertEquals (1, aajobs.size(), '# of jobs present');
    }

    /*******************************************************************************************************************
     * @description Test Batch Execution when where clause is present (LDV)
     */
    @isTest
    public static void shouldExecuteChunkingBatchWithWhereClauseToCountAccounts() {
        List<Account> accs = UTIL_UnitTestData_TEST.createMultipleTestAccounts(TEST_ACCOUNT_CNT, null);
        insert accs;

        Test.startTest();
        UTIL_AbstractChunkingLDV_MOCK mockAbstractChunkingLDV = new UTIL_AbstractChunkingLDV_MOCK();
        mockAbstractChunkingLDV.setBatchSize(1);

        mockAbstractChunkingLDV.setTestWhereClause('Id = \'' + accs[0].Id + '\'');
        mockAbstractChunkingLDV.setExpectedResult(1);
        mockAbstractChunkingLDV.setExpectedLdvMode(true);

        Database.executeBatch(mockAbstractChunkingLDV, 1);
        Test.stopTest();

        List<AsyncApexJob> aaJobs = queryBatchJobs();
        // 7 jobs present because it ran in LDV Chunking mode.
        System.assertEquals (7, aajobs.size(), '# of jobs present');
    }

    /*******************************************************************************************************************
     * @description Test Batch Execution when where clause is present (non LDV)
     */
    @isTest
    public static void shouldExecuteBatchWithWhereClauseToCountAccounts() {
        List<Account> accs = UTIL_UnitTestData_TEST.createMultipleTestAccounts(TEST_ACCOUNT_CNT, null);
        insert accs;

        Test.startTest();
        UTIL_AbstractChunkingLDV_MOCK mockAbstractChunkingLDV = new UTIL_AbstractChunkingLDV_MOCK();
        mockAbstractChunkingLDV.setBatchSize(10);

        mockAbstractChunkingLDV.setTestWhereClause('Id = \'' + accs[0].Id + '\'');
        mockAbstractChunkingLDV.setTestMaxNonLDVSize(TEST_NOLDV_DISTANCE_CHECK_VALUE);
        mockAbstractChunkingLDV.setExpectedResult(1);
        mockAbstractChunkingLDV.setExpectedLdvMode(false);

        Database.executeBatch(mockAbstractChunkingLDV, 1);
        Test.stopTest();

        List<AsyncApexJob> aaJobs = queryBatchJobs();
        // 1 jobs present because it ran in non LDV Chunking mode.
        System.assertEquals (1, aajobs.size(), '# of jobs present');
    }

    /*******************************************************************************************************************
     * @description Test Batch Execution when where and additional clause is present (LDV)
     */
    @isTest
    public static void shouldExecuteChunkingBatchWithWhereAndAddtlWhereClauseToCountAccounts() {
        List<Account> accs = UTIL_UnitTestData_TEST.createMultipleTestAccounts(TEST_ACCOUNT_CNT, null);
        insert accs;

        Test.startTest();
        UTIL_AbstractChunkingLDV_MOCK mockAbstractChunkingLDV = new UTIL_AbstractChunkingLDV_MOCK();
        mockAbstractChunkingLDV.setBatchSize(10);
        mockAbstractChunkingLDV.setAdditionalWhereClause('Id = \'' + accs[1].Id + '\' or Id=\'' + accs[2].Id + '\' or Id=\'' + accs[3].Id + '\'');

        mockAbstractChunkingLDV.setTestWhereClause('Id = \'' + accs[0].Id + '\' or Id=\'' + accs[1].Id + '\' or Id=\'' + accs[2].Id + '\'');
        mockAbstractChunkingLDV.setExpectedResult(2);
        mockAbstractChunkingLDV.setExpectedLdvMode(true);

        Database.executeBatch(mockAbstractChunkingLDV, 1);
        Test.stopTest();

        List<AsyncApexJob> aaJobs = queryBatchJobs();
        // 7 jobs present because it ran in LDV Chunking mode.
        System.assertEquals (7, aajobs.size(), '# of jobs present');
    }

    /*******************************************************************************************************************
     * @description Test Batch Execution when where  and additional clause is present (non LDV)
     */
    @isTest
    public static void shouldExecuteBatchWithWhereAndAddtlWhereClauseToCountAccounts() {
        List<Account> accs = UTIL_UnitTestData_TEST.createMultipleTestAccounts(TEST_ACCOUNT_CNT, null);
        insert accs;

        Test.startTest();
        UTIL_AbstractChunkingLDV_MOCK mockAbstractChunkingLDV = new UTIL_AbstractChunkingLDV_MOCK();
        mockAbstractChunkingLDV.setBatchSize(10);
        mockAbstractChunkingLDV.setAdditionalWhereClause('Id = \'' + accs[1].Id + '\' or Id = \'' + accs[2].Id + '\' or Id = \'' + accs[3].Id + '\'');

        mockAbstractChunkingLDV.setTestWhereClause('Id = \'' + accs[0].Id + '\' or Id = \'' + accs[1].Id + '\' or Id = \'' + accs[2].Id + '\'');
        mockAbstractChunkingLDV.setTestMaxNonLDVSize(TEST_NOLDV_DISTANCE_CHECK_VALUE);
        mockAbstractChunkingLDV.setExpectedResult(2);
        mockAbstractChunkingLDV.setExpectedLdvMode(false);

        Database.executeBatch(mockAbstractChunkingLDV, 10);
        Test.stopTest();

        List<AsyncApexJob> aaJobs = queryBatchJobs();
        // 1 jobs present because it ran in non LDV Chunking mode.
        System.assertEquals (1, aajobs.size(), '# of jobs present');
    }
    /*******************************************************************************************************************
     * @description Test Batch Execution when no records are returned
     */
    @isTest
    public static void shouldProperlyExecuteBatchWithnoRecordsReturned() {

        Test.startTest();
        UTIL_AbstractChunkingLDV_MOCK mockAbstractChunkingLDV = new UTIL_AbstractChunkingLDV_MOCK();
        mockAbstractChunkingLDV.setBatchSize(10);

        mockAbstractChunkingLDV.setExpectedResult(0);
        mockAbstractChunkingLDV.setExpectedLdvMode(false);

        Database.executeBatch(mockAbstractChunkingLDV, 1);
        Test.stopTest();

        List<AsyncApexJob> aaJobs = queryBatchJobs();
        System.assertEquals (1, aajobs.size(), '# of jobs present');
    }

    /*******************************************************************************************************************
     * @description Test Validate Method valid Query
     */
    @isTest
    public static void shouldReturnNullForValidatingValidQuery() {
        // UserInfo.getUserId is not valid for Account, but doesn't matter for this test because we are only validating syntactical correctness.
        UTIL_AbstractChunkingLDV_MOCK mockAbstractChunkingLDV = new UTIL_AbstractChunkingLDV_MOCK();
        mockAbstractChunkingLDV.setBatchSize(10);
        mockAbstractChunkingLDV.setAdditionalWhereClause('Id= \'' + UTIL_UnitTestData_TEST.mockId(Account.SObjectType) + '\'');

        mockAbstractChunkingLDV.setTestWhereClause('OwnerId= \'' + UTIL_UnitTestData_TEST.mockId(User.SObjectType) + '\'');

        System.assertEquals(null, mockAbstractChunkingLDV.validateQuery(), 'No Exception expected');
    }

    /*******************************************************************************************************************
     * @description Test Validate Method invalid Query
     */
    @isTest
    public static void shouldReturnExceptionForValidatingInvalidQuery() {
        UTIL_AbstractChunkingLDV_MOCK mockAbstractChunkingLDV = new UTIL_AbstractChunkingLDV_MOCK();
        mockAbstractChunkingLDV.setBatchSize(10);
        mockAbstractChunkingLDV.setAdditionalWhereClause('Id= \'' + UTIL_UnitTestData_TEST.mockId(Account.SObjectType) + '\'');

        //Invalid Where Clause
        mockAbstractChunkingLDV.setTestWhereClause('OwnerId equals \'' + UTIL_UnitTestData_TEST.mockId(User.SObjectType) + '\'');

        System.assertNotEquals(null, mockAbstractChunkingLDV.validateQuery(), 'Exception expected');
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
            AND ApexClass.Name = 'UTIL_AbstractChunkingLDV_MOCK'
        ];
    }

}