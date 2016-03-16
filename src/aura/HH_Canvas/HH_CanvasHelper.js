({
	doInit : function(component) {
        var hhId = component.get('v.hhId');
        
        // query for the Household account/object 
		var action = component.get("c.getHH");
        action.setParams({ hhId : hhId });
		var self = this;
		action.setCallback(this, function(response) {
			var state = response.getState();
			if (component.isValid() && state === "SUCCESS") {
                var hh = response.getReturnValue();
                console.log(hh);                
				component.set("v.hh", hh);
			}
            else if (component.isValid() && state === "ERROR") {
                self.reportError(response);
            }            
		});
		$A.enqueueAction(action);        

        // query for the Household Contacts 
		var action = component.get("c.getContacts");
        action.setParams({ hhId : hhId });
		var self = this;
		action.setCallback(this, function(response) {
			var state = response.getState();
			if (component.isValid() && state === "SUCCESS") {
                var listCon = response.getReturnValue();
                console.log(listCon);                
				component.set("v.listCon", listCon);
			}
            else if (component.isValid() && state === "ERROR") {
                self.reportError(response);
            }            
		});
		$A.enqueueAction(action);        

    },

    // helper to display an errors that occur from a server method call
    reportError: function(response) {
        var errors = response.getError();
        if (errors) {
            $A.logf("Errors", errors);
            if (errors[0] && errors[0].message) {
                $A.error("Error message: " + errors[0].message);
            } else if (errors[0] && errors[0].pageErrors && errors[0].pageErrors[0].message) {
                $A.error("Error message: " + errors[0].pageErrors[0].message);
            } else {
                $A.error("Unknown error");
            }
        } else {
            $A.error("Unknown error");
        }        
    },

})