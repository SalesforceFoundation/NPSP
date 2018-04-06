({
    /* @description: changes field visibility and save button access based on the mode
    * this is bound to a change handler to the mode attribute
    */
    changeMode: function(cmp){
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
                cmp.set("v.isReadOnly", false);
            } else if (mode === "edit") {
                cmp.set("v.isReadOnly", false);
            } else if (mode === "create") {
                cmp.set("v.isReadOnly", false);
            }
        }
    },

    /* @description: filters the full rollup data to find which rollups use a particular filter group
    * @param filterGroupLabel: label of the selected filter group
    * @param labels: labels for the rollups UI
    */
    filterRollupList: function(cmp, filterGroupLabel, labels){
        //filters row data based selected filter group
        var rollupList = cmp.get("v.rollupList");
        var filteredRollupList = rollupList.filter(function(rollup){
            return rollup.filterGroupName === filterGroupLabel;
        });

        var summaryObjects = cmp.get("v.summaryObjects");
        var rollupsBySummaryObj = [];
        for(var i=0; i<summaryObjects.length; i++){
            var listItem = {label: summaryObjects[i].label, list: []};
            rollupsBySummaryObj.push(listItem);
        }

        //filter rollup list by type
        filteredRollupList.forEach(function (rollup){
            var item = {label: rollup.rollupName, name: rollup.id}
            for(i=0; i<rollupsBySummaryObj.length; i++){
                if (rollup.summaryObject === rollupsBySummaryObj[i].label){
                    rollupsBySummaryObj[i].list.push(item);
                }
            }
        });

        var itemList = [];
        //only add object to list if there are rollups with matching summary objects
        rollupsBySummaryObj.forEach(function(objList){
           if (objList.list.length > 1){
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

    /* @description: opens a modal popup so user can add or edit a filter rule
     */
    getAvailableOperations: function(cmp, type){
        var opMap = cmp.get("v.operatorMap");
        var operators = [{name: 'Equals', label: opMap.Equals}, {name: 'Not_Equals', label: opMap.Not_Equals}];

        if (type === 'boolean') {
            //equals/not equals are only matches
        } else if (type === 'reference'){
            operators.push({name: 'In_List', label: opMap.In_List});
            operators.push({name: 'Not_In_List', label: opMap.Not_In_List});
        } else if (type === 'date' || type === 'datetime' || type === 'time'
            || type === 'double' || type === 'integer' || type === 'currency' || type === 'percent'){
            operators.push({name: 'Greater', label: opMap.Greater});
            operators.push({name: 'Greater_or_Equal', label: opMap.Greater_or_Equal});
            operators.push({name: 'Less', label: opMap.Less});
            operators.push({name: 'Less_or_Equal', label: opMap.Less_or_Equal});
        } else {
            operators.push({name: 'Starts_With', label: opMap.Starts_With});
            operators.push({name: 'Contains', label: opMap.Contains});
            operators.push({name: 'Does_Not_Contain', label: opMap.Does_Not_Contain});

            if (type === 'multipicklist'){
                operators.push({name: 'Is_Included', label: opMap.Is_Included});
                operators.push({name: 'Is_Not_Included', label: opMap.Is_Not_Included});
            } else if (type != 'textarea'){
                operators.push({name: 'In_List', label: opMap.In_List});
                operators.push({name: 'Not_In_List', label: opMap.Not_In_List});
            }
        }

        cmp.set("v.filteredOperators", operators);

    },

    /* @description: opens a modal popup so user can add or edit a filter rule
     * @param field - field name
     */
    getFieldType: function(cmp, field){
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

    /* @description: queries for picklist options to populate filterRuleConstantPicklist
     * @param field - field name
     */
    getPicklistOptions: function(cmp, field){
        var action = cmp.get("c.getFilterRuleConstantPicklistOptions");
        action.setParams({objectName: cmp.get("v.activeFilterRule.objectName"), selectedField: field});
        console.log(cmp.get("v.activeFilterRule.objectName"), field);
        action.setCallback(this, function (response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                console.log(JSON.stringify(response.getReturnValue()));
                cmp.set("v.filterRuleConstantPicklist", response.getReturnValue());
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

        console.log('before enqueue')
        $A.enqueueAction(action);
    },

    /* @description - changes picklist values or input type based on field type
     * @param operator - selected filter rule operator API name
     * @param type - DisplayType of the selected field transformed to lower case
     */
    rerenderValue: function(cmp, operator){
        var type = this.getFieldType(cmp, cmp.get("v.activeFilterRule.fieldName"));
        console.log('type is ' + type);
        console.log('operator is ' + operator);
        if (type === 'boolean'){
            //boolean fields don't have official translations (confirmed in process builder)
            cmp.set("v.filterRuleFieldType", 'picklist');
            var options = [{name: 'true', label: 'True'}, {name: 'false', label: 'False'}];
            cmp.set("v.filterRuleConstantPicklist", options);
        } else if (type === 'date'){
            cmp.set("v.filterRuleFieldType", 'date');
        } else if (type === 'datetime') {
            cmp.set("v.filterRuleFieldType", 'datetime-local');
        } else if (type === 'picklist' || type === 'multipicklist'){
            if(operator === 'Equals' || operator === 'Not_Equals'){
                cmp.set("v.filterRuleFieldType", 'picklist');
            } else if (operator === 'Starts_With' || operator === 'Contains' ||  operator === 'Does_Not_Contain'){
                cmp.set("v.filterRuleFieldType", 'text');
            } else if (operator === 'In_List' || operator === 'Not_In_List'
                || operator === 'Is_Included' || operator === 'Is_Not_Included'){
                cmp.set("v.filterRuleFieldType", 'multipicklist');
            }
        } else if (type === 'reference'){
            var field = cmp.get("v.activeFilterRule.fieldName");
            //record type is a special case where we want to exactly match options and provide picklists
            if (field !== 'RecordTypeId'){
                cmp.set("v.filterRuleFieldType", 'text');
            } else {
                if (operator === 'Equals' || operator === 'Not_Equals'){
                    cmp.set("v.filterRuleFieldType", 'picklist');
                } else if (operator === 'In_List' || operator === 'Not_In_List'){
                    cmp.set("v.filterRuleFieldType", 'multipicklist');
                }
            }
        } else if (type === 'time'){
            cmp.set("v.filterRuleFieldType", 'time');
        } else if (type === 'double' || type === 'integer'
            || type === 'currency' || type === 'percent'){
            cmp.set("v.filterRuleFieldType", 'number');
        } else {
            cmp.set("v.filterRuleFieldType", 'text');
        }
    },

    /* @description: opens a modal popup so user can add or edit a filter rule
     */
    resetActiveFilterRule: function(cmp){
        var defaultFilterRule = {objectName: '', fieldName: '', operatorName: '', constant: ''};
        cmp.set("v.activeFilterRule", defaultFilterRule);
        cmp.set("v.filteredFields", "");
    },

    /* @description: resets the list of filter rules based on the
     * @param object - selected object API name
     */
    resetFilterRuleFields: function(cmp, object){
        var objectDetails = cmp.get("v.objectDetails");
        cmp.set("v.filteredFields", objectDetails[object]);
    },

    /* @description: resets the possible list of operations based on the selected filter rule
     * @param field - selected field API name
     * @param type - type of the selected field
     */
    resetFilterRuleOperators: function(cmp, field){
        var type = this.getFieldType(cmp, field);
        if(type === 'picklist' || type === 'multipicklist' || field === 'RecordTypeId'){
            this.getPicklistOptions(cmp, field);
        }
        cmp.set("v.filterRuleFieldType", "text");
        this.getAvailableOperations(cmp, type);
    },

    /* @description: restructures returned Apex response to preserve separate variables
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
                if (entityList[i].name === apiName) {
                    label = entityList[i].label;
                    break;
                }
            }
        }
        return label;
    },

    /* @description: toggles a modal popup and backdrop
    */
    toggleFilterRuleModal: function(cmp){
        var backdrop = cmp.find('backdrop');
        $A.util.toggleClass(backdrop, 'slds-backdrop_open');
        var modal = cmp.find('modaldialog');
        $A.util.toggleClass(modal, 'slds-fade-in-open');
    },

    /* @description: verifies all required fields have been populated before saving the filter group
     */
    validateFilterGroupFields: function(cmp){
        var canSave = true;
        var name = cmp.get("v.activeFilterGroup.MasterLabel");
        var description = cmp.get("v.activeFilterGroup.Description__c");
        var filterRuleList = cmp.get("v.filterRuleList");

        cmp.find("nameInput").showHelpMessageIfInvalid();
        cmp.find("descriptionInput").showHelpMessageIfInvalid();
        //todo: where to put error message for filter rules? or can a filter group be saved w/o filter rules?

        if (!description){
            canSave = false;
        } else if (!name){
            canSave = false;
        } else if (filterRuleList.length === 0){
            canSave = false;
        }

        return canSave;
    }
})