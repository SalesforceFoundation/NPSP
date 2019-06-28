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
public class UTIL_AbstractCommon_BATCH_TEST extends UTIL_AbstractCommon_BATCH {

    /*******************************************************************************************************************
     * @description The number of Accounts to create for test conditions
     */
    private static final Integer TEST_ACCOUNT_CNT = 7;

    private Integer expectedResult;
    private Integer testChunkSize = 1;
    private String testWhereClause = '';

    /*******************************************************************************************************************
     * @description Test Batch Execution with inner test batch class to test non chunking conditions
     */
    @isTest
    public static void executeTestBatch() {

        List<Account> accs = new List<Account>();

        for (Integer i = 0; i < TEST_ACCOUNT_CNT; i++) {
            accs.add(
                new Account(
                    Name = '1-Test Account #' + i
                )
            );
        }
        insert accs;

        Test.startTest();

        UTIL_AbstractCommon_BATCH_TEST tab = new UTIL_AbstractCommon_BATCH_TEST(10);
        tab.setTestChunkSize(10);
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

        List<Account> accs = new List<Account>();

        for (Integer i = 0; i < TEST_ACCOUNT_CNT; i++) {
            accs.add(
                new Account(
                    Name = '2-Test Account #' + i
                )
            );
        }
        insert accs;

        Test.startTest();

        UTIL_AbstractCommon_BATCH_TEST tab = new UTIL_AbstractCommon_BATCH_TEST(1, true, '');
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
        assertConstructor('No Params', new UTIL_AbstractCommon_BATCH_TEST(), UTIL_AbstractCommon_BATCH.DEFAULT_BATCH_SIZE, false, '');
        assertConstructor('LDVMode Only', new UTIL_AbstractCommon_BATCH_TEST(false), UTIL_AbstractCommon_BATCH.DEFAULT_BATCH_SIZE, false, '');
        assertConstructor('LDVMode, Additional Where', new UTIL_AbstractCommon_BATCH_TEST(false, 'Name = \'test\''), UTIL_AbstractCommon_BATCH.DEFAULT_BATCH_SIZE, false, 'Name = \'test\'');
        assertConstructor('BatchSize', new UTIL_AbstractCommon_BATCH_TEST(5), 5, false, '');
        assertConstructor('LDVMode, Additional Where, BatchSize', new UTIL_AbstractCommon_BATCH_TEST(5, true, 'Name = \'test\''), 5, true, 'Name = \'test\'');
    }


