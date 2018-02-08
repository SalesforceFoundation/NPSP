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
                cmp.set("v.cachedRollupList", model.items);
                cmp.set("v.filterGroupList", model.filterGroups);

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

                var cols = [{label: model.labels.name, name: 'rollupName'}
                            , {label: model.labels.summaryObject, name: 'summaryObject'}
                            , {label: model.labels.detailObject, name: 'detailObject'}
                            , {label: model.labels.creditType, name: 'creditType'}
                            , {label: model.labels.operation, name: 'operation'}
                            , {label: model.labels.filterGroupLabel, name: 'filterGroupName'}
                            , {label: model.labels.active, name: 'active'}
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
        var cols = [{label: labels.name, name: 'label'}
            , {label: labels.filterGroupDescription, name: 'description'}
            , {label: labels.countOf+' '+labels.filterGroupLabelPlural, name: 'countFilterRules'}
            , {label: labels.countOf+' '+labels.rollupLabelPlural, name: 'countRollups'}
            ];
        cmp.set("v.columns", cols);
        cmp.set("v.isRollupsGrid", false);

        var rollupSummaryTitle = cmp.get("v.labels.rollupSummaryTitle");
    },

    displayNewRollupForm: function (cmp, event, helper) {
        //toggle grid and detail views, set detail mode to create
        //resets the active rollup to ensure there is no leftover data
        cmp.set("v.isRollupsGrid", false);
        cmp.set("v.isRollupDetail", true);
        cmp.set("v.detailMode", "create");
        cmp.set("v.activeRollup", {});
    },

    displayRollupsGrid: function(cmp, event, helper){
        //sets the rollups grid to be displayed, resets the column labels
        helper.displayRollupsGrid(cmp);
    },

    filterBySummaryObject: function(cmp, event, helper){
        //filters visible rollups by the summary object picklist
        var object = cmp.find("selectSummaryObject").get("v.value");
        helper.filterData(cmp, object);
    },

    handleRollupCancelEvent: function(cmp, event, helper){
        //switches to rollup grid after hearing cancel event from rollup detail
        helper.displayRollupsGrid(cmp);
    },

    handleRollupSelect: function(cmp, event, helper) {
        /**called when the activeRollupId changes, specifically in the rollupRow
         * switches the display to the detail view and sets the width for the buttons
         * called after user returns to grid since activeRollupId is cleared, null check is necessary**/
        var activeRollupId = cmp.get("v.activeRollupId");
        if(activeRollupId != null){
            cmp.set("v.isRollupsGrid",false);
            cmp.set("v.isRollupDetail",true);
            cmp.set("v.width", 8);
        } else{
            cmp.set("v.width", 12);
        }

    },

    setMode: function(cmp, event, helper) {
        //changes the mode from the edit or clone buttons
        var name = event.getSource().get("v.name");
        cmp.set("v.detailMode", name);
    },

    sortByColumns: function(cmp, event, helper){
        var fieldName = event.getParam('fieldName');
        var sortDirection = event.getParam('sortDirection');
        helper.sortData(cmp, fieldName, sortDirection);
    },
})