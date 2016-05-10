({
    // initialize the container by loading up our Household and Contacts
	doInit : function(component, event, helper) {        
        helper.fixupCustomLabels(component);
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

    // a Contact has been requested to delete, so prompt the user and track the deletion
    doDeleteContact : function(component, event, helper) {
        helper.doDeleteContact(component, event);		
	},

    // a Contact has been requested to delete, so prompt the user and track the deletion
    cancelDeleteContact : function(component, event, helper) {
        helper.cancelDeleteContact(component, event);		
	},

    // a Contact has been requested to delete, so prompt the user and track the deletion
    handleContactDeleteEvent : function(component, event, helper) {
        helper.promptDeleteContact(component, event);		
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
    
    // the default Address has changed, so update our Contacts
    handleAddressChangedEvent : function(component, event, helper) {
        helper.updateDefaultAddress(component, event);		
	},

})