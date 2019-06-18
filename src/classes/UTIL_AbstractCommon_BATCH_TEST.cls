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

    /*******************************************************************************************************************
    * @description Test Batch Execution with inner test batch class to iterate over and count Accounts while simulating
    * Chunking conditions
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
        Database.executeBatch(tab, 10);
        Test.stopTest();



    }

    /* Batch Implementation Here... */

    private Integer recCnt = 0;

    public UTIL_AbstractCommon_BATCH_TEST() {
        super();
    }

    public UTIL_AbstractCommon_BATCH_TEST(Integer batchSize) {
        super(batchSize);
    }
    public override void doExecute(Database.BatchableContext bc, List<SObject>records ) {
        recCnt += records.size();
    }

    public override Integer getLDVChunkSize() {
        return 20;
    }

    public override String getSOQLObjectName() {
        return 'Account';
    }

    public override void doFinish(Database.BatchableContext bc , Boolean isComplete) {
        if (isComplete) {
            System.assertEquals (TEST_ACCOUNT_CNT, recCnt, 'Account Count Mismatch');
            System.debug('# of Account Records Found: ' + recCnt);
        } else {
            throw new System.AssertException ('Failed to indicate it was complete to doFinish. Test failed.');
        }
    }

}