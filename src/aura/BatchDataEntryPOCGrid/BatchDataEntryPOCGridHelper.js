({
    navigateToComponent : function(component, cmpName) {

        $A.createComponent(
        cmpName,
        {},
        function(newComp) {
        var content = component.find("body");
        content.set("v.body", newComp);
        });
    },
    
    batchDataImportHelper : function(component) {

		//call apex class method
        var action = component.get("c.bdiImportData");
							          
        action.setCallback(this, function(response){
            var state = response.getState();
            var toastEvent = $A.get("e.force:showToast");

            if (state === "SUCCESS") {

            /*    toastEvent.setParams({
                    "title": "Success!",
                    "message": "BDI batch was queued successfully."
                });*/

                alert('BDI batch was queued correctly');
            }
            else {

                /*toastEvent.setParams({
                    "title": "Failure!",
                    "message": "Something went wrong."
                });*/
                alert('Something went wrong');
            }
        });

        $A.enqueueAction(action);
	},

    continueToValidationHelper: function(component) {

        //call apex class method
        var action = component.get('c.continueToValidation');

        action.setCallback(this, function(response){
            var state = response.getState();
            var toastEvent = $A.get("e.force:showToast");

            if (state === "SUCCESS") {

                console.log("SUCCESS");
            }
            else {

                console.log('Something went wrong');
            }
        });

        $A.enqueueAction(action);
    },

    continueToCommitHelper: function (component) {

        var batchId = component.get('v.recordId');

        var urlEvent = $A.get("e.force:navigateToURL");
        urlEvent.setParams({
            "url": "/apex/BDI_DataImport?batchId=" + batchId + "&retURL=" + batchId,
            "isredirect": "true"
        });
        urlEvent.fire();
    }
})