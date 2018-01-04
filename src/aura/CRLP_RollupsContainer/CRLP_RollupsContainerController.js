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
                var cols = [model.labels.rollupName
                            , model.labels.summaryObject
                            , model.labels.detailObject
                            , model.labels.creditType
                            , model.labels.operation
                            , model.labels.filterGroupLabel
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
    /*navToFilterGroups: function(cmp, event, helper){
        console.log('in the nav function');
        var urlEvent = $A.get("e.force:navigateToURL");
        urlEvent.setParams({
            "url": "/apex/STG_SettingsManager"
        });
        urlEvent.fire();
    },*/
    navToFilterGroupsGrid: function(cmp, event, helper){
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

        var cols = ["Name"
            , "Description"
            ];
        cmp.set('v.columns', cols);
        cmp.set('v.breadcrumbLevel', 1);

        cmp.set("v.isRollupsGrid",false);
        cmp.set("v.isFilterGroupsGrid",true);
    },
    navToRollupsGrid: function(cmp, event, helper){
        cmp.set("v.isRollupsGrid",true);
        cmp.set("v.isFilterGroupsGrid",false);
        var labels = cmp.get("v.labels");
        var cols = [labels.rollupName
            , labels.summaryObject
            , labels.detailObject
            , labels.creditType
            , labels.operation
            , labels.filterGroupLabel
            , labels.active
        ];
        cmp.set('v.columns', cols);
    }
})