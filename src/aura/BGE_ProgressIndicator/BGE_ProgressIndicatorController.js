({
	doInit : function(component, event, helper) {

		var stage = component.get("v.processStage");
		var cmpTarget = component.find(stage);
        $A.util.addClass(cmpTarget, 'slds-is-active');
	}
})