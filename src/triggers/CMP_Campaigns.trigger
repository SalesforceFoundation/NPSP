trigger CMP_Campaigns on Campaign (after delete, after insert, after undelete, 
after update, before delete, before insert, before update) {

    //@TODO: Right now we don't have anything for globally enabling or disabling triggers. Confirm!
    SUBSYS_TriggerHandler th = new SUBSYS_TriggerHandler();
    th.initializeHandler(Trigger.isBefore, Trigger.isAfter, Trigger.isInsert, Trigger.isUpdate,
                        Trigger.isDelete, Trigger.isUnDelete, Trigger.new, Trigger.old, 
                        Schema.Sobjecttype.Campaign);
	th.runModules(); 


    SUBSYS_TriggerHandlerSettings thSettings = new SUBSYS_TriggerHandlerSettings();
    thSettings.initializeHandler(Trigger.isBefore, Trigger.isAfter, Trigger.isInsert, Trigger.isUpdate,
                                Trigger.isDelete, Trigger.isUnDelete, Trigger.new, Trigger.old, 
                                Schema.Sobjecttype.Campaign);
    thSettings.runModules(); 
}