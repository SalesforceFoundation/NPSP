//This class just performs a small database change to check the TDTM design
public with sharing class TDTM_Runnable_Impl implements TDTM_Runnable {

    @future
    public static void runFuture(Set<Id> n, Set<Id> o, String ta, String obj) {
        String qn = 'select id from ' + obj + ' where id IN ';
        
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
        sampleImpl.run(newlist, oldlist, t, objResult);
    }

    public void run(List<Sobject> newlist, List<Sobject> oldlist, TDTM_TriggerActionHelper.Action ta, 
    Schema.Describesobjectresult obj) {
        insert new Contact(FirstName = CAO_Constants.CONTACT_FIRSTNAME_FOR_TESTS,
                            LastName = CAO_Constants.CONTACT_LASTNAME_FOR_TESTS);
    }
}