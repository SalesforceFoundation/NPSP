({

    /**
    * @description Handle events sent from the modal
    */
    handleClose: function (component, event, helper) {
        $A.get("e.force:closeQuickAction").fire();
    },
    /**
    * @description Handle events sent from the modal
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