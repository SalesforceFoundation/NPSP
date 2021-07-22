({
    /**
     * @description: changes field visibility and save button access based on the mode
     * this is bound to a change handler to the mode attribute
     */
    changeMode: function(cmp) {
        var mode = cmp.get("v.mode");
        var labels = cmp.get("v.labels");
        //we check to see if mode is null since the change handler is called when mode is cleared in the container
        if (mode) {
            //View is the only readOnly mode. Clone removes the activeRollupId for save.
            //Create hides all fields
            if (mode === "view") {
                cmp.set("v.isReadOnly", true);
            } else if (mode === "clone") {
                cmp.set("v.activeFilterGroupId", null);
                cmp.set("v.activeFilterGroup.recordId", null);
                cmp.set("v.activeFilterGroup.recordName", null);
                cmp.set("v.rollupItems", []);
                cmp.set("v.rollupList", []);
                cmp.set("v.activeFilterGroup.label", cmp.get("v.activeFilterGroup.label") + " (Clone)");

                var filterRuleList = cmp.get("v.filterRuleList");
                for (var i = 0; i < filterRuleList.length; i++) {
                    filterRuleList[i].recordId = null;
                    filterRuleList[i].recordName = null;
                }
                cmp.set("v.filterRuleList", filterRuleList);

                cmp.set("v.isReadOnly", false);
            } else if (mode === "edit") {
                cmp.set("v.isReadOnly", false);
            } else if (mode === "create") {
                cmp.set("v.isReadOnly", false);
            } else if (mode === "delete") {
                //verify no rollups use the filter group before deleting
                var countRollups = cmp.get("v.rollupList").length;

                this.toggleFilterRuleModal(cmp);
                if (countRollups === 0) {
                    cmp.find('deleteModalMessage').set("v.value", labels.filterGroupDeleteConfirm);
                } else {
                    cmp.find('deleteModalMessage').set("v.value", labels.filterGroupDeleteWarning);
                }
            }
        }
    },

    /**
     * @description: filters the full rollup data to find which rollups use the selected filter group and display them in a tree
     * @param filterGroupLabel: label of the selected filter group
     * @param labels: labels for the rollups UI
     */
    filterRollupList: function(cmp, filterGroupLabel, labels) {
        //filters rollups that use this filter group
        var rollupList = cmp.get("v.rollupList");
        var filteredRollupList = rollupList.filter(function(rollup) {
            return rollup.filterGroupName === filterGroupLabel;
        });
        cmp.set("v.rollupList", filteredRollupList);

        //create data structure for tree
        var summaryObjects = cmp.get("v.summaryObjects");
        var rollupsBySummaryObj = [];
        for (var i=0; i<summaryObjects.length; i++) {
            var listItem = {label: summaryObjects[i].label, list: []};
            rollupsBySummaryObj.push(listItem);
        }

        //place rollups in the array of the matching summary object
        filteredRollupList.forEach(function (rollup) {
            var item = {label: rollup.displayName, name: rollup.recordId}
            for (i=0; i<rollupsBySummaryObj.length; i++){
                if (rollup.summaryObject === rollupsBySummaryObj[i].label) {
                    rollupsBySummaryObj[i].list.push(item);
                }
            }
        });

        var itemList = [];
        //only display summary object list item if there are rollups that use that summary object
        rollupsBySummaryObj.forEach(function(objList){
           if (objList.list.length > 0) {
               var obj = {label: objList.label
                         , name: "title"
                         , expanded: false
                         , items: objList.list
               };
               itemList.push(obj);

           }
        });

        cmp.set("v.rollupItems", itemList);
    },

    /**
     * @description: opens a modal popup so user can add or edit a filter rule
     */
    getAvailableOperations: function(cmp, type){
        var opMap = cmp.get("v.operatorMap");
        var operators = [{value: 'Equals', label: opMap.Equals}, {value: 'Not_Equals', label: opMap.Not_Equals}];

        if (type === 'boolean') {
            //equals/not equals are only matches
        } else if (type === 'reference') {
            operators.push({value: 'In_List', label: opMap.In_List});
            operators.push({value: 'Not_In_List', label: opMap.Not_In_List});
        } else if (type === 'date' || type === 'datetime' || type === 'time'
            || type === 'double' || type === 'integer' || type === 'currency' || type === 'percent') {
            operators.push({value: 'Greater', label: opMap.Greater});
            operators.push({value: 'Greater_or_Equal', label: opMap.Greater_or_Equal});
            operators.push({value: 'Less', label: opMap.Less});
            operators.push({value: 'Less_or_Equal', label: opMap.Less_or_Equal});
        } else {
            operators.push({value: 'Starts_With', label: opMap.Starts_With});
            operators.push({value: 'Contains', label: opMap.Contains});
            operators.push({value: 'Does_Not_Contain', label: opMap.Does_Not_Contain});

            if (type === 'multipicklist') {
                operators.push({value: 'Is_Included', label: opMap.Is_Included});
                operators.push({value: 'Is_Not_Included', label: opMap.Is_Not_Included});
            } else if (type !== 'textarea') {
                operators.push({value: 'In_List', label: opMap.In_List});
                operators.push({value: 'Not_In_List', label: opMap.Not_In_List});
            }
        }

        cmp.set("v.filteredOperators", operators);

    },

    /**
     * @description handles errors from both
     * save function (queueing up deployment)
     * and pollForDeploymentStatus (actual deployment)
     * @param errors - list of errors from response
     */
    handleErrors: function(cmp, errors) {
        var msg = "Unknown error";
        if (errors && errors[0] && errors[0].message) {
            msg = errors[0].message;
        }
        if (cmp.get("v.mode") === 'delete') {
            this.showToast(cmp, 'error', cmp.get("v.labels.filtersDeleteFail"), msg);
        } else {
            this.showToast(cmp, 'error', cmp.get("v.labels.filtersSaveFail"), msg);
            cmp.set("v.mode", 'edit');
            this.changeMode(cmp);
        }
    },

    /**
     * @description: determines whether filter rule operators are compatible
     * @param operator
     * @param previous operator
     * @return boolean
     */
    isCompatibleOperation: function(operator, previousOperator) {

        var arrayOps = ['In_List','Not_In_List','Is_Included','Is_Not_Included'];

        if ((arrayOps.includes(previousOperator) && arrayOps.includes(operator))
        || (!arrayOps.includes(previousOperator) && !arrayOps.includes(operator))) {
            return true;
        } else {
            return false;
        }
    },

     /**
     * @description: opens a modal popup so user can add or edit a filter rule
     * @param field - field name
     */
    retrieveFieldType: function(cmp, field) {
        var filteredFields = cmp.get("v.filteredFields");
        var type;

        for (var i = 0; i < filteredFields.length; i++) {
            if (filteredFields[i].name === field) {
                type = filteredFields[i].type.toLowerCase();
                break;
            }
        }
        return type;
    },

    /**
     * @description: queries for picklist options to populate filterRuleConstantPicklist
     * @param field - field name
     */
    getPicklistOptions: function(cmp, field) {
        var action = cmp.get("c.getFilterRuleConstantPicklistOptions");
        action.setParams({objectName: cmp.get("v.activeFilterRule.objectName"), selectedField: field});
        action.setCallback(this, function (response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                cmp.set("v.filterRuleConstantPicklist", response.getReturnValue());
            }
            else if (state === "ERROR") {
                var errors = response.getError();
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        this.showToast(cmp, "error", cmp.get("v.labels.error"), errors[0].message);
                    }
                } else {
                    this.showToast(cmp, "error", cmp.get("v.labels.error"), "Unknown Error");
                }
            }
        });

        $A.enqueueAction(action);
    },

    /**
     * @description Inserting or updating a CMT record is an asynchronous deployment process. This method uses the
     * unique jobId and the Filter_Group__mdt.DeveloperName value to recursively call an apex controller method to determine
     * when the deployment has completed (by looking in a custom settings object). If it completes, the final recordId
     * is returned. Otherwise an error message to render is returned. If the return is null, then it calls this method
     * again to wait another second an try again.
     * @param jobId The returns CMT deployment job id to query status for
     * @param recordName Unique record name value (that was just inserted/updated) to query for.
     */
    pollForDeploymentStatus : function(cmp, jobId, recordName, counter) {
        var helper=this;
        var pollingInterval = 2000; // 2 seconds.
        var maxPollingCount = 45; // 1min 30, because the polling interval is 2 seconds (45 * 2 seconds).
        var poller = window.setTimeout(
            $A.getCallback(function() {
                counter++;
                var action = cmp.get("c.getDeploymentStatus");
                var mode = cmp.get("v.mode");
                action.setParams({jobId: jobId, recordName: recordName, objectType: 'Filter', mode: mode});
                action.setCallback(this, function (response) {
                    var state = response.getState();
                    var mode = cmp.get("v.mode");
                    if (state === "SUCCESS") {
                        // Response will be a serialized deployResult wrapper class
                        var deployResult = JSON.parse(response.getReturnValue());
                        // if there is a record id response
                        if (deployResult && deployResult.completed === true && (deployResult.filterGroupItem || mode === 'delete')) {
                            window.clearTimeout(poller);
                            helper.toggleSpinner(cmp, false);

                            if (mode === 'delete') {

                                helper.showToast(cmp, 'success', cmp.get("v.labels.filtersDeleteProgress"), cmp.get("v.labels.filtersDeleteSuccess"));
                                helper.sendMessage(cmp, 'filterGroupDeleted', recordName);

                            } else {

                                helper.showToast(cmp, 'success', cmp.get("v.labels.filtersSaveProgress"), cmp.get("v.labels.filtersSaveSuccess"));

                                var model = helper.restructureResponse(deployResult.filterGroupItem);

                                // Save the inserted/updated record id
                                cmp.set("v.activeFilterGroup", model.filterGroup);
                                cmp.set("v.activeFilterGroupId", model.filterGroup.recordId);

                                // for a new record, copy the activeFilterGroup map to the cachedFilterGroup map
                                if (cmp.get("v.cachedFilterGroup") === null) {
                                    cmp.set("v.cachedFilterGroup", helper.restructureResponse(cmp.get("v.activeFilterGroup")));
                                } else if (cmp.get("v.cachedFilterGroup") && cmp.get("v.cachedFilterGroup.recordName")) {
                                    var activeFilterGroup = cmp.get("v.activeFilterGroup");
                                    var cachedFilterGroup = cmp.get("v.cachedFilterGroup");
                                    for (var key in activeFilterGroup) {
                                        if (cachedFilterGroup.hasOwnProperty(key)) {
                                            cachedFilterGroup[key] = activeFilterGroup[key];
                                        }
                                    }
                                    cmp.set("v.cachedFilterGroup", cachedFilterGroup);
                                }

                                var filterRuleList = helper.restructureResponse(model.filterRuleList);
                                var filterRuleListCached = helper.restructureResponse(model.filterRuleList);

                                cmp.set("v.filterRuleList", filterRuleList);
                                cmp.set("v.cachedFilterRuleList", filterRuleListCached);
                                cmp.set("v.deletedRuleList", []);

                                var rollupList = cmp.get("v.rollupList");

                                // need to send back an object with the following properties
                                var filterGroupTableItem = {};
                                filterGroupTableItem.label = model.filterGroup.label;
                                filterGroupTableItem.description = model.filterGroup.description;
                                filterGroupTableItem.name = model.filterGroup.recordName;
                                filterGroupTableItem.recordId = model.filterGroup.recordId;
                                if (filterRuleList) {
                                    filterGroupTableItem.countFilterRules = filterRuleList.length;
                                } else {
                                    filterGroupTableItem.countFilterRules = 0;
                                }
                                if (rollupList) {
                                    filterGroupTableItem.countRollups = rollupList.length;
                                } else {
                                    filterGroupTableItem.countRollups = 0;
                                }

                                // Send a message with the changed or new Rollup to the RollupContainer Component
                                helper.sendMessage(cmp, 'filterRecordChange', filterGroupTableItem);

                                cmp.set("v.mode",'view');
                            }

                        } else {
                            // No record id, so run call this method again to check in another 1 second
                            if (counter < maxPollingCount) {
                                helper.pollForDeploymentStatus(cmp, jobId, recordName, counter);
                            } else {
                                // When the counter hits the max, need to tell the user what happened
                                if (mode === 'delete') {
                                    helper.showToast(cmp, 'info', cmp.get("v.labels.filtersDeleteProgress"), cmp.get("v.labels.filtersDeleteTimeout"));
                                } else {
                                    helper.showToast(cmp, 'info', cmp.get("v.labels.filtersSaveProgress"), cmp.get("v.labels.filtersSaveTimeout"));
                                }
                                helper.toggleSpinner(cmp, false);

                            }
                        }
                    } else if (state === "ERROR") {
                        // If an error is returned, parse the message, display and remove the spinner
                        var errors = response.getError();
                        helper.toggleSpinner(cmp, false);
                        helper.handleErrors(cmp, errors);
                        window.clearTimeout(poller);
                    }
                });
                $A.enqueueAction(action);
            }), pollingInterval
        );
    },

    /**
     * @description: parses the constant label into constant name form depending on the format of the value
     * @param valueApiName - API name of the constant
     * @return constantLabel - formatted name for display in the lightning:datatable
     */
    reformatValueLabel: function(cmp, valueApiName){
        var updatedLabel;

        var filterRuleFieldType = cmp.get("v.filterRuleFieldType");

        var fieldName = cmp.get("v.activeFilterRule.fieldName");
        if (fieldName === 'RecordTypeId') {
            var labelList = [];
            var value = cmp.get("v.activeFilterRule.value");
            var filterRuleConstantPicklist = cmp.get("v.filterRuleConstantPicklist");
            for (var i=0; i<valueApiName.length; i++) {
                labelList.push(this.retrieveFieldLabel(valueApiName[i], filterRuleConstantPicklist));
            }
            updatedLabel = labelList.join(";\n");
            cmp.set("v.activeFilterRule.value", valueApiName.join(";"));
        } else if (filterRuleFieldType === "multipicklist" && valueApiName) {
            // reformat for separate lines
            updatedLabel = valueApiName.join(";\n");
            var newValueApiName = valueApiName.join(";");
            cmp.set("v.activeFilterRule.value", newValueApiName);
        } else if (filterRuleFieldType === "text-picklist" && valueApiName && valueApiName.indexOf(";") > 0) {
            var valueList = valueApiName.split(';');
            var cleanList = valueList.map(function(value){
               return value.replace('\n', '').trim();
            });
            updatedLabel = cleanList.join(";\n");
            var newValueApiName = updatedLabel.replace(/\n/g, "");
            cmp.set("v.activeFilterRule.value", newValueApiName);
        } else if (filterRuleFieldType === "text" && valueApiName) {
            cmp.set("v.activeFilterRule.value", newValueApiName);
        }

        return updatedLabel;
    },

    /**
     * @description - changes picklist values or input type based on field type. Reformats values based on type.
     * @param operator - selected filter rule operator API name
     * @param value - active filter rule value
     */
    rerenderValue: function(cmp, operator, value) {
        var type = this.retrieveFieldType(cmp, cmp.get("v.activeFilterRule.fieldName"));
        var filterRuleFieldType;

        if (type === 'boolean') {
            //boolean fields don't have official translations (confirmed in process builder)
            filterRuleFieldType = 'picklist';
            var options = [
                {value: 'true', label: cmp.get("v.labels.labelBooleanTrue")},
                {value: 'false', label: cmp.get("v.labels.labelBooleanFalse")}
            ];
            cmp.set("v.filterRuleConstantPicklist", options);
        } else if (type === 'date') {
            filterRuleFieldType = 'date';
        } else if (type === 'datetime') {
            filterRuleFieldType = 'datetime-local';
        } else if (type === 'picklist' || type === 'multipicklist') {
            if (operator === 'Equals' || operator === 'Not_Equals') {
                cmp.set("v.activeFilterRule.value", value);
                filterRuleFieldType = 'picklist';
            } else if (operator === 'Starts_With' || operator === 'Contains' ||  operator === 'Does_Not_Contain') {
                filterRuleFieldType = 'text';
            } else if (operator === 'In_List' || operator === 'Not_In_List'
                || operator === 'Is_Included' || operator === 'Is_Not_Included') {
                //clear array or reformat values into an array
                var values;
                if (Array.isArray(value)) {
                    values = value;
                } else {
                    values = (value === "") ? [] : value.split(";");
                }
                cmp.set("v.activeFilterRule.value", values);
                filterRuleFieldType = 'multipicklist';
            }
        } else if (type === 'reference') {
            var field = cmp.get("v.activeFilterRule.fieldName");
            //record type is a special case where we want to exactly match options and provide picklists
            if (field !== 'RecordTypeId') {
                //check if text field is offered but a user can enter a list of semi-colon separated values
                if (operator === 'In_List' || operator === 'Not_In_List'
                    || operator === 'Is_Included' || operator === 'Is_Not_Included') {
                    filterRuleFieldType = 'text-picklist';
                } else {
                    filterRuleFieldType = 'text';
                }
            } else {
                if (operator === 'Equals' || operator === 'Not_Equals') {
                    cmp.set("v.activeFilterRule.value", value);
                    filterRuleFieldType = 'picklist';
                } else if (operator === 'In_List' || operator === 'Not_In_List') {
                    //clear array or reformat values into an array
                    var values;
                    if (Array.isArray(value)) {
                        values = value;
                    } else {
                        values = (value === "") ? [] : value.split(";");
                    }
                    cmp.set("v.activeFilterRule.value", values);
                    filterRuleFieldType = 'multipicklist';
                }
            }
        } else if (type === 'double' || type === 'integer'
            || type === 'currency' || type === 'percent') {
            filterRuleFieldType = 'number';
        } else {
            //same check for semi-colon separated values
            if (operator === 'In_List' || operator === 'Not_In_List'
                || operator === 'Is_Included' || operator === 'Is_Not_Included') {
                filterRuleFieldType = 'text-picklist';
            } else {
                filterRuleFieldType = 'text';
            }
        }

        //rerender filterRuleFieldType to clear any existing errors
        cmp.set("v.filterRuleFieldType", '');
        cmp.set("v.filterRuleFieldType", filterRuleFieldType);

        // Allow for null values ONLY on Equals and Not Equals operators; also clear potential required value errors
        if (operator === 'Equals' || operator === 'Not_Equals') {
            cmp.set("v.isValueRequired", false);
            cmp.find("filterRuleErrorText").set("v.value", '');
        } else {
            cmp.set("v.isValueRequired", true);
        }
    },

    /**
     * @description: resets active filter rule values
     */
    resetActiveFilterRule: function(cmp) {
        var defaultFilterRule = {objectName: '', fieldName: '', operationName: '', value: ''};
        cmp.set("v.activeFilterRule", defaultFilterRule);
        cmp.set("v.filteredFields", "");
        cmp.set("v.filterRuleFieldType", "text");
    },

    /**
     * @description: resets the list of filter rule fields based on the selected object
     * @param object - selected object API name
     */
    resetFilterRuleFields: function(cmp, object) {
        var objectDetails = cmp.get("v.objectDetails");
        var sortedFields = this.sortFields(objectDetails[object]);
        cmp.set("v.filteredFields", sortedFields);
    },

    /**
     * @description: resets the possible list of operations based on the selected filter rule
     * @param field - selected field API name
     * @param type - type of the selected field
     */
    resetFilterRuleOperators: function(cmp, field) {
        var type = this.retrieveFieldType(cmp, field);
        if (type === 'picklist' || type === 'multipicklist' || field === 'RecordTypeId') {
            this.getPicklistOptions(cmp, field);
        }
        cmp.set("v.filterRuleFieldType", "text");
        this.getAvailableOperations(cmp, type);
    },

    /**
     * @description: restructures returned Apex response to preserve separate variables
     * @return: the parsed and stringified JSON
     */
    restructureResponse: function (resp) {
        return JSON.parse(JSON.stringify(resp));
    },

    /**
     * @description: retrieves the label of an entity (field, operation, etc) based on the api name from a LIST of objects with name and label entries
     * @param apiName: the name of the field
     * @param entityList: list of fields to search
     * @return label: field label that matches the apiName
     */
    retrieveFieldLabel: function (apiName, entityList) {
        var label;
        if (entityList) {
            for (var i = 0; i < entityList.length; i++) {
                if (entityList[i].name === apiName || entityList[i].value === apiName) {
                    label = entityList[i].label;
                    break;
                }
            }
        }
        return label;
    },

    /**
     * @description Save the filter group and any modified filter rules
     * @param activeFilterGroup
     * @param filterRuleList
     * @param deletedRuleList
     */
    saveFilterGroupAndRules : function(cmp, activeFilterGroup, filterRuleList, deletedRuleList) {
        this.toggleSpinner(cmp, true);

        var filterGroupCMT = activeFilterGroup;
        filterGroupCMT.rules = filterRuleList;
        if (deletedRuleList) {
            for (var i = 0; i < deletedRuleList.length; i++) {
                deletedRuleList[i].isDeleted = true;
                filterGroupCMT.rules.push(deletedRuleList[i]);
            }
        }

        var action = cmp.get("c.saveFilterGroupAndRules");
        action.setParams({jsonFilterGroup: JSON.stringify(filterGroupCMT)});
        action.setCallback(this, function (response) {
            var state = response.getState();

            if (state === "SUCCESS") {
                // Response value will be in the format of "JobId-RecordDeveloperName"
                var responseText = response.getReturnValue();
                var jobId = responseText.split("-")[0];
                var recordName = responseText.split("-")[1];
                this.pollForDeploymentStatus(cmp, jobId, recordName, 0);

            } else if (state === "ERROR") {
                var errors = response.getError();
                this.toggleSpinner(cmp, false);
                this.handleErrors(cmp, errors);
            }
        });
        if (cmp.get("v.mode") === 'delete') {
            this.showToast(cmp, 'info', cmp.get("v.labels.filtersDeleteProgress"), cmp.get("v.labels.pleaseWait"));
        } else {
            this.showToast(cmp, 'info', cmp.get("v.labels.filtersSaveProgress"), cmp.get("v.labels.pleaseWait"));
        }
        $A.enqueueAction(action);
    },

    /**
     * @description Sends a lightning message to all listening components
     * @param channel - intended channel to hear the message
     * @param message - body of the message
     */
    sendMessage: function(cmp, channel, message){
        var sendMessage = $A.get('e.ltng:sendMessage');
        sendMessage.setParams({
            'channel': channel,
            'message': message
        });
        sendMessage.fire();
    },

    /**
     * @description Sort provided fields by the field labels
     * @param fields - list of fields to sort
     */
    sortFields: function(fields){
        fields.sort(function (a, b) {
            if (a.label < b.label) {
                return -1;
            }
            if (a.label > b.label) {
                return 1;
            }
            return 0;
        });
        return fields;
    },

    /**
     * @description Show a message on the screen in the parent cmp
     * @param type - error, success, info
     * @param title - message title
     * @param message - message to display
     */
    showToast: function(cmp, type, title, message) {
        var channel = 'showToast';
        var message = {type: type, title: title, message: message};
        this.sendMessage(cmp, channel, message);
    },

    /**
     * @description: toggles a modal popup and backdrop
     */
    toggleFilterRuleModal: function(cmp) {
        var backdrop = cmp.find('backdrop');
        $A.util.toggleClass(backdrop, 'slds-backdrop_open');
        var modal = cmp.find('modaldialog');
        $A.util.toggleClass(modal, 'slds-fade-in-open');
    },

    /**
     * @description Show or Hide the page spinner in the parent cmp
     */
    toggleSpinner: function(cmp, showSpinner) {
        this.sendMessage(cmp, 'toggleSpinner', {showSpinner: showSpinner});
    },

    /**
     * @description: verifies all required fields have been populated before saving the filter group
     * @return: boolean canSave confirming if filter group can be saved
     */
    validateFilterGroupFields: function(cmp) {
        var canSave = true;
        var name = cmp.get("v.activeFilterGroup.label");
        var description = cmp.get("v.activeFilterGroup.description");
        var filterRuleList = cmp.get("v.filterRuleList");

        cmp.find("nameInput").focus();
        cmp.find("descriptionInput").focus();

        if (!description || !name || name.length > 40) {
            canSave = false;
        }

        if (!filterRuleList || filterRuleList.length === 0) {
            canSave = false;
            cmp.find("noFilterRulesMessage").set("v.severity", "error");
        }

        return canSave;
    },

    /**
     * @description: verifies filter rule that all fields are provided and isn't a duplicate
     * @return: boolean canSave confirming if filter group can be saved
     */
    validateFilterRuleFields: function(cmp, filterRule, filterRuleList) {

        //check for field validity
        var canSave = cmp.find("filterRuleField").reduce(function (validSoFar, filterRuleCmp) {
            filterRuleCmp.showHelpMessageIfInvalid();
            return validSoFar && filterRuleCmp.get("v.validity").valid;
        }, true);

        //custom error handling for multipicklist bug
        if (cmp.get("v.filterRuleFieldType") === 'multipicklist' && filterRule.value.length < 1){
            canSave = false;
            cmp.find("filterRuleFieldPicklist").showHelpMessageIfInvalid();
        }

        //check for duplicates
        if (!filterRuleList) {
            // nothing to compare
        } else {
            //check for specific API names instead of the full row to avoid issues with the ID not matching
            for (var i = 0; i < filterRuleList.length; i++) {
                if (i !== filterRule.index
                    && filterRuleList[i].objectName === filterRule.objectName
                    && filterRuleList[i].fieldName === filterRule.fieldName
                    && filterRuleList[i].operationName === filterRule.operationName
                    && filterRuleList[i].value === filterRule.value) {
                    cmp.find("filterRuleErrorText").set("v.value", cmp.get("v.labels.filterRuleDuplicate"));
                    return false;
                }
            }
        }

        if (!canSave) {
            cmp.find("filterRuleErrorText").set("v.value", cmp.get("v.labels.filterRuleFieldMissing"));
        }

        return canSave;

    }
})