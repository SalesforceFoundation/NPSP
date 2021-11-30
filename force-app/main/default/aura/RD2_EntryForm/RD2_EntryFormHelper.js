({
    /**
    * @description Handle events sent from the modal
    */
    handleModalEvent: function (component, event) {
        this.redirectToPage(component, event);
    },

    /**
     * @description: Redirect the page to either parent or RD record
     */
    redirectToPage: function (component, event) {
        let navEvt = this.constructNavigationEvent(event.getParams('detail').recordId);
        navEvt.fire();
    },

    /**
     * @description: Determine where the page should be redirect and construct the event
     */
    constructNavigationEvent: function (navigateToId) {
        let navEvt;

        if (navigateToId) {
            navEvt = $A.get("e.force:navigateToSObject");
            navEvt.setParams({
                "recordId": navigateToId,
                "slideDevName": "related"
            });

        } else {
            navEvt = $A.get("e.force:navigateToObjectHome");
            navEvt.setParams({
                "scope": "npe03__Recurring_Donation__c"
            });
        }

        return navEvt;
    }
})