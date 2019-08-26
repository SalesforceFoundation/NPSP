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
* @group Allocations
* @group-content ../../ApexDocContent/Allocations.htm
* @description Tests for ALLO_ScheduleAllocationBatch
*/
@isTest
public with sharing class ALLO_ScheduleAllocationBatch_TEST {

    /*******************************************************************************************************
    * @description This method tests to make sure the schedulable class kicks off the batch class appropriately.
    ********************************************************************************************************/
    static testMethod void testSchedulableExecutionRunsBatch() {
        String CRON_EXP = '0 0 0 15 3 ? *';


        Test.startTest();

        String jobId = System.schedule('ScheduleApexClassTest',  CRON_EXP, new ALLO_ScheduleAllocationBatch());
        CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered, NextFireTime FROM CronTrigger WHERE ID = :jobId];
        System.assertEquals(CRON_EXP, ct.CronExpression);
        System.assertEquals(0, ct.TimesTriggered);

        Test.stopTest();

        String batchClassName = UTIL_Namespace.StrTokenNSPrefix('ALLO_UpdPaymentAllocations_BATCH');
        List<ApexClass> batchClasses = [SELECT Id FROM ApexClass WHERE Name =: batchClassName];

        Integer batchJobAsyncJobCount = [SELECT COUNT() FROM AsyncApexJob WHERE ApexClassId =: batchClasses[0].Id];

        System.assertEquals(1, batchJobAsyncJobCount, 'The batch job was not executed');
        // Add assert here to validate result
    }
}