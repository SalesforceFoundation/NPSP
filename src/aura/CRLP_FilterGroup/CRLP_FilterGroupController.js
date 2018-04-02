({
    /* @description: setup for the filter group component which sets the active filter group and datatable
    */
    doInit: function (cmp, event, helper) {
        //query for the active filter group
        var activeFilterGroupId = cmp.get("v.activeFilterGroupId");
        var objectList = cmp.get("v.detailObjects");
        var objectNames = objectList.map(function (obj, index, array) {
            return obj.name;
        });

        if (activeFilterGroupId === null) {
            activeFilterGroupId = '';
        }

        var action = cmp.get("c.setupFilterGroupDetail");
        action.setParams({id: activeFilterGroupId, objectNames: objectNames});

        action.setCallback(this, function (response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var model = helper.restructureResponse(response.getReturnValue());
                if(activeFilterGroupId){
                    //note: the parsing is important to avoid a shared reference
                    cmp.set("v.activeFilterGroup", helper.restructureResponse(model.filterGroup));
                    cmp.set("v.cachedFilterGroup", helper.restructureResponse(model.filterGroup));
                }

                var operators = [];
                for(var i in model.operators){
                    operators.push({name: i, label: model.operators[i]});
                }
                cmp.set("v.operators", operators);

                var labels = cmp.get("v.labels");

                var actions = [{label: labels.edit, name:'edit'}
                    , {label: labels.clone, name:'clone'}
                    , {label: labels.delete, name:'delete'}
                ];

                var filterRuleColumns = [{label: labels.object, fieldName: 'objectLabel', type: 'string'}
                    , {label: labels.field, fieldName: 'fieldLabel', type: 'string'}
                    , {label: labels.operator, fieldName: 'operator', type: 'string'}
                    , {label: labels.constant, fieldName: 'constant', type: 'string'}
                    , {type: 'action', typeAttributes: {rowActions: actions}}
                ];

                cmp.set("v.filterRuleList", model.filterRuleList);
                console.log(model.filterRuleList);
                cmp.set("v.filterRuleColumns", filterRuleColumns);
                cmp.set("v.objectDetails", model.filterFieldsByDataType);
                helper.filterRollupList(cmp, model.filterGroup.MasterLabel, labels);
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

    },

    /* @description: creates a new filter rule
    */
    addFilterRule: function(cmp, event, helper){
        helper.openFilterRuleModal(cmp);
    },

    /* @description: cancels the pop up for filter rule
    */
    cancelFilterRule: function(cmp, event, helper){
        var backdrop = cmp.find('backdrop');
        $A.util.removeClass(backdrop, 'slds-backdrop_open');
        var modal = cmp.find('modaldialog');
        $A.util.removeClass(modal, 'slds-fade-in-open');
    },

    /* @description: handles individual row events for the filter rule table
    */
    handleRowAction: function(cmp, event, helper){
        var action = event.getParam('action');
        var row = event.getParam('row');

        if(action.name !== 'delete'){
            //handle modal popup
            helper.openFilterRuleModal(cmp);
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

    /* @description: filters the filter fields when filter rule objects is changed
    */
    onChangeFilterRuleObject: function(cmp, event, helper){
        console.log('on change filter rule');
        var object = event.getSource().get("v.value");
        var objectDetails = cmp.get("v.objectDetails");
        console.log(object);
        console.log(objectDetails);
        console.log(objectDetails[object]);
        cmp.set("v.filteredFields", objectDetails[object]);
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

    /* @description: saves filter rule into the list of filter rules on the filter group
    */
    saveFilterRule: function(cmp, event, helper){
        //todo: add exception handling
        //todo: save to DB first
        var filterRule = cmp.get("v.activeFilterRule");
        console.log(filterRule);
        var filterRuleList = cmp.get("v.filterRuleList");
        filterRuleList.push(filterRule);
        cmp.set("v.filterRuleList", filterRuleList);
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