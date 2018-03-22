({
	onCheck : function(component, event, helper) {

		var checkbox = component.find("checkbox");
		var checkboxValue = checkbox.get("v.value");


		if (checkboxValue && checkboxValue === true) {

			var batch = component.get("v.item")

			console.log("sending " + batch);

			$A.get("e.c:BGE_BatchListTableRowSelectEvent")
			.setParams({
				"batch": batch
			})
			.fire();
		}
		else {
			console.log("sending nothing");
		}

	}
})