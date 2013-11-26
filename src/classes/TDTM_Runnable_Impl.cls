//This class performs a small database change to check the TDTM design
@isTest
public with sharing class TDTM_Runnable_Impl extends TDTM_Runnable {

    private static Boolean alreadyCalled = false;
    
    public override TDTM_Runnable.DmlWrapper run(List<Sobject> newlist, List<Sobject> oldlist, 
    TDTM_TriggerActionHelper.Action ta, Schema.DescribeSObjectResult describeSObjectResult) {

        TDTM_Runnable.DmlWrapper dmlWrapper = new TDTM_Runnable.DmlWrapper();
        if(!alreadyCalled) {
        	alreadyCalled = true;
	        for(Integer i = 0; i < newlist.size(); i++) {
	        	dmlWrapper.objectsToInsert.add(new Contact(FirstName = CAO_Constants.CONTACT_FIRSTNAME_FOR_TESTS + i,
	                                                        LastName = CAO_Constants.CONTACT_LASTNAME_FOR_TESTS + i));
	        }
        }
        return dmlWrapper;
    }
}