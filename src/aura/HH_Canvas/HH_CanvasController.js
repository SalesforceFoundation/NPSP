({
	doInit : function(component, event, helper) {
		helper.doInit(component);
        helper.initJQueryHandlers(component);
	},
    
    doSave : function(component, event, helper) {
    	helper.doSave(component);
	}
})