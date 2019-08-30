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
* @description Mock Batch Class for tests of UTIL_AbstractCommon_BATCH class
*/
@isTest
public class UTIL_AbstractCommon_MOCK extends UTIL_AbstractCommon_BATCH {

    private Integer expectedResult;
    private Integer testChunkSize = 1;
    private Integer testMaxNonLDVSize = 1;
    private String testWhereClause = '';

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
    public UTIL_AbstractCommon_MOCK() {
        super();
    }

    /**
     * @description Constructor
     * @param batchSize How many records should be in each batch
     */
    public UTIL_AbstractCommon_MOCK(Integer batchSize) {
        super(batchSize);
    }

    /**
     * @description Constructor
     * @param batchSize How many records should be in each batch
     * @param additionalWhereClause If present will be added to the inner query, or the batch query if executing in non ldv mode.
     */
    public UTIL_AbstractCommon_MOCK(Integer batchSize, String additionalWhereClause) {
        super(batchSize, additionalWhereClause);
    }

    /**
     * @description Constructor
     * @param ldvMode - if true, will execute in chunking more regardless of distance between min and max record Id
     */
    public UTIL_AbstractCommon_MOCK(Boolean ldvMode) {
        super(ldvMode);
    }

    /**
     * @description Constructor
     * @param ldvMode - if true, will execute in chunking more regardless of distance between min and max record Id
     * @param additionalWhereClause If present will be added to the inner query, or the batch query if executing in non ldv mode.
     */
    public UTIL_AbstractCommon_MOCK(Boolean ldvMode, String additionalWhereClause) {
        super(ldvMode, additionalWhereClause);
    }

    /**
     * @description Constructor
     * @param batchSize How many records should be in each batch
     * @param ldvMode - if true, will execute in chunking more regardless of distance between min and max record Id
     * @param additionalWhereClause If present will be added to the inner query, or the batch query if executing in non ldv mode.
     */
    public UTIL_AbstractCommon_MOCK(Integer batchSize, Boolean ldvMode, String additionalWhereClause) {
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
     * @return Integer size to limit batch results to when running in LDV Chunking mode
     */
    public override Integer getLDVChunkSize() {
        return this.testChunkSize;
    }

    /**
     * @description Here to allow overriding of Max Non LDV Record Count (Size)
     * @return Integer Maximum number of records that be present for the distance check before running in LDV mode
     */
    public override Integer getMaxNonLDVSize() {
        return this.testMaxNonLDVSize;
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

    /**
     * @description Allows the test batches max non ldv size to be configured for specific tests
     * @param Integer testMaxNonLDVSize Size to set the maxNonLDVSize to
     */
    public void setTestMaxNonLDVSize(Integer testMaxNonLDVSize) {
        this.testMaxNonLDVSize = testMaxNonLDVSize;
    }

}