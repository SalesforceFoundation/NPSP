({
	checkFieldsPopulation: function (component, message, fields) {

		var result = true;

		if (component.get("v.TemplateFieldInstance.Name") === '' ) { //|| component.get("v.TemplateFieldInstance.Name}") === undefined) {

			fields.push('Name');
			component.find("templateFieldName").set("v.errors", [{ message: "Please, populate this field" }]);
			result = false;
		}
		else {

			component.find("templateFieldName").set("v.errors", null);
		}
		return result;
	},
})