/*
    Copyright (c) 2015 Salesforce.org
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
* @date 2015
* @group API
* @group-content ../../ApexDocContent/API.htm
* @description API class that exposes data import functionality.
*/
global with sharing class BDI_DataImport_API {

     private class BDIException extends Exception {}

    /*******************************************************************************************************
    * @description string values for different matching behaviors BDI can support.  couldn't use an enum
    * since we need to store it in a custom settings text field.
    */
    global static final string DoNotMatch = 'Do Not Match'; // Don't Match. Always create new Opportunities.
    global static final string RequireNoMatch = 'No Match'; // Always create.  Show error if any match.
    global static final string RequireExactMatch = 'Single Match'; // Use exact match. Show error if there isn't an exact match or there are no matches.
    global static final string ExactMatchOrCreate = 'Single Match or Create'; // Use exact match. Show error if there isn't an exact match. Create opportunity if there are no matches.
    global static final string RequireBestMatch = 'Best Match'; // Use the best match. Show error if no match.
    global static final string BestMatchOrCreate = 'Best Match or Create'; // Use the best match. Create opportunity if no match.

    /*******************************************************************************************************
    * @description master values for the BDI Status field picklist
    */
    global static final string bdiImported = 'Imported';
    global static final string bdiFailed = 'Failed';
    global static final string bdiDryRunValidated = 'Dry Run - Validated';
    global static final string bdiDryRunError = 'Dry Run - Error';
    global static final String bdiProcessing = 'Processing';

    global static final String BATCH_STATUS_OPEN = 'Open';
    global static final String BATCH_STATUS_COMPLETED = 'Completed';
    global static final String BATCH_STATUS_FAILED = 'Failed - Needs Review';


    /*******************************************************************************************************
    * @description Imports all DataImport records that have not been previously imported and do not belong
    * to any specific batch. Their status is changed to imported, once the process finishes.
    * @return ID The ID of the batch job that performs the data import.
    */
    global static ID importData() {
        list<ProcessDataImportBatchesResult> listResult = processDataImportBatches(new list<ID>{null});
        if (listResult != null) {
            return listResult[0].apexJobId;
        } else {
            return null;
        }
    }

    /*******************************************************************************************************
    * @description Imports all DataImport records that have not been previously imported.
    * Their status is changed to imported, once the process finishes.
    * @param listbatchId the batch(es) to scope processing to.  Can be a list containing a null Id for all
    * records not referenced by any Batch.
    * @return list<ProcessDataImportBatchesResult> a list of Result classes
    */
    @InvocableMethod(label='processDataImportBatches' description='starts the batch processing of a list of DataImport batches')
    global static list<ProcessDataImportBatchesResult> processDataImportBatches(list<ID> listBatchId) {

        return processDataImportBatches(listBatchId, false);
    }

    /*******************************************************************************************************
    * @description Processes all DataImport records that have not been previously imported in either
    * Dry Run Mode, or for actual Commit. Their status is updated, once the process finishes.
    * @param listbatchId the batch(es) to scope processing to.  Can be a list containing a null Id for all
    * records not referenced by any Batch.
    * @param isDryRun whether to run in Dry Run mode or commit records.
    * @return list<ProcessDataImportBatchesResult> a list of Result classes
    */
    global static list<ProcessDataImportBatchesResult> processDataImportBatches(list<ID> listBatchId, Boolean isDryRun) {

        list<ProcessDataImportBatchesResult> listResult = new list<ProcessDataImportBatchesResult>();

        Savepoint sp = Database.setSavepoint();
        for (ID batchId : listBatchId) {
            try {
                BDI_DataImport_BATCH batch = new BDI_DataImport_BATCH(batchId, isDryRun);
                listResult.add(new ProcessDataImportBatchesResult(Database.executeBatch(batch, integer.valueOf(batch.diSettings.Batch_Size__c))));
            } catch (exception ex) {
                Database.rollback(sp);
                ex.setMessage('Error encountered in batch: ' + batchId + '. ' + ex.getMessage());
                throw ex;
            }
        }
        return listResult;
    }

    /*******************************************************************************************************
    * @description Process the provided list of DataImport records
    * @param diSettings the settings to control processing behavior
    * @param listDI a list of Data Import records to process
    * @param isDryRun whether to process in Dry Run mode or commit records.
    * @return void
    */
    global static void processDataImportRecords(Data_Import_Settings__c diSettings, List<DataImport__c> listDI, Boolean isDryRun) {
        BDI_DataImportService bdi = new BDI_DataImportService(isDryRun, 
            BDI_DataImportService.getDefaultMappingService());
        bdi.process(null, diSettings, listDI);
    }

    /*******************************************************************************************************
    * @description The return result object for each batch that is provided to processDataImportBatches()
    */
    global class ProcessDataImportBatchesResult {

        /*******************************************************************************************************
        * @description The return result object for each batch that is provided to processDataImportBatches()
        */
        @InvocableVariable
        global ID apexJobId;

        /*******************************************************************************************************
        * @description constructor
        */
        ProcessDataImportBatchesResult(ID apexJobId) {
            this.apexJobId = apexJobId;
        }
    }

}