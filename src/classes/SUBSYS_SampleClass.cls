//This class just performs a small database change to check the SUBSYS design.
public with sharing class SUBSYS_SampleClass implements SUBSYS_iModule {

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

        SUBSYS_TriggerAction t = SUBSYS_TriggerActionHelper.getTriggerActionFromName(ta);
        SUBSYS_SampleClass instance = new SUBSYS_SampleClass();
        instance.run(newlist, oldlist, t, objResult);
    }

    public void run(List<Sobject> newlist, List<Sobject> oldlist, SUBSYS_TriggerAction ta, 
    Schema.Describesobjectresult obj) {
        insert new Contact(FirstName = CAO_Constants.CONTACT_FIRSTNAME_FOR_TESTS,
                            LastName = CAO_Constants.CONTACT_LASTNAME_FOR_TESTS);
    }
}