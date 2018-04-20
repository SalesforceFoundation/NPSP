({
    /**
     * @description: changes field visibility and save button access based on the mode
     * this is bound to a change handler to the mode attribute
     */
    changeMode: function(cmp) {
        var mode = cmp.get("v.mode");
        //we check to see if mode is null since the change handler is called when mode is cleared in the container
        if (mode) {
            console.log("Mode is " + mode);
            console.log("In changeMode");

            //View is the only readOnly mode. Clone removes the activeRollupId for save.
            //Create hides all fields
            if (mode === "view") {
                cmp.set("v.isReadOnly", true);
            } else if (mode === "clone") {
                cmp.set("v.activeFilterGroupId", null);
                cmp.set("v.activeFilterGroup.recordId", null);
                cmp.set("v.activeFilterGroup.recordName", null);

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
            }
        }
    },

    /**
     * @description: filters the full rollup data to find which rollups use a particular filter group
     * @param filterGroupLabel: label of the selected filter group
     * @param labels: labels for the rollups UI
     */
    filterRollupList: function(cmp, filterGroupLabel, labels) {
        //filters row data based selected filter group
        var rollupList = cmp.get("v.rollupList");
        var filteredRollupList = rollupList.filter(function(rollup) {
            return rollup.filterGroupName === filterGroupLabel;
        });

        var summaryObjects = cmp.get("v.summaryObjects");
        var rollupsBySummaryObj = [];
        for (var i=0; i<summaryObjects.length; i++) {
            var listItem = {label: summaryObjects[i].label, list: []};
            rollupsBySummaryObj.push(listItem);
        }

        //filter rollup list by type
        filteredRollupList.forEach(function (rollup) {
            var item = {label: rollup.displayName, name: rollup.id}
            for (i=0; i<rollupsBySummaryObj.length; i++){
                if (rollup.summaryObject === rollupsBySummaryObj[i].label) {
                    rollupsBySummaryObj[i].list.push(item);
                }
            }
        });

        var itemList = [];
        //only add object to list if there are rollups with matching summary objects
        rollupsBySummaryObj.forEach(function(objList){
           if (objList.list.length > 1) {
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
     * @description: opens a modal popup so user can add or edit a filter rule
     * @param field - field name
     */
    getFieldType: function(cmp, field) {
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
        console.log(cmp.get("v.activeFilterRule.objectName"), field);
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
        var maxPollingRetryCount = 30;
        var poller = window.setTimeout(
            $A.getCallback(function() {
                counter++;
                console.log('setTimeout(' + jobId + ',' + recordName + '):' + counter);
                var action = cmp.get("c.getDeploymentStatus");
                action.setParams({jobId: jobId, recordName: recordName, objectType: 'Filter'});
                action.setCallback(this, function (response) {
                    console.log('getDeploymentStatus.callback');
                    var state = response.getState();
                    if (state === "SUCCESS") {
                        // Response will be a serialized deployResult wrapper class
                        var deployResult = JSON.parse(response.getReturnValue());
                        console.log('deployResult=' + deployResult);
                        // if there is a record id response
                        if (deployResult && deployResult.completed === true && deployResult.filterGroupItem) {
                            window.clearTimeout(poller);
                            helper.toggleSpinner(cmp, false);
                            helper.showToast(cmp, 'success', cmp.get("v.labels.filtersSaveProgress"), cmp.get("v.labels.filtersSaveSuccess"));

                            var model = helper.restructureResponse(deployResult.filterGroupItem);

                            // Save the inserted/updated record id
                            cmp.set("v.activeFilterGroup", model.filterGroup);
                            cmp.set("v.activeFilterGroupId", model.filterGroup.recordId);

                            // for a new record, copy the activeFilterGroup map to the cachedFilterGroup map
                            if (cmp.get("v.cachedFilterGroup") && cmp.get("v.cachedFilterGroup.recordName")) {
                                var activeFilterGroup = cmp.get("v.activeFilterGroup");
                                var cachedFilterGroup = cmp.get("v.cachedFilterGroup");
                                for (var key in activeFilterGroup) {
                                    if (activeFilterGroup.hasOwnProperty(key)) {
                                        cachedFilterGroup[key] = activeFilterGroup[key];
                                    }
                                }
                                cmp.set("v.cachedFilterGroup", cachedFilterGroup);
                            }

                            var filterRuleList = helper.restructureResponse(model.filterRuleList);
                            var filterRuleListCached = helper.restructureResponse(model.filterRuleList);

                            cmp.set("v.filterRuleList", filterRuleList);
                            cmp.set("v.cachedFilterRuleList", filterRuleListCached);
                            var rollupItems = cmp.get("v.rollupItems");

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
                            if (rollupItems) {
                                filterGroupTableItem.countRollups = rollupItems.length;
                            } else {
                                filterGroupTableItem.countRollups = 0;
                            }

                            // Send a message with the changed or new Rollup to the RollupContainer Component
                            helper.sendMessage(cmp, 'filterRecordChange', filterGroupTableItem);

                        } else {
                            // No record id, so run call this method again to check in another 1 second
                            if (counter < maxPollingRetryCount) {
                                helper.pollForDeploymentStatus(cmp, jobId, recordName, counter);
                            } else {
                                // When the counter hits the max, need to tell the user what happened
                                helper.showToast(cmp, 'info', cmp.get("v.labels.filtersSaveProgress"), cmp.get("v.labels.filtersSaveTimeout"));
                                helper.toggleSpinner(cmp, false);
                            }
                        }
                    } else {
                        // If an error is returned, parse the message, display and remove the spinner
                        var errors = response.getError();
                        var msg = "Unknown error";
                        if (errors && errors[0] && errors[0].message) {
                            msg = errors[0].message;
                        }
                        helper.showToast(cmp, 'error', cmp.get("v.labels.filtersSaveFail"), msg);
                        window.clearTimeout(poller);
                        helper.toggleSpinner(cmp, false);
                    }
                });
                $A.enqueueAction(action);
            }), (1000 + (maxPollingRetryCount*50)) /* query every 1 second with a small multiplier */
        );
    },

    /**
     * @description: parses the constant label into constant name form depending on the format of the value
     * @param valueApiName - API name of the constant
     * @param operation - API name of the operator
     * @return constantLabel - formatted name for display in the lightning:datatable
     */
    reformatValueLabel: function(cmp, valueApiName, operation){
        var updatedLabel;

        var filterRuleFieldType = cmp.get("v.filterRuleFieldType");

        if (filterRuleFieldType === "multipicklist" && valueApiName) {
            updatedLabel = valueApiName.join(";\n");
        } else if (filterRuleFieldType === "text" && valueApiName.indexOf(";") > 0 && valueApiName) {
            var labelRe = /;[\n]+[ ]+|;[ ]+[\n]+|;/g;
            updatedLabel = valueApiName.replace(labelRe, ";\n");

            var nameRe = /\n| /g;
            var newValueApiName = valueApiName.replace(nameRe, "");
            cmp.set("v.activeFilterRule.value", newValueApiName);
        }

        return updatedLabel;
    },

    /**
     * @description - changes picklist values or input type based on field type
     * @param operator - selected filter rule operator API name
     * @param type - DisplayType of the selected field transformed to lower case
     */
    rerenderValue: function(cmp, operator) {
        var type = this.getFieldType(cmp, cmp.get("v.activeFilterRule.fieldName"));
        console.log('type is ' + type);
        console.log('operator is ' + operator);
        if (type === 'boolean') {
            //boolean fields don't have official translations (confirmed in process builder)
            cmp.set("v.filterRuleFieldType", 'picklist');
            var options = [{value: 'true', label: 'True'}, {value: 'false', label: 'False'}];
            cmp.set("v.filterRuleConstantPicklist", options);
        } else if (type === 'date') {
            cmp.set("v.filterRuleFieldType", 'date');
        } else if (type === 'datetime') {
            cmp.set("v.filterRuleFieldType", 'datetime-local');
        } else if (type === 'picklist' || type === 'multipicklist') {
            if (operator === 'Equals' || operator === 'Not_Equals') {
                cmp.set("v.filterRuleFieldType", 'picklist');
            } else if (operator === 'Starts_With' || operator === 'Contains' ||  operator === 'Does_Not_Contain'){
                cmp.set("v.filterRuleFieldType", 'text');
            } else if (operator === 'In_List' || operator === 'Not_In_List'
                || operator === 'Is_Included' || operator === 'Is_Not_Included'){
                cmp.set("v.filterRuleFieldType", 'multipicklist');
            }
        } else if (type === 'reference') {
            var field = cmp.get("v.activeFilterRule.fieldName");
            //record type is a special case where we want to exactly match options and provide picklists
            if (field !== 'RecordTypeId') {
                cmp.set("v.filterRuleFieldType", 'text');
            } else {
                if (operator === 'Equals' || operator === 'Not_Equals') {
                    cmp.set("v.filterRuleFieldType", 'picklist');
                } else if (operator === 'In_List' || operator === 'Not_In_List') {
                    cmp.set("v.filterRuleFieldType", 'multipicklist');
                }
            }
        } else if (type === 'time') {
            cmp.set("v.filterRuleFieldType", 'time');
        } else if (type === 'double' || type === 'integer'
            || type === 'currency' || type === 'percent') {
            cmp.set("v.filterRuleFieldType", 'number');
        } else {
            cmp.set("v.filterRuleFieldType", 'text');
        }
    },

    /**
     * @description: opens a modal popup so user can add or edit a filter rule
     */
    resetActiveFilterRule: function(cmp) {
        var defaultFilterRule = {objectName: '', fieldName: '', operationName: '', value: ''};
        cmp.set("v.activeFilterRule", defaultFilterRule);
        cmp.set("v.filteredFields", "");
        cmp.set("v.filterRuleFieldType", "text");
    },

    /**
     * @description: resets the list of filter rules based on the
     * @param object - selected object API name
     */
    resetFilterRuleFields: function(cmp, object) {
        var objectDetails = cmp.get("v.objectDetails");
        cmp.set("v.filteredFields", objectDetails[object]);
    },

    /**
     * @description: resets the possible list of operations based on the selected filter rule
     * @param field - selected field API name
     * @param type - type of the selected field
     */
    resetFilterRuleOperators: function(cmp, field) {
        var type = this.getFieldType(cmp, field);
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

    /* @description: retrieves the label of an entity (field, operation, etc) based on the api name from a LIST of objects with name and label entries
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
        action.setParams({filterGroupCMT: JSON.stringify(filterGroupCMT)});
        action.setCallback(this, function (response) {
            var state = response.getState();
            console.log('STATE=' + state);

            if (state === "SUCCESS") {
                // Response value will be in the format of "JobId-RecordDeveloperName"
                var responseText = response.getReturnValue();
                var jobId = responseText.split("-")[0];
                var recordName = responseText.split("-")[1];

                console.log('Response = ' + response.getReturnValue());
                console.log('Returned jobId = ' + jobId);
                console.log('Returned RecordName = ' + recordName);

                this.pollForDeploymentStatus(cmp, jobId, recordName, 0);
            } else if (state === "ERROR") {

                var errors = response.getError();
                var msg = "Unknown error";
                if (errors && errors[0] && errors[0].message) {
                    msg = errors[0].message;
                }
                this.showToast(cmp, 'error', cmp.get("v.labels.filtersSaveFail"), msg);
                this.toggleSpinner(cmp, false);
            }
        });
        this.showToast(cmp, 'info', cmp.get("v.labels.filtersSaveProgress"), cmp.get("v.labels.filtersSaveProgress"));
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
     * @description Show a message on the screen
     * @param type - error, success, info
     * @param title - message title
     * @param message - message to display
     */
    showToast: function(cmp, type, title, message) {
        cmp.set("v.toastStatus", type);
        var altText = cmp.get("v.labels." + type);
        var text = {message: message, title: title, alternativeText: altText};
        cmp.set("v.notificationText", text);
        cmp.set("v.notificationClasses", "");
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
     * @description Show or Hide the page spinner
     * @param showSpinner - true to show; false to hide
     */
    toggleSpinner: function(cmp, showSpinner) {
        var spinner = cmp.find("waitingSpinner");
        if (showSpinner === true) {
            $A.util.removeClass(spinner, "slds-hide");
        } else {
            $A.util.addClass(spinner, "slds-hide");
        }
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

        cmp.find("nameInput").showHelpMessageIfInvalid();
        cmp.find("descriptionInput").showHelpMessageIfInvalid();

        if (!description || !name || name.length > 40) {
            canSave = false;
        }

        if (filterRuleList.length === 0) {
            canSave = false;
        } else if (!filterRuleList || filterRuleList.length === 0) {
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

        //check for specific API name duplicates instead of the full row to avoid issues with the ID not matching
        for (var i = 0; i < filterRuleList.length; i++) {
            if (i !== filterRule.index
                && filterRuleList[i].objectName === filterRule.objectName
                && filterRuleList[i].fieldName === filterRule.fieldName
                && filterRuleList[i].operatorName === filterRule.operatorName
                && filterRuleList[i].constantName === filterRule.constantName) {
                cmp.set("v.filterRuleError", cmp.get("v.labels.filterRuleDuplicate"));
                return canSave = false;
            }
        }

        //check for duplicates
        if (!filterRuleList) {
            // nothing to compare
        } else if (cmp.get("v.filterRuleMode") === 'create') {
            //check for specific API names instead of the full row to avoid issues with the ID not matching
            for (var i = 0; i < filterRuleList.length; i++) {
                if (filterRuleList[i].objectName === filterRule.objectName
                    && filterRuleList[i].fieldName === filterRule.fieldName
                    && filterRuleList[i].operationName === filterRule.operationName
                    && filterRuleList[i].value === filterRule.value) {
                    cmp.set("v.filterRuleError", cmp.get("v.labels.filterRuleDuplicate"));
                    return canSave = false;
                }
            }
        } else {
            for (var i = 0; i < filterRuleList.length; i++) {
                if (i !== filterRule.index
                    && filterRuleList[i].objectName === filterRule.objectName
                    && filterRuleList[i].fieldName === filterRule.fieldName
                    && filterRuleList[i].operationName === filterRule.operationName
                    && filterRuleList[i].value === filterRule.value) {
                    cmp.set("v.filterRuleError", cmp.get("v.labels.filterRuleDuplicate"));
                    return canSave = false;
                }
            }
        }

        cmp.set("v.filterRuleError", "");

        return canSave;

    }
})