({
    doInit: function (cmp, event, helper) {
        //could be better to move to Helper
        var action = cmp.get("c.setupRollups");
        console.log("in the init function");

        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var model = response.getReturnValue();
                cmp.set("v.labels", model.labels);
                cmp.set("v.rollupList", model.items);
                var cols = [model.labels.name
                            , model.labels.summaryObject
                            , model.labels.detailObject
                            //TODO: this will need extra logic b/c it comes from 3 fields: , model.labels.detailField
                            , model.labels.creditType
                            , model.labels.operation
                            , model.labels.filterGroupName
                            , model.labels.active
                            ];
                cmp.set('v.columns', cols);
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