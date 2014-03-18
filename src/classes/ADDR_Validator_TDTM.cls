public with sharing class ADDR_Validator_TDTM extends TDTM_Runnable {
	
	private static Boolean alreadyRun = false;
	
	public override DmlWrapper run(List<SObject> newList, List<SObject> oldList, 
    TDTM_TriggerActionHelper.Action triggerAction, Schema.DescribeSObjectResult objResult) { 
        
        DmlWrapper wrapper = new DmlWrapper();
        
        if(!alreadyRun) {
	        Address_Verification_Settings__c settings = Address_Verification_Settings__c.getInstance();
	        if (trigger.isAfter && settings.enable_automatic_verification__c) {
                ADDR_Validator.verifyRecords(new Map<Id, SObject>(newList).keyset());
	        }
        }
        alreadyRun = true;
        return wrapper;
    }
}