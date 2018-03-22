({
	saveBatch: function (component, batchRecord, selectedTemplate) {

		if (batchRecord.Id != null) {
			var action = component.get("c.updateBatchTemplate");
		}
		else {
			var action = component.get("c.saveBatchTemplate");
		}
		action.setParams({
			"batch": batchRecord,
			"templateId": selectedTemplate.Id
		});

		action.setCallback(this, function (response) {

			var state = response.getState();

			if (state === "SUCCESS") {

				var toastEvent = $A.get("e.force:showToast");

				toastEvent.setParams({
					title: "Success!",
					message: "The record has been saved successfully.",
					type: "success",
					duration: 5
				});
				toastEvent.fire();

				$A.createComponent(
					"c:BGE_EnterData",
					{ "batchId": response.getReturnValue(),
					  "batch": batchRecord,
					  "templateName": selectedTemplate.Name },

					function (newComp) {
						var content = component.find("body");
						content.set("v.body", newComp);
					});
			}
		});
		$A.enqueueAction(action);
	},

	deleteTemplate: function (component, currentTemplate) {
		
		var action = component.get("c.deleteTemplate");

		action.setParams({
			"templateIdToDelete": currentTemplate.Id
		});

		action.setCallback(this, function (response) {

			var state = response.getState();

			if (state === "SUCCESS") {

				var templateWasDeleted = response.getReturnValue();
				var toastEvent = $A.get("e.force:showToast");

				if (templateWasDeleted == true) {
					toastEvent.setParams({
						title: "Warning!",
						message: "The record has been deleted successfully.",
						type: "warning",
						duration: 5
					});
				}
				else {
					toastEvent.setParams({
						title: "Error!",
						message: "The record hasn't been deleted - Review if any batch is associated to the Template.",
						type: "error",
						duration: 5
					});
				}
				toastEvent.fire();
			}
		});
		$A.enqueueAction(action);

		var action = component.get('c.loadTemplates');
		action.setCallback(this, function (response) {
			//store state of response
			var state = response.getState();
			if (state === "SUCCESS") {
				//set response value in objClassController attribute on component
				component.set('v.existingTemplates', response.getReturnValue());
			}
		});
		$A.enqueueAction(action);
	}
})