public with sharing class STG_PanelRDBatch_CTRL extends STG_Panel { 

    public STG_PanelRDBatch_CTRL() {
    	isRunningBatch = false;
    }
    
    public override string idPanel() { return 'idPanelRDBatch'; }
    
    public boolean isRunningBatch { get; set; }
    
    public PageReference runBatch() {
    	Savepoint sp = Database.setSavepoint();
        try {
	    	isRunningBatch = true;
	
	        string queryRCD = RD_RecurringDonations.strQueryRDNoWhere();
	        queryRCD += ' where npe03__Open_Ended_Status__c = \'' + system.label.npe03.RecurringDonationOpenStatus + '\'';
	        if (Test.isRunningTest())
	            queryRCD = queryRCD + ' LIMIT 50';
	        
	        //call the batch job, processing 50 at a time 
	        Id batchInstanceId = Database.executeBatch(new RD_RecurringDonations_BATCH(queryRCD), 50); 
        }
        catch(Exception e) {
            Database.rollback(sp);
            ERR_Handler.processError(e, ERR_Handler.Context.RD);
        }
    	return null;
    }
 
}