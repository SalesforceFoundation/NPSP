({
    init: function(component, event, helper) {
        // Prepare a new record from template
        component.find("batchRecordCreator").getNewRecord(
            "DataImportBatch__c", // sObject type (entityApiName)
            null,      // recordTypeId
            false,     // skip cache?
            $A.getCallback(function() {
                var rec = component.get("v.newBatch");
                var error = component.get("v.batchError");
                if(error || (rec === null)) {
                    console.log("Error initializing record template: " + error);
                    return;
                }
                console.log("Record template initialized: " + rec.sobjectType);

            })
        );
    },

    closeModal: function(component, event, helper) {

        var dismissEvent = $A.get("e.c:BGE_BatchMenuDismissModalEvent");
        console.log(JSON.stringify(dismissEvent));
        dismissEvent.fire();
    },

    lightningInputOnChange: function(component, event, helper) {

        var batchName = component.find("batchName").get("v.value")

        if (batchName && batchName.length > 2) {
            component.set("v.nextButtonEnabled", true);
        }
    },

    handleSaveContact: function(component, event, helper) {

            // Default Values
            component.set("v.sampleBatch.Batch_Status__c", "In Progress");
            component.set("v.sampleBatch.Object_Name__c", "Opportunity");

            component.find("batchRecordCreator").saveRecord(function(saveResult) {

                if (saveResult.state === "SUCCESS" || saveResult.state === "DRAFT") {
                    
                    // record is saved successfully
                    var resultsToast = $A.get("e.force:showToast");
                    /*resultsToast.setParams({
                        "title": "Saved",
                        "message": "The record was saved."
                    });*/
                    resultsToast.fire();

                    // window.alert(saveResult);
                }
                else if (saveResult.state === "INCOMPLETE") {
                    // handle the incomplete state
                    console.log("User is offline, device doesn't support drafts.");
                }
                else if (saveResult.state === "ERROR") {
                    // handle the error state
                    console.log('Problem saving contact, error: ' + JSON.stringify(saveResult.error));
                }
                else {
                    console.log('Unknown problem, state: ' + saveResult.state + ', error: ' + JSON.stringify(saveResult.error));
                }
            });
    }
})