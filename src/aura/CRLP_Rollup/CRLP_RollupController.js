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
        //resets mode to view to become display-only
        //also needs to reset rollup values to match what exists in the database
        console.log("before changing view");
        cmp.set("v.mode", "view");
        console.log('in cancel');
        var cachedRollup = cmp.get("v.cachedRollup");
        console.log("Cached Rollup summary obj: ");
        console.log(cmp.get("v.cachedRollup.Summary_Object__r.QualifiedApiName"));
        console.log(cachedRollup);
        //json shenanigans to avoid shared reference
        cmp.set("v.activeRollup",JSON.parse(JSON.stringify(cachedRollup.valueOf())));
        console.log('after changing rollup');
        //helper.resetAllFields(cmp);
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
                if(object === 'null'){
                    cmp.set("v.activeRollup.Detail_Field__r.QualifiedApiName", null);
                }

                //remove summary fields since no summary object is selected
                var newFields = [{name: 'None', label: "No eligible fields found."}];
                cmp.set("v.summaryFields", newFields);
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
                if(summaryObject != null && detailField != null){
                    helper.filterSummaryFieldsByDetailField(cmp, detailField, summaryObject);
                } else {
                    //cmp.set("v.activeRollup.Detail_Field__r.QualifiedApiName","select");
                    cmp.set("v.activeRollup.Summary_Field__r.QualifiedApiName",null);
                }
            }
        }
    },

    onChangeAmountObject: function(cmp, event, helper){
        if(cmp.get("v.mode")!='view') {
            //change amount fields to match new summary object + existing detailField
            console.log('HITTING CHANGEAMOUNTOBJECT FUNCTION');
            if (cmp.get("v.objectDetails") != null && cmp.get("v.activeRollup") != null) {
                console.log('In onChangeAmount FUNCTION');
                var object = cmp.get("v.activeRollup.Amount_Object__r.QualifiedApiName");
                helper.resetFields(cmp, object, 'amount');
            }
        }
    },
    onChangeDateObject: function(cmp, event, helper){
        if(cmp.get("v.mode")!='view') {
            console.log('HITTING CHANGEDATEOBJECT FUNCTION');
            if (cmp.get("v.objectDetails") != null && cmp.get("v.activeRollup") != null) {
                //change date fields to match new summary object + existing detailField
                console.log('In onChangeDateObject FUNCTION');
                var object = cmp.get("v.activeRollup.Date_Object__r.QualifiedApiName");
                helper.resetFields(cmp, object, 'date');
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
    }

})