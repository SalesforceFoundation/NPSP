({
    /**
     * @description: setup for the filter group component which sets the active filter group and datatable
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

                cmp.set("v.operatorMap", model.operators);

                var labels = cmp.get("v.labels");

                var actions = [{label: labels.edit, name: 'edit'}
                    , {label: labels.delete, name: 'delete'}
                ];

                var filterRuleColumns = [{label: labels.object, fieldName: 'objectLabel', type: 'string'}
                    , {label: labels.field, fieldName: 'fieldLabel', type: 'string'}
                    , {label: labels.operator, fieldName: 'operationLabel', type: 'string'}
                    , {label: labels.constant, fieldName: 'constantLabel', type: 'string'}
                ];

                var filterRuleActionColumns = [{label: labels.object, fieldName: 'objectLabel', type: 'string'}
                    , {label: labels.field, fieldName: 'fieldLabel', type: 'string'}
                    , {label: labels.operator, fieldName: 'operationLabel', type: 'string'}
                    , {label: labels.constant, fieldName: 'constantLabel', type: 'string'}
                    , {type: 'action', typeAttributes: {rowActions: actions}}
                ];

                cmp.set("v.filterRuleList", helper.restructureResponse(model.filterRuleList));
                cmp.set("v.cachedFilterRuleList", helper.restructureResponse(model.filterRuleList));
                cmp.set("v.filterRuleColumns", filterRuleColumns);
                cmp.set("v.filterRuleActionColumns", filterRuleActionColumns);
                cmp.set("v.objectDetails", model.filterFieldsByDataType);
                helper.filterRollupList(cmp, model.filterGroup.label, labels);
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

    /**
     * @description: creates a new filter rule
     */
    addFilterRule: function(cmp, event, helper){
        cmp.set("v.filterRuleMode", 'create');
        helper.toggleFilterRuleModal(cmp);
    },

    /**
     * @description: cancels the pop up for filter rule and clears the active filter rule
     */
    cancelFilterRule: function(cmp, event, helper){
        helper.toggleFilterRuleModal(cmp);
        helper.resetActiveFilterRule(cmp);
        cmp.set("v.filterRuleMode", "");
        cmp.set("v.filterRuleError", "")
    },

    /**
     * @description: closes the toast notification window
     */
    closeNotificationWindow : function(cmp, event, helper) {
        cmp.set("v.notificationClasses", "slds-hide");
    },

    /**
     * @description: handles individual row events for the filter rule table
     */
    handleRowAction: function(cmp, event, helper){
        var action = event.getParam('action');
        var row = event.getParam('row');
        var rows = cmp.get("v.filterRuleList");
        row.index = rows.indexOf(row);

        //break the shared reference to avoid accidental data updates
        var cleanRow = helper.restructureResponse(row);
        cmp.set("v.activeFilterRule", cleanRow);

        if(action.name !== 'delete'){
            //handle modal popup
            cmp.set("v.filterRuleMode", 'edit');
            helper.toggleFilterRuleModal(cmp);
            helper.resetFilterRuleFields(cmp, cleanRow.objectName);
            helper.resetFilterRuleOperators(cmp, cleanRow.fieldName);
            helper.rerenderValue(cmp, cleanRow.operation);

        } else {
            //cautions user about deleting filter rule
            cmp.set("v.filterRuleMode", 'delete');
            helper.toggleFilterRuleModal(cmp);
        }
    },

    /**
     * @description: handles the cancel action during the edit of a filter group
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
            cmp.set("v.activeFilterGroup", helper.restructureResponse(cachedFilterGroup));
            cmp.set("v.filterRuleList", cmp.get("v.cachedFilterRuleList"));
        }

    },

    /**
     * @description: fires when mode is changed and handles the readonly
     */
    onChangeMode: function(cmp, event, helper){
        helper.changeMode(cmp);
    },

    /**
     * @description: filters the filter fields when filter rule objects is changed
     */
    onChangeFilterRuleObject: function(cmp, event, helper){
        var object = event.getSource().get("v.value");
        helper.resetFilterRuleFields(cmp, object);
    },

    /**
     * @description: checks for type on filter rule field to update eligible values
     */
    onChangeFilterRuleField: function(cmp, event, helper){
        var field = event.getSource().get("v.value");
        helper.resetFilterRuleOperators(cmp, field);
        cmp.set("v.activeFilterRule.operation", "");
    },

    /**
     * @description: renders constant value based on selected operator
     */
    onChangeFilterRuleOperator: function(cmp, event, helper){
        var operator = event.getSource().get("v.value");
        helper.rerenderValue(cmp, operator);
    },

    /**
     * @description: adds constant field to selected list
     */
    /*onChangeFilterRuleConstantPicklist: function(cmp, event, helper){
        var constant = event.getSource().get("v.value");
        var fieldCmp = cmp.find("filterRuleUIField");
        var value = fieldCmp.get("v.value");
        var constantPicklist = cmp.get("v.filterRuleConstantPicklist");
        console.log(JSON.stringify(constantPicklist));
    },*/

    /**
     * @description: saves a new filter group and associated filter rules
     */
    onSave: function(cmp, event, helper){
        //placeholder for on cancel function in !view mode
        //add check for description, name and a filter rule
        var activeFilterGroup = cmp.get("v.activeFilterGroup");
        var canSave = helper.validateFilterGroupFields(cmp, activeFilterGroup);
        if(canSave){
            cmp.set("v.mode", 'view');

            //todo: add save code here

            //sends the message to the parent cmp RollupsContainer
            var sendMessage = $A.get('e.ltng:sendMessage');
            sendMessage.setParams({
                'message': activeFilterGroup.label,
                'channel': 'nameChange'
            });
            sendMessage.fire();
        }
    },

    /**
     * @description: adds, edits or deletes filter on the list of filter rules on the filter group
     */
    saveFilterRule: function(cmp, event, helper){
        //set field labels first
        var filterRule = cmp.get("v.activeFilterRule");
        var filterRuleList = cmp.get("v.filterRuleList");
        var mode = cmp.get("v.filterRuleMode");

        if (mode !== 'delete') {
            var canSave = helper.validateFilterRuleFields(cmp, filterRule, filterRuleList);

            if (canSave) {
                //set field labels directly
                filterRule.objectLabel = helper.retrieveFieldLabel(filterRule.objectName, cmp.get("v.detailObjects"));
                filterRule.fieldLabel = helper.retrieveFieldLabel(filterRule.fieldName, cmp.get("v.filteredFields"));
                filterRule.operationLabel = helper.retrieveFieldLabel(filterRule.operation, cmp.get("v.filteredOperators"));

                //special reformatting for multipicklist and semi-colon delimited lists
                if (filterRule.operation === 'In_List' || filterRule.operation === 'Not_In_List') {
                    filterRule.constantLabel = helper.reformatConstantLabel(cmp, filterRule.constantName, filterRule.operation);
                } else {
                    filterRule.valueLabel = filterRule.valueName;
                }

                //if mode is create, just add to list, otherwise update the item in the existing list
                if (mode === 'create') {
                    filterRuleList.push(filterRule);
                } else {
                    filterRuleList[filterRule.index] = filterRule;
                }
                cmp.set("v.filterRuleList", filterRuleList);

                helper.toggleFilterRuleModal(cmp);
                helper.resetActiveFilterRule(cmp);
            }
        } else {
            filterRuleList.splice(filterRule.index, 1);
            cmp.set("v.filterRuleList", filterRuleList);
            helper.toggleFilterRuleModal(cmp);
            helper.resetActiveFilterRule(cmp);
        }
    },

    /**
     * @description: navigates the user to the selected rollup from the filter group detail page
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