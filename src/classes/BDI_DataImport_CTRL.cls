public with sharing class BDI_DataImport_CTRL {
	
	public BDI_DataImport_CTRL() {
		batchRunning = false;
		bdi = null;
		ApexJobId = null;
	}

    public BDI_DataImport_BATCH bdi { get; set; }
    public Boolean batchRunning { get; set; }
    private ID ApexJobId;

    public PageReference importData() {
        try {
            batchRunning = true;
            bdi = new BDI_DataImport_BATCH();
            ApexJobId = Database.executeBatch(bdi, 10);

        } catch (Exception ex) {
            ERR_Handler.processError(ex, ERR_Handler.Context.BDI);
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ex.getMessage()));
        }
        return null;
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

    public boolean isBatchJobCompleted { 
        get {
            if (ApexJobId != null) {
                AsyncApexJob aaj = [select TotalJobItems, Status, ExtendedStatus, NumberOfErrors, MethodName, JobType, JobItemsProcessed, Id, 
                                    CreatedDate, CreatedById, CompletedDate, ApexClassId, ApexClass.Name, CreatedBy.Name
                                    From AsyncApexJob where Id = :ApexJobId];
                return (aaj.Status == 'Completed' || aaj.Status == 'Failed' || aaj.Status == 'Aborted');
            }
            return false;
        }
        set;
    }

    public PageReference cancel() {
        PageReference ref = new PageReference('/home/home.jsp');
        ref.setRedirect(true);
        return ref;
    }
    
    public integer crecToProcess {
        get {
        	if (crecToProcess == null) {
        	   crecToProcess = [select count() from DataImport__c where Status__c <> 'Imported'];
        	}
        	return crecToProcess;
        }
        set;
    }
}