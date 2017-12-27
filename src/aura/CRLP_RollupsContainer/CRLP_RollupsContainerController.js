/**
 * Created by randi.wilson on 12/27/17.
 */
({
    doInit: function (cmp, event, helper) {
        //better to move to Helper
        var action = cmp.get("c.getRollupDefinitions");
        console.log("in the init function");

        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                // Alert the user with the value returned
                // from the server

                cmp.set("v.rollupList", response.getReturnValue());
                cmp.set('v.columns', [
                    //Rollup Type, Rollup Name, Target Field, Operation, Filter Group Name, Status
                    //Description doesn't exist
                    {label: 'Rollup Type', fieldName: 'rollupType', type: 'text'},
                    {label: 'Name', fieldName: 'rollupName', type: 'text'},
                    {label: 'Target Field', fieldName: 'targetField', type: 'text'},
                    {label: 'Operation', fieldName: 'operation', type: 'text'},
                    {label: 'Filter Group Name', fieldName: 'filterGroupName', type: 'text'},
                    {label: 'Active', fieldName: 'active', type: 'text'}
                ]);
                console.log(response.getReturnValue());
            }
            else if (state === "INCOMPLETE") {
                // do something
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
    },
})