({
	saveTemplate: function (component, newTemplateRecord, batchTemplateFields, batchTemplateFieldsToDelete) {

		var action;
		var existsInvalidValues = component.get("v.errorInLastRow");

		// To remove last row if has any error
		if (existsInvalidValues) {

			batchTemplateFields.pop();
		}

		if (component.get("v.toCreate")) {
			action = component.get("c.saveTemplate");
			action.setParams({
				"newTemplate": newTemplateRecord,
				"batchTemplateFields": batchTemplateFields
			});
		}
		else if (component.get("v.toClone")) {
			action = component.get("c.cloneTemplate");
			action.setParams({
				"newTemplate": newTemplateRecord,
				"batchTemplateFields": batchTemplateFields
			});
		}
		else if (component.get("v.toEdit")) {
			action = component.get("c.editTemplate");
			action.setParams({
				"newTemplate": newTemplateRecord,
				"batchTemplateFields": batchTemplateFields,
				"batchTemplateFieldsToDelete": batchTemplateFieldsToDelete
			});
		}

		action.setCallback(this, function (response) {

			var state = response.getState();

			if (state === "SUCCESS") {

				var toastEvent = $A.get("e.force:showToast");
				var result = response.getReturnValue();

				if (result) {
					toastEvent.setParams({
						title: "Warning!",
						message: result,
						type: "warning",
						duration: 5
					});
				}
				else {
					toastEvent.setParams({
						title: "Success!",
						message: "The record has been saved successfully.",
						type: "success",
						duration: 5
					});
				}
				
				toastEvent.fire();
			}
		});
		$A.enqueueAction(action);
	},

	createObjectData: function (component, event) {

		// Get the templateFields from component and add(push) New Object to List
		var rowItemList = component.get("v.templateFields");
		var existsInvalidValues = false;
		var toastEvent = $A.get("e.force:showToast");

		var index = rowItemList.length;

		if (rowItemList.length > 0) {

			index = rowItemList.length-1;
		}

		var lastFieldCreated = rowItemList[index];

		for (var indexVar = 0; indexVar < rowItemList.length - 1; indexVar++) {

			if (lastFieldCreated.Name == rowItemList[indexVar].Name) {

				toastEvent.setParams({
					title: "Warning!",
					message: "Exists duplicate fields. Please validate",
					type: "warning",
					duration: 5
				});

				existsInvalidValues = true;
			}
		}

		if (lastFieldCreated != undefined && (lastFieldCreated.Name == '' || lastFieldCreated.Name == null)) {

			toastEvent.setParams({
				title: "Warning!",
				message: "Please include at least a Name by row",
				type: "warning",
				duration: 5
			});

			existsInvalidValues = true;
		}

		if (!existsInvalidValues) {

			rowItemList.push({
				'sobjectType': 'Batch_Template_Field__c',
				'Name': '',
				'Order__c': 0,
				'Read_Only__c': false,
				'Required__c': false
			});

			//Set the updated list to attribute (templateFields) again
			component.set("v.templateFields", rowItemList);
		}
		else {
			component.set("v.errorInLastRow", existsInvalidValues);
			toastEvent.fire();
		}

	},

})