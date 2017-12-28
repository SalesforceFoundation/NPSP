({
    doInit: function (cmp, event, helper) {
        //better to move to Helper
        var action = cmp.get("c.setupRollups");
        console.log("in the init function");

        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var model = response.getReturnValue();
                cmp.set("v.rollupList", model.items);
                cmp.set('v.columns', [
                    //these can't be translated; another reason for a custom table component
                    {label: 'Rollup Type', fieldName: 'rollupType', type: 'text'},
                    {label: 'Name', fieldName: 'rollupName', type: 'text'},
                    {label: 'Target Field', fieldName: 'targetField', type: 'text'},
                    {label: 'Operation', fieldName: 'operation', type: 'text'},
                    {label: 'Filter Group Name', fieldName: 'filterGroupName', type: 'text'},
                    {label: 'Active', fieldName: 'active', type: 'text'}
                    //{label: 'Actions', fieldName: '', type:'text'}
                ]);
                cmp.set("v.labels", model.labels);
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