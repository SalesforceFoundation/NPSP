({
    // initialize the container by loading up our Household and Contacts
    doInit : function(component, event, helper) {
        helper.fixupCustomLabels(component);
        helper.loadObjects(component);
        helper.initNewContact(component);
    },

    // display the spinner
    showSpinner : function(component /* , event, helper */) {
        component.set("v.showSpinner", true);
    },

    // hide the spinner
    hideSpinner : function(component /* , event, helper */) {
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
        helper.updateDefaultAddress(component, event.getParam('addrDefault'));
    },

    // show the new contact popup
    showNewContactPopup : function(component /*, event, helper */) {
        component.set('v.showNewContactPopup', true);
    },

    // proceed with create a new contact
    doNewContact : function(component, event, helper) {
        helper.createNewContact(component, event);
    },

    // cancel New Contact
    cancelNewContact : function(component /* , event, helper */) {
        component.set('v.showNewContactPopup', false);
    },

    // Salutation select list has changed, so update conNew
    onSalutationChange : function(component, event, helper) {
        helper.onSalutationChange(component);
    },

    // temp code for testing household Merge
    mergeTest : function(component, event, helper) {
        var hhMerge = {'sobjectType' : 'Account',
                        'Id' : '001G000001z8sxB',
                        'Number_of_Household_Members__c' : '2'};
        component.set('v.hhMerge', hhMerge);
        var conAdd = {'sobjectType' : 'Contact',
                        'Id' : '001G000001z8tAW',
                        'FirstName' : 'John',
                        'LastName' : 'Doe',
                        'MailingStreet' : 'Doe street',
                        'MailingCity' : 'Doe city',
                        'is_Address_Override__c' : 'true'};
        component.set('v.conAdd', conAdd);
        helper.addOrMergeContact(component, conAdd, hhMerge);
    },

    // add just the contact to the Household
    doAddContact : function(component, event, helper) {
        var conAdd = component.get('v.conAdd');
        helper.addContact(component, conAdd);
        component.set('v.showMergeHHPopup', false);
    },

    // merge the new household into the household
    doMergeHH : function(component, event, helper) {
        var hhMerge = component.get('v.hhMerge');
        helper.mergeHousehold(component, hhMerge);
        component.set('v.showMergeHHPopup', false);
    },

    // cancel Merge HH Popup
    cancelMergeHHPopup : function(component /* , event, helper */) {
        component.set('v.showMergeHHPopup', false);
    },

})