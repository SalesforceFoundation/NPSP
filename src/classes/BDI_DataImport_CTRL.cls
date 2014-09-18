public with sharing class BDI_DataImport_CTRL {
	
	public BDI_DataImport_CTRL() {
		batchRunning = false;
		bdi = null;
		ApexJobId = null;
		dtStart = null;
		
	}

    public BDI_DataImport_BATCH bdi { get; set; }
    public Boolean batchRunning { get; set; }
    private ID ApexJobId;
    private DateTime dtStart;

    // action method that user wants to close this page
    public PageReference close() {
        string strURL = ApexPages.currentPage().getParameters().get('retURL');
        if (strURL == null || strURL == '') strURL = '/home/home.jsp';
        PageReference p = new PageReference(strURL);
        p.setRedirect(true);
        return p;
    }

    public PageReference importData() {
        try {
            batchRunning = true;
            bdi = new BDI_DataImport_BATCH();
            ApexJobId = Database.executeBatch(bdi, 10);
            dtStart = system.now();

        } catch (Exception ex) {
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
	                percentComplete = ((aaj.JobItemsProcessed  / aaj.TotalJobItems) * 100.0).intValue();
	                //don't let it go backwards from preparing/queued
	                if (percentComplete == 0 || percentComplete == null)
	                    percentComplete = 5;
	            }
            return percentComplete;
            }
            else 
                return 0;	
        }
        set;
    }

    public string strTimeSpent {
        get {
        	if (dtStart != null && !isBatchJobCompleted) {
        		DateTime dt = DateTime.newInstance(system.Now().getTime() - dtStart.getTime());
        		strTimeSpent = dt.format('m:ss');
        		return strTimeSpent;
        	}
            return null;
        }
        private set;
    }

}