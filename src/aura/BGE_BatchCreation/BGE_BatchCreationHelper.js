({
	saveRecord: function (component, newBatchRecord) {

		var action;

		if (newBatchRecord.Id == null) {
			action = component.get("c.saveBatch");
		}
		action.setParams({
			"batch": newBatchRecord
		});

		action.setCallback(this, function (response) {

			var state = response.getState();

			if (state === "SUCCESS") {

				var toastEvent = $A.get("e.force:showToast");

				toastEvent.setParams({
					title: "Success!",
					message: "The record has been created successfully.",
					type: "success",
					duration: 5
				});
				toastEvent.fire();
			}
		});
		$A.enqueueAction(action);
	},

	checkFieldsPopulation: function (component, message, fields) {

		var result = true;

		if (component.get("v.createBatch.Name") === '' || component.get("v.createBatch.Name") === undefined) {

			fields.push('Name');
			component.find("batchName").set("v.errors", [{ message: "Please, populate the field" }]);
			result = false;
		}
		else {

			component.find("batchName").set("v.errors", null);
		}
		return result;
	},
})