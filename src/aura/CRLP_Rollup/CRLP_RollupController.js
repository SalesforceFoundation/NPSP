({
    /* @description: fired on each init of rollup
    */
    doInit: function(cmp, event, helper) {
        console.log("In Rollup doInit");
         /* queries active rollup ID to populate the full active rollup detail
         * switches the display to the detail view and sets the width for the buttons**/
        var activeRollupId = cmp.get("v.activeRollupId");
        helper.getRollupRecord(cmp, helper, activeRollupId);
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
    },

    closeNotificationWindow : function(cmp, event, helper) {
        console.log('Close Window');
        cmp.set("v.notificationClasses", "slds-hide");
    }

})