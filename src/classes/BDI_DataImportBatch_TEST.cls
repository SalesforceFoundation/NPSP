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
* @group-content ../../ApexDocContent/BatchDataImport.htm
* @description tests specific to the Batch Data Importer Schedule class
*/

@isTest
public with sharing class BDI_DataImportBatch_TEST {

    /*********************************************************************************************************
    * @description operation
    *     schedule a run with one batch to import
    * verify:
    *     one batch is scheduled
    */
    static testMethod void scheduleSingleBatch() {
        system.assertEquals(1, scheduleNBatches(1));
    }

    /*********************************************************************************************************
    * @description operation
    *     schedule a run with multiple batches to import
    * verify:
    *     multiple batches are scheduled
    */
    static testMethod void scheduleMultipleBatches() {
        system.assertEquals(3, scheduleNBatches(3));
    }

    /*********************************************************************************************************
    * @description operation
    *     schedule a run with max multiple batches to import
    * verify:
    *     multiple batches are scheduled
    */
    static testMethod void scheduleMaxMultipleBatches() {
        integer maxSOQL = limits.getLimitQueries() - limits.getQueries();
        integer maxAsync = limits.getLimitQueueableJobs() - limits.getQueueableJobs();
        integer nBatches = math.min(maxAsync, maxSOQL);

        system.assertEquals(nBatches, scheduleNBatches(nBatches));
    }

    /*********************************************************************************************************
    * @description operation
    *     schedule a run with too many multiple batches to import
    * verify:
    *     multiple batches are scheduled, but not all
    */
    static testMethod void scheduleTooManyMultipleBatches() {
        integer maxSOQL = limits.getLimitQueries() - limits.getQueries();
        integer maxAsync = limits.getLimitQueueableJobs() - limits.getQueueableJobs();
        integer nBatches = math.min(maxAsync, maxSOQL);

        system.assertEquals(nBatches, scheduleNBatches(nBatches + 1));
    }

    /*********************************************************************************************************
    * @description operation
    *     schedule a run with max multiple batches to import
    * verify:
    *     multiple batches are scheduled
    * @param numberOfBatches How many batches to create for scheduling
    * @return integer The number of batches that got scheduled
    */
    static integer scheduleNBatches(integer numberOfBatches) {
        list<DataImport__c> listDI = new list<DataImport__c>();

        // create our N batches to be scheduled
        for (integer i = 0; i < numberOfBatches; i++) {
            DataImportBatch__c batch = BDI_DataImportAPI_TEST.newBatch('b' + i, true);
            listDI.add(BDI_DataImportAPI_TEST.newDI(batch.Id, 'c1', 'C1'));
        }

        // add a batch that isn't set for scheduled processing
        DataImportBatch__c batch2 = BDI_DataImportAPI_TEST.newBatch('b2', false);
        listDI.add(BDI_DataImportAPI_TEST.newDI(batch2.Id, 'c2', 'C2'));

        // add a DI record with no batch
        listDI.add(BDI_DataImportAPI_TEST.newDI(null, 'c3', 'C3'));

        insert listDI;

        //run batch data import
        Test.StartTest();
        String sch = '0 0 0 * * ? *';
        system.schedule('Test BDI Scheduled Batch', sch, new BDI_DataImportBatch_SCHED());
        Test.stopTest();

        // There will now be two things in AsyncApexJob - the Schedulable itself
        // and also the Batch Apex job. This code looks for both of them.
        // note that you can't assert that the data import occurred, because stopTest() only ensures the Scheduler got run
        // but won't cause the batch invoked by the scheduler to run!

        // Check schedulable is in the job list
        List<AsyncApexJob> jobsScheduled = [select Id, ApexClassID, ApexClass.Name, Status, JobType from AsyncApexJob where JobType = 'ScheduledApex'];
        System.assertEquals(1, jobsScheduled.size(), 'expecting one scheduled job');
        System.assertEquals('BDI_DataImportBatch_SCHED', jobsScheduled[0].ApexClass.Name, 'expecting specific scheduled job');

        // check apex batch is in the job list
        List<AsyncApexJob> jobsApexBatch = [select Id, ApexClassID, ApexClass.Name, Status, JobType from AsyncApexJob where JobType = 'BatchApex'];
        if (jobsApexBatch.size() > 0) {
            System.assertEquals('BDI_DataImport_BATCH', jobsApexBatch[0].ApexClass.Name, 'expecting specific batch job');
        }

        return jobsApexBatch.size();
    }
}