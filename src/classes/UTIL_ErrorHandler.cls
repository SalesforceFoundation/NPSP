public with sharing class UTIL_ErrorHandler {

    public static Boolean DiagnosticsEnabled = true;
    
    public static MAP<integer, string>sObjInsErrMAP = new MAP<integer, string>(); // This stores the error associated with the list position of the SObjInsLIST to the triggering ID 
    public static MAP<integer, string>sObjUpdErrMAP = new MAP<integer, string>(); // This stores the error associated with the list position of the SObjUpdLIST to the triggering ID 
    
    public static void saveErrorInfo(Exception e) {
    	if(DiagnosticsEnabled) {
	    	String info = 'Exception occurred in line ' + e.getLineNumber() + ' - ' + e.getMessage()  
	              + ' stack: ' + e.getStackTraceString();
	              
	        //ErrorInfo__c errorRecord = new ErrorInfo__c(info);
	        //insert errorRecord;
    	}
    }
    
    public static void processResults(List<Database.SaveResult> insertResults, List<Database.SaveResult> updateResults, 
    List<Database.DeleteResult> deleteResults, List<Database.UndeleteResult> undeleteResults) {
        
        Map<String, String> errorMap = new Map<string, string>();
        
        if(DiagnosticsEnabled) {
        	
        	//INSERT
        	Integer i = 0;
	        for(Database.SaveResult srItem : insertResults) {
	        	if (!srItem.isSuccess())
                    errorMap.put(sObjInsErrMAP.get(i), srItem.getErrors()[0].getMessage());
                i++;
	        }
	        
	        //UPDATE
	        for(Database.SaveResult result : updateResults) {
	            
	        }
	        
	        //DELETE
	        for(Database.DeleteResult result : deleteResults) {
	            
	        }
	        
	        //UNDELETE
	        for(Database.UndeleteResult result : undeleteResults) {
	            
	        }
	        
	        secondStep(errorMap);
        }
    }
    
    private static void secondStep(Map<String, String> errorMap) {
    	Integer i = 0;
        for (string strErrorID: errorMap.keySet()) {
            if (strErrorID.isNumeric()) {
                i = integer.valueOf(strErrorID);
                //@TODO: this does not work in our case because there might be more than one trigger for
                //this context. What do we do with the errors then?
                Trigger.new[i].addError(errorMap.get(strErrorID));
            } else {
                if (trigger.isDelete) {
                    Trigger.oldMap.get(strErrorID).addError(errorMap.get(strErrorID));
                } else {
                    Trigger.newMap.get(strErrorID).addError(errorMap.get(strErrorID));
                }
            }
            i++;
        }
    } 
}