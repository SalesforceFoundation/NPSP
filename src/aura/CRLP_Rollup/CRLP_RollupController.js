({
    doInit: function(cmp, event, helper) {
        console.log("In Rollup doInit");
        /**called when the activeRollupId changes, specifically in the rollupRow
         * queries active rollup ID to populate the full active rollup detail
         * switches the display to the detail view and sets the width for the buttons
         * called after user returns to grid since activeRollupId is cleared, null check is necessary**/
        var activeRollupId = cmp.get("v.activeRollupId");

        if (activeRollupId !== null) {
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

    onChangeMode: function (cmp, event, helper) {
        helper.changeMode(cmp);
    },

    onCancel: function(cmp, event, helper) {
        //options for cancel: return to rollup summaries or return to view
        //first checks to see if mode is clone and bubbles up an Id of 0 to parent to trigger handleRollupSelect
        //else resets mode to view to become display-only and resets rollup values
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
            cmp.set("v.activeRollup", JSON.parse(JSON.stringify(cachedRollup.valueOf())));
        }
    },

    /*onChangeDetailObject: function(cmp, event, helper){
        helper.onChangeSummaryObject(cmp);
    },
*/
    onChangeSummaryObject: function(cmp, event, helper){
        helper.onChangeSummaryObjectHelper(cmp);

        //change summary fields to match available detail field types + existing summary object
        if(cmp.get("v.mode") !== 'view'){
            if(cmp.get("v.objectDetails") !== null && cmp.get("v.activeRollup") !== null){
                console.log('in onChangeSummaryObject');
                var summaryObject = cmp.get("v.activeRollup.Summary_Object__r.QualifiedApiName");
                helper.resetFields(cmp, cmp.get("v.activeRollup.Summary_Object__r.QualifiedApiName"), "summary");
            }
        }

        var labels = cmp.get("v.labels");
        var templateList = [];
        if (summaryObject === 'Account') {
            console.log('adding stuff for Account');
            //debugger;
            templateList.push({label: labels.opportunityLabel + ' -> ' + labels.accountLabel + ' ' + labels.hardCredit,
                    summaryObject: 'Account', name: 'Opportunity'}
                , {label: labels.opportunityLabel + ' -> ' + labels.accountLabel + ' ' + labels.softCredit
                    , summaryObject: 'Account', name: 'npe01__OppPayment__c'}
                , {label: labels.opportunityLabel + ' -> ' + labels.contactLabel + ' ' + labels.hardCredit
                    , summaryObject: 'Account', name: 'Partial_Soft_Credit__c'});
        } else if (summaryObject === 'Contact') {
            templateList.push({label: labels.opportunityLabel + ' -> ' + labels.contactLabel + ' ' + labels.softCredit
                , summaryObject: 'Contact', name: 'Opportunity'}
            , {label: labels.paymentLabel + ' -> ' + labels.accountLabel + ' ' + labels.hardCredit
                    , summaryObject: 'Contact', name: 'Partial_Soft_Credit__c'}
            , {label: labels.paymentLabel + ' -> ' + labels.contactLabel + ' ' + labels.hardCredit
                    , summaryObject: 'Contact', name: 'npe01__OppPayment__c'});
        } else if (summaryObject === 'General_Accounting_Unit__c') {
            templateList.push({label: labels.allocationLabel + ' -> ' + labels.gauLabel
                , summaryObject: 'General_Accounting_Unit__c', name: 'Allocation__c'});
        }

        cmp.set("v.rollupTypes",templateList);
        console.log('RollupTypes: '+cmp.get("v.rollupTypes"));

    },

    onChangeSummaryField: function (cmp, event, helper) {
      helper.updateAllowedOperations(cmp);
    },

    onChangeOperation: function (cmp, event, helper) {
        //no check for view mode because the recalculation of operation is necessary with label formatting
        if (cmp.get("v.objectDetails") !== null && cmp.get("v.activeRollup") !== null) {
            console.log('On change operation');
            helper.updateDependentOperations(cmp);
        }
    },
    onChangeYearlyOperation: function (cmp, event, helper) {
        if (cmp.get("v.objectDetails") !== null && cmp.get("v.activeRollup") !== null) {
            console.log('On change yearly operation');
            helper.changeYearlyOperationsOptions(cmp, true);
        }
    },
    onSave: function(cmp, event, helper){
        var activeRollup = cmp.get("v.activeRollup");
        helper.saveRollup(cmp, activeRollup);
    }

})