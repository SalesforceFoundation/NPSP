({
    /**
     * @description: Close and redirect the modal
     */
    handleCloseModal: function(component) {
        let navEvt = this.constructNavigationEvent(
            component.get('v.parentId'),
            component.get('v.recordId')
        );

        component.get('v.modal').then(modal => {
            modal.close();
        });

        navEvt.fire();
    },

    /**
     * @description: Determine where the page should be redirect and construct the event
     */
    constructNavigationEvent: function(parentId, recordId) {
        let navEvt;

        if(parentId || recordId) {
            navEvt = $A.get("e.force:navigateToSObject");
            navEvt.setParams({
            "recordId": parentId || recordId,
            "slideDevName": "related"
            });

        } else {
            navEvt = $A.get("e.force:navigateToObjectHome");
            navEvt.setParams({
                "scope": "npe03__Recurring_Donation__c"
            });
        }

        return navEvt;
    },

    /**
    * @description: Decode the Base64 component fragment and get the parent Id from the url.
    * If the target fragment is not found, return a blank string or null
    */
    getParentId: function() {
        let syntax = 'inContextOfRef';
        syntax = syntax.replace(/[\[\]]/g, "\\$&");
        var url = window.location.href;
        var regex = new RegExp("[?&]" + syntax + "(=1\.([^&#]*)|&|#|$)");
        var encodedFramgents = regex.exec(url);

        if (!encodedFramgents) {
            return null;
        } else if (!encodedFramgents[2]) {
            return '';
        }
        
        const decodedFragment = decodeURIComponent(encodedFramgents[2].replace(/\+/g, " "));
        return JSON.parse(window.atob(decodedFragment)).attributes.recordId;
    }
})