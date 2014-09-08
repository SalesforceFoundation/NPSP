public with sharing class BDI_DataImport_CTRL {
	
	public BDI_DataImport_CTRL() {
		batchRunning = false;
		dtLastRun = system.now();
	}

    public Boolean batchRunning { get; set; }
    private List<AsyncApexJob> aaj = new List<AsyncApexJob>();
    private DateTime dtLastRun { get; set; }
    public AsyncApexJob apexjob {get{
            if (batchRunning && aaj.isEmpty())
                aaj = [select a.Id, a.TotalJobItems, a.Status, a.NumberOfErrors, 
                                a.JobType, a.JobItemsProcessed, a.ExtendedStatus, 
                                a.CompletedDate, a.ApexClassId From AsyncApexJob a 
                                where CompletedDate > :dtLastRun and
                                (a.Status = 'Completed' or a.Status = 'Aborted' or a.Status = 'Failed') and 
                                a.JobType = 'BatchApex' 
                                order by CompletedDate desc limit 1];
        return !aaj.isEmpty() ? aaj[0] : null;
    }set;}


    public PageReference importData() {
        try {
            batchRunning = true;
            dtLastRun = system.now();
            aaj.clear();
            BDI_DataImport_BATCH bdi = new BDI_DataImport_BATCH();
            ID batchprocessid = Database.executeBatch(bdi, 20);

        } catch (Exception ex) {
            ERR_Handler.processError(ex, ERR_Handler.Context.BDI);
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ex.getMessage()));
        }
        return null;
    }

    public PageReference cancel() {
        PageReference ref = new PageReference('/home/home.jsp');
        ref.setRedirect(true);
        return ref;
    }

    
}