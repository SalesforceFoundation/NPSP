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
    public Boolean batchRunning { get; set; }
    private ID apexJobId;
    private DateTime dtStart;

    public boolean userCanEditSettings {
        get {
            return Data_Import_Settings__c.SobjectType.getDescribe().isUpdateable();
        }
    }
    
    public BDI_DataImport_CTRL() {
        batchRunning = false;
        apexJobId = null;
        dtStart = null;
        isEditMode = false;
    }

    public PageReference preload() { 
        // force loading data import settings.
        // for some reason, just leaving the references to diSettings in the page
        // wasn't enough to get the settings initially saved (the upsert in the CustomSettingsFacade failed),
        // and our explicit upsert when running the batch would hit a runtime error.
        // by referring to diSettings in our initial action method, the upsert from the Facade succeeds,
        // and our later upsert succeeds!
        diSettings = diSettings;     
        
        return null;
    }
    
    public Data_Import_Settings__c diSettings {
        get {
            if (diSettings == null) {
                diSettings = UTIL_CustomSettingsFacade.getDataImportSettings();
                // our picklist options hold lowercase DIfields
                diSettings.Donation_Matching_Rule__c = diSettings.Donation_Matching_Rule__c.toLowercase();
            }
            return diSettings;
        }
        private set;
    }
    
    /*******************************************************************************************************
    * @description is the panel in Edit Mode
    */ 
    public boolean isEditMode { get; set; }
    
    /*********************************************************************************************************
    * @description puts the Settings panel into Edit mode.
    * @return null
    */
    public PageReference editBDISettings() {
        isEditMode = true;
        return null;
    }        

    /*********************************************************************************************************
    * @description saves the Settings, and puts panel into readonly mode.
    * @return null
    */
    public PageReference saveBDISettings() {

        if (BDI_SettingsUI_CTRL.saveBDISettings(diSettings)) {
            isEditMode = false;
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
        if (String.isBlank(retUrl)) retUrl = '/home/home.jsp';

        PageReference p = new PageReference(retUrl);
        p.setRedirect(true);
        return p;
    }
    
    /*********************************************************************************************************
    * @description starts the batch job to import data
    * @return null
    */
    public PageReference importData() {
        if (userCanEditSettings && !BDI_SettingsUI_CTRL.saveBDISettings(diSettings)) {
            return null;
        }

        dtStart = system.now();
        apexJobId = BDI_DataImport_API.importData();
        if(apexJobId != null)
            batchRunning = true;
        return null;
    }

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
    
    public string strBatchStatus {
        get {
            string strLabel = (aaj.Status == 'Processing' ? label.bdiStatusProcessing : label.bdiStatusProcessed);
            return string.format(strLabel, new string[]{string.valueOf(aaj.JobItemsProcessed), string.valueOf(aaj.TotalJobItems)});
        }
    }
    
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

    public integer crecImported { 
        get {
            if (apexJobId != null) {
                crecImported = [select count() from DataImport__c where Status__c = :label.bdiImported and ApexJobId__c = :apexJobId];
                return crecImported;
            }
            return null;
        }
        set;
    }

    public integer crecFailed { 
        get {
            if (apexJobId != null) {
                crecFailed = [select count() from DataImport__c where Status__c = :label.bdiFailed and ApexJobId__c = :apexJobId];
                return crecFailed;
            }
            return null;
        }
        set;
    }

    public integer crecToProcess {
        get {
            crecToProcess = [select count() from DataImport__c where Status__c <> :label.bdiImported];
            return crecToProcess;
        }
        set;
    }

    public boolean isBatchJobCompleted { 
        get {
            return (batchRunning == true && (aaj.Status == 'Completed' || aaj.Status == 'Failed' || aaj.Status == 'Aborted'));
        }
        set;
    }

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
