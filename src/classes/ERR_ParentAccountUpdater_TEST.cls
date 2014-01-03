public with sharing class ERR_ParentAccountUpdater_TEST extends TDTM_Runnable 
{    
     public override DmlWrapper run(List<SObject> newlist, List<SObject> oldlist, 
        TDTM_TriggerActionHelper.Action triggerAction, Schema.DescribeSObjectResult objResult) {
         
        DmlWrapper dmlWrapper = new DmlWrapper();

        try {   
            for(SObject o : newList) {
                Contact c = (Contact)o;
                c.Account.Name = 'New Acc Name';
                dmlWrapper.objectsToUpdate.put(c.Account.Id, c.Account);
            }
        } catch(Exception e) {
            System.debug(LoggingLevel.WARN, '****Exception caught in run method: ' + e.getMessage());
            Error__c error = new Error__c();
            error.Datetime__c = System.now();        
            error.Error_Type__c = e.getTypeName();
            error.Full_Message__c = e.getMessage();
            error.Stack_Trace__c = e.getStackTraceString();
            dmlWrapper.objectsToInsert.add(error);
        }
        
        return dmlWrapper;
    }
}