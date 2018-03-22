({
	// goToStoreDetail: function (component, event, helper) {

	// 	var selectedItem = event.currentTarget; // Get the target object
	// 	var index = selectedItem.dataset.record; // Get its value i.e. the index
	// 	var selectedTemplate = component.get("v.existingTemplates")[index];

	// 	component.set("v.currentTemplate", selectedTemplate);

	// 	//console.log('TEST 1 ' + selectedTemplate.Name);
	// },

	// selectTemplate: function (component, event, helper) {

	// 	var target = event.getSource();
	// 	var value = target.get("v.value");

	// 	var currentTemplate = component.get("v.currentTemplate");

	// 	//console.log('TEST 2 ' + currentTemplate.Name);

	// 	if (value == 1) {

	// 		alert('Functionality on development Edit');
	// 	}
	// 	else if (value == 2) {

	// 		$A.createComponent(
	// 			"c:BGE_TemplateCreation",
	// 			{ "createTemplate": currentTemplate },

	// 			function (newComp) {
	// 				var content = component.find("body");
	// 				console.log('TEST 3 ' + content);
	// 				content.set("v.body2", newComp);
	// 			});
	// 	}
	// 	else if (value == 3) {

	// 		alert('Functionality on development Delete');
	// 	}
	// },
})