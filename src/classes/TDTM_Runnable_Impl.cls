//This class just performs a small database change to check the TDTM design
@isTest
public with sharing class TDTM_Runnable_Impl implements TDTM_Runnable {

    public TDTM_TriggerHandler.DmlWrapper runMain(List<Sobject> newlist, List<Sobject> oldlist, 
    TDTM_TriggerActionHelper.Action ta, Schema.Describesobjectresult obj) {
        TDTM_TriggerHandler.DmlWrapper dmlWrapper = new TDTM_TriggerHandler.DmlWrapper();
        for(Integer i = 0; i < newlist.size(); i++) {
        	dmlWrapper.objectsToInsert.add(new Contact(FirstName = CAO_Constants.CONTACT_FIRSTNAME_FOR_TESTS + i,
                                                        LastName = CAO_Constants.CONTACT_LASTNAME_FOR_TESTS + i));
        }
        return dmlWrapper;
    }
    
    public TDTM_TriggerHandler.DmlWrapper runInProgress(List<Sobject> newlist, List<Sobject> oldlist, 
    TDTM_TriggerActionHelper.Action ta, Schema.Describesobjectresult obj) {
        TDTM_TriggerHandler.DmlWrapper dmlWrapper = new TDTM_TriggerHandler.DmlWrapper();
        for(Integer i = 0; i < newlist.size(); i++) {
            dmlWrapper.objectsToInsert.add(new Contact(FirstName = CAO_Constants.CONTACT_FIRSTNAME_FOR_TESTS + i,
                                                        LastName = CAO_Constants.CONTACT_LASTNAME_FOR_TESTS + i));
        }
        return dmlWrapper;
    }
    
    @future
    public static void runFuture(Set<Id> n, Set<Id> o, String ta, String obj) {
        String qn = 'select id from ' + obj + ' where id IN ';
        
        //We are not really doing anything will all this. It's just a sample implementation
        //of how the class to run can have access to the records afected by the trigger.
        List<sobject> newlist = Database.query(qn + ':n');
        List<sobject> oldlist = Database.query(qn + ':o'); 
        Schema.DescribeSObjectResult objResult;
        for(Schema.SObjectType t : Schema.getGlobalDescribe().values()){
            if (t.getDescribe().getName() == obj){
                objResult = t.getDescribe();
                break;
            }
        }

        TDTM_TriggerActionHelper.Action t = TDTM_TriggerActionHelper.getTriggerActionFromName(ta);
        TDTM_Runnable sampleImpl = new TDTM_Runnable_Impl();
        TDTM_TriggerHandler.DmlWrapper dmlWrapper = sampleImpl.runMain(newlist, oldlist, t, objResult);
        insert dmlWrapper.objectsToInsert;
        update dmlWrapper.objectsToUpdate.values();
        delete dmlWrapper.objectsToDelete.values();
    }
}