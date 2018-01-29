({

    getRollup: function(cmp, event, helper) {
        console.log("IN GETROLLUP");
        /**called when the activeRollupId changes, specifically in the rollupRow
         * queries active rollup ID to populate the full active rollup detail
         * switches the display to the detail view and sets the width for the buttons
         * called after user returns to grid since activeRollupId is cleared, null check is necessary**/
        var activeRollupId = cmp.get("v.activeRollupId");

        if (activeRollupId != null) {
            var action = cmp.get("c.getRollupById");
            action.setParams({id: activeRollupId});

            action.setCallback(this, function (response) {
                var state = response.getState();
                if (state === "SUCCESS") {
                    //note: the parsing is important to avoid a shared reference
                    //todo: try to stringify on server side; only parse on client
                    //review: https://stackoverflow.com/questions/6605640/javascript-by-reference-vs-by-value
                    cmp.set("v.activeRollup", JSON.parse(JSON.stringify(response.getReturnValue())));
                    cmp.set("v.cachedRollup", JSON.parse(JSON.stringify(response.getReturnValue())));
                    if (!$A.util.isUndefined(cmp.get("v.activeRollup.Yearly_Operation_Type__c"))) {
                        //cmp.set("v.activeRollup.Yearly_Operation_Type__c", cmp.get("v.activeRollup.Yearly_Operation_Type__c").replace(/_/g, ' '));
                    }
                    if (!$A.util.isUndefined(cmp.get("v.activeRollup.Operation__c"))) {
                        //cmp.set("v.activeRollup.Operation__c", cmp.get("v.activeRollup.Operation__c").replace(/_/g, ' '));
                    }
                    //change mode needs to be fired here because the sibling change of mode isn't being registered
                    helper.changeMode(cmp);
                    //moved these into the callback so the slow load doesn't happen.
                    //need to consider an error message if the callback fails.
                    //the way this is now, if it fails, it'll stay on the grid cmp
                }
                else if (state === "ERROR") {
                    var errors = response.getError();
                    if (errors) {
                        if (errors[0] && errors[0].message) {
                            console.log("Error message: " +
                                errors[0].message);
                        }
                    } else {
                        console.log("Unknown error");
                    }
                }
            });

            $A.enqueueAction(action);

        } else {

        }
    },

    changeMode: function (cmp, event, helper) {
        helper.changeMode(cmp);
    },

    setModeEdit: function(cmp, event, helper) {
        //resetting mode here kicks off changeMode
        cmp.set("v.mode", "edit");
        console.log("In setModeEdit");
    },

    setModeClone: function(cmp, event, helper) {
        //resetting mode here kicks off changeMode
        cmp.set("v.mode", "clone");
    },

    onCancel: function(cmp, event, helper) {
        //options for cancel: return to rollup summaries or return to view
        //first checks to see if mode is clone and bubbles up an Id of 0 to parent to trigger handleRollupSelect
        //else resets mode to view to become display-only and resets rollup values
        console.log(cmp.get("v.activeRollupId"));
        if((cmp.get("v.mode") == 'clone' || cmp.get("v.mode") == 'create') && cmp.get("v.activeRollupId") == null){
            console.log("changing active rollup ID");
            //set off an event here
            var event = $A.get("e.c:CRLP_CancelEvent");
            event.setParams({});
            event.fire();
        } else {
            console.log("before changing view");
            cmp.set("v.mode", "view");
            console.log('in cancel');
            var cachedRollup = cmp.get("v.cachedRollup");
            console.log("Cached Rollup summary obj: ");
            console.log(cmp.get("v.cachedRollup.Summary_Object__r.QualifiedApiName"));
            console.log(cachedRollup);
            //json shenanigans to avoid shared reference
            cmp.set("v.activeRollup", JSON.parse(JSON.stringify(cachedRollup.valueOf())));
            console.log('after changing rollup');
        }
    },

    onChangeDetailObject: function(cmp, event, helper){
        if(cmp.get("v.mode")!='view') {
            console.log("hitting changedetailobject");
            if (cmp.get("v.objectDetails") != null && cmp.get("v.activeRollup") != null) {
                console.log("in changedetailobject function");
                //set new summary objects based on selected value
                var object = cmp.get("v.activeRollup.Detail_Object__r.QualifiedApiName");
                console.log('object: ' + object);
                helper.resetSummaryObjects(cmp, object);

                //set new detail fields based on new selected detail object
                helper.resetFields(cmp, object, 'detail');
                cmp.set("v.activeRollup.Detail_Field__r.QualifiedApiName", null);
                cmp.set("v.activeRollup.Summary_Object__r.QualifiedApiName", null);
                cmp.set("v.activeRollup.Amount_Field__r.QualifiedApiName", null);
                cmp.set("v.activeRollup.Date_Field__r.QualifiedApiName", null);

                //remove summary fields since no summary object is selected
                var newFields = [{name: 'None', label: cmp.get("v.labels.noFields")}];
                cmp.set("v.summaryFields", newFields);
                console.log("reset summary fields");

                //reset amount fields to match detail
                //TODO: reset entity label
                var objLabel;
                var detailObjects = cmp.get("v.detailObjects");

                for(var i=0; i<detailObjects.length; i++){
                    if(detailObjects[i].name == object){
                        objLabel = detailObjects[i].label;
                        break;
                    }
                }

                //change detail object labels to correctly show selected detail object in amount field
                cmp.set("v.activeRollup.Detail_Object__r.Label", objLabel);

                //filter and reset amount fields
                helper.resetFields(cmp, cmp.get("v.activeRollup.Detail_Object__r.QualifiedApiName"), "amount");

                //set date object label and api name based on the selected detail object then reset fields + selected value
                if(object == 'npe01__OppPayment__c'){
                    cmp.set("v.activeRollup.Date_Object__r.Label", cmp.get("v.labels.paymentLabel"));
                    cmp.set("v.activeRollup.Date_Object__r.QualifiedApiName", "npe01__OppPayment__c");
                } else {
                    cmp.set("v.activeRollup.Date_Object__r.Label", cmp.get("v.labels.opportunityLabel"));
                    cmp.set("v.activeRollup.Date_Object__r.QualifiedApiName", "Opportunity");
                }
                helper.resetFields(cmp, cmp.get("v.activeRollup.Date_Object__r.QualifiedApiName"), "date");
            }
        }
    },

    changeSummaryFields: function(cmp, event, helper){
        if(cmp.get("v.mode")!='view'){
            if(cmp.get("v.objectDetails") != null && cmp.get("v.activeRollup") != null){
                //change summary fields to match available detail field types + existing summary object
                console.log('in change summary field');
                var detailField = cmp.get("v.activeRollup.Detail_Field__r.QualifiedApiName");
                var summaryObject = cmp.get("v.activeRollup.Summary_Object__r.QualifiedApiName");
                //todo: nulls are evaluating to strings here; do we need a null check?
                helper.filterSummaryFieldsByDetailField(cmp, detailField, summaryObject);
            }
        }
    },

    onChangeOperation: function(cmp, event, helper){
        console.log('HITTING CHANGEOPERATION FUNCTION');
        if(cmp.get("v.mode")!='view') {
            if (cmp.get("v.objectDetails") != null && cmp.get("v.activeRollup") != null) {
                console.log('In change operation FUNCTION');
                helper.changeOperationsOptions(cmp);
            }
        }
    },
    onChangeYearlyOperation: function(cmp, event, helper){
        if(cmp.get("v.mode")!='view') {
            console.log('HITTING CHANGEYEARLYOBJECT FUNCTION');
            if (cmp.get("v.objectDetails") != null && cmp.get("v.activeRollup") != null) {
                helper.changeYearlyOperationsOptions(cmp);
            }
        }
    },
    onSetTemplate: function(cmp, event, helper){
        //set the correct options from the selected template
        var labels = cmp.get("v.labels");
        var selectedTemplate = cmp.get("v.selectedTemplate");
        console.log(selectedTemplate);
        var detailObj;
        var summaryObj

        if(selectedTemplate == 'null' || selectedTemplate == null){
            console.log('NULL selected template is: ' + selectedTemplate);
            detailObj = null;
            summaryObj = null;
        } else {
            detailObj = selectedTemplate.detailObject;
            summaryObj = selectedTemplate.summaryObject;
        }

        cmp.set("v.activeRollup.Detail_Object__r.QualifiedApiName", detailObj);
        cmp.set("v.activeRollup.Summary_Object__r.QualifiedApiName", summaryObj);
        cmp.set("v.mode", "clone");
    },

})