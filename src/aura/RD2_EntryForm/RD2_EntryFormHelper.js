({
    handleCloseModal: function(component) {
        const parentId = component.get('v.parentId');
        const recordId = component.get('v.recordId');
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

        navEvt.fire();
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