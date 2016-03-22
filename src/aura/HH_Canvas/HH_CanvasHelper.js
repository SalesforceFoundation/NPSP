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
    reportError : function(response) {
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
    
    initJQueryHandlers : function(component) {
        if (typeof jQuery !== "undefined" && typeof $j === "undefined") {
            $j = jQuery.noConflict(true);;
        }        
        
        if (typeof $j === "undefined")
            return;
        
        // turn on jqueryui drag/sortable support
        j$('.slds-has-cards--space').sortable( {
            tolerance: "pointer", 
            
            // called after DOM has been updated after a drag/drop sort
 	        update: function(event, ui) {
                debugger;
                
                // update our listCon to the new order
                var listCon = component.get('v.listCon');
                var listConNew = [];
                for (var i = 0; i < this.children.length; i++) {
                    var icon = this.children[i].getAttribute("data-icontact");
                	listConNew.push(listCon[icon]);
                    listCon[icon].npo02__Household_Naming_Order__c = i;
                }
                component.set('v.listCon', listConNew);
                
                // now notify other components the reorder occurred
                var event = $A.get("e.c:HH_ContactReorderEvent");
                event.setParams({ "listCon" : listConNew });
                event.fire();
            }
        });
        j$('.slds-has-cards--space').disableSelection();         
    },
    
    doSave : function(component) {
        debugger;
        var listCon = component.get("v.listCon");

        // update our contacts
		var action = component.get("c.updateContacts");
        action.setParams({listCon: listCon});
		var self = this;
		action.setCallback(this, function(response) {
			var state = response.getState();
			if (component.isValid() && state === "SUCCESS") {
                //self.close(component);
                alert('save successful from Canvas!');
			}
            else if (component.isValid() && state === "ERROR") {
                self.reportError(response);
            }            
		});
		$A.enqueueAction(action);        
    },

})