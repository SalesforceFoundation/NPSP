({
    doInit: function (cmp, event, helper) {
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
                            , model.labels.creditType
                            , model.labels.operation
                            , model.labels.filterGroupLabel
                            , model.labels.active
                            ];
                cmp.set("v.columns", cols);

                cmp.set("v.isRollupsGrid",true);
                cmp.set("v.isFilterGroupsGrid",false);
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

    displayFilterGroupsGrid: function(cmp, event, helper){
        //check for list first so that we only make necessary server trips
        if($A.util.isEmpty(cmp.get("v.filterGroupList"))){
            var action = cmp.get("c.getFilterGroupDefinitions");

            action.setCallback(this, function(response) {
                var state = response.getState();
                if (state === "SUCCESS") {
                    var filtergroups = response.getReturnValue();
                    cmp.set("v.filterGroupList", filtergroups);
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
                cmp.set("v.isFilterGroupsGrid",true);
            });

            $A.enqueueAction(action);
        } else {
            cmp.set("v.isFilterGroupsGrid",true);
        }

        var labels = cmp.get("v.labels");
        var cols = [labels.name
            , labels.filterGroupDescription
            , labels.countOf+' '+labels.filterGroupLabelPlural
            , labels.countOf+' '+labels.rollupLabelPlural
            ];
        cmp.set("v.columns", cols);
        cmp.set("v.breadcrumbLevel", 1);
        cmp.set("v.isRollupsGrid",false);

        var rollupSummaryTitle = cmp.get("v.labels.rollupSummaryTitle");
        cmp.set("v.breadcrumbs",[{label:rollupSummaryTitle,onclick:'!c.displayRollupsGrid'}])
    },

    displayRollupsGrid: function(cmp, event, helper){
        cmp.set("v.isRollupsGrid",true);
        cmp.set("v.isFilterGroupsGrid",false);
        cmp.set("v.isRollupDetail",false);
        cmp.set("v.activeRollup", null);
        cmp.set("v.detailMode", null);

        var labels = cmp.get("v.labels");

        var cols = [labels.name
            , labels.summaryObject
            , labels.detailObject
            , labels.creditType
            , labels.operation
            , labels.filterGroupLabel
            , labels.active
        ];
        cmp.set("v.columns", cols);

        cmp.set("v.breadcrumbs",null);
        cmp.set("v.activeRollupId", null);
    },

    handleRollupSelect: function(cmp, event, helper) {
        //query using the active rollup ID to populate the full active rollup detail
        var activeRollupId = cmp.get("v.activeRollupId");
        //first check that activeRollupId hasn't been nulled out
        if(activeRollupId != null){
            var action = cmp.get("c.getRollupById");
            action.setParams({ id : activeRollupId });

            action.setCallback(this, function(response) {
                var state = response.getState();
                if (state === "SUCCESS") {
                    cmp.set("v.activeRollup", response.getReturnValue());
                    var activeRollupMap = cmp.get("v.activeRollup");
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

            cmp.set("v.isRollupsGrid",false);
            cmp.set("v.isRollupDetail",true);
        }

    },
    displayNewRollupForm: function (cmp, event, helper) {
        //toggle grid and detail views, set detail mode to create
        cmp.set("v.isRollupsGrid",false);
        cmp.set("v.isRollupDetail",true);
        cmp.set("v.detailMode", cmp.get("v.labels.create"));
        cmp.set("v.activeRollup", {});
    }

})