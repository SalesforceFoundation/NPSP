public with sharing class ERR_Handler_CTRL_TEST {

    public pageReference withoutManualRollback() {
    	Savepoint sp = Database.setSavepoint();
        try {       
            Contact contact1 = new Contact(FirstName = 'test', LastName = 'testerson1', Title = 'VP1');
            insert contact1;
                    
            npe4__Relationship__c[] relationships = new npe4__Relationship__c[]{
                new npe4__Relationship__c(npe4__contact__c = contact1.id, npe4__Type__c='TestLookupType') };
        
            insert relationships;
        
        } catch(Exception e) {
            ERR_Handler.processError(e, ERR_Handler.Context.TDTM);
        }
        return null;
    }
    
    public pageReference withManualRollback() {
        Savepoint sp = Database.setSavepoint();
        try {       
            Contact contact1 = new Contact(FirstName = 'test', LastName = 'testerson1', Title = 'VP1');
            insert contact1;
            
            //Deleting the contact to force an exception. In the method above an exception is not thrown
            //because the error is caught by TDTM_TriggerHandler.
            delete contact1;
                    
            npe4__Relationship__c[] relationships = new npe4__Relationship__c[]{
                new npe4__Relationship__c(npe4__contact__c = contact1.id, npe4__Type__c='TestLookupType') };
            insert relationships;
        
        } catch(Exception e) {
            Database.rollback(sp);
            ERR_Handler.processError(e, ERR_Handler.Context.TDTM);
        }
        return null;
    }
}