({
    /* @description: fired on each init of rollup
    */
    doInit: function(cmp, event, helper) {
        console.log("In Rollup doInit");
         /* queries active rollup ID to populate the full active rollup detail
         * switches the display to the detail view and sets the width for the buttons**/
        var activeRollupId = cmp.get("v.activeRollupId");

        //retrieve full active rollup information only if ID is passed to the component in view, edit or clone mode
        if (activeRollupId !== null) {
            var action = cmp.get("c.getRollupById");
            action.setParams({id: activeRollupId});

            action.setCallback(this, function (response) {
                var state = response.getState();
                if (state === "SUCCESS") {
                    //note: the duplicate parsing is important to avoid a shared reference
                    cmp.set("v.activeRollup", helper.restructureResponse(response.getReturnValue()));
                    cmp.set("v.cachedRollup", helper.restructureResponse(response.getReturnValue()));

                    //change mode needs to be fired here because the sibling change of mode isn't being registered
                    //TODO: review this since sibling isn't being used now
                    helper.changeMode(cmp);

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

            // creating a new Rollup

        }

        helper.setObjectAndFieldDependencies(cmp);
    },

    /* @description: fires when mode is changed
    */
    onChangeMode: function (cmp, event, helper) {
        helper.changeMode(cmp);
    },

    /* @description: fires when cancel button is clicked
    * options for cancel: return to rollup summaries or return to view
    * if mode is clone or create and ID is null the user returns to the grid
    * else resets mode to view to become display-only and resets rollup values
    */
    onCancel: function(cmp, event, helper) {
        //todo: should we make this more sensitive to a clone from edit mode
        if((cmp.get("v.mode") === 'clone' || cmp.get("v.mode") === 'create') && cmp.get("v.activeRollupId") === null){
            //set off cancel event for container
            var cancelEvent = $A.get("e.c:CRLP_CancelEvent");
            cancelEvent.setParams({grid: 'rollup'});
            cancelEvent.fire();
            console.log('firing cancel event');
        } else {
            cmp.set("v.mode", "view");
            var cachedRollup = cmp.get("v.cachedRollup");
            //json shenanigans to avoid shared reference
            cmp.set("v.activeRollup", helper.restructureResponse(cachedRollup.valueOf()));
            //reset all field visibility and values
            helper.fieldSetup(cmp);
        }
    },

    /* @description: fires when save button is clicked
    */
    onSave: function(cmp, event, helper){
        var activeRollup = cmp.get("v.activeRollup");
        helper.saveRollup(cmp, activeRollup);
    },

    /* @description: listens for a message from the select field cmp to trigger a change in the rollup information
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
            } else if (fieldName === 'rollupType'){
                helper.onChangeRollupType(cmp, value, label);
            } else if (fieldName === 'filterGroup'){
                helper.onChangeFilterGroup(cmp, label);
            } else if (fieldName ==='operation'){
                helper.onChangeOperation(cmp, value);
            } else if(fieldName === 'yearlyOperation'){
                helper.onChangeYearlyOperationsOptions(cmp, true, label);
            } else if(fieldName === 'integer'){
                helper.onChangeInteger(cmp, value);
            } else if(fieldName === 'detailField'){
                helper.onChangeDetailField(cmp, value, label);
            }
        }
    }

})