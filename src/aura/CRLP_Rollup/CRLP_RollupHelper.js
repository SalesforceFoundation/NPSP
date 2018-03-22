({
    setObjectAndFieldDependencies: function (cmp) {
        console.log("In setObjectAndFieldDependencies");

        //set list of objects and get data type for all
        //todo: is this check still necessary?
        if ($A.util.isEmpty(cmp.get("v.objectDetails"))) {

            console.log("In the helper function");
            var labels = cmp.get("v.labels");
            var detailObjects = [{label: labels.opportunityLabel, name: 'Opportunity'}
                , {label: labels.partialSoftCreditLabel, name: 'Partial_Soft_Credit__c'}
                , {label: labels.paymentLabel, name: 'npe01__OppPayment__c'}
                , {label: labels.allocationLabel, name: 'Allocation__c'}];
            var summaryObjects = cmp.get("v.summaryObjects");
            var availableObjects = detailObjects.concat(summaryObjects);

            cmp.set("v.detailObjects", detailObjects);

            //put only the object names into a list
            var objectList = availableObjects.map(function (obj, index, array) {
                return obj.name;
            });

            var action = cmp.get("c.getFieldsByDataType");
            action.setParams({objectNames: objectList});

            action.setCallback(this, function (response) {
                var state = response.getState();
                console.log('STATE' + state);
                if (state === "SUCCESS") {
                    console.log('RESPONSE: ' + response.getReturnValue());
                    var data = response.getReturnValue();
                    cmp.set("v.objectDetails", data);
                    this.setIntegerYearList(cmp);

                    console.log('Before calling reset details');
                    //need to reset fields to populate the selected objects -- refactor to see if necessary
                    //fields can be lazy loaded if user is creating a new rollup
                    //setup is first called here instead of in change mode to ensure active rollup information is returned from the server
                    if (cmp.get("v.mode") !== 'create') {
                        this.fieldSetup(cmp);
                    } else {
                        //set active default as true
                        cmp.set("v.activeRollup.Active__c", true);
                        // check for a summary object filter to see if summary fields need to be set
                        var summaryObject = cmp.get("v.activeRollup.Summary_Object__r.QualifiedApiName");
                        var summaryObjects = cmp.get("v.summaryObjects");
                        var label = this.retrieveFieldLabel(summaryObject, summaryObjects);

                        if(summaryObject != undefined){
                            this.onChangeSummaryObject(cmp, summaryObject, label);
                        }
                        this.hideAllFields(cmp);
                    }

                    //update filter group list to contain none as a first option
                    //note: unshift can't be used here due to an issue with bound values
                    var filterGroups = cmp.get("v.filterGroups");
                    var tempList = [{"name": cmp.get("v.labels.na"), "label": cmp.get("v.labels.na")}];
                    tempList = tempList.concat(filterGroups);
                    cmp.set("v.filterGroups", tempList);

                    console.log('Called reset details');
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
            console.log('about to make the callback');
            $A.enqueueAction(action);
        }
    },

    changeMode: function (cmp) {
        //we check to see if mode is null since the change handler is called when mode is cleared in the container
        var mode = cmp.get("v.mode");
        console.log(mode);
        if (mode !== null) {
            console.log("Mode is " + mode);
            console.log("In changeMode");

            //View is the only readOnly mode. Clone removes the activeRollupId for save.
            //Create hides all fields and sets isIncomplete to disable the save button.
            if (mode === "view") {
                cmp.set("v.isReadOnly", true);
            } else if (mode === "clone") {
                cmp.set("v.activeRollupId", null);
                cmp.set("v.isReadOnly", false);
            } else if (mode === "edit") {
                cmp.set("v.isReadOnly", false);
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
        this.onChangeYearlyOperationsOptions(cmp, false);
        this.onChangeInteger(cmp, cmp.get("v.activeRollup.Integer__c"));
        this.updateAllowedOperations(cmp);
        this.onChangeOperation(cmp, cmp.get("v.activeRollup.Operation__c"));
        this.resetRollupTypes(cmp);
        this.setRollupType(cmp);
    },

    /* @description: filters a picklist of fields by their type
    * @typeList: list of types to match
    * @allFields: list of mapped fields to their type to filter
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
    * @detailObject: currently selected detail object
    */
    filterDetailFieldsBySummaryField: function (cmp, detailObject) {
        //current version filters strictly; update will include type conversion fields
        var summaryField = cmp.get("v.activeRollup.Summary_Field__r.QualifiedApiName");

        //need to get all detail fields, or we filter on a subset of all options
        var allFields = cmp.get("v.objectDetails")[detailObject];
        var newFields = [];

        //loop over all summary fields to get the type of selected field
        var summaryFields = cmp.get("v.summaryFields");
        var type;
        for (var i = 0; i < summaryFields.length; i++) {
            if (summaryFields[i].name === summaryField) {
                type = summaryFields[i].type;
                break;
            }
        }
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
            newFields = [{name: 'None', label: cmp.get("v.labels.noFields")}];
            cmp.set("v.detailFields", newFields);
        }
        //reset detail field to null to prompt user selection
        cmp.set("v.activeRollup.Detail_Field__r.QualifiedApiName", null);
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
    * @summaryObject: summaryObject API name
    * @label: summaryObject API label
    */
    onChangeSummaryObject: function (cmp, summaryObject, label) {
        console.log("hitting onChangeSummaryObjectHelper");

        this.resetFields(cmp, summaryObject, 'summary');
        cmp.set("v.activeRollup.Summary_Field__r.QualifiedApiName", null);
        cmp.set("v.activeRollup.Summary_Object__r.Label", label);
        cmp.set("v.activeRollup.Description__c", null);
        cmp.set("v.activeRollup.Detail_Object__r.QualifiedApiName", null);
        cmp.set("v.activeRollup.Detail_Field__r.QualifiedApiName", null);
        cmp.set("v.activeRollup.Amount_Field__r.QualifiedApiName", null);
        cmp.set("v.activeRollup.Date_Field__r.QualifiedApiName", null);

        this.resetRollupTypes(cmp);

        this.onChangeSummaryField(cmp, '');
    },

    /* @description: sets the detail field label and determines if save button may illuminate since detail field is required if visible
    */
    onChangeDetailField: function (cmp, detailField, label) {
        if (detailField !== '') {
            cmp.set("v.isIncomplete", false);
        } else {
            cmp.set("v.isIncomplete", true);
        }
        cmp.set("v.activeRollup.Detail_Field__r.Label", label);
    },

    /* @description: sets the filter group master label when the filter group is changed
    * @label: filter group label
    */
    onChangeFilterGroup: function (cmp, label) {
        cmp.set("v.activeRollup.Filter_Group__r.MasterLabel", label);
    },

    /* @description: stores the selected years back integer value for years to be used when the page is in view mode
    * @value: integer value
    */
    onChangeInteger: function (cmp, value) {
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

    /* @description: conditionally renders the yearly operation, use fiscal year, amount, date and detail fields
    * @operation: operation API name
    */
    onChangeOperation: function (cmp, operation) {
        console.log("in helper onChangeOperation");
        var renderMap = cmp.get("v.renderMap");

        //AMOUNT, DATE & DETAIL FIELD RENDERING
        renderMap = this.renderAmountField(cmp, operation, renderMap);
        renderMap = this.renderDateField(cmp, operation, renderMap);
        renderMap = this.renderDetailField(cmp, operation, renderMap);
        renderMap = this.renderFiscalYear(cmp, renderMap);

        //TIME BOUND OPERATION RENDERING
        if (operation !== '' && operation !== 'Donor_Streak' && operation !== 'Years_Donated') {
            renderMap["timeBoundOperation"] = true;
            var timeOperation = cmp.get("v.activeRollup.Yearly_Operation_Type__c");
        } else {
            renderMap["timeBoundOperation"] = false;
            cmp.set(("v.activeRollup.Yearly_Operation_Type__c"), 'All_Time');
            var timeBoundLabel = this.retrieveFieldLabel('All_Time', cmp.get("v.yearlyOperations"));
            cmp.set("v.selectedYearlyOperationLabel", timeBoundLabel);
            renderMap["integerDays"] = false;
            renderMap["integerYears"] = false;
        }

        cmp.set("v.renderMap", renderMap);

        //set selected operation label to be available in view mode
        var operations = cmp.get("v.operations");
        var label = operations[operation];
        cmp.set("v.selectedOperationLabel", label);

        //disables save button if a detail field is required for a single result operation and detail field or operation isn't selected
        var detailField = cmp.get("v.activeRollup.Detail_Field__r.QualifiedApiName");
        if (operation !== '') {
            if (!renderMap["detailField"]) {
                //if detail field isn't required, save button enables
                cmp.set("v.isIncomplete", false);
            } else if (detailField !== '' && detailField !== null) {
                //if detail field is required, save button enables only if detail field is selected
                cmp.set("v.isIncomplete", false);
            } else {
                cmp.set("v.isIncomplete", true);
            }
        } else {
            cmp.set("v.isIncomplete", true);
        }

    },

    /* @description: renders filter group and operation, resets fields for the amount, detail and date fields based on the detail object
    * @detailObject: detail object API name stored as the name on the rollupType attribute
    * @rollupLabel: rollup type label
    */
    onChangeRollupType: function (cmp, detailObject, rollupLabel) {
        var renderMap = cmp.get("v.renderMap");
        //during create, visibility of operation and filter group are toggled
        if(cmp.get("v.mode") === "create"){
            if (rollupLabel !== '') {
                renderMap["filterGroup"] = true;
                renderMap["operation"] = true;
                cmp.set("v.renderMap", renderMap);
                this.filterDetailFieldsBySummaryField(cmp, detailObject);
            } else {
                renderMap["operation"] = false;
                renderMap["filterGroup"] = false;
            }
            //always reset operation and filter group when rollup is changed during create
            cmp.set("v.renderMap", renderMap);
            cmp.set("v.activeRollup.Operation__c", '');
            this.onChangeOperation(cmp, '');
            var na = cmp.get("v.labels.na");
            cmp.set("v.activeRollup.Filter_Group__r.QualifiedApiName", na);
            this.onChangeFilterGroup(cmp, na);
        }

        //set detail object label explicitly since detail obj name is bound to rollup type field, but the label is not
        var detailObjects = cmp.get("v.detailObjects");
        var detailLabel = this.retrieveFieldLabel(detailObject, detailObjects);
        cmp.set("v.activeRollup.Detail_Object__r.Label", detailLabel);
        cmp.set("v.selectedRollupType", {label: rollupLabel, name: detailObject});

        //reset amount fields
        this.resetFields(cmp, detailObject, 'amount');
        console.log("after resetting amount");

        //reset date fields
        //set date object label and api name based on the selected detail object then reset fields + selected value
        //defaults field to Payment on the payment object, and CloseDate for everything else
        if (detailObject === 'npe01__OppPayment__c') {
            cmp.set("v.activeRollup.Date_Object__r.Label", cmp.get("v.labels.paymentLabel"));
            cmp.set("v.activeRollup.Date_Object__r.QualifiedApiName", "npe01__OppPayment__c");
            this.resetFields(cmp, cmp.get("v.activeRollup.Date_Object__r.QualifiedApiName"), "date");
            cmp.set("v.activeRollup.Date_Field__r.QualifiedApiName", "npe01__Payment_Date__c");
        } else {
            cmp.set("v.activeRollup.Date_Object__r.Label", cmp.get("v.labels.opportunityLabel"));
            cmp.set("v.activeRollup.Date_Object__r.QualifiedApiName", "Opportunity");
            this.resetFields(cmp, cmp.get("v.activeRollup.Date_Object__r.QualifiedApiName"), "date");
            cmp.set("v.activeRollup.Date_Field__r.QualifiedApiName", "CloseDate");
        }

    },

    /* @description: renders rollupType field, filters allowed operations by field type when summary field changes
    * @label: summary field label
    */
    onChangeSummaryField: function (cmp, label) {
        //toggle rendering for create flow
        if(cmp.get("v.mode") === 'create'){
            var renderMap = cmp.get("v.renderMap");
            if(label !== ''){
                renderMap["rollupType"] = true;
                renderMap["description"] = true;
            } else{
                renderMap["rollupType"] = false;
                renderMap["description"] = false;
            }
            cmp.set("v.renderMap", renderMap);
        }

        //sets rollup type automatically if there is only 1
        var rollupTypes = cmp.get("v.rollupTypes");
        if (rollupTypes.length === 1 && label !== '') {
            cmp.set("v.activeRollup.Detail_Object__r.QualifiedApiName", rollupTypes[0].name);
            cmp.set("v.selectedRollupType", {label: rollupTypes[0].label, name: rollupTypes[0].name});
            this.onChangeRollupType(cmp, rollupTypes[0].name, rollupTypes[0].label);
        } else {
            cmp.set("v.selectedRollupType", {name: '', label: ''});
            cmp.set("v.activeRollup.Detail_Object__r.QualifiedApiName", '');
            this.onChangeRollupType(cmp, '', '');
        }

        //reset operation if selected operation isn't in the list
        this.updateAllowedOperations(cmp);
        var operationLabel = this.retrieveFieldLabel(cmp.get("v.activeRollup.Operation__c"), cmp.get("v.allowedOperations"));
        if(operationLabel === undefined || label === ''){
            cmp.set("v.activeRollup.Operation__c", '');
            this.onChangeOperation(cmp, '');
        }

        this.updateRollupName(cmp);
        cmp.set("v.activeRollup.Summary_Field__r.Label", label);
    },

    /* @description: fires when yearly operations options is changed or when set up
    * @isOnChange: determines if this is fired during a change (true) or during setup (false)
    * @label: yearly operations label
    */
    onChangeYearlyOperationsOptions: function (cmp, isOnChange, label) {
        console.log("in helper changeYearlyOperationsOptions");
        var operation = cmp.get("v.activeRollup.Time_Bound_Operation_Type__c");
        var renderMap = cmp.get("v.renderMap");
        if (operation === 'All_Time') {
            //disable fiscal year, disable integer, and reset values
            renderMap = this.renderFiscalYear(cmp, renderMap);
            renderMap["integerDays"] = false;
            renderMap["integerYears"] = false;
            if (isOnChange) {
                cmp.set("v.activeRollup.Use_Fiscal_Year__c", cmp.get("v.cachedRollup.Use_Fiscal_Year__c"));
                cmp.set("v.activeRollup.Integer__c", cmp.get("v.cachedRollup.Integer__c"));
                this.onChangeInteger(cmp, 0);
            }
        } else if (operation === 'Years_Ago') {
            //enable fiscal year and integerYears
            renderMap = this.renderFiscalYear(cmp, renderMap);
            renderMap["integerDays"] = false;
            renderMap["integerYears"] = true;
            //set a default integer of 0
            if (isOnChange) {
                cmp.set("v.activeRollup.Integer__c", 0);
                this.onChangeInteger(cmp, 0);
            }
        } else if (operation === 'Days_Back') {
            //disable fiscal year and enable integerDays
            renderMap = this.renderFiscalYear(cmp, renderMap);
            renderMap["integerDays"] = true;
            renderMap["integerYears"] = false;
            //set a default integer of 0 and the default fiscal year
            if (isOnChange) {
                cmp.set("v.activeRollup.Use_Fiscal_Year__c", cmp.get("v.cachedRollup.Use_Fiscal_Year__c"));
                cmp.set("v.activeRollup.Integer__c", 0);
                this.onChangeInteger(cmp, 0);
            }
        } else {
            //default to not showing these fields and reset values
            //took this out because some operations (not time bound operations) require fiscal year checkbox
            //renderMap["fiscalYear"] = false;
            renderMap["integerDays"] = false;
            renderMap["integerYears"] = false;
            if (isOnChange) {
                cmp.set("v.activeRollup.Use_Fiscal_Year__c", cmp.get("v.cachedRollup.Use_Fiscal_Year__c"));
                cmp.set("v.activeRollup.Integer__c", cmp.get("v.cachedRollup.Integer__c"));
                this.onChangeInteger(cmp, 0);
            }
        }
        //check to display or clear the dateField for Years_Ago or Days_Back
        renderMap = this.renderDateField(cmp, operation, renderMap);

        cmp.set("v.renderMap", renderMap);

        //set selected operation to be available in view mode
        var yearlyOperations = cmp.get("v.yearlyOperations");
        if(label === undefined){
            var label = this.retrieveFieldLabel(operation, yearlyOperations);
        }
        cmp.set("v.selectedYearlyOperationLabel", label);
    },

    /* @description: conditionally render amount field based on the selected operation
    * @operation: operation API name
    * @renderMap: current map of fields to render
    * @return: updated render map
    */
    renderAmountField: function (cmp, operation, renderMap) {
        if (operation === 'Largest'
            || operation === 'Smallest'
            || operation === 'Best_Year'
            || operation === 'Best_Year_Total'
            || operation === 'Sum'
            || operation === 'Count'
            || operation === 'Average') {
            //enable amount field
            renderMap["amountField"] = true;

            //set the default amount field based on the selected detail object
            if (cmp.get("v.activeRollup.Detail_Object__r.QualifiedApiName") === 'npe01__OppPayment__c') {
                cmp.set("v.activeRollup.Amount_Field__r.QualifiedApiName", 'npe01__Payment_Amount__c');
            } else {
                cmp.set("v.activeRollup.Amount_Field__r.QualifiedApiName", 'Amount');
            }
        } else {
            //disable amount field and clear values
            renderMap["amountField"] = false;
            cmp.set("v.activeRollup.Amount_Field__r.Label", cmp.get("v.labels.na"));
            cmp.set("v.activeRollup.Amount_Field__r.QualifiedApiName", null);
        }
        return renderMap;
    },

    /* @description: conditionally render date field based on the selected operation and yearly operations
    * @operation: operation API name
    * @renderMap: current map of fields to render
    * @return: updated render map
    */
    renderDateField: function (cmp, operation, renderMap) {
        if (operation === 'First'
            || operation === 'Last'
            || operation === 'Years_Ago'
            || operation === 'Days_Back') {
            //enable date field and set defaults based on the dateObject, which is set from the rollup type
            var dateObject = cmp.get("v.activeRollup.Date_Object__r.QualifiedApiName");
            if (dateObject === 'npe01__OppPayment__c') {
                cmp.set("v.activeRollup.Date_Field__r.QualifiedApiName", "npe01__Payment_Date__c");
            } else {
                cmp.set("v.activeRollup.Date_Field__r.QualifiedApiName", "CloseDate");
            }
            //enable date field
            renderMap["dateField"] = true;
        } else {
            //disable date field and clear values
            renderMap["dateField"] = false;
            cmp.set("v.activeRollup.Date_Field__r.Label", cmp.get("v.labels.na"));
            cmp.set("v.activeRollup.Date_Field__r.QualifiedApiName", null);
        }

        return renderMap;
    },

    /* @description: conditionally render detail field based on the selected operation, specifically Single Result Operations
    * @operation: operation API name
    * @renderMap: current map of fields to render
    * @return: updated render map
    */
    renderDetailField: function (cmp, operation, renderMap) {
        if (operation === 'First'
            || operation === 'Last'
            || operation === 'Smallest'
            || operation === 'Largest') {
            //enable detail field
            renderMap["detailField"] = true;
        } else {
            //disable detail field and and clear values
            renderMap["detailField"] = false;
            cmp.set("v.activeRollup.Detail_Field__r.Label", cmp.get("v.labels.na"));
            cmp.set("v.activeRollup.Detail_Field__r.QualifiedApiName", null);
        }

        return renderMap;

    },

    /* @description: conditionally render fiscal year checkbox based on the selected operation and yearly operation
    * note that both operations are retrieved instead of passed since only 1 would be available
    * @renderMap: current map of fields to render
    * @return: updated render map
    */
    renderFiscalYear: function (cmp, renderMap) {
        var operation = cmp.get("v.activeRollup.Operation__c");
        var yearlyOperation = cmp.get("v.activeRollup.Yearly_Operation_Type__c");

        if ((operation === 'Donor_Streak'
            || operation === 'Years_Donated'
            || operation === 'Best_Year'
            || operation === 'Best_Year_Total'
            || yearlyOperation === 'Years_Ago')
            && operation != '') {
            //enable fiscal year
            renderMap["fiscalYear"] = true;
        } else {
            //disable detail field and and clear values
            renderMap["fiscalYear"] = false;
            cmp.set("v.activeRollup.Use_Fiscal_Year__c", cmp.get("v.cachedRollup.Use_Fiscal_Year__c"));
        }

        return renderMap;

    },

    /* @description: resets fields based on the selected object and context
    * @object: corresponding object to the fields
    * @context: which fields to reset. values are: detail, summary, date, and amount
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

        var summaryObject = cmp.get("v.activeRollup.Summary_Object__r.QualifiedApiName");
        var detailObject = cmp.get("v.activeRollup.Detail_Object__r.QualifiedApiName");

        this.resetFields(cmp, summaryObject, 'summary');

        //detail object is the provided object for amount fields because detail and amount object are ALWAYS the same
        this.resetFields(cmp, detailObject, 'amount');
        this.resetFields(cmp, detailObject, 'detail');

        var dateObject = cmp.get("v.activeRollup.Date_Object__r.QualifiedApiName");
        this.resetFields(cmp, dateObject, 'date');
    },

    /* @description: resets the list of rollup types based on the selected summary object
    */
    resetRollupTypes: function (cmp) {
        var summaryObject = cmp.get("v.activeRollup.Summary_Object__r.QualifiedApiName");
        var labels = cmp.get("v.labels");
        var templateList = [];
        if (summaryObject === 'Account') {
            templateList.push({
                    label: labels.opportunityLabel + ' -> ' + labels.accountLabel + ' ' + labels.hardCredit,
                    summaryObject: 'Account', name: 'Opportunity'
                }
                , {
                    label: labels.paymentLabel + ' -> ' + labels.accountLabel + ' ' + labels.hardCredit
                    , summaryObject: 'Account', name: 'npe01__OppPayment__c'
                }
                , {
                    label: labels.opportunityLabel + ' -> ' + labels.accountLabel + ' ' + labels.softCredit
                    , summaryObject: 'Account', name: 'Partial_Soft_Credit__c'
                });
        } else if (summaryObject === 'Contact') {
            templateList.push({
                    label: labels.opportunityLabel + ' -> ' + labels.contactLabel + ' ' + labels.hardCredit
                    , summaryObject: 'Contact', name: 'Opportunity'
                }
                , {
                    label: labels.opportunityLabel + ' -> ' + labels.contactLabel + ' ' + labels.softCredit
                    , summaryObject: 'Contact', name: 'Partial_Soft_Credit__c'
                }
                , {
                    label: labels.paymentLabel + ' -> ' + labels.contactLabel + ' ' + labels.hardCredit
                    , summaryObject: 'Contact', name: 'npe01__OppPayment__c'
                });
        } else if (summaryObject === 'General_Accounting_Unit__c') {
            templateList.push({
                label: labels.allocationLabel + ' -> ' + labels.gauLabel
                , summaryObject: 'General_Accounting_Unit__c', name: 'Allocation__c'
            });
        } else if (summaryObject === 'npe03__Recurring_Donation__c') {
            templateList.push({
                label: labels.opportunityLabel + ' -> ' + labels.rdLabel
                , summaryObject: 'npe03__Recurring_Donation__c', name: 'Opportunity'
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
    * @apiName: the name of the field. ex: 'General_Account_Unit__c'
    * @entityList: list of fields to search
    * @label: field label that matches the apiName
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

    /*
    * @description: saves the active rollup and sets the mode to view
    * @param: activeRollup
    */
    saveRollup: function (cmp, activeRollup) {
        // Set the mode to view while the save is running
        cmp.set("v.mode", 'view');

        this.toggleSpinner(cmp, true);

        //save record here

        var rollupCMT = {};
        rollupCMT.recordName = cmp.get("v.activeRollup.DeveloperName");
        rollupCMT.label = cmp.get("v.activeRollup.MasterLabel");
        rollupCMT.summaryObject = cmp.get("v.activeRollup.Summary_Object__r.QualifiedApiName");
        rollupCMT.summaryField = cmp.get("v.activeRollup.Summary_Field__r.QualifiedApiName");
        rollupCMT.detailObject = cmp.get("v.activeRollup.Detail_Object__r.QualifiedApiName");
        rollupCMT.detailField = cmp.get("v.activeRollup.Detail_Field__r.QualifiedApiName");
        rollupCMT.dateObject = cmp.get("v.activeRollup.Date_Object__r.QualifiedApiName");
        rollupCMT.dateField = cmp.get("v.activeRollup.Date_Field__r.QualifiedApiName");
        rollupCMT.amountObject = cmp.get("v.activeRollup.Amount_Object__r.QualifiedApiName");
        rollupCMT.amountField = cmp.get("v.activeRollup.Amount_Field__r.QualifiedApiName");
        rollupCMT.filterGroupRecordName = cmp.get("v.activeRollup.Filter_Group__r.QualifiedApiName");
        rollupCMT.description = cmp.get("v.activeRollup.Description__c");
        rollupCMT.operation = cmp.get("v.activeRollup.Operation__c");
        rollupCMT.timeBoundOperationType = cmp.get("v.activeRollup.Time_Bound_Operation_Type__c");
        rollupCMT.intValue = cmp.get("v.activeRollup.Integer__c");
        rollupCMT.useFiscalYear = cmp.get("v.activeRollup.Use_Fiscal_Year__c");
        rollupCMT.isActive = cmp.get("v.activeRollup.Active__c");

        var action = cmp.get("c.saveRollup");
        action.setParams({rollupCMT: JSON.stringify(rollupCMT)});
        action.setCallback(this, function (response) {
            var state = response.getState();
            console.log('STATE=' + state);
            if (state === "SUCCESS") {
                var responseText = response.getReturnValue();
                // Response value will be one of the following
                // - JobId-RecordDeveloperName
                // - ERROR: Error Message
                if (responseText.startsWith("ERROR")) {
                    this.showToast(cmp, 'error', cmp.get("v.labels.saveFail"), responseText);
                    this.toggleSpinner(cmp, false);
                } else {
                    var jobId = responseText.split("-")[0];
                    var recordName = responseText.split("-")[1];

                    console.log('Response = ' + response.getReturnValue());
                    console.log('Returned jobId = ' + jobId);
                    console.log('Returned DeveloperName = ' + recordName);

                    console.log('Calling pollForDeploymentStatus');
                    this.pollForDeploymentStatus(cmp, jobId, recordName, 0);
                }
            } else if (state === "ERROR") {
                var errors = response.getError();
                var msg = "Unknown error";
                if (errors && errors[0] && errors[0].message) {
                    msg = errors[0].message;
                }
                this.showToast(cmp, 'error', cmp.get("v.labels.saveFail"), msg);
                this.toggleSpinner(cmp, false);
            }
        });
        this.showToast(cmp, 'info', cmp.get("v.labels.savingMessage"), cmp.get("v.labels.savingMessage"));
        $A.enqueueAction(action);
    },

    /* @description: sets the selected rollup type based on detail and summary objects when a record is loaded
    */
    setRollupType: function (cmp) {
        console.log('IN SET ROLLUP TYPE FUNCTION.');
        var summaryObject = cmp.get("v.activeRollup.Summary_Object__r.QualifiedApiName");
        var detailObject = cmp.get("v.activeRollup.Detail_Object__r.QualifiedApiName");
        var labels = cmp.get("v.labels");
        var rollupType = {};

        if (detailObject === 'Opportunity' && summaryObject === 'Account') {
            rollupType.name = 'Opportunity';
            rollupType.summaryObject = 'Account';
            rollupType.label = labels.opportunityLabel + ' -> ' + labels.accountLabel + ' ' + labels.hardCredit;

        } else if (detailObject === 'npe01__OppPayment__c' && summaryObject === 'Account') {
            rollupType.name = 'npe01__OppPayment__c';
            rollupType.summaryObject = 'Account';
            rollupType.label = labels.paymentLabel + ' -> ' + labels.accountLabel + ' ' + labels.hardCredit;

        } else if (detailObject === 'Partial_Soft_Credit__c' && summaryObject === 'Account') {
            rollupType.name = 'Partial_Soft_Credit__c';
            rollupType.summaryObject = 'Account';
            rollupType.label = labels.opportunityLabel + ' -> ' + labels.accountLabel + ' ' + labels.softCredit;

        } else if (detailObject === 'Opportunity' && summaryObject === 'Contact') {
            rollupType.name = 'Opportunity';
            rollupType.summaryObject = 'Contact';
            rollupType.label = labels.opportunityLabel + ' -> ' + labels.contactLabel + ' ' + labels.hardCredit;

        } else if (detailObject === 'Partial_Soft_Credit__c' && summaryObject === 'Contact') {
            rollupType.name = 'Partial_Soft_Credit__c';
            rollupType.summaryObject = 'Contact';
            rollupType.label = labels.opportunityLabel + ' -> ' + labels.contactLabel + ' ' + labels.softCredit;

        } else if (detailObject === 'npe01__OppPayment__c' && summaryObject === 'Contact') {
            rollupType.name = 'npe01__OppPayment__c';
            rollupType.summaryObject = 'Contact';
            rollupType.label = labels.paymentLabel + ' -> ' + labels.contactLabel + ' ' + labels.hardCredit;

        } else if (detailObject === 'Allocation__c' && summaryObject === 'General_Accounting_Unit__c') {
            rollupType.name = 'Allocation__c';
            rollupType.summaryObject = 'General_Accounting_Unit__c';
            rollupType.label = labels.allocationLabel + ' -> ' + labels.gauLabel;

        } else if (detailObject === 'Opportunity' && summaryObject === 'General_Accounting_Unit__c') {
            rollupType.name = 'Opportunity';
            rollupType.summaryObject = 'General_Accounting_Unit__c';
            rollupType.label = labels.allocationLabel + ' -> ' + labels.gauLabel;
        } else if (detailObject === 'Opportunity' && summaryObject === 'npe03__Recurring_Donation__c'){
            rollupType.name = 'Opportunity';
            rollupType.summaryObject = 'npe03__Recurring_Donation__c';
            rollupType.label = labels.opportunityLabel + ' -> ' + labels.rdLabel;
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

    /* @description: resets allowed operations based on the summary field type
    */
    updateAllowedOperations: function (cmp) {

        //start with all operations
        var ops = cmp.get("v.operations");

        var field = cmp.get("v.activeRollup.Summary_Field__r.QualifiedApiName");
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

    /* @description: sets the rollup name with a simple concatenation of the summary object and summary field
    * also sends the updated name to the parent component to display as the page title
    */
    updateRollupName: function (cmp, event) {
        var summaryObjectAPI = cmp.get("v.activeRollup.Summary_Object__r.QualifiedApiName");
        var summaryObjects = cmp.get("v.summaryObjects");
        var summaryObjectName = this.retrieveFieldLabel(summaryObjectAPI, summaryObjects);

        var summaryFieldAPI = cmp.get("v.activeRollup.Summary_Field__r.QualifiedApiName");
        var summaryFields = cmp.get("v.summaryFields");
        var summaryFieldName = this.retrieveFieldLabel(summaryFieldAPI, summaryFields);

        var label = summaryObjectName + ': ' + summaryFieldName;
        var masterLabel = '';
        var mode = cmp.get("v.mode");

        if(mode === 'create' && (summaryObjectName === undefined || summaryFieldName === undefined )){
            masterLabel = cmp.get("v.labels.rollupNew");
            cmp.set("v.activeRollup.MasterLabel", masterLabel);
        } else if (mode === 'create') {
            // masterLabel = cmp.get("v.labels.rollupNew") + ' - ' + label;
            masterLabel = "UDR: " + label;
            cmp.set("v.activeRollup.MasterLabel", masterLabel);
        } else if (summaryObjectName !== undefined && summaryFieldName !== undefined ) {
            //only reset the name once summary object and field are selected for edit and clone modes
            // masterLabel = label;
            masterLabel = "UDR: " + label;
            cmp.set("v.activeRollup.MasterLabel", masterLabel);
        }

        //sends the message to the parent cmp RollupsContainer
        if(masterLabel !== ''){
            var sendMessage = $A.get('e.ltng:sendMessage');
            sendMessage.setParams({
                'message': masterLabel,
                'channel': 'rollupNameChange'
            });
            sendMessage.fire();
        }
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
     * @description
     * @param cmp Relevant Component
     * @param jobId The returns CMT deployment job id to query status for
     * @param recordName Uniqude record name value (that was just inserted/updated) to query for.
     */
    pollForDeploymentStatus : function(cmp, jobId, recordName, counter) {
        var helper=this;
        var maxPollingCount = 15;
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
                        var recordId = response.getReturnValue();
                        console.log('recordId=' + recordId);
                        // if there is a record id response
                        if (recordId !== undefined && recordId !== null) {
                            cmp.set("v.activeRollupId", recordId);
                            helper.getRollupRecord(cmp, recordId);
                            window.clearTimeout(poller);
                            helper.toggleSpinner(cmp, false);
                            this.showToast(cmp, 'success', cmp.get("v.labels.savingMessage"), cmp.get("v.labels.saveSuccess"));
                        } else {
                            // No record id, so run this again
                            if (counter < maxPollingCount) {
                                console.log('Calling pollForDeploymentStatus again');
                                helper.pollForDeploymentStatus(cmp, jobId, recordName, counter);
                            } else {
                                console.log('Stop Polling Action');
                            }
                        }
                    } else {
                        var errors = response.getError();
                        var msg = "Unknown error";
                        if (errors && errors[0] && errors[0].message) {
                            msg = errors[0].message;
                        }
                        helper.showToast(cmp, 'error', cmp.get("v.labels.saveFail"), msg);
                        window.clearTimeout(poller);
                        helper.toggleSpinner(cmp, false);
                    }
                });
                $A.enqueueAction(action);
            }), (1000 + (maxPollingCount*10)) /* query every 1 second with a small multiplier */
        );
    },

    /**
     * @description Retrieve the specified Rollup__mdt record using the record Id and initialize the page components
     * with the data
     * @param cmp Component
     * @param helper This helper controller
     * @param recordId Rollup__mdt.Id
     */
    getRollupRecord : function(cmp, helper, recordId) {
        //retrieve full active rollup information only if ID is passed to the component in view, edit or clone mode
        if (recordId !== null) {
            this.toggleSpinner(cmp, true);
            var action = cmp.get("c.getRollupById");
            action.setParams({id: recordId});
            action.setCallback(this, function (response) {
                var state = response.getState();
                if (state === "SUCCESS") {
                    //note: the duplicate parsing is important to avoid a shared reference
                    cmp.set("v.activeRollup", this.restructureResponse(response.getReturnValue()));
                    cmp.set("v.cachedRollup", this.restructureResponse(response.getReturnValue()));

                    //change mode needs to be fired here because the sibling change of mode isn't being registered
                    //TODO: review this since sibling isn't being used now
                    helper.changeMode(cmp);

                } else if (state === "ERROR") {
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
                helper.toggleSpinner(cmp, false);
            });

            $A.enqueueAction(action);

        } else {
            // creating a new Rollup
        }

        this.setObjectAndFieldDependencies(cmp);
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
    }

})