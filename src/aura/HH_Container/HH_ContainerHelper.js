({
    /*******************************************************************************************************
    * @description called at onInit to load up the Household Object/Account, and its Contacts
    */
	loadObjects : function(component) {
        component.set("v.showSpinner", true);
        var hhId = component.get('v.hhId');
        
        // query for the Household account/object 
		var action = component.get("c.getHH");
        action.setParams({ hhId : hhId });
		var self = this;
		action.setCallback(this, function(response) {
			var state = response.getState();
			if (component.isValid() && state === "SUCCESS") {
                var hh = response.getReturnValue();
				component.set("v.hh", hh);

                // set our auto-naming checkbox states
                var strExclusions = hh.npo02__SYSTEM_CUSTOM_NAMING__c;
                component.set('v.isAutoName', strExclusions == null || !strExclusions.includes('Name'));
                component.set('v.isAutoFormalGreeting', strExclusions == null || !strExclusions.includes('Formal_Greeting__c'));
                component.set('v.isAutoInformalGreeting', strExclusions == null || !strExclusions.includes('Informal_Greeting__c'));
			}
            else if (component.isValid() && state === "ERROR") {
                self.reportError(component, response);
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
				component.set("v.listCon", listCon);                
			}
            else if (component.isValid() && state === "ERROR") {
                self.reportError(component, response);
            }            
		});
		$A.enqueueAction(action);        

    },
    
    /*******************************************************************************************************
    * @description get updated names and greetings from server's custom naming code
    */
	updateHHNames : function(component) {
        var hh = component.get('v.hh');
        var listCon = component.get('v.listCon');     
        
        // update our auto-naming exclusion states
        this.updateNamingExclusions(component, hh);
        
        // get updated Names and Greetings 
		var action = component.get("c.getHHNamesGreetings");
        action.setParams({ hh : hh, listCon : listCon });
		var self = this;
		action.setCallback(this, function(response) {
			var state = response.getState();
			if (component.isValid() && state === "SUCCESS") {
                var hh = response.getReturnValue();
				component.set("v.hh", hh);
			}
            else if (component.isValid() && state === "ERROR") {
                self.reportError(component, response);
            }            
		});
		$A.enqueueAction(action);        
    },

    /*******************************************************************************************************
    * @description helper to display an errors that occur from a server method call
    */
    reportError : function(component, response) {
        var errors = response.getError();
        if (errors) {
            $A.log("Errors", errors);
            if (errors[0] && errors[0].message) {
                this.displayUIMessage(component, "Error message: " + errors[0].message);
            } else if (errors[0] && errors[0].pageErrors && errors[0].pageErrors[0].message) {
                this.displayUIMessage(component, "Error message: " + errors[0].pageErrors[0].message);
            } else {
                this.displayUIMessage(component, "Unknown error");
            }
        } else {
            this.displayUIMessage(component, "Unknown error");
        }        
    },

    /*******************************************************************************************************
    * @description creates a ui:message component for the given error string
    */
    displayUIMessage : function(component, strError) {
        debugger;
        $A.createComponents([
            ["ui:message",{
                "title" : "Runtime Error",
                "severity" : "error",
            }],
            ["ui:outputText",{
                "value" : strError
            }]
        ],
            function(components, status) {
                if (status === "SUCCESS") {
                    debugger;
                    //component.set("v.showSpinner", false);
                    var message = components[0];
                    var outputText = components[1];
                    // set the body of the ui:message to be the ui:outputText
                    message.set("v.body", outputText);
                    var div = component.find("divUIMessage");
                    // Replace div body with the dynamic component
                    div.set("v.body", message);
                }
       });
    },
    
    /*******************************************************************************************************
    * @description Saves all changes and return to the household
    */
    save : function(component) {
        component.set("v.showSpinner", true);
        
        // save the contacts
        var listCon = component.get("v.listCon");
		var action = component.get("c.updateContacts");
        action.setParams({ listCon : listCon});
		var self = this;
        var countSuccesses = 0;
		action.setCallback(this, function(response) {
			var state = response.getState();
			if (component.isValid() && state === "SUCCESS") {
                countSuccesses++;
                if (countSuccesses == 2)
	                self.close(component);
			}
            else if (component.isValid() && state === "ERROR") {
                self.reportError(component, response);
            }            
		});
		$A.enqueueAction(action);

        // update our auto-naming exclusion states
        var hh = component.get("v.hh");
        this.updateNamingExclusions(component, hh);
        
        // save the Household
		var action = component.get("c.updateHousehold");
        action.setParams({ hh : hh});
		action.setCallback(this, function(response) {
			var state = response.getState();
			if (component.isValid() && state === "SUCCESS") {
                countSuccesses++;
                if (countSuccesses == 2)
	                self.close(component);
			}
            else if (component.isValid() && state === "ERROR") {
                self.reportError(component, response);
            }            
		});
		$A.enqueueAction(action);
    },
    
    /*******************************************************************************************************
	* @description Update our auto-naming exclusion states based on our checkboxes.
    */
    updateNamingExclusions : function(component, hh) {
		var strExclusions = '';
        if (!component.get('v.isAutoName'))
            strExclusions += 'Household__c.Name;';
        if (!component.get('v.isAutoFormalGreeting'))
            strExclusions += 'Household__c.Formal_Greeting__c;';
        if (!component.get('v.isAutoInformalGreeting'))
            strExclusions += 'Household__c.Informal_Greeting__c;';
        hh.npo02__SYSTEM_CUSTOM_NAMING__c = strExclusions;   
    },

    /*******************************************************************************************************
	* @description Update our auto-naming exclusion states based on Name/Greeting Changes
    */
    updateAutoNaming : function(component, event) {
        var inputText = event.getSource();
        var idText = inputText.getLocalId();
        
        if (idText == 'txtHHName')
            component.set('v.isAutoName', false);
        else if (idText == 'txtFormalGreeting')
            component.set('v.isAutoFormalGreeting', false);
        else if (idText == 'txtInformalGreeting')
            component.set('v.isAutoInformalGreeting', false);
    },

    /*******************************************************************************************************
	* @description Close the page by redirecting back to the household
    */
    close : function(component) {
        // the correct way to handle navigation in Salesforce classic vs. LEX/mobile
        if (typeof sforce === "undefined") {
	    	window.top.location.replace('/' + component.get('v.hhId'));
        } else {
	    	sforce.one.navigateToSObject(component.get('v.hhId'));
        }
    },                           
    
})