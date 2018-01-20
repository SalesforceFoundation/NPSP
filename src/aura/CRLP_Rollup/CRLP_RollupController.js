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
                    cmp.set("v.activeRollup", response.getReturnValue());
                    cmp.set("v.cachedRollup", response.getReturnValue());
                    if (!$A.util.isUndefined(cmp.get("v.activeRollup.Yearly_Operation_Type__c"))) {
                        cmp.set("v.activeRollup.Yearly_Operation_Type__c", cmp.get("v.activeRollup.Yearly_Operation_Type__c").replace(/_/g, ' '));
                    }
                    if (!$A.util.isUndefined(cmp.get("v.activeRollup.Operation__c"))) {
                        cmp.set("v.activeRollup.Operation__c", cmp.get("v.activeRollup.Operation__c").replace(/_/g, ' '));
                    }
                    cmp.set("v.isRollupsGrid", false);
                    cmp.set("v.isRollupDetail", true);
                    cmp.set("v.width", 8);
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
            cmp.set("v.width", 12);
        }
    },

/*
    setActiveToCached:function(cmp, event, helper) {
        console.log("in setActiveToCached");
        var activeRollup = cmp.get("v.activeRollup");
        console.log('Active Rollup: '+activeRollup);
        cmp.set("v.cachedRollup",activeRollup);
        console.log('Cached Rollup: '+cmp.get("v.cachedRollup"));
        helper.changeMode(cmp);
    },
*/

    changeMode: function (cmp, event, helper) {
        helper.changeMode(cmp);
    },

    onModeChanged:function(cmp,event,helper){
        console.log('heard ModeChanged event');
        var mode = event.getParam('mode');
        cmp.set("v.mode", mode);
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
        console.log('in cancel');
        var cachedRollup = cmp.get("v.cachedRollup");
        console.log("Cached Rollup: "+cachedRollup);
        cmp.set("v.activeRollup",cachedRollup);
        console.log("Active Rollup:");
        console.log(cmp.get("v.activeRollup"));
        cmp.set("v.mode", "view");
        //helper.resetAllFields(cmp);
        //helper.resetRollup(cmp);
    },

    onChangeDetailObject: function(cmp, event, helper){
        console.log("in changedetailobject");
        if(cmp.get("v.objectDetails") != null){
            if(cmp.get("v.activeRollup") != null) {
                //set new summary objects based on selected value
                var object = cmp.get("v.activeRollup.Detail_Object__r.QualifiedApiName");
                console.log('object: ' + object);
                helper.resetSummaryObjects(cmp, object);

                //set new detail fields based on new selected detail object
                helper.resetFields(cmp, object, 'detail');

                //TODO: what should we be doing with summary fields?
                //likely: change to 'please select'
            }
        }
    },

    onChangeDetailField: function(cmp, event, helper){
        if(cmp.get("v.objectDetails") != null){
            if(cmp.get("v.activeRollup") != null){
                //change summary fields to match available detail field types + existing summary object
                console.log('in change summary field');
                //var detailField = cmp.find("detailFieldSelect").get("v.value");
                //var summaryObject = cmp.find("summaryObjectSelect").get("v.value");
                var detailField = cmp.get("v.activeRollup.Detail_Field__r.QualifiedApiName");
                console.log("Detail Field: "+detailField);
                var summaryObject = cmp.get("v.activeRollup.Summary_Object__r.QualifiedApiName")
                console.log("Summary Field: "+summaryObject);
                helper.filterSummaryFieldsByDetailField(cmp, detailField, summaryObject);
            }
        }
    },

    changeAmountObject: function(cmp, event, helper){
        //change amount fields to match new summary object + existing detailField
        var object = cmp.find("amountObjectSelect").get("v.value");
        helper.resetFields(cmp, object, 'amount');
    },
    changeDateObject: function(cmp, event, helper){
        console.log('HITTING CHANGEDATEOBJECT FUNCTION');
        //change date fields to match new summary object + existing detailField
        var object = cmp.find("dateObjectSelect").get("v.value");
        helper.resetFields(cmp, object, 'date');
    },

})