/*
    Copyright (c) 2014 Salesforce.org
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
* @date 2014
* @group Batch Data Import
* @group-content ../../ApexDocContent/BatchDataImport.htm
* @description Batch class for the Batch Data Importer.
*
* Batch process looks for all DataImport records that need to be processed
*
*/
public class BDI_DataImport_BATCH implements Database.Batchable<sObject> {

    /*******************************************************************************************************
    * @description the soql string of DataImport records for the entire batch to run against
    */
    private String strSoql;

    /*******************************************************************************************************
    * @description the Data Import Settings to use for this batch
    */
    public Data_Import_Settings__c diSettings;

    /*******************************************************************************************************
    * @description the optional Data Import Batch being processed
    */
    public Id batchId;

    /*******************************************************************************************************
    * @description whether to process the batch in Dry Run mode
    */
    public Boolean isDryRun;

    /*******************************************************************************************************
    * @description constructor, which sets up our initial soql
    */
    public BDI_DataImport_BATCH() {
        this(null, false);
    }

    /*******************************************************************************************************
    * @description constructor that takes a specific batch, which sets up our initial soql
    * and loads the appropriate data import settings.
    * @param batchId the specific batch to process
    * @param isDryRun whether to run in Dry Run mode or commit records.
    */
    public BDI_DataImport_BATCH(ID batchId, Boolean isDryRun) {
        // remember our batchId
        this.batchId = batchId;

        this.isDryRun = isDryRun;

        // now load our settings
        diSettings = BDI_DataImportService.loadSettings(batchId);

        // and make sure settings are valid
        BDI_DataImportService.validateSettings(diSettings);

        // get the appropriate soql for the DI records
        strSoql = BDI_DataImportService.strSoqlForBatchProcess(batchId);
    }

    /*******************************************************************************************************
    * @description Start method of the Batchable interface
    * @return QueryLocator the BDI records to process
    */
    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator(strSoql);
    }
    
    /*******************************************************************************************************
    * @description The real work gets done here! Given a list of di records, process them.
    * @param listDI a list of Data Import records to import
    * @return void
    */
    public void execute(Database.BatchableContext bc, List<DataImport__c> listDI) {
        BDI_DataImportService.execute(bc.getJobId(), diSettings, listDI, isDryRun);
    }

    /*******************************************************************************************************
    * @description Batchable finish method, that will update the (optional) Batch's statistics.
    * @param bc The BatchableContext
    * @return void
    */
    public void finish(Database.BatchableContext bc) {
        if (!isDryRun) {
            BDI_DataImportService.updateDIBatchStatistics(bc.getJobId(), batchId);
        }
    }
}