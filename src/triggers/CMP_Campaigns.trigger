trigger CMP_Campaigns on Campaign (after delete, after insert, after undelete, 
after update, before delete, before insert, before update) {

    //@TODO: Right now we don't have anything for globally enabling or disabling triggers. Confirm!
    
    
    if(Trigger.new[0].Name == 'ObjectTest') { //Use object
        System.debug('****Using object');
        run(new TDTM_ObjectDataGateway());
    } else if(Trigger.new[0].Name == 'CustomSettingTest') { //Use custom settings
        System.debug('****Using custom settings');
        run(new TDTM_SettingsDataGateway());
    }
    
    private void run(TDTM_iTableDataGateway dao) {
    	TDTM_TriggerHandler thSettings = new TDTM_TriggerHandler();
	    thSettings.initializeHandler(Trigger.isBefore, Trigger.isAfter, Trigger.isInsert, Trigger.isUpdate,
	                                Trigger.isDelete, Trigger.isUnDelete, Trigger.new, Trigger.old, 
	                                Schema.Sobjecttype.Campaign);
	    thSettings.runModules(dao);
    }
}