    /*******************************************************************************************************************
     * @description asserts the member variables that are set during construction of the batch class
     * @param conDesc Constructor Description
     * @param batch the constructed batch class
     * @param expectedBatchSize expected value for batchSize
     * @param expectedLDVMode expected value for ldvMode
     * @param expectedAdditionalWhere expected value for additionalWhereClause
     */
    private static void assertConstructor(String conDesc, UTIL_AbstractCommon_BATCH_TEST batch, Integer expectedBatchSize, Boolean expectedLDVMode, String expectedAdditionalWhere) {
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
        List<Account> accs = new List<Account>();

        for (Integer i = 0; i < TEST_ACCOUNT_CNT; i++) {
            accs.add(
                new Account(
                    Name = '3-Test Account #' + i
                )
            );
        }
        insert accs;

        Test.startTest();
        UTIL_AbstractCommon_BATCH_TEST tab = new UTIL_AbstractCommon_Batch_TEST(10, 'Name = \'3-Test Account #0\'');
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
    @isTest
    public static void executeAddtlWhereClause() {
        List<Account> accs = new List<Account>();

        for (Integer i = 0; i < TEST_ACCOUNT_CNT; i++) {
            accs.add(
                new Account(
                    Name = '4-Test Account #' + i
                )
            );
        }
        insert accs;

        Test.startTest();
        UTIL_AbstractCommon_BATCH_TEST tab = new UTIL_AbstractCommon_Batch_TEST(10, 'Name = \'4-Test Account #0\'');
        tab.setTestChunkSize(10);
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
    @isTest
    public static void executeWhereClauseLDV() {
        List<Account> accs = new List<Account>();

        for (Integer i = 0; i < TEST_ACCOUNT_CNT; i++) {
            accs.add(
                new Account(
                    Name = '5-Test Account #' + i
                )
            );
        }
        insert accs;

        Test.startTest();
        UTIL_AbstractCommon_BATCH_TEST tab = new UTIL_AbstractCommon_Batch_TEST(10);
        tab.setTestWhereClause('Name = \'5-Test Account #0\'');
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
    @isTest
    public static void executeWhereClause() {
        List<Account> accs = new List<Account>();

        for (Integer i = 0; i < TEST_ACCOUNT_CNT; i++) {
            accs.add(
                new Account(
                    Name = '6-Test Account #' + i
                )
            );
        }
        insert accs;

        Test.startTest();
        UTIL_AbstractCommon_BATCH_TEST tab = new UTIL_AbstractCommon_Batch_TEST(10);
        tab.setTestWhereClause('Name = \'6-Test Account #0\'');
        tab.setTestChunkSize(10);
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
        List<Account> accs = new List<Account>();

        for (Integer i = 0; i < TEST_ACCOUNT_CNT; i++) {
            accs.add(
                new Account(
                    Name = '7-Test Account #' + i
                )
            );
        }
        insert accs;

        Test.startTest();
        UTIL_AbstractCommon_BATCH_TEST tab = new UTIL_AbstractCommon_Batch_TEST(10, 'Name = \'7-Test Account #1\' or Name=\'7-Test Account #2\' or Name=\'7-Test Account #3\'');
        tab.setTestWhereClause('Name = \'7-Test Account #0\' or Name=\'7-Test Account #1\' or Name=\'7-Test Account #2\'');
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
        List<Account> accs = new List<Account>();

        for (Integer i = 0; i < TEST_ACCOUNT_CNT; i++) {
            accs.add(
                new Account(
                    Name = '8-Test Account #' + i
                )
            );
        }
        insert accs;

        Test.startTest();
        UTIL_AbstractCommon_BATCH_TEST tab = new UTIL_AbstractCommon_Batch_TEST(10, 'Name = \'8-Test Account #1\' or Name=\'8-Test Account #2\' or Name=\'8-Test Account #3\'');
        tab.setTestWhereClause('Name = \'8-Test Account #0\' or Name=\'8-Test Account #1\' or Name=\'8-Test Account #2\'');
        tab.setTestChunkSize(10);
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
        UTIL_AbstractCommon_BATCH_TEST tab = new UTIL_AbstractCommon_Batch_TEST(10);
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

        UTIL_AbstractCommon_BATCH_TEST tab = new UTIL_AbstractCommon_Batch_TEST(10, 'Name = \'Test Account #1\' or Name=\'Test Account #2\' or Name=\'Test Account #3\'');
        tab.setTestWhereClause('Name = \'Test Account #0\' or Name=\'Test Account #1\' or Name=\'Test Account #2\'');

        System.assertEquals(null, tab.validateQuery(), 'No Exception expected');
    }

    /*******************************************************************************************************************
     * @description Test Validate Method invalid Query
     */
    @isTest
    public static void validateInvalidQuery() {

        UTIL_AbstractCommon_BATCH_TEST tab = new UTIL_AbstractCommon_Batch_TEST(10, 'Name = \'Test Account #1\' or Name=\'Test Account #2\' or Name=\'Test Account #3\'');
        tab.setTestWhereClause('Name equals \'Test Account #0\' or Name equals \'Test Account #1\' or Name equals \'Test Account #2\'');

        System.assertNotEquals(null, tab.validateQuery(), 'Exception expected');
    }

    /* Test Harness for Batch Implementation Here... */

    /**
     * @description sets the Number of Records we expect to find at the end of execution during tests.
     * @param anExpectedResult - The Number of Records we expect to find
     */
    public void setExpectedResult(Integer anExpectedResult) {
        this.expectedResult = anExpectedResult;
    }

    // Initialize private variable for record count to 0
    private Integer recCnt = 0;

    /**
     * @description No parameter constructor
     */
    public UTIL_AbstractCommon_BATCH_TEST() {
        super();
    }

    /**
     * @description Constructor
     * @param batchSize How many records should be in each batch
     */
    public UTIL_AbstractCommon_BATCH_TEST(Integer batchSize) {
        super(batchSize);
    }

    /**
     * @description Constructor
     * @param batchSize How many records should be in each batch
     * @param additionalWhereClause If present will be added to the inner query, or the batch query if executing in non ldv mode.
     */
    public UTIL_AbstractCommon_BATCH_TEST(Integer batchSize, String additionalWhereClause) {
        super(batchSize, additionalWhereClause);
    }

    /**
     * @description Constructor
     * @param ldvMode - if true, will execute in chunking more regardless of distance between min and max record Id
     */
    public UTIL_AbstractCommon_BATCH_TEST(Boolean ldvMode) {
        super(ldvMode);
    }

    /**
     * @description Constructor
     * @param ldvMode - if true, will execute in chunking more regardless of distance between min and max record Id
     * @param additionalWhereClause If present will be added to the inner query, or the batch query if executing in non ldv mode.
     */
    public UTIL_AbstractCommon_BATCH_TEST(Boolean ldvMode, String additionalWhereClause) {
        super(ldvMode, additionalWhereClause);
    }


    /**
     * @description Constructor
     * @param batchSize How many records should be in each batch
     * @param ldvMode - if true, will execute in chunking more regardless of distance between min and max record Id
     * @param additionalWhereClause If present will be added to the inner query, or the batch query if executing in non ldv mode.
     */
    public UTIL_AbstractCommon_BATCH_TEST(Integer batchSize, Boolean ldvMode, String additionalWhereClause) {
        super(batchSize, ldvMode, additionalWhereClause);
    }

    /**
     * @description Test implementation of doExecute method (the implementing classes equivalent to the execute method)
     * @param bc BatchableContext
     * @param records The list of records returned for this batch, filtered for any additionalWhere clause added, and including the fields/subqueries configured for this batch
     */
    public override void doExecute(Database.BatchableContext bc, List<SObject>records ) {
        recCnt += records.size();
    }

    /**
     * @description Primarily here to allow overriding of LDVChunk size for specific requirements, E.g. if a specific batch needs a lower threshold for running in LDV mode
     */
    public override Integer getLDVChunkSize() {
        return this.testChunkSize;
    }

    /**
     * @description Required to set the main object the batch executes against
     */
    public override SObjectType getSObjectType() {
        return Account.getSObjectType();
    }

    /**
      * Setter for testWhereClause Field
      * @param testWhereClause new value for testWhereClause
      */
    public void setTestWhereClause(String testWhereClause) {
        this.testWhereClause = testWhereClause;
    }

    /**
     * Overridable test Where Clause to add to the inner query, or non LDV query, if not running in LDV/Chunking mode
     * @return String ''
     */
    public override String getWhereClause() {
        return this.testWhereClause;
    }

    /**
     * @description Called on completion of the batch job.  If this is running LDV Mode it may be called more than once.  All but the last invocation will
     * have an isComplete value of false.  This method isd similar in nature/roughly equivalent to the finish method of a standard Apex Batch job
     * @param bc BatchableContext
     * @param isComplete boolean value that indicates whether or not this is the final invocation, or will be executing against additional chunks
     */
    public override void doFinish(Database.BatchableContext bc , Boolean isComplete) {
        if (isComplete) {
            System.debug('# of Account Records Found: ' + recCnt);
            System.assertEquals (expectedResult, recCnt, 'Account Count Mismatch');
        }
    }
    /**
     * @description Allows the test batches chunk size to be updated
     * @param Integer testChunkSize Size to set the chunk size for the test batch to
     */
    public void setTestChunkSize(Integer testChunkSize) {
        this.testChunkSize = testChunkSize;
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
            AND ApexClass.Name = 'UTIL_AbstractCommon_BATCH_TEST'
        ];
    }
}