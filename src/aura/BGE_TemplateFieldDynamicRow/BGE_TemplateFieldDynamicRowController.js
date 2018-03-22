({
	addNewRow: function (component, event, helper) {
		// fire the AddNewRowEvt Lightning Event 
		component.getEvent("AddRowEvent").fire();
	},

	removeRow: function (component, event, helper) {
		// fire the DeleteRowEvt Lightning Event and pass the deleted Row Index to Event parameter/attribute
		component.getEvent("DeleteRowEvent").setParams({ "indexVar": component.get("v.rowIndex"), "templateFieldToDelete": component.get("v.TemplateFieldInstance") }).fire();
	},

})