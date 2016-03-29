({
    // initialize the container by loading up our Household and Contacts
	doInit : function(component, event, helper) {
        helper.loadObjects(component);
	},
    
	// display the spinner
    showSpinner : function(component, event, helper) {
    	component.set("v.showSpinner", true);
    },

    // hide the spinner
    hideSpinner : function(component, event, helper) {
    	component.set("v.showSpinner", false);
    },

    // a Contact has changed, so update our naming
    handleContactChangedEvent : function(component, event, helper) {
        helper.updateHHNames(component);		
	},

    // Contact ordering has changed, so update our naming
    handleContactReorderEvent : function(component, event, helper) {
        helper.updateHHNames(component);				
	},
    
    // an autoName checkbox has changed, so update our naming
    onCheck : function(component, event, helper) {
        helper.updateHHNames(component);				
	},

    // a Name/Greeting textbox has changed, so update our autoName state
    onTextChange : function(component, event, helper) {
        helper.updateAutoNaming(component, event);				
	},

    // save all changes and return to the household
    save : function(component, event, helper) {
        helper.save(component);
    },
    
	// close and return to the household
    close : function(component, event, helper) {
		helper.close(component);
    },                           
    
})