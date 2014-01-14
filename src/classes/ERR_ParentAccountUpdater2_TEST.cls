@isTest
public with sharing class ERR_ParentAccountUpdater2_TEST extends TDTM_Runnable {

    public override DmlWrapper run(List<SObject> newlist, List<SObject> oldlist, 
     TDTM_TriggerActionHelper.Action triggerAction, Schema.DescribeSObjectResult objResult) {
         
        DmlWrapper dmlWrapper = new DmlWrapper();
 
        List<Contact> contactsWithParentInfo = [select Account.Id, Account.Name from Contact where Id in :newList];
        
        for(SObject o : contactsWithParentInfo) {
            Contact c = (Contact)o;
            c.Account.Name = 'New Acc Name';
            dmlWrapper.objectsToUpdate.put(c.Account.Id, c.Account);
        }
        
        return dmlWrapper;
    }
}