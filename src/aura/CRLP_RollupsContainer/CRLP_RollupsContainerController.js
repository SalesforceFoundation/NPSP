({
    doInit: function (cmp, event, helper) {
        var action = cmp.get("c.setupRollups");
        console.log("in the init function");

        //setup rollup records, filter group records, and operations
        //also sets the rollups grid to display on page load
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var modelString = response.getReturnValue();
                var model = JSON.parse(modelString);

                cmp.set("v.labels", model.labels);
                cmp.set("v.rollupList", model.items);
                cmp.set("v.filterGroupList", model.filterGroups);

                console.log(model.operations);

                var ops = [];
                for(var i in model.operations){
                    ops.push({name: i, label: model.operations[i]});
                }
                cmp.set("v.operations", ops);

                var yOps = [];
                for(var i in model.yearlyOperations){
                    yOps.push({name: i, label: model.yearlyOperations[i]});
                }
                cmp.set("v.yearlyOperations", yOps);

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
        //sets the filter group grid to be displayed, resets the column labels, and changes the breadcrumbs
        cmp.set("v.isFilterGroupsGrid",true);
        var labels = cmp.get("v.labels");
        var cols = [labels.name
            , labels.filterGroupDescription
            , labels.countOf+' '+labels.filterGroupLabelPlural
            , labels.countOf+' '+labels.rollupLabelPlural
            ];
        cmp.set("v.columns", cols);
        cmp.set("v.isRollupsGrid", false);

        var rollupSummaryTitle = cmp.get("v.labels.rollupSummaryTitle");
    },

    displayRollupsGrid: function(cmp, event, helper){
        //sets the rollups grid to be displayed, resets the column labels, and changes the breadcrumbs
        cmp.set("v.isRollupsGrid", true);
        cmp.set("v.isFilterGroupsGrid", false);
        cmp.set("v.isRollupDetail", false);
        cmp.set("v.detailMode", null);
        cmp.set("v.activeRollup", null);

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
        //checks if we're coming from the detail view; if already null the onchange won't fire
        cmp.set("v.activeRollupId", null);
    },

    handleRollupSelect: function(cmp, event, helper) {
        /**called when the activeRollupId changes, specifically in the rollupRow
         * queries active rollup ID to populate the full active rollup detail
         * switches the display to the detail view and sets the width for the buttons
         * called after user returns to grid since activeRollupId is cleared, null check is necessary**/
        var activeRollupId = cmp.get("v.activeRollupId");
        if(activeRollupId != null){
            /*
            var action = cmp.get("c.getRollupById");

            action.setParams({ id : activeRollupId });

            action.setCallback(this, function(response) {
                var state = response.getState();
                if (state === "SUCCESS") {
                    cmp.set("v.activeRollup", response.getReturnValue());
                    var activeRollupMap = cmp.get("v.activeRollup");
                    if(!$A.util.isUndefined(cmp.get("v.activeRollup.Yearly_Operation_Type__c"))) {
                        cmp.set("v.activeRollup.Yearly_Operation_Type__c",cmp.get("v.activeRollup.Yearly_Operation_Type__c").replace(/_/g, ' '));
                    }
                    if(!$A.util.isUndefined(cmp.get("v.activeRollup.Operation__c"))){
                        cmp.set("v.activeRollup.Operation__c",cmp.get("v.activeRollup.Operation__c").replace(/_/g, ' '));
                    }
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
            */

            cmp.set("v.isRollupsGrid",false);
            cmp.set("v.isRollupDetail",true);
            cmp.set("v.width", 8);
        } else{
            cmp.set("v.width", 12);
        }

    },
    displayNewRollupForm: function (cmp, event, helper) {
        //toggle grid and detail views, set detail mode to create
        //resets the active rollup to ensure there is no leftover data
        cmp.set("v.isRollupsGrid", false);
        cmp.set("v.isRollupDetail", true);
        cmp.set("v.detailMode", "create");
        //todo: check if this is necessary
        cmp.set("v.activeRollup", {});
    },

    //TODO: can these be combined?
    setModeEdit: function(cmp, event, helper) {
        //changes the mode from the edit or clone buttons
        cmp.set("v.detailMode", "edit");
        console.log("In setModeEdit");
    },
    setModeClone: function(cmp, event, helper) {
        //changes the mode from the edit or clone buttons
        cmp.set("v.detailMode", "clone");
        console.log("In setModeClone");
    },
})