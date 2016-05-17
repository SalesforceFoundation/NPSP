({
    // initialize the container by loading up our Household and Contacts
	doInit : function(component, event, helper) {        
        helper.fixupCustomLabels(component);
        helper.loadObjects(component);
        helper.initNewContact(component);
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

    // proceed with deleting the contact
    doDeleteContact : function(component, event, helper) {
        helper.doDeleteContact(component, event);		
	},

    // cancel deleting the contact
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

    // show the new contact popup
    showNewContactPopup : function(component, event, helper) {
        component.set('v.showNewContactPopup', true);
	},

    // proceed with create a new contact
    doNewContact : function(component, event, helper) {
        helper.createNewContact(component, event);		
	},

    // cancel New Contact
    cancelNewContact : function(component, event, helper) {
        component.set('v.showNewContactPopup', false);
	},
    
    // Salutation select list has changed, so update conNew
    onSalutationChange : function(component, event, helper) {
        helper.onSalutationChange(component);
    },    
})