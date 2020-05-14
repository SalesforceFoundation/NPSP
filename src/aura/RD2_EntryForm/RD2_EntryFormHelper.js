({
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

    constructNavigationEvent: function(parentId, recordId) {
        let navEvt;

        if(parentId || recordId) {
            navEvt = $A.get("e.force:navigateToSObject");
            navEvt.setParams({
            "recordId": (recordId) ? recordId : parentId,
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

    getParentId: function() {
        let syntax = 'inContextOfRef';
        syntax = syntax.replace(/[\[\]]/g, "\\$&");
        var url = window.location.href;
        var regex = new RegExp("[?&]" + syntax + "(=1\.([^&#]*)|&|#|$)");
        var results = regex.exec(url);

        if (!results) {
            return null;
        } else if (!results[2]) {
            return '';
        }
        
        const decodedUrlId = decodeURIComponent(results[2].replace(/\+/g, " "));
        return JSON.parse(window.atob(decodedUrlId)).attributes.recordId;
    }
})