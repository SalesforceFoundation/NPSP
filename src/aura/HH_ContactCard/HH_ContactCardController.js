({
    // a naming exclusion checkbox has been modified, notify our container
    onCheck : function(component, event, helper) {
        helper.fireContactChangedEvent(component, event);
    },

    // the delete button has been pressed, notify our container
    deleteContact : function(component, event, helper) {
        helper.fireContactDeleteEvent(component, event);
    },
})
