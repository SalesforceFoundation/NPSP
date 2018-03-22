({

	dismissModals : function(component, event, helper) {

		console.log("dismissModals");
		component.set("v.showNewBatchModal", false);
		component.set("v.showListBatchModal", false);
		component.set("v.showNewTemplateModal", false);
	},

	showGrid : function(component, event, helper) {

		console.log("showGrid");

		var batchId = event.getParam("batchId");
		component.set("v.batchId", batchId);

		component.set("v.showBatchGrid", true);
		component.set("v.showNewBatchModal", false);
		component.set("v.showListBatchModal", false);
	},

	showModal: function(component, event, helper) {

		var modalName = event.getParam("modalName");

		if (modalName == 'edit') {
			component.set("v.showListBatchModal", true);
		}
		else if (modalName == 'new') {
			component.set("v.showNewBatchModal", true);
		}
		else if (modalName == 'newTemplate') {
			component.set("v.showNewTemplateModal", true);
		}
		else {
			console.error("Modal Name not valid")
		}
	},

	nextToInitial : function(component, event, helper) {
		
		$A.createComponent(
			"c:BGE_Initial",
			{},

			function(newComp) {
			var content = component.find("body");
			content.set("v.body", newComp);
		});
	},

})