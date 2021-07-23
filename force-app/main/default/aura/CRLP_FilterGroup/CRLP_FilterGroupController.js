({
    /**
     * @description: setup for the filter group component which sets the active filter group and datatable
     */
    doInit: function (cmp, event, helper) {
        helper.toggleSpinner(cmp, true);
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
        action.setParams({filterGroupId: activeFilterGroupId, objectNames: objectNames});

        action.setCallback(this, function (response) {
            var state = response.getState();
            var labels = cmp.get("v.labels");

            if (state === "SUCCESS") {
                var data = helper.restructureResponse(response.getReturnValue());
                var model = JSON.parse(data);
                if (activeFilterGroupId){
                    //note: the parsing is important to avoid a shared reference
                    cmp.set("v.activeFilterGroup", helper.restructureResponse(model.filterGroup));
                    cmp.set("v.cachedFilterGroup", helper.restructureResponse(model.filterGroup));
                }
                cmp.set("v.operatorMap", model.operators);

                var actions = [{label: labels.edit, name: 'edit'}
                    , {label: labels.delete, name: 'delete'}
                ];

                var filterRuleColumns = [{label: labels.object, fieldName: 'objectLabel', type: 'string'}
                    , {label: labels.field, fieldName: 'fieldLabel', type: 'string'}
                    , {label: labels.operator, fieldName: 'operationLabel', type: 'string'}
                    , {label: labels.constant, fieldName: 'valueLabel', type: 'string'}
                ];

                var filterRuleActionColumns = [{label: labels.object, fieldName: 'objectLabel', type: 'string'}
                    , {label: labels.field, fieldName: 'fieldLabel', type: 'string'}
                    , {label: labels.operator, fieldName: 'operationLabel', type: 'string'}
                    , {label: labels.constant, fieldName: 'valueLabel', type: 'string'}
                    , {type: 'action', typeAttributes: {rowActions: actions}}
                ];

                var filterRuleList = helper.restructureResponse(model.filterRuleList);
                var filterRuleListCached = helper.restructureResponse(model.filterRuleList);

                cmp.set("v.filterRuleList", filterRuleList);
                cmp.set("v.cachedFilterRuleList", filterRuleList);

                cmp.set("v.filterRuleColumns", filterRuleColumns);
                cmp.set("v.filterRuleActionColumns", filterRuleActionColumns);
                cmp.set("v.objectDetails", model.filterFieldsByDataType);
                if (model.filterGroup) {
                    helper.filterRollupList(cmp, model.filterGroup.label, labels);
                } else {
                    cmp.set("v.rollupList", []);
                }
                helper.changeMode(cmp);

            }
            else if (state === "ERROR") {
                var errors = response.getError();
                var msg = labels.unknownError;
                if (errors && errors[0] && errors[0].message) {
                    msg = errors[0].message;
                }
                helper.showToast(cmp, 'error', labels.filtersDisplayError, msg);
            }
            helper.toggleSpinner(cmp, false);
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
     * @description: closes modal and resets filter rules as needed
     */
    cancelModal: function(cmp, event, helper){
        if (cmp.get("v.mode") === 'delete') {
            cmp.set("v.mode", 'view');
        } else {
            helper.resetActiveFilterRule(cmp);
        }
        helper.toggleFilterRuleModal(cmp);
        cmp.set("v.filterRuleMode", "");
    },

    /**
     * @description: handles individual row events for the filter rule table
     */
    handleRowAction: function(cmp, event, helper){
        var action = event.getParam('action');
        var row = event.getParam('row');
        var rows = cmp.get("v.filterRuleList");
        var labels = cmp.get("v.labels");
        row.index = rows.indexOf(row);

        //break the shared reference to avoid accidental data updates
        var cleanRow = helper.restructureResponse(row);
        cmp.set("v.activeFilterRule", cleanRow);

        if (action.name !== 'delete') {
            //handle modal popup
            cmp.set("v.filterRuleMode", 'edit');
            cmp.set("v.previousOperator", cleanRow.operationName);
            helper.toggleFilterRuleModal(cmp);
            helper.resetFilterRuleFields(cmp, cleanRow.objectName);
            helper.resetFilterRuleOperators(cmp, cleanRow.fieldName);
            helper.rerenderValue(cmp, cleanRow.operationName, cleanRow.value);

        } else {
            //cautions user about deleting filter rule
            cmp.set("v.filterRuleMode", 'delete');
            helper.toggleFilterRuleModal(cmp);
            if (cmp.get("v.rollupList").length === 0) {
                cmp.find('deleteModalMessage').set("v.value", labels.filterRuleDeleteConfirm);
            } else {
                cmp.find('deleteModalMessage').set("v.value", labels.filterRuleDeleteWarning);
            }
        }
    },

    /**
     * @description: handles the cancel action during the edit of a filter group
     */
    onCancel: function(cmp, event, helper){
        if((cmp.get("v.mode") === 'clone' || cmp.get("v.mode") === 'create') && cmp.get("v.activeFilterGroupId") === null){
            //set off cancel event for container
            helper.sendMessage(cmp, 'cancelEvent', {grid: 'filterGroup'});
        } else {
            cmp.set("v.mode", "view");
            var cachedFilterGroup = cmp.get("v.cachedFilterGroup");
            //json shenanigans to avoid shared reference
            cmp.set("v.activeFilterGroup", helper.restructureResponse(cachedFilterGroup));
            cmp.set("v.filterRuleList", cmp.get("v.cachedFilterRuleList"));
            //clear any filter rules previously marked for delete
            cmp.set("v.deletedRuleList", []);
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
        cmp.set("v.activeFilterRule.operationName", "");
        cmp.set("v.activeFilterRule.value", "");
        cmp.set("v.isValueRequired", true);
    },

    /**
     * @description: renders value based on selected operator
     */
    onChangeFilterRuleOperator: function(cmp, event, helper){
        var operator = event.getSource().get("v.value");
        var previousOperator = cmp.get("v.previousOperator");
        var isCompatibleOperation = helper.isCompatibleOperation(operator, previousOperator);
        if(isCompatibleOperation) {
            helper.rerenderValue(cmp, operator, cmp.get("v.activeFilterRule.value"));
        } else {
            cmp.set("v.activeFilterRule.value", "");
            helper.rerenderValue(cmp, operator, "");
        }
        cmp.set("v.previousOperator", operator);
    },

    /**
     * @description: saves a new filter group and associated filter rules
     */
    onSaveFilterGroupAndRules: function(cmp, event, helper){
        if (cmp.get("v.mode") === 'delete') {
            cmp.set("v.activeFilterGroup.isDeleted", true);
            helper.toggleFilterRuleModal(cmp);
        }
        var activeFilterGroup = cmp.get("v.activeFilterGroup");
        var filterRuleList = cmp.get("v.filterRuleList");
        var deletedRuleList = cmp.get("v.deletedRuleList");
        var canSave = helper.validateFilterGroupFields(cmp, activeFilterGroup);
        if (canSave) {
            helper.saveFilterGroupAndRules(cmp, activeFilterGroup, filterRuleList, deletedRuleList);

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
     * Only flags the row record for saving
     */
    onQueueFilterRuleSave: function(cmp, event, helper){
        var filterRule = cmp.get("v.activeFilterRule");
        var filterRuleList = cmp.get("v.filterRuleList");
        var mode = cmp.get("v.filterRuleMode");

        if (mode !== 'delete') {
            //explicit null setting to match saved values
            if (filterRule.value === '') {
                filterRule.value = null;
            }

            var canSave = helper.validateFilterRuleFields(cmp, filterRule, filterRuleList);

            if (canSave) {
                //set field labels directly
                filterRule.objectLabel = helper.retrieveFieldLabel(filterRule.objectName, cmp.get("v.detailObjects"));
                filterRule.fieldLabel = helper.retrieveFieldLabel(filterRule.fieldName, cmp.get("v.filteredFields"));
                filterRule.operationLabel = helper.retrieveFieldLabel(filterRule.operationName, cmp.get("v.filteredOperators"));

                //special reformatting for multipicklist and semi-colon delimited lists, as well as Record Type ID field
                if (filterRule.operationName === 'In_List' || filterRule.operationName === 'Not_In_List') {
                    filterRule.valueLabel = helper.reformatValueLabel(cmp, filterRule.value);
                } else if (filterRule.fieldName === 'RecordTypeId' &&
                           (filterRule.operationName === 'Equals' || filterRule.operationName === 'Not_Equals')) {
                    filterRule.valueLabel = helper.retrieveFieldLabel(filterRule.value, cmp.get("v.filterRuleConstantPicklist"));
                } else {
                    filterRule.valueLabel = filterRule.value;

                    let constantPicklist = cmp.get("v.filterRuleConstantPicklist");
                    if (constantPicklist && Array.isArray(constantPicklist)) {
                        filterRule.valueLabel = helper.retrieveFieldLabel(filterRule.value, constantPicklist);
                        if (!filterRule.valueLabel) {
                            filterRule.valueLabel = filterRule.value;
                        }
                    }
                }

                //if mode is create, just add to list, otherwise update the item in the existing list
                if (mode === 'create') {
                    filterRuleList.push(filterRule);
                } else {
                    filterRuleList[filterRule.index] = filterRule;
                }
                cmp.set("v.filterRuleList", filterRuleList);

                //only closes if there are no errors
                helper.toggleFilterRuleModal(cmp);
                helper.resetActiveFilterRule(cmp);
                cmp.set("v.filterRuleMode", "");
            }
        } else {
            if (filterRule.recordId) {
                var deletedRuleList = cmp.get("v.deletedRuleList");
                deletedRuleList.push(filterRule);   // queue this rule for deleting if was previously saved
                cmp.set("v.deletedRuleList", deletedRuleList);
            }
            filterRuleList.splice(filterRule.index, 1);
            cmp.set("v.filterRuleList", filterRuleList);
            helper.toggleFilterRuleModal(cmp);
            helper.resetActiveFilterRule(cmp);
            cmp.set("v.filterRuleMode", "");
        }
    },

    /**
     * @description: navigates the user to the selected rollup from the filter group detail page
     */
    selectRollup: function(cmp, event, helper){
        //select rollup for navigation
        var channel = 'navigateEvent';
        var rollupId = event.getParam('name');
        var filterGroupId = cmp.get("v.activeFilterGroupId");
        if (rollupId !== 'title') {
            var message = {id: rollupId, target: 'rollup', lastId: filterGroupId};
            var sendMessage = $A.get('e.ltng:sendMessage');
            sendMessage.setParams({
                'channel': channel,
                'message': message
            });
            sendMessage.fire();
        }
    }
})