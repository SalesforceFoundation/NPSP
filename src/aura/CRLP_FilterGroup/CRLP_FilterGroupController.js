
({
    doInit: function(cmp, event, helper){
        //query for the active filter group
        var activeFilterGroupId = cmp.get("v.activeFilterGroupId");
        if (activeFilterGroupId != null) {
            var action = cmp.get("c.getFilterGroupById");
            action.setParams({id: activeFilterGroupId});

            action.setCallback(this, function (response) {
                var state = response.getState();
                if (state === "SUCCESS") {
                    //note: the parsing is important to avoid a shared reference
                    //todo: try to stringify on server side; only parse on client
                    //review: https://stackoverflow.com/questions/6605640/javascript-by-reference-vs-by-value
                    var filterGroup = response.getReturnValue();
                    cmp.set("v.activeFilterGroup", JSON.parse(JSON.stringify(filterGroup)));
                    cmp.set("v.cachedFilterGroupRollup", JSON.parse(JSON.stringify(response.getReturnValue(filterGroup))));

                    var labels = cmp.get("v.labels");

                    var actions = [{label: labels.edit, name:'edit'}
                        , {label: labels.clone, name:'clone'}
                        , {label: labels.delete, name:'delete'}
                    ];

                    var filterRuleColumns = [{label: labels.object, fieldName: 'objectType', type: 'string', sortable: 'false'}
                        , {label: labels.field, fieldName: 'targetField', type: 'string', sortable: 'false'}
                        , {label: labels.operator, fieldName: 'operation', type: 'string', sortable: 'false'}
                        , {label: labels.constant, fieldName: 'values', type: 'string', sortable: 'false'}
                        , {type: 'action', typeAttributes: { rowActions: actions }}
                    ];

                    cmp.set("v.filterRuleColumns", filterRuleColumns);
                    helper.filterRollupList(cmp, filterGroup.MasterLabel, labels);

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

        }
    },

    onCancel: function(cmp, event, helper){
        //placeholder for on cancel function in !view mode

    },

    onSave: function(cmp, event, helper){
        //placeholder for on cancel function in !view mode

    },

    selectRollup: function(cmp, event, helper){
        //select rollup for navigation
        var rollupId = event.getParam('name');
        if(rollupId != 'title'){
            var event = $A.get("e.c:CRLP_ViewRollupEvent");
            event.setParams({id: rollupId, target: 'rollup'});
            event.fire();
        }
    }
})