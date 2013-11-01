global with sharing class SUBSYS_TriggerHandler {

    private List<Sobject> newlist;
    private List<Sobject> oldlist; 
    private SUBSYS_triggerAction thisAction;
    private Schema.DescribeSobjectResult obj;

    public void initializeHandler(Boolean isBefore, Boolean isAfter, Boolean isInsert, Boolean isUpdate,
    Boolean isDelete, Boolean isUnDelete, List<Sobject> newlistfromtrigger, List<Sobject>oldlistFromTrigger, 
    Schema.DescribeSobjectResult describeobj) {
    	
        newlist = newlistfromtrigger;
        oldlist = oldlistfromtrigger;

        thisAction = SUBSYS_TriggerActionHelper.determineTriggerAction(isBefore, isAfter, isInsert, isUpdate,
                                                                        isDelete, isUnDelete);

        obj = describeobj;
    }

    public void runModules() {
        List<SubmoduleWrapper> submoduleRunList = new List<SubmoduleWrapper>();
        //only add valid modules to the runlist
        for (String s : SUBSYS_Helper.getSubSystemModules().keySet()){
            SubsystemModule__c ssm = SUBSYS_Helper.getSubSystemModules().get(s);
            if (ssm != null && (ssm.Active__c == true &&
                ssm.Object__c.equalsIgnoreCase(obj.getName()) && 
                ssm.Trigger_Actions__c.containsIgnoreCase(thisAction.name()))){
                submoduleRunList.add(new SubmoduleWrapper(ssm));
            }
        }
        
        //sort the runlist by fire-order
        submoduleRunList.sort();
        
        //run the relevant classes
        for (SubmoduleWrapper sw : submoduleRunList){
        
        	//ceiroa: these two lines are important - here is where we read from the object and 
        	//we instantiate the objects to be called (from data stored in the object) 
            Type t = Type.forName(sw.ssm.Class__c);
            SUBSYS_iModule ism = (SUBSYS_iModule)t.newInstance();
        
            if(!sw.ssm.Asynchronous__c){
                system.debug('Running Sync: ' + sw.ssm.Class__c);
                //ceiroa: the objects we create dynamically need to implement the iSubsystemModule
                //interface - TODO: check that they actually do 
                ism.run(newlist, oldlist, thisAction, obj);
            }                 
            else{
                system.debug('Running Async: ' + sw.ssm.Class__c);
                Map<Id,Sobject> nm = new Map<Id,Sobject>(newlist);
                Map<Id,Sobject> om = new Map<Id,Sobject>(oldlist);
                ism.runFuture(nm.keySet(), om.keySet(), thisAction.name(), obj.getName());
            }                
        }         
    }
    
    
    public class SubmoduleWrapper implements Comparable {

	    public SubsystemModule__c ssm;
	    public SubmoduleWrapper(SubsystemModule__c s){ ssm = s; }
    
	    public Integer compareTo(Object compareTo) {
	        // Cast argument to OpportunityWrapper
	        SubmoduleWrapper compareToSSM = (SubmoduleWrapper)compareTo;
	        
	        // The return value of 0 indicates that both elements are equal
	        if (ssm.Load_Order__c > compareToSSM.ssm.Load_Order__c) return -1;
	        else if (ssm.Load_Order__c < compareToSSM.ssm.Load_Order__c) return 1;
	        return 0;       
        }
    }
}