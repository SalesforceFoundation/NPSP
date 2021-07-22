({
    /**
     * @description Init function
     */
    doInit: function (component, event, helper) {
       helper.handleShowModal(component, event, helper);
    },

    /**
     * @description: Listen and handle the event sent from the modal
     */
    handleModalEvent: function(component, event, helper) {
        helper.handleModalEvent(component, event);
    }
})
