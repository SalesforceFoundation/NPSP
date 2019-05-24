/*
    Copyright (c) 2017 Salesforce.org
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
* @date 2017
* @group Batch Data Import
* @description Tests for BDI Performance Analysis Logging class for NPSP.
*/

@isTest
public with sharing class BDI_PerfLogger_TEST {

    private static final Id TEST_BATCHID = 'a0o4A000008aNOB';

    /*******************************************************************************************************
    * @description eats up clock cycles for at least duration (milliseconds) specified
    * @return Long the actual time (milliseconds) eaten
    */
    private static Long wait(Long duration) {
        Long tmStart = System.now().getTime();
        while (System.now().getTime() - tmStart < duration) {
            // spin some cycles
            for (Integer i = 0; i < 100; i++) {}
        }
        return System.now().getTime() - tmStart;
    }

    /*******************************************************************************************************
    * @description tests creating PerfLogs, and validates timings correctly work
    * @return void
    */
    static testMethod void testPerfLoggerTiming() {
        BDI_PerfLogger perfLogger = new BDI_PerfLogger(TEST_BATCHID, 1);

        BDI_PerfLogger.PerfLog pl1 = perfLogger.newPerfLog('testLabel1');
        BDI_PerfLogger.PerfLog pl2 = perfLogger.newPerfLog('testLabel2');

        Long duration2 = wait(1000);
        pl2.stop();

        Long duration1 = wait(1000);
        pl1.stop();

        system.assert(pl2.duration >= duration2 && pl2.duration < (duration1 + duration2), 'log2 duration should be in expected range');
        system.assert(pl1.duration >= (duration1 + duration2), 'log1 duration should be in expected range');
        system.assertEquals(1, pl1.countCalls);
        system.assertEquals(1, pl2.countCalls);
    }

    /*******************************************************************************************************
    * @description tests creating PerfLogs, and reusing PerfLogs, and validates timings and count of callers
    * correctly work
    * @return void
    */
    static testMethod void testPerfLoggerMultipleCallsSameLabel() {
        BDI_PerfLogger perfLogger = new BDI_PerfLogger(TEST_BATCHID, 1);

        BDI_PerfLogger.PerfLog pl1 = perfLogger.newPerfLog('testLabel1');
        BDI_PerfLogger.PerfLog pl2 = perfLogger.newPerfLog('testLabel2');

        Long duration1 = wait(1000);
        pl1.stop();

        BDI_PerfLogger.PerfLog pl1b = perfLogger.newPerfLog('testLabel1');
        system.assertEquals(pl1, pl1b);

        Long duration1b = wait(1000);
        pl1b.stop();

        system.assert(pl1b.duration >= (duration1 + duration1b), 'log1 duration should be in expected range');
        system.assertEquals(2, pl1b.countCalls);
        system.assertEquals(1, pl2.countCalls);
    }

    /*******************************************************************************************************
    * @description test creating & timing PerfLogs, and then saving them.  Verifies saved logs are correct.
    * @return void
    */
    static testMethod void testPerfLoggerSaving() {
        BDI_PerfLogger perfLogger = new BDI_PerfLogger(TEST_BATCHID, 1);

        BDI_PerfLogger.PerfLog pl1 = perfLogger.newPerfLog('testLabel1');
        BDI_PerfLogger.PerfLog pl2 = perfLogger.newPerfLog('testLabel2');

        Long duration2 = wait(1000);
        pl2.stop();

        Long duration1 = wait(1000);
        pl1.stop();

        system.assert(pl2.duration >= duration2 && pl2.duration < (duration1 + duration2), 'log2 duration should be in expected range');
        system.assert(pl1.duration >= (duration1 + duration2), 'log1 duration should be in expected range');
        system.assertEquals(1, pl1.countCalls);
        system.assertEquals(1, pl2.countCalls);

        perfLogger.stop();
        perfLogger.save();
        if (pl1.getPerfLogSObject() != null) {
            List<SOBject> logs = database.query('SELECT Id, BDI_Batch__c, Component__c, Label__c, Duration__c, Parent_Duration__c, Number_of_Calls__c ' +
                'FROM PerfLog__c ORDER BY Label__c');
            system.assertEquals(2, logs.size());
            system.assertEquals('testLabel1', logs[0].get('Label__c'));
            system.assertEquals('testLabel2', logs[1].get('Label__c'));
            system.assertEquals(pl1.duration, logs[0].get('Duration__c'));
            system.assertEquals(pl2.duration, logs[1].get('Duration__c'));
            system.assertEquals(1, logs[1].get('Number_of_Calls__c'));
            system.assert(double.valueOf(logs[0].get('Parent_Duration__c')) >= double.valueOf(pl1.duration));
            system.assertEquals(TEST_BATCHID, logs[0].get('BDI_Batch__c'));
        }
    }
}