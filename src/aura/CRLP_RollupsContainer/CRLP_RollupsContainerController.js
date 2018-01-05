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
                            , model.labels.creditType
                            , model.labels.operation
                            , model.labels.filterGroupLabel
                            , model.labels.active
                            ];
                cmp.set('v.columns', cols);

                cmp.set('v.isRollupsGrid',true);
                cmp.set('v.isFilterGroupsGrid',false);
                //cmp.set('v.activeRollupId',model.items[0].id);
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
            });

            $A.enqueueAction(action);
        }

        var labels = cmp.get("v.labels");
        var cols = [labels.name
            , labels.filterGroupDescription
            , labels.countOf+' '+labels.filterGroupLabelPlural
            , labels.countOf+' '+labels.rollupLabelPlural
            ];
        cmp.set('v.columns', cols);
        cmp.set('v.breadcrumbLevel', 1);

        cmp.set("v.isRollupsGrid",false);
        cmp.set("v.isFilterGroupsGrid",true);
        console.log('made it past booleans');

        var rollupSummaryTitle = cmp.get("v.labels.rollupSummaryTitle");
        cmp.set("v.breadcrumbs",[{label:rollupSummaryTitle,onclick:'!c.displayRollupsGrid'}])
    },

    displayRollupsGrid: function(cmp, event, helper){
        cmp.set("v.isRollupsGrid",true);
        cmp.set("v.isFilterGroupsGrid",false);
        cmp.set("v.isRollupDetail",false);

        var labels = cmp.get("v.labels");

        var cols = [labels.name
            , labels.summaryObject
            , labels.detailObject
            , labels.creditType
            , labels.operation
            , labels.filterGroupLabel
            , labels.active
        ];
        cmp.set('v.columns', cols);

        cmp.set("v.breadcrumbs",null);
    },

    handleRollupSelect: function(cmp, event, helper) {

        //console.log(cmp.get("v.activeRollup.rollupName"));
        //console.log(cmp.get("v.activeRollup.id"));
        var action = cmp.get("c.getRollupById");
        action.setParams({ id : cmp.get("v.activeRollupId") });

        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                cmp.set("v.activeRollup", response.getReturnValue());
                console.log('GOT TO ASSIGNMENT IN HANDLEROLLUPSELECT FUNCTION');
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

    //setActiveRollup: function(cmp, event, helper) {
    //    var rollup = cmp.get("v.rollup");
    //    cmp.set("v.activeRollup",rollup);
    //}

})