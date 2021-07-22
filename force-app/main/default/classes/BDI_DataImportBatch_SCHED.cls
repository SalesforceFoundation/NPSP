/*
    Copyright (c) 2017, Salesforce.org
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
* @description Schedulable class that creates the batch processes to process any specified NPSP Data Import Batches
*/
public without sharing class BDI_DataImportBatch_SCHED implements Schedulable {

    /*******************************************************************************************************
    * @description Schedulable execute method executes this batch job.
    * @return void
    */
    public void execute(SchedulableContext context) {
        try {
            // get the Id's of batches we should process
            list<Id> listIdBatches = BDI_DataImportBatch_SEL.selectUsingScheduledProcessing();

            // if we found some, process via our api
            if (listIdBatches.size() > 0) {

                // ensure we don't blow thru available soql limits, as we will
                // issue one soql per batch to initialize it.
                // also avoid async limits.
                integer maxSOQL = limits.getLimitQueries() - limits.getQueries();
                integer maxAsync = limits.getLimitQueueableJobs() - limits.getQueueableJobs();
                integer numTrim = listIDBatches.size() - math.min(maxAsync, maxSOQL);

                if (numTrim > 0) {
                    for (integer i = listIDBatches.size()-1; numTrim > 0; i--) {
                        listIdBatches.remove(i);
                        numTrim--;
                    }
                }
                BDI_DataImport_API.processDataImportBatches(listIdBatches);
            }
        } catch (Exception e) {
            ERR_Handler.processError(e, ERR_Handler_API.Context.BDI);
        }
    }
}