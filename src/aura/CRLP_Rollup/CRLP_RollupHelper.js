({
    /* @description: resets values and visibility for objects based on the object details
    * this is run when the page is first loaded or when a cancel event resets the page
    */
    setObjectAndFieldDependencies: function (cmp) {
        console.log("In setObjectAndFieldDependencies");

        //need to reset fields to populate the selected objects -- refactor to see if necessary
        //fields can be lazy loaded if user is creating a new rollup
        if (cmp.get("v.mode") !== 'create') {
            this.fieldSetup(cmp);
        } else {
            //set active default as true
            cmp.set("v.activeRollup.isActive", true);
            // check for a summary object filter to see if summary fields need to be set
            var summaryObject = cmp.get("v.activeRollup.summaryObject");
            var summaryObjects = cmp.get("v.summaryObjects");
            var label = this.retrieveFieldLabel(summaryObject, summaryObjects);

            //sets summary object if it's being passed from the container
            if (summaryObject) {
                this.onChangeSummaryObject(cmp, summaryObject, label);
            }
            this.hideAllFields(cmp);
            this.setIntegerYearList(cmp);
        }

        //update filter group list to contain none as a first option
        //note: unshift can't be used here due to an issue with bound values
        var filterGroups = cmp.get("v.filterGroups");
        var tempList = [{"name": cmp.get("v.labels.na"), "label": cmp.get("v.labels.na")}];
        tempList = tempList.concat(filterGroups);
        cmp.set("v.filterGroups", tempList);


        console.log('Called reset details');
    },

    /* @description: changes field visibility and save button access based on the mode
    * this is bound to a change handler to the mode attribute
    */
    changeMode: function (cmp) {
        var mode = cmp.get("v.mode");
        //we check to see if mode is null since the change handler is called when mode is cleared in the container
        if (mode) {
            console.log("Mode is " + mode);
            console.log("In changeMode");

            //View is the only readOnly mode. Clone removes the activeRollupId for save.
            //Create hides all fields and sets isIncomplete to disable the save button.
            if (mode === "view") {
                cmp.set("v.isReadOnly", true);
            } else if (mode === "clone") {
                cmp.set("v.activeRollupId", null);
                cmp.set("v.isReadOnly", false);
                var newSummary = this.uniqueSummaryFieldCheck(cmp, cmp.get("v.summaryFields"));
                cmp.set("v.summaryFields", newSummary);
                cmp.set("v.isIncomplete", false);
            } else if (mode === "edit") {
                cmp.set("v.isReadOnly", false);
                cmp.set("v.isIncomplete", false);
            } else if (mode === "create") {
                cmp.set("v.isIncomplete", true);
                cmp.set("v.isReadOnly", false);
                this.hideAllFields(cmp);
            }
        }
    },

    /* @description: applies the correct labels for all underlying API values and resets allowed values
    * this is run when the page is first loaded or when a cancel event resets the page
    */
    fieldSetup: function(cmp){
        this.resetAllFields(cmp);
        this.updateAllowedOperations(cmp);
        this.onChangeOperation(cmp, cmp.get("v.activeRollup.operation"));
        this.setIntegerYearList(cmp);
        this.onChangeTimeBoundOperationsOptions(cmp, false);
        this.onChangeInteger(cmp, cmp.get("v.activeRollup.intValue"));
    },

    /* @description: filters a picklist of fields by their type
    * @param typeList: list of types to match
    * @param allFields: list of mapped fields to their type to filter
    * @return: the filtered list of values
    */
    filterFieldsByType: function (cmp, typeList, allFields) {
        //if type is null, no detail field is selected
        console.log("filter fields by type function");
        var newFields = [];

        typeList.forEach(function (type) {
            if (!(type === undefined || type === null)) {
                allFields.forEach(function (field) {
                    var datatype = field.type;
                    if (datatype === type) {
                        newFields.push(field);
                    }
                });
            }
        });
        return newFields;
    },

    /* @description: filters possible detail fields by summary type and updates the detailFields attribute
    * @param detailObject: currently selected detail object
    */
    filterDetailFieldsBySummaryField: function (cmp, detailObject) {
        //current version filters strictly; update will include type conversion fields
        var summaryField = cmp.get("v.activeRollup.summaryField");

        //need to get all detail fields, or we filter on a subset of all options
        var allFields = cmp.get("v.objectDetails")[detailObject];
        var newFields = [];

        //loop over all summary fields to get the type of selected field
        var summaryFields = cmp.get("v.summaryFields");
        var type = this.getFieldType(cmp, summaryField, summaryFields);

        //TODO: maybe check if type is the same to see if need to filter?
        //if type is undefined, return all fields
        if (type === undefined || allFields === undefined) {
            newFields = allFields;
        } else {
            newFields = this.filterFieldsByType(cmp, [type], allFields);
        }

        if (newFields.length > 0) {
            cmp.set("v.detailFields", newFields);
        } else {
            newFields = [{name: '', label: cmp.get("v.labels.noFields")}];
            cmp.set("v.detailFields", newFields);
        }
        //reset detail field to null to prompt user selection
        cmp.set("v.activeRollup.detailField", null);
    },

    /* @description: gets the type of a field
    * @param field: name of the field
    * @param fieldList: list of fields with name, type and label keys
    * @return: the type of the field
    */
    getFieldType: function(cmp, field, fieldList){
        for (var i = 0; i < fieldList.length; i++) {
            if (fieldList[i].name === field) {
                var type = fieldList[i].type;
                return type;
            }
        }
    },

    /* @description: hides all fields but the summary view with the renderMap var to walk user through a create rollup flow
    */
    hideAllFields: function (cmp) {
        var renderMap = cmp.get("v.renderMap");
        for (var key in renderMap) {
            renderMap[key] = false;
        }
        cmp.set("v.renderMap", renderMap);
    },

    /* @description: resets the detail object, description, all picklist fields, and rollup types when summary object is changed
    * @param summaryObject: summaryObject API name
    * @param label: summaryObject API label
    */
    onChangeSummaryObject: function (cmp, summaryObject, label) {
        console.log("hitting onChangeSummaryObjectHelper");

        this.resetFields(cmp, summaryObject, 'summary');
        cmp.set("v.activeRollup.summaryField", null);
        cmp.set("v.activeRollup.summaryObjectLabel", label);
        cmp.set("v.activeRollup.description", null);
        cmp.set("v.activeRollup.detailObject", null);
        cmp.set("v.activeRollup.detailField", null);
        cmp.set("v.activeRollup.amountField", null);
        cmp.set("v.activeRollup.dateField", null);

        this.resetRollupTypes(cmp);

        this.onChangeSummaryField(cmp, '');
    },

    /* @description: sets the detail field label and determines if save button may illuminate since detail field is required if visible
    * @param detailField: selected detail field API name
    * @param label: selected detail field label
    */
    onChangeDetailField: function (cmp, detailField, label) {
        console.log('in helper on change detail');
        this.verifyRollupSaveActive(cmp, detailField);
        cmp.set("v.activeRollup.detailFieldLabel", label);
    },

    /* @description: sets the filter group master label when the filter group is changed
    * @param label: filter group label
    */
    onChangeFilterGroup: function (cmp, label) {
        console.log('in helper on change filter group');
        cmp.set("v.activeRollup.filterGroupLabel", label);
    },

    /* @description: stores the selected years back integer value for years to be used when the page is in view mode
    * @param value: integer value
    */
    onChangeInteger: function (cmp, value) {
        console.log('in helper on change integer');
        var renderMap = cmp.get("v.renderMap");
        if(renderMap["integerYears"]){
            var integerList = cmp.get("v.integerList");
            //need to convert value to an integer due to strict comparison in retrieveFieldLabel
            var label = this.retrieveFieldLabel(parseInt(value), integerList);
            cmp.set("v.selectedIntegerLabel", label);
        } else {
            cmp.set("v.selectedIntegerLabel", "");
        }
    },

    /* @description: conditionally renders the time bound operation, use fiscal year, amount, date and detail fields
    * @param operation: operation API name
    */
    onChangeOperation: function (cmp, operation) {
        console.log("in helper onChangeOperation");
        var renderMap = cmp.get("v.renderMap");

        //TIME BOUND OPERATION RENDERING
        if (operation && operation !== 'Donor_Streak' && operation !== 'Years_Donated') {
            renderMap["timeBoundOperation"] = true;
            renderMap["rollupType"] = true;
        } else {
            renderMap["timeBoundOperation"] = false;
            renderMap["rollupType"] = false;
            cmp.set(("v.activeRollup.timeBoundOperationType"), 'All_Time');
            var timeBoundLabel = this.retrieveFieldLabel('All_Time', cmp.get("v.timeBoundOperations"));
            cmp.set("v.selectedTimeBoundOperationLabel", timeBoundLabel);
            renderMap["integerDays"] = false;
            renderMap["integerYears"] = false;
        }
        //AMOUNT, DATE & DETAIL FIELD RENDERING
        var rollupLabel = cmp.get("v.selectedRollupType").label;
        renderMap = this.renderAmountField(cmp, operation, rollupLabel, renderMap);
        renderMap = this.renderDateField(cmp, operation, rollupLabel, renderMap);
        renderMap = this.renderDetailField(cmp, operation, rollupLabel, renderMap);
        renderMap = this.renderFiscalYear(cmp, renderMap);

        cmp.set("v.renderMap", renderMap);

        //set selected operation label to be available in view mode
        var operations = cmp.get("v.operations");
        var label = operations[operation];
        cmp.set("v.selectedOperationLabel", label);

        //check that detail field and rollup type have been populated before saving
        this.verifyRollupSaveActive(cmp, cmp.get("v.activeRollup.detailField"));

    },

    /* @description: renders filter group and operation, resets fields for the amount, detail and date fields based on the detail object
    * @param detailObject: detail object API name stored as the name on the rollupType attribute
    * @param rollupLabel: rollup type label
    */
    onChangeRollupType: function (cmp, detailObject, rollupLabel) {
        console.log('in helper on change rollup');
        var renderMap = cmp.get("v.renderMap");
        var labels = cmp.get("v.labels");
        //during create, visibility of operation and filter group are toggled
        if(cmp.get("v.mode") === "create"){
            if (rollupLabel) {
                renderMap["filterGroup"] = true;
                cmp.set("v.renderMap", renderMap);
                this.filterDetailFieldsBySummaryField(cmp, detailObject);
            } else {
                renderMap["filterGroup"] = false;
            }
            cmp.set("v.activeRollup.filterGroupLabel", labels.na);
            this.onChangeFilterGroup(cmp, na);
        }

        //AMOUNT, DATE & DETAIL FIELD RENDERING
        var operation = cmp.get("v.activeRollup.operation");
        renderMap = this.renderAmountField(cmp, operation, rollupLabel, renderMap);
        renderMap = this.renderDateField(cmp, operation, rollupLabel, renderMap);
        renderMap = this.renderDetailField(cmp, operation, rollupLabel, renderMap);

        cmp.set("v.renderMap", renderMap);

        //set detail object label explicitly since detail obj name is bound to rollup type field, but the label is not
        var detailObjects = cmp.get("v.detailObjects");
        var detailLabel = this.retrieveFieldLabel(detailObject, detailObjects);
        cmp.set("v.activeRollup.detailObjectLabel", detailLabel);
        cmp.set("v.selectedRollupType", {label: rollupLabel, name: detailObject});

        //reset amount fields
        this.resetFields(cmp, detailObject, 'amount');

        //reset date fields
        //set date object label and api name based on the selected detail object then reset fields + selected value
        //defaults field to Payment on the payment object, and CloseDate for everything else
        if (detailObject === labels.objectPayment) {
            cmp.set("v.activeRollup.dateObjectLabel", labels.labelPayment);
            cmp.set("v.activeRollup.dateObject", labels.objectPayment);
            this.resetFields(cmp, cmp.get("v.activeRollup.dateObject"), "date");
            cmp.set("v.activeRollup.dateField", "npe01__Payment_date__c");
        } else {
            cmp.set("v.activeRollup.dateObjectLabel", labels.labelOpportunity);
            cmp.set("v.activeRollup.dateObject", labels.objectOpportunity);
            this.resetFields(cmp, cmp.get("v.activeRollup.dateObject"), "date");
            cmp.set("v.activeRollup.dateField", "CloseDate");
        }

        //check if save button can be activated
        var detailField = cmp.get("v.activeRollup.detailField");
        this.verifyRollupSaveActive(cmp, detailField);

    },

    /* @description: renders rollupType field, filters allowed operations by field type when summary field changes
    * @param label: summary field label
    */
    onChangeSummaryField: function (cmp, label) {
        console.log('in helper on change summary');
        //toggle rendering for create flow
        if(cmp.get("v.mode") === 'create'){
            var renderMap = cmp.get("v.renderMap");
            if(label){
                renderMap["description"] = true;
                renderMap["operation"] = true;
            } else{
                renderMap["description"] = false;
                renderMap["operation"] = false;
            }
            cmp.set("v.renderMap", renderMap);
            cmp.set("v.activeRollup.operation", '');
            this.onChangeOperation(cmp, '');
        }

        //sets rollup type automatically if there is only 1
        var rollupTypes = cmp.get("v.rollupTypes");
        if (rollupTypes.length === 1 && label) {
            cmp.set("v.activeRollup.detailObject", rollupTypes[0].name);
            cmp.set("v.selectedRollupType", {label: rollupTypes[0].label, name: rollupTypes[0].name});
            this.onChangeRollupType(cmp, rollupTypes[0].name, rollupTypes[0].label);
        } else {
            cmp.set("v.selectedRollupType", {name: '', label: ''});
            cmp.set("v.activeRollup.detailObject", '');
            this.onChangeRollupType(cmp, '', '');
        }

        //reset operation if selected operation isn't in the list
        this.updateAllowedOperations(cmp);
        var operationLabel = this.retrieveFieldLabel(cmp.get("v.activeRollup.operation"), cmp.get("v.allowedOperations"));
        if(!operationLabel){
            cmp.set("v.activeRollup.operation", '');
            this.onChangeOperation(cmp, '');
        }

        this.updateRollupName(cmp);
        cmp.set("v.activeRollup.summaryFieldLabel", label);
    },

    /* @description: fires when time bound operations options is changed or when set up
    * @param isOnChange: determines if this is fired during a change (true) or during setup (false)
    * @param label: time bound operations label
    */
    onChangeTimeBoundOperationsOptions: function (cmp, isOnChange, label) {
        console.log("in helper changeTimeBoundOperationsOptions");
        var operation = cmp.get("v.activeRollup.timeBoundOperationType");
        var renderMap = cmp.get("v.renderMap");
        if (operation === 'All_Time') {
            //disable fiscal year, disable integer, and reset values
            renderMap = this.renderFiscalYear(cmp, renderMap);
            renderMap["integerDays"] = false;
            renderMap["integerYears"] = false;
            if (isOnChange) {
                cmp.set("v.activeRollup.useFiscalYear", cmp.get("v.cachedRollup.useFiscalYear"));
                cmp.set("v.activeRollup.intValue", cmp.get("v.cachedRollup.intValue"));
                this.onChangeInteger(cmp, 0);
            }
        } else if (operation === 'Years_Ago') {
            //enable fiscal year and integerYears
            renderMap = this.renderFiscalYear(cmp, renderMap);
            renderMap["integerDays"] = false;
            renderMap["integerYears"] = true;
            //set a default integer of 0
            if (isOnChange) {
                cmp.set("v.activeRollup.intValue", 0);
                this.onChangeInteger(cmp, 0);
            }
        } else if (operation === 'Days_Back') {
            //disable fiscal year and enable integerDays
            renderMap = this.renderFiscalYear(cmp, renderMap);
            renderMap["integerDays"] = true;
            renderMap["integerYears"] = false;
            //set a default integer of 0 and the default fiscal year
            if (isOnChange) {
                cmp.set("v.activeRollup.useFiscalYear", cmp.get("v.cachedRollup.useFiscalYear"));
                cmp.set("v.activeRollup.intValue", 0);
                this.onChangeInteger(cmp, 0);
            }
        } else {
            //default to not showing these fields and reset values
            renderMap["integerDays"] = false;
            renderMap["integerYears"] = false;
            if (isOnChange) {
                cmp.set("v.activeRollup.useFiscalYear", cmp.get("v.cachedRollup.useFiscalYear"));
                cmp.set("v.activeRollup.intValue", cmp.get("v.cachedRollup.intValue"));
                this.onChangeInteger(cmp, 0);
            }
        }
        //check to display or clear the dateField for Years_Ago or Days_Back
        var rollupLabel = cmp.get("v.selectedRollupType").label;
        renderMap = this.renderDateField(cmp, operation, rollupLabel, renderMap);

        cmp.set("v.renderMap", renderMap);

        //set selected operation to be available in view mode
        var timeBoundOperations = cmp.get("v.timeBoundOperations");
        if(label === undefined){
            label = this.retrieveFieldLabel(operation, timeBoundOperations);
        }
        cmp.set("v.selectedTimeBoundOperationLabel", label);
    },

    /* @description: conditionally render amount field based on the selected operation
    * @param operation: operation API name
    * @param rollupLabel: label of the selected rollup type passed to ensure a rollup type is not null
    * @param renderMap: current map of fields to render
    * @return: updated render map
    */
    renderAmountField: function (cmp, operation, rollupLabel, renderMap) {
        if ((operation === 'Largest'
            || operation === 'Smallest'
            || operation === 'Best_Year'
            || operation === 'Best_Year_Total'
            || operation === 'Sum'
            || operation === 'Count'
            || operation === 'Average')
            && rollupLabel) {
            //enable amount field
            renderMap["amountField"] = true;

            //set the default amount field based on the selected detail object
            if (cmp.get("v.activeRollup.detailObject") === 'npe01__OppPayment__c') {
                cmp.set("v.activeRollup.amountField", 'npe01__Payment_amount__c');
            } else {
                cmp.set("v.activeRollup.amountField", 'Amount');
            }
        } else {
            //disable amount field and clear values
            renderMap["amountField"] = false;
            cmp.set("v.activeRollup.amountField", null);
        }
        return renderMap;
    },

    /* @description: conditionally render date field based on the selected operation and rollup selection
    * @param operation: operation API name
    * @param renderMap: current map of fields to render
    * @return: updated render map
    */
    renderDateField: function (cmp, operation, rollupLabel, renderMap) {
        if ((operation === 'First'
            || operation === 'Last'
            || operation === 'Years_Ago'
            || operation === 'Days_Back')
            && rollupLabel) {
            //enable date field and set defaults based on the dateObject, which is set from the rollup type
            var dateObject = cmp.get("v.activeRollup.dateObject");
            if (dateObject === 'npe01__OppPayment__c') {
                cmp.set("v.activeRollup.dateField", "npe01__Payment_date__c");
            } else {
                cmp.set("v.activeRollup.dateField", "CloseDate");
            }
            //enable date field
            renderMap["dateField"] = true;
        } else {
            //disable date field and clear values
            renderMap["dateField"] = false;
            cmp.set("v.activeRollup.dateField", null);
        }

        return renderMap;
    },

    /* @description: conditionally render detail field based on the selected operation, specifically Single Result Operations
    * @param operation: operation API name
    * @param renderMap: current map of fields to render
    * @return: updated render map
    */
    renderDetailField: function (cmp, operation, rollupLabel, renderMap) {
        if ((operation === 'First'
            || operation === 'Last'
            || operation === 'Smallest'
            || operation === 'Largest')
            && rollupLabel) {
            //enable detail field
            renderMap["detailField"] = true;
        } else {
            //disable detail field and and clear values
            renderMap["detailField"] = false;
            cmp.set("v.activeRollup.detailField", null);
        }

        return renderMap;

    },

    /* @description: conditionally render fiscal year checkbox based on the selected operation and time bound operation
    * note that both operations are retrieved instead of passed since only 1 would be available
    * @param renderMap: current map of fields to render
    * @return: updated render map
    */
    renderFiscalYear: function (cmp, renderMap) {
        var operation = cmp.get("v.activeRollup.operation");
        var timeBoundOperation = cmp.get("v.activeRollup.timeBoundOperationType");

        if ((operation === 'Donor_Streak'
            || operation === 'Years_Donated'
            || operation === 'Best_Year'
            || operation === 'Best_Year_Total'
            || timeBoundOperation === 'Years_Ago')
            && operation) {
            //enable fiscal year
            renderMap["fiscalYear"] = true;
        } else {
            //disable detail field and and clear values
            renderMap["fiscalYear"] = false;
            cmp.set("v.activeRollup.useFiscalYear", cmp.get("v.cachedRollup.useFiscalYear"));
        }

        return renderMap;

    },

    /* @description: resets fields based on the selected object and context
    * @param object: corresponding object to the fields
    * @param context: which fields to reset. values are: detail, summary, date, and amount
    */
    resetFields: function (cmp, object, context) {

        console.log("Fired field reset for context [" + context + "] and object [" + object + "]");
        var newFields = cmp.get("v.objectDetails")[object];

        if (newFields === undefined) {
            newFields = [{name: 'None', label: cmp.get("v.labels.noFields")}];
        }

        if (context === 'detail') {
            cmp.set("v.detailFields", newFields);
        } else if (context === 'summary') {
            //check if record's summary field needs to be added
            newFields = this.uniqueSummaryFieldCheck(cmp, newFields);
            cmp.set("v.summaryFields", newFields);
        } else if (context === 'date') {
            newFields = this.filterFieldsByType(cmp, ["DATE"], newFields);
            cmp.set("v.dateFields", newFields);
        } else if (context === 'amount') {
            newFields = this.filterFieldsByType(cmp, ["DOUBLE", "CURRENCY"], newFields);
            cmp.set("v.amountFields", newFields);
        }
    },

    /* @description: resets all fields
    */
    resetAllFields: function (cmp) {
        //todo: refactor to see if/when is even necessary

        var activeRollup = cmp.get("v.activeRollup");
        var summaryObject = activeRollup.summaryObject;
        var detailObject = activeRollup.detailObject;

        console.log("Summary Object=" + summaryObject);
        console.log("Detail Object=" + detailObject);

        this.resetFields(cmp, summaryObject, 'summary');

        //detail object is the provided object for amount fields because detail and amount object are ALWAYS the same
        this.resetFields(cmp, detailObject, 'amount');
        this.resetFields(cmp, detailObject, 'detail');

        var dateObject = activeRollup.dateObject;
        console.log("Date Object=" + dateObject);

        this.resetFields(cmp, dateObject, 'date');

        this.resetRollupTypes(cmp);
        this.setRollupType(cmp);
    },

    /* @description: resets the list of rollup types based on the selected summary object
    */
    resetRollupTypes: function (cmp) {
        var activeRollup = cmp.get("v.activeRollup");
        var summaryObject = activeRollup.summaryObject;
        var labels = cmp.get("v.labels");
        var templateList = [];
        if (summaryObject === labels.objectAccount) {
            templateList.push({
                    label: labels.labelOpportunity + ' -> ' + labels.labelAccount + ' ' + labels.hardCredit,
                    summaryObject: labels.objectAccount, name: labels.objectOpportunity
                }
                , {
                    label: labels.labelPayment + ' -> ' + labels.labelAccount + ' ' + labels.hardCredit
                    , summaryObject: labels.objectAccount, name: labels.objectPayment
                }
                , {
                    label: labels.labelOpportunity + ' -> ' + labels.labelAccount + ' ' + labels.softCredit
                    , summaryObject: labels.objectAccount, name: labels.objectPartialSoftCredit
                });
        } else if (summaryObject === labels.objectContact) {
            templateList.push({
                    label: labels.labelOpportunity + ' -> ' + labels.labelContact + ' ' + labels.hardCredit
                    , summaryObject: labels.objectContact, name: labels.objectOpportunity
                }
                , {
                    label: labels.labelOpportunity + ' -> ' + labels.labelContact + ' ' + labels.softCredit
                    , summaryObject: labels.objectContact, name: labels.objectPartialSoftCredit
                }
                , {
                    label: labels.labelPayment + ' -> ' + labels.labelContact + ' ' + labels.hardCredit
                    , summaryObject: labels.objectContact, name: labels.objectPayment
                });
        } else if (summaryObject === labels.objectGAU) {
            templateList.push({
                label: labels.labelAllocation + ' -> ' + labels.labelGAU
                , summaryObject: labels.objectGAU, name: labels.objectAllocation
            });
        } else if (summaryObject === labels.objectRD) {
            templateList.push({
                label: labels.labelOpportunity + ' -> ' + labels.labelRD
                , summaryObject: labels.objectRD, name: labels.objectOpportunity
            });
        }

        cmp.set("v.rollupTypes", templateList);
    },

    /* @description: restructures returned Apex response to preserve separate variables
    * @return: the parsed and stringified JSON
    */
    restructureResponse: function (resp) {
        return JSON.parse(JSON.stringify(resp));
    },

    /* @description: retrieves the label of an entity (field, operation, etc) based on the api name from a LIST of objects with name and label entries
    * @param apiName: the name of the field. ex: 'General_Account_Unit__c'
    * @param entityList: list of fields to search
    * @return label: field label that matches the apiName
    */
    retrieveFieldLabel: function (apiName, entityList) {
        var label;
        if (!(entityList === undefined || entityList === null)) {
            for (var i = 0; i < entityList.length; i++) {
                if (entityList[i].name === apiName) {
                    label = entityList[i].label;
                    break;
                }
            }
        }
        return label;
    },

    /* @description: saves the active rollup and sets the mode to view
    * @param activeRollup:
    */
    saveRollup: function (cmp, activeRollup) {
        // Set the mode to view while the save is running
        cmp.set("v.mode", 'view');

        this.toggleSpinner(cmp, true);

        //save record here

        var rollupCMT = {};
        rollupCMT.recordName = cmp.get("v.activeRollup.recordName");
        rollupCMT.label = cmp.get("v.activeRollup.label");
        rollupCMT.summaryObject = cmp.get("v.activeRollup.summaryObject");
        rollupCMT.summaryField = cmp.get("v.activeRollup.summaryField");
        rollupCMT.detailObject = cmp.get("v.activeRollup.detailObject");
        rollupCMT.detailField = cmp.get("v.activeRollup.detailField");
        rollupCMT.dateObject = cmp.get("v.activeRollup.dateObject");
        rollupCMT.dateField = cmp.get("v.activeRollup.dateField");
        rollupCMT.amountObject = cmp.get("v.activeRollup.amountObject");
        rollupCMT.amountField = cmp.get("v.activeRollup.amountField");
        rollupCMT.filterGroupRecordName = cmp.get("v.activeRollup.filterGroupRecordName");
        rollupCMT.description = cmp.get("v.activeRollup.description");
        rollupCMT.operation = cmp.get("v.activeRollup.operation");
        rollupCMT.timeBoundOperationType = cmp.get("v.activeRollup.timeBoundOperationType");
        rollupCMT.intValue = cmp.get("v.activeRollup.intValue");
        rollupCMT.useFiscalYear = cmp.get("v.activeRollup.useFiscalYear");
        rollupCMT.isActive = cmp.get("v.activeRollup.isActive");

        var action = cmp.get("c.saveRollup");
        action.setParams({rollupCMT: JSON.stringify(rollupCMT)});
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
                console.log('Returned DeveloperName = ' + recordName);

                cmp.set("v.activeRollup.recordName", recordName);
                if (cmp.get("v.cachedRollup") && cmp.get("v.cachedRollup.recordName")) {
                    cmp.set("v.cachedRollup.DeveloperName", recordName);
                }

                console.log('Calling pollForDeploymentStatus');
                this.pollForDeploymentStatus(cmp, jobId, recordName, 0);

            } else if (state === "ERROR") {

                var errors = response.getError();
                var msg = "Unknown error";
                if (errors && errors[0] && errors[0].message) {
                    msg = errors[0].message;
                }
                this.showToast(cmp, 'error', cmp.get("v.labels.rollupSaveFail"), msg);
                this.toggleSpinner(cmp, false);
            }
        });
        this.showToast(cmp, 'info', cmp.get("v.labels.rollupSaveProgress"), cmp.get("v.labels.rollupSaveProgress"));
        $A.enqueueAction(action);
    },

    /* @description: sets the selected rollup type based on detail and summary objects when a record is loaded
    */
    setRollupType: function (cmp) {
        console.log('IN SET ROLLUP TYPE FUNCTION.');
        var summaryObject = cmp.get("v.activeRollup.summaryObject");
        var detailObject = cmp.get("v.activeRollup.detailObject");
        var labels = cmp.get("v.labels");
        var rollupType = {};

        if (detailObject === labels.objectOpportunity && summaryObject === labels.objectAccount) {
            rollupType.name = labels.objectOpportunity;
            rollupType.summaryObject = labels.objectAccount;
            rollupType.label = labels.labelOpportunity + ' -> ' + labels.labelAccount + ' ' + labels.hardCredit;

        } else if (detailObject === labels.objectPayment && summaryObject === labels.objectAccount) {
            rollupType.name = labels.objectPayment;
            rollupType.summaryObject = labels.objectAccount;
            rollupType.label = labels.labelPayment + ' -> ' + labels.labelAccount + ' ' + labels.hardCredit;

        } else if (detailObject === labels.objectPartialSoftCredit && summaryObject === labels.objectAccount) {
            rollupType.name = labels.objectPartialSoftCredit;
            rollupType.summaryObject = labels.objectAccount;
            rollupType.label = labels.labelOpportunity + ' -> ' + labels.labelAccount + ' ' + labels.softCredit;

        } else if (detailObject === labels.objectOpportunity && summaryObject === labels.objectContact) {
            rollupType.name = labels.objectOpportunity;
            rollupType.summaryObject = labels.objectContact;
            rollupType.label = labels.labelOpportunity + ' -> ' + labels.labelContact + ' ' + labels.hardCredit;

        } else if (detailObject === labels.objectPartialSoftCredit && summaryObject === labels.objectContact) {
            rollupType.name = labels.objectPartialSoftCredit;
            rollupType.summaryObject = labels.objectContact;
            rollupType.label = labels.labelOpportunity + ' -> ' + labels.labelContact + ' ' + labels.softCredit;

        } else if (detailObject === labels.objectPayment && summaryObject === labels.objectContact) {
            rollupType.name = labels.objectPayment;
            rollupType.summaryObject = labels.objectContact;
            rollupType.label = labels.labelPayment + ' -> ' + labels.labelContact + ' ' + labels.hardCredit;

        } else if (detailObject === labels.objectAllocation && summaryObject === labels.objectGAU) {
            rollupType.name = labels.objectAllocation;
            rollupType.summaryObject = labels.objectGAU;
            rollupType.label = labels.labelAllocation + ' -> ' + labels.labelGAU;

        } else if (detailObject === labels.objectOpportunity && summaryObject === labels.objectGAU) {
            rollupType.name = labels.objectOpportunity;
            rollupType.summaryObject = labels.labelGAU;
            rollupType.label = labels.labelAllocation + ' -> ' + labels.labelGAU;

        } else if (detailObject === labels.objectOpportunity && summaryObject === labels.objectRD){
            rollupType.name = labels.objectOpportunity;
            rollupType.summaryObject = labels.objectRD;
            rollupType.label = labels.labelOpportunity + ' -> ' + labels.labelRD;
        }

        cmp.set("v.selectedRollupType", rollupType);
    },

    /* @description: creates the integer picklist for years, and is only called during setup
    */
    setIntegerYearList: function (cmp) {
        var integerList = [];
        var labels = cmp.get("v.labels");

        integerList.push({name: 0, label: labels.picklistLabelThisYear});
        integerList.push({name: 1, label: labels.picklistLabelLastYear});
        for (var i = 2; i < 21; i++) {
            var yearsAgoKey = labels['picklistLabelYearsAgo' + i];
            integerList.push({name: i, label: yearsAgoKey});
        }

        cmp.set("v.integerList", integerList);
    },

    /* @description: checks the mode to see if record's summary field needs to be added to or removed from summary field list
    *  @param newFields: list of all fields in name and label key value pairs
    *  @return: updated list of newFields
    */
    uniqueSummaryFieldCheck: function (cmp, newFields){
        var mode = cmp.get("v.mode");
        var summaryField = cmp.get("v.activeRollup.summaryField");
        if(mode === 'clone'){
            //remove if it's in the list
            for (var i = 0; i < newFields.length; i++) {
                if (newFields[i].name === summaryField) {
                    newFields.splice(i, 1);
                }
            }
        }

        return newFields
    },

    /* @description: resets allowed operations based on the summary field type
    */
    updateAllowedOperations: function (cmp) {

        //start with all operations
        var ops = cmp.get("v.operations");

        var field = cmp.get("v.activeRollup.summaryField");
        var summaryFields = cmp.get("v.summaryFields");

        var type;
        for (var i = 0; i < summaryFields.length; i++) {
            if (summaryFields[i].name === field) {
                type = summaryFields[i].type;
                break;
            }
        }

        //create lists of allowed operations
        var allowedOps = [];
        allowedOps.push({name: 'Smallest', label: ops['Smallest']});
        allowedOps.push({name: 'Largest', label: ops['Largest']});
        allowedOps.push({name: 'First', label: ops['First']});
        allowedOps.push({name: 'Last', label: ops['Last']});

        if (type === 'DOUBLE' || type === 'INTEGER' || type === 'LONG') {
            allowedOps.push({name: 'Count', label: ops['Count']});
            allowedOps.push({name: 'Sum', label: ops['Sum']});
            allowedOps.push({name: 'Average', label: ops['Average']});
            allowedOps.push({name: 'Best_Year', label: ops['Best_Year']});
            allowedOps.push({name: 'Best_Year_Total', label: ops['Best_Year_Total']});
            allowedOps.push({name: 'Donor_Streak', label: ops['Donor_Streak']});
        } else if (type === 'CURRENCY') {
            allowedOps.push({name: 'Sum', label: ops['Sum']});
            allowedOps.push({name: 'Average', label: ops['Average']});
            allowedOps.push({name: 'Best_Year', label: ops['Best_Year']});
            allowedOps.push({name: 'Best_Year_Total', label: ops['Best_Year_Total']});
        } else if (type === 'TEXT' || type === 'STRING' || type === 'TEXTAREA') {
            allowedOps.push({name: 'Best_Year', label: ops['Best_Year']});
            allowedOps.push({name: 'Years_Donated', label: ops['Years_Donated']});
        }

        cmp.set("v.allowedOperations", allowedOps);

    },

    /** 
    * @description: sets the rollup name with a simple concatenation of the summary object and summary field
    * also sends the updated name to the parent component to display as the page title
    */
    updateRollupName: function (cmp, event) {
        var summaryObjectAPI = cmp.get("v.activeRollup.summaryObject");
        var summaryObjects = cmp.get("v.summaryObjects");
        var summaryObjectName = this.retrieveFieldLabel(summaryObjectAPI, summaryObjects);

        var summaryFieldAPI = cmp.get("v.activeRollup.summaryField");
        var summaryFields = cmp.get("v.summaryFields");
        var summaryFieldName = this.retrieveFieldLabel(summaryFieldAPI, summaryFields);

        var label = summaryObjectName + ': ' + summaryFieldName;

        // shrink the label size since it's limited to 40 characters
        label = label.replace('Account', 'Acct').replace('Contact', 'Cnct').
        replace('General Accounting Unit', 'GAU').replace('Recurring Donation', 'RD').
        replace('number', 'num').replace(' of ', '').replace('count', 'cnt');

        var recordName = cmp.get("v.activeRollup.recordName");
        var masterLabel = '';
        var mode = cmp.get("v.mode");

        if(mode === 'create' && (!summaryObjectName || !summaryFieldName)){
            masterLabel = cmp.get("v.labels.rollupNew");
            cmp.set("v.activeRollup.label", masterLabel);
        } else if (mode === 'create') {
            masterLabel = "UDR: " + label;
            cmp.set("v.activeRollup.label", masterLabel);
        } else if (summaryObjectName && summaryFieldName) {
            // Only reset the name once summary object and field are selected for edit and clone modes
            // Don't add the UDR prefix if modifying a packaged rollup definition
            if (!recordName.startsWith('NPSP')) {
                masterLabel = "UDR: " + label;
            } else {
                masterLabel = label;
            }
            cmp.set("v.activeRollup.label", masterLabel);
        }
        if (masterLabel.length > 40) {
            masterLabel = masterLabel.substring(0,39);
            if (masterLabel.endsWith('_')) {
                masterLabel = masterLabel.substring(0,38);
            }
        }

        //sends the message to the parent cmp RollupsContainer
        if(masterLabel){
            var sendMessage = $A.get('e.ltng:sendMessage');
            sendMessage.setParams({
                'message': masterLabel,
                'channel': 'rollupNameChange'
            });
            sendMessage.fire();
        }
    },

    /**
     * @description Inserting or updating a CMT record is an asynchronous deployment process. This method uses the
     * unique jobId and the Rollup__mdt.DeveloperName value to recursively call an apex controller method to determine
     * when the deployment has completed (by looking in a custom settings object). If it completes, the final recordId
     * is returned. Otherwise an error message to render is returned. If the return is null, then it calls this method
     * again to wait another second an try again.
     * @param cmp Relevant Component
     * @param jobId The returns CMT deployment job id to query status for
     * @param recordName Uniqude record name value (that was just inserted/updated) to query for.
     */
    pollForDeploymentStatus : function(cmp, jobId, recordName, counter) {
        var helper=this;
        var maxPollingRetryCount = 30;
        var poller = window.setTimeout(
            $A.getCallback(function() {
                counter++;
                console.log('setTimeout(' + jobId + ',' + recordName + '):' + counter);
                var action = cmp.get("c.getDeploymentStatus");
                action.setParams({jobId: jobId, recordName: recordName});
                action.setCallback(this, function (response) {
                    console.log('getDeploymentStatus.callback');
                    var state = response.getState();
                    if (state === "SUCCESS") {
                        // Response will be a deployResult wrapper class
                        var deployResult = response.getReturnValue();
                        deployResult = helper.restructureResponse(deployResult);
                        console.log('deployResult=' + deployResult);
                        // if there is a record id response
                        if (deployResult && deployResult.completed === true && deployResult.rollupItem) {
                            window.clearTimeout(poller);
                            helper.toggleSpinner(cmp, false);
                            helper.showToast(cmp, 'success', cmp.get("v.labels.rollupSaveProgress"), cmp.get("v.labels.rollupSaveSuccess"));

                            // Save the inserted/updated record id
                            cmp.set("v.activeRollupId", deployResult.rollupItem.id);
                            cmp.set("v.activeRollup.id", deployResult.rollupItem.id);

                            // for a new record, copy the activeRollup map to the cachedRollup map
                            if (cmp.get("v.cachedRollup") && cmp.get("v.cachedRollup.recordName")) {
                                var activeRollup = cmp.get("v.activeRollup");
                                var cachedRollup = cmp.get("v.cachedRollup");
                                for (var key in activeRollup) {
                                    if (activeRollup.hasOwnProperty(key)) {
                                        cachedRollup[key] = activeRollup[key];
                                    }
                                }
                                cmp.set("v.cachedRollup", cachedRollup);
                            }

                            // Send a message with the changed or new Rollup to the RollupContainer Component
                            var sendMessage = $A.get('e.ltng:sendMessage');
                            sendMessage.setParams({
                                'message': deployResult.rollupItem,
                                'channel': 'rollupRecordChange'
                            });
                            sendMessage.fire();

                        } else {
                            // No record id, so run call this method again to check in another 1 second
                            if (counter < maxPollingRetryCount) {
                                helper.pollForDeploymentStatus(cmp, jobId, recordName, counter);
                            } else {
                                // When the counter hits the max, need to give the tell the user what happened
                                this.showToast(cmp, 'info', cmp.get("v.labels.rollupSaveProgress"), cmp.get("v.labels.rollupSaveTimeout"));
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
                        helper.showToast(cmp, 'error', cmp.get("v.labels.rollupSaveFail"), msg);
                        window.clearTimeout(poller);
                        helper.toggleSpinner(cmp, false);
                    }
                });
                $A.enqueueAction(action);
            }), (1000 + (maxPollingRetryCount*50)) /* query every 1 second with a small multiplier */
        );
    },

    /**
     * @description Show a message on the screen
     * @param cmp Relevant Component
     * @param type - error, success, info
     * @param title - message title
     * @param message - message to display
     */
    showToast : function(cmp, type, title, message) {
        console.log(message);
        cmp.set("v.notificationClasses", "notification-" + type);
        cmp.set("v.notificationMessage", message);
        // TODO Get Toasts to work or replace with something better
        /*var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            "type":type,
            "title": title,
            "message": message
        });
        toastEvent.fire();*/
    },

    /**
     * @description Show or Hide the page spinner
     * @param cmp
     * @param showSpinner - true to show; false to hide
     */
    toggleSpinner : function(cmp, showSpinner) {
        var spinner = cmp.find("waitingSpinner");
        if (showSpinner === true) {
            $A.util.removeClass(spinner, "slds-hide");
        } else {
            $A.util.addClass(spinner, "slds-hide");
        }
    },

    /**
    * @description: verifies all required fields have been populated before saving the component
    * @return: if cmp can be saved
    */
    validateFields: function(cmp){
        //todo: find any other combinations that may be missing before validating on save
        var canSave = true;
        var description = cmp.get("v.activeRollup.description");

        if(!description){
            cmp.find("descriptionInput").showHelpMessageIfInvalid();
            canSave = false;
        }

        return canSave;
    },

    /** 
    * @description: disables save button if a detail field is required for a single result operation and detail field or rollup type isn't selected
    * @param detailField: selected detail field API name
    */
    verifyRollupSaveActive: function(cmp, detailField){
        console.log('in on change save active');
        var renderMap = cmp.get("v.renderMap");
        var selectedRollup = cmp.get("v.selectedRollupType");

        if (selectedRollup.label) {
            if (!renderMap["detailField"]) {
                //if detail field isn't required, save button enables
                cmp.set("v.isIncomplete", false);
            } else if (detailField) {
                //if detail field is required, save button enables only if detail field is selected
                cmp.set("v.isIncomplete", false);
            } else {
                cmp.set("v.isIncomplete", true);
            }
        } else {
            cmp.set("v.isIncomplete", true);
        }
    }
})