global class RLLP_OppAccount_BATCH implements Database.Batchable<sObject> {
	
	String query;
	
	global RLLP_OppAccount_BATCH() {
		
	}
	
	global Database.QueryLocator start(Database.BatchableContext BC) {
		return Database.getQueryLocator(query);
	}

   	global void execute(Database.BatchableContext BC, List<sObject> scope) {
	
	}
	
	global void finish(Database.BatchableContext BC) {
		
	}
	
}