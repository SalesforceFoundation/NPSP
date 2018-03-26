({
    /* @description: setup for the filter group component which sets the active filter group and datatable
    */
    doInit: function(cmp, event, helper){
        //query for the active filter group
        var activeFilterGroupId = cmp.get("v.activeFilterGroupId");
        if (activeFilterGroupId) {
            var action = cmp.get("c.getFilterGroupById");
            action.setParams({id: activeFilterGroupId});

            action.setCallback(this, function (response) {
                var state = response.getState();
                if (state === "SUCCESS") {
                    //note: the parsing is important to avoid a shared reference
                    var data = JSON.parse(JSON.stringify(response.getReturnValue()));
                    cmp.set("v.activeFilterGroup", helper.restructureResponse(data.filterGroup));
                    cmp.set("v.cachedFilterGroup", helper.restructureResponse(data.filterGroup));

                    var labels = cmp.get("v.labels");

                    var actions = [{label: labels.edit, name: 'edit'}
                        , {label: labels.clone, name: 'clone'}
                        , {label: labels.delete, name: 'delete'}
                    ];

                    var filterRuleColumns = [{label: labels.object, fieldName: 'objectLabel', type: 'string'}
                        , {label: labels.field, fieldName: 'fieldLabel', type: 'string'}
                        , {label: labels.operator, fieldName: 'operator', type: 'string'}
                        , {label: labels.constant, fieldName: 'constant', type: 'string'}
                        , {type: 'action', typeAttributes: { rowActions: actions }}
                    ];
                    //todo: add actions back

                    cmp.set("v.filterRuleList", data.filterRuleList);
                    cmp.set("v.filterRuleColumns", filterRuleColumns);
                    helper.filterRollupList(cmp, data.filterGroup.MasterLabel, labels);
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

        }
    },

    /* @description: creates a new filter rule
    */
    createFilterRule: function(cmp, event, helper){
        //placeholder for creating a new filter rule
        helper.openFilterRuleModal(cmp);
    },

    /* @description: handles individual row events for the filter rule table
    */
    handleRowAction: function(cmp, event, helper){
        var action = event.getParam('action');
        var row = event.getParam('row');

        if(action.name !== 'delete'){
            //handle modal popup
            helper.openFilterRuleModal(cmp, row);
        } else {
            //caution user about deleting the filter rule?
            helper.openFilterRuleDeleteModal(cmp);
            var rowIndex = rows.indexOf(row);
            rows.splice(rowIndex, 1);
            cmp.set("v.filterRuleList", rows);
        }
    },

    /* @description: handles the cancel action during the edit of a filter group
    */
    onCancel: function(cmp, event, helper){
        if((cmp.get("v.mode") === 'clone' || cmp.get("v.mode") === 'create') && cmp.get("v.activeFilterGroupId") === null){
            //set off cancel event for container
            var cancelEvent = $A.get("e.c:CRLP_CancelEvent");
            cancelEvent.setParams({grid: 'filterGroup'});
            cancelEvent.fire();
        } else {
            cmp.set("v.mode", "view");
            var cachedFilterGroup = cmp.get("v.cachedFilterGroup");
            //json shenanigans to avoid shared reference
            cmp.set("v.activeFilterGroup", helper.restructureResponse(cachedFilterGroup.valueOf()));
        }

    },

    /* @description: fires when mode is changed and handles the readonly
    */
    onChangeMode: function(cmp, event, helper){
        helper.changeMode(cmp);
    },

    /* @description: saves a new filter group and associated filter rules
    */
    onSave: function(cmp, event, helper){
        //placeholder for on cancel function in !view mode
        //add check for description, name and a filter rule
        var activeFilterGroup = cmp.get("v.activeFilterGroup");
        var canSave = helper.validateFields(cmp, activeFilterGroup);
        if(canSave){
            cmp.set("v.mode", 'view');

            //sends the message to the parent cmp RollupsContainer
            var sendMessage = $A.get('e.ltng:sendMessage');
            sendMessage.setParams({
                'message': activeFilterGroup.MasterLabel,
                'channel': 'nameChange'
            });
            sendMessage.fire();
        }
    },

    /* @description: navigates the user to the selected rollup from the filter group detail page
    */
    selectRollup: function(cmp, event, helper){
        //select rollup for navigation
        var rollupId = event.getParam('name');
        var filterGroupId = cmp.get("v.activeFilterGroupId");
        if(rollupId !== 'title'){
            var navEvent = $A.get("e.c:CRLP_NavigateEvent");
            navEvent.setParams({id: rollupId, target: 'rollup', lastId: filterGroupId});
            navEvent.fire();
        }
    }
})