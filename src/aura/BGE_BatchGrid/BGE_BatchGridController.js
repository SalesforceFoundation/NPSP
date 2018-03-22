({
	init : function(component, event, helper) {

		var batchId = component.get("v.batchId");

		var action = component.get("c.getDataImports");

		action.setStorable();

		action.setParams({
			batchId: batchId
		});

		action.setCallback(this, function(result) {
			component.set("v.records", result.getReturnValue());
		});

		$A.enqueueAction(action);
	}
})