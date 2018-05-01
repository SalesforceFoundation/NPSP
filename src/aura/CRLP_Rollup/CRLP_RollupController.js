({
    /**
     * @description: fired on each init of rollup
     *   queries active rollup ID to populate the full active rollup detail
     *   sets operations and object details
     */
    doInit: function(cmp, event, helper) {
        console.log("In Rollup doInit");
         /*
         * switches the display to the detail view and sets the width for the buttons**/
        var labels = cmp.get("v.labels");
        var detailObjects = cmp.get("v.detailObjects");
        var summaryObjects = cmp.get("v.summaryObjects");
        cmp.set("v.detailObjects", detailObjects);

        //put only the object names into a list
        var summaryNames = summaryObjects.map(function (summaryObj, index, array) {
            return summaryObj.name;
        });
        var detailNames = detailObjects.map(function (detailObj, index, array) {
            return detailObj.name;
        });

        var activeRollupId = cmp.get("v.activeRollupId");
        if(activeRollupId === null){
            activeRollupId = '';
        }
        var action = cmp.get("c.setupRollupDetail");

        action.setParams({rollupId: activeRollupId, targetObjectNames: summaryNames, detailObjectNames: detailNames});

        action.setCallback(this, function (response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var data = response.getReturnValue();
                var model = JSON.parse(data);
                //note: the duplicate parsing is important to avoid a shared reference
                if(activeRollupId){
                    cmp.set("v.activeRollup", helper.restructureResponse(model.rollup));
                    cmp.set("v.cachedRollup", helper.restructureResponse(model.rollup));
                }

                var tOps = [];
                for(var j in model.timeBoundOperations){
                    tOps.push({name: j, label: model.timeBoundOperations[j]});
                }
                tOps.sort(function(a,b){
                    return a.name > b.name;
                });
                cmp.set("v.timeBoundOperations", tOps);

                cmp.set("v.operations", model.operations);
                cmp.set("v.objectDetails", model.fieldsByDataType);
                console.log('before change mode');
                //change mode needs to be fired here because the sibling change of mode isn't being registered
                helper.changeMode(cmp);
                helper.setObjectAndFieldDependencies(cmp);

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
            helper.toggleSpinner(cmp, false);
        });

        $A.enqueueAction(action);
    },

    /**
     * @description: fires when mode is changed
     */
    onChangeMode: function (cmp, event, helper) {
        helper.changeMode(cmp);
    },

    /**
     * @description: fires when cancel button is clicked
     * options for cancel: return to rollup summaries or return to view
     * if mode is clone or create and ID is null the user returns to the grid
     * else resets mode to view to become display-only and resets rollup values
     */
    onCancel: function(cmp, event, helper) {
        //todo: should we make this more sensitive to a clone from edit mode: will need to also factor in uniqueSummaryFieldCheck type check
        if((cmp.get("v.mode") === 'clone' || cmp.get("v.mode") === 'create') && cmp.get("v.activeRollupId") === null){
            //set off cancel event for container
            var cancelEvent = $A.get("e.c:CRLP_CancelEvent");
            cancelEvent.setParams({grid: 'rollup'});
            cancelEvent.fire();
            console.log('firing cancel event');
        } else if (cmp.get("v.mode") === 'delete') {
            helper.toggleModal(cmp);
            cmp.set("v.mode", "view");
        } else {
            cmp.set("v.mode", "view");
            var cachedRollup = cmp.get("v.cachedRollup");
            //json shenanigans to avoid shared reference
            cmp.set("v.activeRollup", helper.restructureResponse(cachedRollup.valueOf()));
            //reset all field visibility and values
            helper.fieldSetup(cmp);
        }
    },

    /**
     * @description: fires when save button is clicked
     */
    onSave: function(cmp, event, helper){
        var activeRollup = cmp.get("v.activeRollup");
        if (cmp.get("v.mode") == 'delete') {
            helper.toggleModal(cmp);
            helper.saveRollup(cmp, activeRollup);
        } else {
            var canSave = helper.validateFields(cmp);
            if(canSave){
                helper.saveRollup(cmp, activeRollup);
                cmp.set("v.mode", 'view');
                helper.updateRollupName(cmp);
            }
        }
    },

    /**
     * @description: listens for a message from the select field cmp to trigger a change in the rollup information
     * fields are IDed by their camelcase names. ex: Summary_Object__c is summaryObject
     */
    onSelectValueChange: function(cmp, event, helper){
        var message = event.getParam("message");
        var channel = event.getParam("channel");
        if(channel === 'selectField'){
            var fieldName = message[0];
            var value = message[1];
            var label = message[2];
            console.log("field name is " + fieldName);
            console.log("value is " + value);

            if(fieldName === 'summaryObject'){
                helper.onChangeSummaryObject(cmp, value, label);
            } else if (fieldName === 'summaryField'){
                helper.onChangeSummaryField(cmp, label);
            } else if (fieldName ==='operation'){
                helper.onChangeOperation(cmp, value);
            } else if(fieldName === 'timeBoundOperation'){
                helper.onChangeTimeBoundOperationsOptions(cmp, true, label);
            } else if(fieldName === 'integer'){
                helper.onChangeInteger(cmp, value);
            } else if (fieldName === 'rollupType'){
                helper.onChangeRollupType(cmp, value, label);
            } else if (fieldName === 'filterGroup'){
                helper.onChangeFilterGroup(cmp, label);
            } else if(fieldName === 'detailField'){
                helper.onChangeDetailField(cmp, value, label);
            } else if(fieldName === 'amountField'){
                cmp.set("v.activeRollup.amountFieldLabel", label);
            } else if(fieldName === 'dateField'){
                cmp.set("v.activeRollup.dateFieldLabel", label);
            }
        }
    },

    /**
     * @description: closes the toast notification window
     */
    closeNotificationWindow : function(cmp, event, helper) {
        cmp.set("v.notificationClasses", "slds-hide");
    }

})