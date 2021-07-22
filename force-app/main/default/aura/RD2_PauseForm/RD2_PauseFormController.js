({
    /**
     * @description: Closes the Pause Recurring Donation QuickAction modal
     */
    handleClose: function (component, event, helper) {
        helper.handleClose(component, event);
    },
    /**
     * @description: Closes the Pause Recurring Donation QuickAction modal 
     * on submit (when user clicks [Save])
     */
    handleCloseOnSave: function (component, event, helper) {
        helper.handleCloseOnSave(component, event);
    }
})