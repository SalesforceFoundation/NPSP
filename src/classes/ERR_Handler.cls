public with sharing class ERR_Handler {

    public static Boolean DiagnosticsEnabled = true;
    
    public static MAP<integer, string>sObjInsErrMAP = new MAP<integer, string>(); // This stores the error associated with the list position of the SObjInsLIST to the triggering ID 
    public static MAP<integer, string>sObjUpdErrMAP = new MAP<integer, string>(); // This stores the error associated with the list position of the SObjUpdLIST to the triggering ID 
    List<SObject> newList;
    List<SObject> oldList;
    
    public void processResults(List<Database.SaveResult> insertResults, List<Database.SaveResult> updateResults, 
    List<Database.DeleteResult> deleteResults, List<Database.UndeleteResult> undeleteResults, 
    List<SObject> newList, List<SObject> oldList) {
        
        this.newList = newList;
        this.oldList = oldList;
        
        Map<String, String> errorMap = new Map<string, string>();
        
        if(DiagnosticsEnabled) {
            
            //INSERT
            if(insertResults != null && insertResults.size() > 0) {
                Integer i = 0;
                for(Database.SaveResult srItem : insertResults) {
                    if (!srItem.isSuccess())
                        errorMap.put(sObjInsErrMAP.get(i), srItem.getErrors()[0].getMessage());
                    i++;
                }
            }
            
            //UPDATE
            if(updateResults != null && updateResults.size() > 0) {
                for(Database.SaveResult result : updateResults) {
                    
                }
            }
            
            //DELETE
            if(deleteResults != null && deleteResults.size() > 0) {
                for(Database.DeleteResult result : deleteResults) {
                    
                }
            }
            
            //UNDELETE
            if(undeleteResults != null && undeleteResults.size() > 0) {
                for(Database.UndeleteResult result : undeleteResults) {
                    
                }
            }
            
            processErrorMap(errorMap);
        }
    }
    
    private void processErrorMap(Map<String, String> errorMap) {
        
        if(errorMap != null && errorMap.size() > 0) {
            Integer i = 0;
            for (string strErrorID: errorMap.keySet()) {
                //@TODO: store error in database (see REL code)
                
                //@TODO: will this work in our case, where we have more than one trigger for
                //this context? If not, what do we do with the errors?
                if (strErrorID.isNumeric()) {
                    i = integer.valueOf(strErrorID);
                    newList[i].addError(errorMap.get(strErrorID));
                } else {
                    /*if (trigger.isDelete) {
                        oldMap.get(strErrorID).addError(errorMap.get(strErrorID));
                    } else {
                        newMap.get(strErrorID).addError(errorMap.get(strErrorID));
                    }*/
                }
                i++;
            }
        }
    }
    
    public void saveErrorInfo(Exception e) {
        if(DiagnosticsEnabled) {
            //String info = 'Exception occurred in line ' + e.getLineNumber() + ' - ' + e.getMessage()  
            //      + ' stack: ' + e.getStackTraceString();   
            //ErrorInfo__c errorRecord = new ErrorInfo__c(info);
            //insert errorRecord;
            
            Error__c error = createError(e);
            insert error;
        }
    } 
    
    public static Error__c createError(Database.SaveResult s, npe4__Relationship__c r){
        
        Error__c re = new Error__c();
        re.Datetime__c = System.now();
        
        String recordURL = URL.getSalesforceBaseUrl().toExternalForm() + '/';
        
        if (s.getId() != null)
            recordURL += s.getId();
        //else            
        //    recordURL += r.ReciprocalRelationship__c;     @TODO. I don't see this field in the original object either!?!
                     
        if (recordURL.startsWith('http:'))
            recordURL = recordURL.replaceFirst('http:', 'https:');           
        re.Record_URL__c = recordURL; 
        
        if (s.getErrors()[0].getStatusCode() == system.Statuscode.REQUIRED_FIELD_MISSING)
            re.Type__c = 'Required Field Missing';   
        else if (s.getErrors()[0].getStatusCode() == system.Statuscode.FIELD_CUSTOM_VALIDATION_EXCEPTION)
            re.Type__c = 'Custom Validation Rule Failed';
        else
            re.Type__c = 'Other';
        
        re.Full_Message__c = s.getErrors()[0].getMessage();
    
        return re;
    }
    
    public static Error__c createError(Exception e){
        Error__c re = new Error__c();
        re.Datetime__c = System.now();        
        re.Type__c = e.getTypeName();
        re.Full_Message__c = e.getMessage();
        re.Stack_Trace__c = e.getStackTraceString();
        return re;
    }
}