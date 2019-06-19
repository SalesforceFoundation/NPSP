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
@isTest
public class UTIL_AbstractCommon_BATCH_TEST extends UTIL_AbstractCommon_BATCH {

    /*******************************************************************************************************************
    * @description The number of Accounts to create for test conditions
    */
    private static final Integer TEST_ACCOUNT_CNT = 7;

    private Integer expectedResult;

    /*******************************************************************************************************************
    * @description Test Batch Execution with inner test batch class to test non chunking conditions
    */
    @isTest
    public static void executeTestBatch() {

        List<Account> accs = new List<Account>();

        for (Integer i = 0; i < TEST_ACCOUNT_CNT; i++) {
            accs.add(
                new Account(
                    Name = 'Test Account #' + i
                )
            );
        }
        insert accs;

        Test.startTest();

        UTIL_AbstractCommon_BATCH_TEST tab = new UTIL_AbstractCommon_BATCH_TEST(10);
        tab.setExpectedResult(TEST_ACCOUNT_CNT);
        Database.executeBatch(tab, 10);
        Test.stopTest();
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
                    Name = 'Test Account #' + i
                )
            );
        }
        insert accs;

        Test.startTest();

        UTIL_AbstractCommon_BATCH_TEST tab = new UTIL_AbstractCommon_BATCH_TEST(10, true);
        tab.setExpectedResult(TEST_ACCOUNT_CNT);
        Database.executeBatch(tab, 10);
        Test.stopTest();
    }


    /*******************************************************************************************************************
    * @description Test Additional Constructors for Abstract Batch
    */
    @isTest
    public static void addtlBatchConstructors() {
        UTIL_AbstractCommon_BATCH_TEST tabNoParam = new UTIL_AbstractCommon_BATCH_TEST();
        UTIL_AbstractCommon_BATCH_TEST tabAddtlWhere = new UTIL_AbstractCommon_BATCH_TEST('Name = \'Test Account #1\'');
        UTIL_AbstractCommon_BATCH_TEST tabAddtlWhereLDV = new UTIL_AbstractCommon_BATCH_TEST('Name = \'Test Account #1\'', true);
        UTIL_AbstractCommon_BATCH_TEST tabBatchSize = new UTIL_AbstractCommon_BATCH_TEST(5);
        UTIL_AbstractCommon_BATCH_TEST tabBatchSizeLDV = new UTIL_AbstractCommon_BATCH_TEST(5, true);
        UTIL_AbstractCommon_BATCH_TEST tabAddtlWhereBatchSize = new UTIL_AbstractCommon_BATCH_TEST('Name = \'Test Account #1\'', 5, true);
    }

    /*******************************************************************************************************************
    * @description Test Batch Execution when no records are returned
    */
    @isTest
    public static void noRecordsReturned() {

            Test.startTest();
            UTIL_AbstractCommon_BATCH_TEST tab = new UTIL_AbstractCommon_Batch_TEST(10);
            tab.setExpectedResult(0);

            Database.executeBatch(tab, 10);
            Test.stopTest();
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
     * @param ldvMode - if true, will execute in chunking more regardless of distance between min and max record Id
     */
    public UTIL_AbstractCommon_BATCH_TEST(Integer batchSize, Boolean ldvMode) {
        super(batchSize, ldvMode);
    }

    /**
     * @description Constructor
     * @param addtionalWhereClause Additional Where Clause added to the query used to retrieve the detailed records
     */
    public UTIL_AbstractCommon_BATCH_TEST(String additionalWhereClause) {
        super(additionalWhereClause);
    }

    /**
     * @description Constructor
     * @param addtionalWhereClause Additional Where Clause added to the query used to retrieve the detailed records
     * @param ldvMode - if true, will execute in chunking more regardless of distance between min and max record Id
     */
    public UTIL_AbstractCommon_BATCH_TEST(String additionalWhereClause, Boolean ldvMode) {
        super(additionalWhereClause, ldvMode);
    }


    /**
     * @description Constructor
     * @param addtionalWhereClause Additional Where Clause added to the query used to retrieve the detailed records
     * @param batchSize How many records should be in each batch
     * @param ldvMode - if true, will execute in chunking more regardless of distance between min and max record Id
     */
    public UTIL_AbstractCommon_BATCH_TEST(String additionalWhereClause, Integer batchSize, Boolean ldvMode) {
        super(additionalWhereClause, batchSize, ldvMode);
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
        return 20;
    }

    /**
     * @description Required to set the main object the batch executes against
     */
    public override String getSOQLObjectName() {
        return 'Account';
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
        } else {
            throw new System.AssertException ('Failed to indicate it was complete to doFinish. Test failed.');
        }
    }

}