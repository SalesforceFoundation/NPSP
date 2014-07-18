public with sharing class RLLP_OppRollup_Chained_BATCH implements Database.Batchable<sObject>, Database.Stateful {

    //These four variables should maintain state across transactions
    Boolean accountsRolled = false;
    Boolean contactsRolled = false;
    Boolean householdsRolled = false;
    Boolean softCreditsRolled = false;
    
    //These four variables should NOT maintain state across transactions
    static Boolean rollingAccounts = false;
    static Boolean rollingContacts = false;
    static Boolean rollingHouseholds = false;
    static Boolean rollingSoftCredits = false;
    
    public Database.Querylocator start(Database.BatchableContext bc) {   	
    	if(canRunBatch()) {
	    	if(!accountsRolled) {
	    		rollingAccounts = true;
	    		return Database.getQueryLocator(RLLP_OppRollup_UTIL.buildAccountQuery());
	    	} else if(!contactsRolled) {
	    		rollingContacts = true;
	    		return Database.getQueryLocator(RLLP_OppRollup_UTIL.buildContactQuery());
	    	} else if(!householdsRolled) {
	    		rollingHouseholds = true;
	    		return Database.getQueryLocator(RLLP_OppRollup_UTIL.buildHouseholdQuery());
	    	} else if(!softCreditsRolled) {
	    		if (RLLP_OppRollup_UTIL.useSoftCredits()){
	    			rollingSoftCredits = true;
	    		    return Database.getQueryLocator(RLLP_OppRollup_UTIL.buildSoftCreditQuery());	
	    		} else {
	    			softCreditsRolled = true;
	    		}
	    	}
    	}
    	return null;
    }
    
    public void execute(Database.BatchableContext bc, List<SObject> records) {
    	if(records != null && records.size() > 0) {
	    	// run rollups for this batch       
	        RLLP_OppRollup rg = new RLLP_OppRollup();
	        if (rollingAccounts) {
                rg.RollupAccounts(new map<id, Account>((list<Account>)records)); 
                accountsRolled = true;
	        } else if (rollingContacts) {
	            rg.rollupContacts(new map<id, Contact>((list<Contact>)records));
	            contactsRolled = true;
    	    } else if (rollingHouseholds) {
	            rg.RollupHouseholds(new map<id, npo02__Household__c>((list<npo02__Household__c>)records));
	            householdsRolled = true;           
	        } else if (rollingSoftCredits && RLLP_OppRollup_UTIL.useSoftCredits()) {
	            rg.RollupSoftCredits(new map<id, Contact>((list<Contact>)records));
	            softCreditsRolled = true;
	        }
    	}
    }
    
    public void finish(Database.BatchableContext bc) {
    	//if there are rollups left to do
    	if(!accountsRolled || !contactsRolled || !householdsRolled || ! softCreditsRolled) {
	        if(canRunBatch()) {
	        	Database.executeBatch(new RLLP_OppRollup_Chained_BATCH(), RLLP_OppRollup_UTIL.BATCH_SIZE);
	        } else {
	        	//Try again in a minute
	            System.scheduleBatch(this, 'RLLP_OppRollup_Chained_BATCH', 1); 
	        }
    	}
    }
    
    private Boolean canRunBatch() {
    	Integer jobs = [Select count() From AsyncApexJob Where JobType = 'BatchApex' and (Status = 'Queued' or Status = 'Processing' 
                       or Status = 'Preparing')];
        if(jobs < 5)
        	return true;
        return false;           
    }
}