({

    /**
    * @description Handles "close" event sent from the LWC:
    * closes the modal
    */
    handleClose: function (component, event, helper) {
        $A.get("e.force:closeQuickAction").fire();
    },
    /**
    * @description Handles "save" event sent from the LWC:
    * closes the modal and redirects to the Recurring Donation detail page
    */
    handleCloseOnSave: function (component, event, helper) {
        const recordId = component.get('v.recordId');

        this.handleClose();

        var refreshPageEvent = $A.get('e.force:navigateToSObject');
        refreshPageEvent.setParams({
            'recordId': recordId
        });
        refreshPageEvent.fire();
    },
})