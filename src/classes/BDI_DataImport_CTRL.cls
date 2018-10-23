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
* @description controller for the NPSP Data Importer visualforce page 
*/

public with sharing class BDI_DataImport_CTRL {

    /*******************************************************************************************************
    * @description is the batch currently running
    */
    public Boolean batchRunning { get; set; }

    /*******************************************************************************************************
    * @description is the batch currently running in Dry Run mode
    */
    public Boolean isDryRun { get; set; }

    /*******************************************************************************************************
    * @description the job Id of the currently running batch
    */
    private ID apexJobId;

    /*******************************************************************************************************
    * @description when the batch process was started
    */
    private DateTime dtStart;

    /*******************************************************************************************************
    * @description does the user have permissions to update these batch/settings
    */
    public boolean userCanEditSettings {
        get {
            return isTrueBatch ?
                DataImportBatch__c.SobjectType.getDescribe().isUpdateable() :
                Data_Import_Settings__c.SobjectType.getDescribe().isUpdateable();
        } private set;
    }
    
    /*******************************************************************************************************
    * @description constructor
    */
    public BDI_DataImport_CTRL() {
        batchRunning = false;
        isDryRun = false;
        apexJobId = null;
        dtStart = null;
        isEditMode = false;

        // load up default settings or a specified batch
        loadBatchAndSettings(ApexPages.currentPage().getParameters().get('batchId'));
    }

    /*******************************************************************************************************
    * @description loads up the specified batch and it settings, or loads custom settings if no batch
    * @return null
    */
    private void loadBatchAndSettings(string strBatchId) {
        if (string.isNotBlank(strBatchId)) {
            // load up the batch and get our settings from it
            diBatch = BDI_DataImportBatch_SEL.selectById(strBatchId);
            diSettings = BDI_DataImportService.diSettingsFromDiBatch(diBatch);
            diTemp.NPSP_Data_Import_Batch__c = diBatch.Id;
        } else {
            diSettings = UTIL_CustomSettingsFacade.getDataImportSettings();
            // need to create our in-memory batch to hold the custom settings
            diBatch = BDI_DataImportService.diBatchFromDiSettings(diSettings);
        }

        // our picklist options hold lowercase DIfields
        diBatch.Donation_Matching_Rule__c = diBatch.Donation_Matching_Rule__c.toLowercase();
    }

    /*******************************************************************************************************
    * @description initial actionMethod called when page first loaded.  handles loading custom settings.
    * @return null
    */
    public PageReference preload() {
        return null;
    }
    
    /*******************************************************************************************************
    * @description the initial custom settings object we defaultly load.  will be converted to a diBatch.
    */
    @TestVisible
    private Data_Import_Settings__c diSettings { get; set; }

    /*******************************************************************************************************
    * @description the current batch we are going to process.  it will be an in-memory only batch (no Id)
    * if we are going to process records that have no batch.
    */
    public DataImportBatch__c diBatch { get; private set; }

    /*******************************************************************************************************
    * @description a temporary DataImport record, we can use to bind the Batch lookup to in the UI.
    */
    public DataImport__c diTemp {
        get {
            if (diTemp == null) {
                diTemp = new DataImport__c();
            }
            return diTemp;
        }
        private set;
    }

    /*******************************************************************************************************
    * @description whether we are processing a real saved batch, or just using custom settings with an
    * in-memory batch.
    */
    public Boolean isTrueBatch {
        get {
            return diBatch.Id != null;
        } private set;
    }
    
    /*******************************************************************************************************
    * @description is the panel in Edit Mode
    */ 
    public boolean isEditMode { get; set; }

    /*********************************************************************************************************
    * @description puts the Settings panel into Edit mode
    * @return null
    */
    public PageReference editBDISettings() {
        isEditMode = true;
        return null;
    }        

    /*********************************************************************************************************
    * @description saves the Batch/Settings, and puts panel into readonly mode.
    * @return null
    */
    public PageReference saveBDISettings() {

        try {
            if (!userCanEditSettings) {
                String strObj = isTrueBatch ?
                    DataImportBatch__c.SobjectType.class.getName() :
                    Data_Import_Settings__c.SObjectType.class.getName();
                throw(new BDIException(String.format(Label.flsError, new list<String>{strObj})));
            }

            // first validate the settings
            Data_Import_Settings__c diSettingsT = BDI_DataImportService.diSettingsFromDiBatch(diBatch);
            if (isTrueBatch) {
                BDI_DataImportService.validateSettings(diBatch);
            } else {
                BDI_DataImportService.validateSettings(diSettingsT);
            }

            // update the correct object (batch vs custom settings)
            if (isTrueBatch) {
                UTIL_DMLService.upsertRecord(diBatch);
            } else {
                diSettingsT.Id = diSettings.Id;
                UTIL_DMLService.upsertRecord(diSettingsT);
                diSettings = diSettingsT;
            }
            isEditMode = false;
        } catch (Exception ex) {
            ApexPages.addMessages(ex);
        }
        return null;

    }        
    
    /*********************************************************************************************************
    * @description puts the Settings panel into readonly mode.
    * @return null
    */
    public PageReference cancelBDISettings() {
        isEditMode = false;
        return null;
    }        

    /*********************************************************************************************************
    * @description closes the page and returns to the original calling page
    * @return PageReference
    */
    public PageReference close() {
        String retUrl = ApexPages.currentPage().getParameters().get('retURL');
        PageReference p;
        if (!String.isBlank(retUrl)) {
            p = new PageReference(retUrl);
        } else {
            p = USER_UserService.getHomePageReference();
        }
        p.setRedirect(true);
        return p;
    }
    
    /*********************************************************************************************************
    * @description starts the batch job to import data
    * @return null
    */
    public PageReference importData() {

        dtStart = system.now();
        try {
            list<BDI_DataImport_API.ProcessDataImportBatchesResult> listResults =
                BDI_DataImport_API.processDataImportBatches(new list<Id>{diBatch.Id});
            apexJobId = listResults[0].apexJobId;
            if (apexJobId != null) {
                batchRunning = true;
            }
        } catch (Exception ex) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ex.getMessage()));
            batchRunning = false;
        }
        return null;
    }

    /*********************************************************************************************************
    * @description starts the batch job to process data in Dry Run mode
    * @return null
    */
    public PageReference startDryRun() {

        dtStart = system.now();
        try {
            list<BDI_DataImport_API.ProcessDataImportBatchesResult> listResults =
                BDI_DataImport_API.processDataImportBatches(new list<Id>{diBatch.Id}, true);
            apexJobId = listResults[0].apexJobId;
            if (apexJobId != null) {
                batchRunning = true;
                isDryRun = true;
            }
        } catch (Exception ex) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ex.getMessage()));
            batchRunning = false;
            isDryRun = false;
        }
        return null;
    }

    /*******************************************************************************************************
    * @description our exception object for BDI errors.
    */
    private class BDIException extends Exception {}

    /*******************************************************************************************************
    * @description the AsyncApexJob for the running batch job
    */
    public AsyncApexJob aaj {
        get {
            if (apexJobId != null) {
                aaj = [select TotalJobItems, Status, ExtendedStatus, NumberOfErrors, MethodName, JobType, JobItemsProcessed, Id, 
                                    CreatedDate, CreatedById, CompletedDate, ApexClassId, ApexClass.Name, CreatedBy.Name
                                    From AsyncApexJob where Id = :apexJobId];
            }
            return aaj;
        }
        private set;
    }
    
    /*******************************************************************************************************
    * @description the current status of the batch job
    */
    public string strBatchStatus {
        get {
            string strLabel = (aaj.Status == 'Processing' ? label.bdiStatusProcessing : label.bdiStatusProcessed);
            return string.format(strLabel, new string[]{string.valueOf(aaj.JobItemsProcessed), string.valueOf(aaj.TotalJobItems)});
        } private set;
    }
    
    /*******************************************************************************************************
    * @description the number of records processed for the batch job
    */
    public integer crecProcessed {
        get {
            if (apexJobId != null) {
                crecProcessed = [select count() from DataImport__c where ApexJobId__c = :apexJobId];
                return crecProcessed;
            }
            return null;
        }
        set;
    }

    /*******************************************************************************************************
    * @description the number of records successfully imported for the batch job
    */
    public integer crecImported {
        get {
            if (apexJobId != null) {
                String status = isDryRun ? BDI_DataImport_API.bdiDryRunValidated : BDI_DataImport_API.bdiImported;
                crecImported = [select count() from DataImport__c where Status__c = :status and ApexJobId__c = :apexJobId];
                return crecImported;
            }
            return null;
        }
        set;
    }

    /*******************************************************************************************************
    * @description the number of records that failed to import for the batch job
    */
    public integer crecFailed {
        get {
            if (apexJobId != null) {
                String status = isDryRun ? BDI_DataImport_API.bdiDryRunError : BDI_DataImport_API.bdiFailed;
                crecFailed = [select count() from DataImport__c where Status__c = :status and ApexJobId__c = :apexJobId];
                return crecFailed;
            }
            return null;
        }
        set;
    }

    /*******************************************************************************************************
    * @description the number of records to process at the beginning of the job.  it does not reflect
    * how many are left to process, since validated and failed records would get counted, and you
    * can't tell if they were already processed or not.
    */
    public integer crecToProcess {
        get {
            crecToProcess = [select count() from DataImport__c where Status__c <> :BDI_DataImport_API.bdiImported and
            NPSP_Data_Import_Batch__c = :diBatch.Id];
            return crecToProcess;
        }
        set;
    }

    /*******************************************************************************************************
    * @description whether the batch job has completed processing
    */
    public boolean isBatchJobCompleted {
        get {
            return (batchRunning == true && (aaj.Status == 'Completed' || aaj.Status == 'Failed' || aaj.Status == 'Aborted'));
        }
        set;
    }

    /*******************************************************************************************************
    * @description the percentage completed for the batch job
    */
    public integer percentComplete {
        get {
            if (aaj != null) {
                //Determine the percent complete based on the number of batches complete
                if (aaj.status == 'Completed') {
                    percentComplete = 100;
                } else if (aaj.status == 'Queued') {
                    percentComplete = 5;
                } else if (aaj.status == 'Preparing') {
                    percentComplete = 10;
                } else if (aaj.TotalJobItems == 0) {
                    //A little check here as we don't want to divide by 0.
                    percentComplete = 5;
                } else {
                    decimal dec = decimal.valueOf(aaj.JobItemsProcessed) / decimal.valueOf(aaj.TotalJobItems);
                    percentComplete = (dec * 100.0).intValue();
                    //don't let it go backwards from preparing/queued
                    if (percentComplete == 0 || percentComplete == null)
                        percentComplete = 10;
                }
                return percentComplete;
            } else {
                return 0;
            }   
        }
        private set;
    }

    /*******************************************************************************************************
    * @description the amount of time, formatted as a string, spent processing the batch job
    */
    public string strTimeSpent {
        get {
            if (dtStart != null && !isBatchJobCompleted) {
                DateTime dt = DateTime.newInstance(system.Now().getTime() - dtStart.getTime());
                strTimeSpent = dt.format('m:ss');
                return strTimeSpent;
            } else if (isBatchJobCompleted) {
                return strTimeSpent;
            } else {
                return null;
            }
        }
        private set;
    }

}