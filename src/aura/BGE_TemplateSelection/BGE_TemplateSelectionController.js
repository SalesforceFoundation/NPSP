({
	doInit: function (component, event, helper) {

		var associatedBatch = component.get('v.associatedBatch');

		if (associatedBatch.Name != null && associatedBatch.Name != undefined) {

			component.set('v.hasBatch', true);
		}

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
	},

	nextToPrevious: function (component, event, helper) {

		var fromCreation = component.get('v.fromCreation');
		var componentName = "c:BGE_BatchCreation";

		if (!fromCreation) {

			componentName = "c:BGE_BatchSelection";
		}

		$A.createComponent(
			componentName,
			{},

			function (newComp) {
				var content = component.find("body");
				content.set("v.body", newComp);
			});
	},

	goToStoreDetail: function (component, event, helper) {

		var selectedItem = event.currentTarget; // Get the target object
		var index = selectedItem.dataset.record; // Get its value i.e. the index
		var selectedTemplate = component.get("v.existingTemplates")[index];

		component.set("v.currentTemplate", selectedTemplate);
	},

	nextToEnterData: function (component, event, helper) {

		var batchRecord = component.get("v.associatedBatch");
		var selectedItem = event.currentTarget; // Get the target object
		var index = selectedItem.dataset.record; // Get its value i.e. the index
		var selectedTemplate = component.get("v.existingTemplates")[index];

		helper.saveBatch(component, batchRecord, selectedTemplate);
	},

	selectTemplate: function (component, event, helper) {

		var target = event.getSource();
		var value = target.get("v.value");
		var currentTemplate = component.get("v.currentTemplate");

		if (value == 1) {

			$A.createComponent(
				"c:BGE_TemplateCreation",
				{
					"template": currentTemplate,
					"toEdit": true,
					"toCreate": false
				},

				function (newComp, event, helper) {

					var content = component.find("body");
					content.set("v.body", newComp);
				});
		}
		else if (value == 2) {

			currentTemplate.Name = '';
			$A.createComponent(
				"c:BGE_TemplateCreation",
				{ 
					"template": currentTemplate,
					"toClone": true,
					"toCreate": false
				},

				function (newComp, event, helper) {

					var content = component.find("body");
					content.set("v.body", newComp);
				});
		}
		else if (value == 3) {

			helper.deleteTemplate(component, currentTemplate);
		}
	},

	nextToTemplateCreation: function (component, event, helper) {


		$A.createComponent(
			"c:BGE_TemplateCreation",
			{
				"toCreate": true
			},

			function (newComp, event, helper) {

				var content = component.find("body");
				content.set("v.body", newComp);
			});
		
	},

	nextToInitial: function (component, event, helper) {

		$A.createComponent(
			"c:BGE_Initial",
			{},

			function (newComp) {
				var content = component.find("body");
				content.set("v.body", newComp);
			});
	},
})