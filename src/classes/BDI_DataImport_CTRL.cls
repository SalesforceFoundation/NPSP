public with sharing class BDI_DataImport_CTRL {
	
	public BDI_DataImport_CTRL() {
		batchRunning = false;
		bdi = null;
		ApexJobId = null;
		dtStart = null;
	}

    public PageReference actionImportOrDelete() {        
        String strAction = ApexPages.currentPage().getParameters().get('action');
        if (strAction == 'deleteImported') {
            return deleteImportedDIRecords();    
        } else if (strAction == 'deleteAll') {
            return deleteAllDIRecords();	
        }
        // else we load up the DataImport page.       
        return null;
    }
    
    public PageReference deleteImportedDIRecords() {
        for (list<DataImport__c> listDI : [select Id from DataImport__c where Status__c = 'Imported'])
            delete listDI;
        return (close());    	
    }
    
    public PageReference deleteAllDIRecords() {
    	for (list<DataImport__c> listDI : [select Id from DataImport__c])
            delete listDI; 
        return (close());
    }
    
    public BDI_DataImport_BATCH bdi { get; set; }
    public Boolean batchRunning { get; set; }
    private ID ApexJobId;
    private DateTime dtStart;
    
    public Data_Import_Settings__c diSettings {
        get {
        	if (diSettings == null) {
                diSettings = UTIL_CustomSettingsFacade.getDataImportSettings();
        	}
        	return diSettings;
        }
        private set;
    }

    // action method that user wants to close this page
    public PageReference close() {
        string strURL = ApexPages.currentPage().getParameters().get('retURL');
        if (strURL == null || strURL == '') strURL = '/home/home.jsp';
        PageReference p = new PageReference(strURL);
        p.setRedirect(true);
        return p;
    }

    private class BDICtrlException extends Exception {}
    
    public PageReference importData() {
        try {
        	// validate settings
        	if (diSettings.Contact_Custom_Unique_ID__c != null) {
                // make sure c1 and c2 have the appropriately named field
        	    if (!UTIL_Describe.isValidField(UTIL_Namespace.StrTokenNSPrefix('DataImport__c'), 'Contact1_' + diSettings.Contact_Custom_Unique_ID__c) ||
        	       !UTIL_Describe.isValidField(UTIL_Namespace.StrTokenNSPrefix('DataImport__c'), 'Contact2_' + diSettings.Contact_Custom_Unique_ID__c)) {
                    throw(new BDICtrlException(string.format(Label.bdiContactCustomIdError, 
                        new string[]{diSettings.Contact_Custom_Unique_ID__c, 
                        	'Contact1_' + diSettings.Contact_Custom_Unique_ID__c,
                        	'Contact2_' + diSettings.Contact_Custom_Unique_ID__c})));
        	    }
        	}
        	
            if (diSettings.Account_Custom_Unique_ID__c != null) {
                // make sure a1 and a2 have the appropriately named field
                if (!UTIL_Describe.isValidField(UTIL_Namespace.StrTokenNSPrefix('DataImport__c'), 'Account1_' + diSettings.Contact_Custom_Unique_ID__c) ||
                   !UTIL_Describe.isValidField(UTIL_Namespace.StrTokenNSPrefix('DataImport__c'), 'Account2_' + diSettings.Contact_Custom_Unique_ID__c)) {
                    throw(new BDICtrlException(string.format(Label.bdiAccountCustomIdError, 
                        new string[]{diSettings.Account_Custom_Unique_ID__c, 
                            'Account1_' + diSettings.Account_Custom_Unique_ID__c,
                            'Account2_' + diSettings.Account_Custom_Unique_ID__c})));
                }
            }
            
        	// save any settings changes.
        	upsert diSettings;
        	
            batchRunning = true;
            bdi = new BDI_DataImport_BATCH();
            ApexJobId = Database.executeBatch(bdi, integer.valueOf(diSettings.Batch_Size__c));
            dtStart = system.now();

        } catch (Exception ex) {
            // no reason to log the error if we haven't started the batch,
            // since it is just a validation error that we are displaying on the page.
            if (batchRunning)
                ERR_Handler.processError(ex, ERR_Handler.Context.BDI);
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ex.getMessage()));
        }
        return null;
    }

    public AsyncApexJob aaj {
        get {
            if (ApexJobId != null) {
                aaj = [select TotalJobItems, Status, ExtendedStatus, NumberOfErrors, MethodName, JobType, JobItemsProcessed, Id, 
                                    CreatedDate, CreatedById, CompletedDate, ApexClassId, ApexClass.Name, CreatedBy.Name
                                    From AsyncApexJob where Id = :ApexJobId];
            }
            return aaj;
        }
        private set;
    }
    
    public integer crecProcessed { 
        get {
            if (ApexJobId != null) {
                crecProcessed = [select count() from DataImport__c where ApexJobId__c = :ApexJobId];
                return crecProcessed;
            }
            return null;
        }
        set;
    }

    public integer crecImported { 
        get {
            if (ApexJobId != null) {
                crecImported = [select count() from DataImport__c where Status__c = 'Imported' and ApexJobId__c = :ApexJobId];
                return crecImported;
            }
            return null;
        }
        set;
    }

    public integer crecFailed { 
        get {
            if (ApexJobId != null) {
                crecFailed = [select count() from DataImport__c where Status__c = 'Failed' and ApexJobId__c = :ApexJobId];
                return crecFailed;
            }
            return null;
        }
        set;
    }

    public integer crecToProcess {
        get {
            crecToProcess = [select count() from DataImport__c where Status__c <> 'Imported'];
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

    public list<SelectOption> listSOContactUniqueID {
        get {
            if (listSOContactUniqueID == null) {
                listSOContactUniqueID = new list<SelectOption>();
                //add a default option
                listSOContactUniqueID.add(new SelectOption('', Label.stgLabelNone));
                            
                Map<String, Schema.DescribeFieldResult> mapNameToDfr = UTIL_Describe.getAllFieldsDescribe('Contact');               
                for (Schema.DescribeFieldResult dfr : mapNameToDfr.values()) {
                    //only allow custom fields that have no namespace
                    if (dfr.isCustom() && dfr.getName().countMatches('__') == 1) {
                    	Schema.Displaytype dt = dfr.getType();
                    	// only strings and numbers
                    	if (dt == Schema.DisplayType.String ||
                    	   dt == Schema.DisplayType.Integer ||
                    	   dt == Schema.DisplayType.Double) {
                           listSOContactUniqueID.add(new SelectOption(dfr.getName(), dfr.getLabel()));
                    	} 
                    }               
                }
            }               
            return listSOContactUniqueID;
        }
        private set;
    }

    public list<SelectOption> listSOAccountUniqueID {
        get {
            if (listSOAccountUniqueID == null) {
                listSOAccountUniqueID = new list<SelectOption>();
                //add a default option
                listSOAccountUniqueID.add(new SelectOption('', Label.stgLabelNone));
                                           
                Map<String, Schema.DescribeFieldResult> mapNameToDfr = UTIL_Describe.getAllFieldsDescribe('Account');               
                for (Schema.DescribeFieldResult dfr : mapNameToDfr.values()) {
                    //only allow custom fields that have no namespace
                    if (dfr.isCustom() && dfr.getName().countMatches('__') == 1) {
                        Schema.Displaytype dt = dfr.getType();
                        // only strings and numbers
                        if (dt == Schema.DisplayType.String ||
                           dt == Schema.DisplayType.Integer ||
                           dt == Schema.DisplayType.Double) {
                           listSOAccountUniqueID.add(new SelectOption(dfr.getName(), dfr.getLabel()));
                        } 
                    }               
                }
            }               
            return listSOAccountUniqueID;
        }
        private set;
    }

}