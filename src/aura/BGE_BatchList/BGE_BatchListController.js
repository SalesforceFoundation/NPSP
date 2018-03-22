({
	init: function(component, event, helper) {

	},

	 lightningInputOnChange: function(component, event, helper) {

	 	var searchInput = component.find("searchInput").get("v.value");

	 	console.log(searchInput);

	 	component.set("v.hasBatches", false);
	 	component.set("v.batchId", null);

	 	if (searchInput && searchInput.length > 1) {

	 		var action = component.get("c.getActiveBatches");

	 		action.setParams({
	 			"stream": searchInput
	 		});

	 		action.setCallback(this, function(result) {

	 			console.log('callbacl ' + result.getReturnValue());

	 			component.set("v.batches", result.getReturnValue());


	 			component.set("v.hasBatches", true);
	 		});

	 		$A.enqueueAction(action);
	 	}
	 },

	setSelectedBatch: function(component, event, helper) {

	 	var batchRecord = event.getParam("batch");
	 	component.set("v.batchId", batchRecord.Id);
	 },

	 resumeBatch: function(component, event, helper) {

	 	$A.get("e.c:BGE_BatchMenuShowGridEvent")
	 	.setParams({
	 		batchId: component.get("v.batchId")
	 	})
	 	.fire();
	 },

     closeModal: function(component, event, helper) {

	 	var dismissEvent = $A.get("e.c:BGE_BatchMenuDismissModalEvent");
	 	console.log(JSON.stringify(dismissEvent));
	 	dismissEvent.fire();
	 },
})