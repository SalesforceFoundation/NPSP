({

	createBatch : function(component, event, helper) {
		// component.set("v.showNewBatchModal", true);

		$A.get("e.c:BGE_BatchMenuShowModalEvent")
		.setParams({
			modalName: "new"
		})
		.fire();
	},

	resumeBatch : function(component, event, helper) {
		// component.set("v.showListBatchModal", true);

		$A.get("e.c:BGE_BatchMenuShowModalEvent")
		.setParams({
			modalName: "edit"
		})
		.fire();
	},

	createTemplate : function(component, event, helper) {

		$A.get("e.c:BGE_BatchMenuShowModalEvent")
		.setParams({
			modalName: "newTemplate"
		})
		.fire();
	},

})