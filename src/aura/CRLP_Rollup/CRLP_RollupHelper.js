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
            var summaryObjects = [{label: labels.accountLabel, name: 'Account'}
                , {label: labels.contactLabel, name: 'Contact'}
                , {label: labels.gauLabel, name: 'General_Accounting_Unit__c'}];
            var availableObjects = detailObjects.concat(summaryObjects);

            cmp.set("v.detailObjects", detailObjects);
            cmp.set("v.summaryObjects", summaryObjects);

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

                    console.log('Before calling reset details');
                    //need to reset fields to populate the selected objects -- refactor to see if necessary
                    //fields can be lazy loaded if user is creating a new rollup
                    //setup is first called here instead of in change mode to ensure active rollup information is returned from the server
                    if (cmp.get("v.mode") !== 'create') {
                        this.onChangeYearlyOperationsOptions(cmp, false);
                        this.updateAllowedOperations(cmp);
                        this.onChangeOperation(cmp);
                        this.resetRollupTypes(cmp);
                        this.setRollupType(cmp);
                        this.resetAllFields(cmp);
                    } else {
                        cmp.set("v.activeRollup.Active__c", true);
                    }

                    //update filter group list to contain none as a first option
                    //note: unshift can't be used here due to an issue with bound values
                    var filterGroups = cmp.get("v.filterGroups");
                    var tempList = [{"name": '', "label": cmp.get("v.labels.na")}];
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

    changeMode: function(cmp){
        //we check to see if mode is null since the change handler is called when mode is cleared in the container
        var mode = cmp.get("v.mode");
        console.log(mode);
        if(mode !== null) {
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

    filterFieldsByType: function(cmp, typeList, allFields) {
        //if type is null, no detail field is selected
        console.log("filter fields by type function");
        var newFields = [];

        typeList.forEach(function(type) {
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

    filterDetailFieldsBySummaryField: function (cmp, detailObject) {
        //filters possible detail fields by summary type and updates the detailFields attribute
        //current version filters strictly; update will include type conversion fields
        var summaryField = cmp.get("v.activeRollup.Summary_Field__r.QualifiedApiName");

        //need to get all detail fields, or we filter on a subset of all options
        var allFields = cmp.get("v.objectDetails")[detailObject];
        var newFields = [];

        console.log(detailObject);

        //loop over all summary fields to get the type of selected field
        var summaryFields = cmp.get("v.summaryFields");
        console.log(summaryFields);
        var type;
        for (var i = 0; i < summaryFields.length; i++) {
            if (summaryFields[i].name === summaryField) {
                type = summaryFields[i].type;
                break;
            }
        }
        //TODO: maybe check if type is the same to see if need to filter?
        console.log("Type is " + type);
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

    hideAllFields: function(cmp){
        //hides all fields but the summary view with the renderMap var to walk user through a create rollup flow
        var renderMap = cmp.get("v.renderMap");
        for (var key in renderMap) {
            renderMap[key] = false;
        }
        cmp.set("v.renderMap", renderMap);
    },

    onChangeSummaryObject: function (cmp, summaryObject, label) {
        console.log("hitting onChangeSummaryObjectHelper");

        //set new summary fields based on new selected summary object
        //var summaryObject = cmp.get("v.activeRollup.Summary_Object__r.QualifiedApiName");
        this.resetFields(cmp, summaryObject, 'summary');
        cmp.set("v.activeRollup.Summary_Field__r.QualifiedApiName", null);
        cmp.set("v.activeRollup.Summary_Object__r.Label", label);
        //cmp.set("v.activeRollup.Detail_Field__r.QualifiedApiName", null);
        //cmp.set("v.activeRollup.Amount_Field__r.QualifiedApiName", null);
        //cmp.set("v.activeRollup.Date_Field__r.QualifiedApiName", null);
        cmp.set("v.activeRollup.MasterLabel", null);

        this.resetRollupTypes(cmp);

        //reset amount fields to match detail
        //TODO: reset entity label
        /**var objLabel;
         var detailObjects = cmp.get("v.detailObjects");

         for(var i=0; i<detailObjects.length; i++){
                if(detailObjects[i].name === object){
                    objLabel = detailObjects[i].label;
                    break;
                }
            }**/

        //change detail object labels to correctly show selected detail object in amount field
        //cmp.set("v.activeRollup.Detail_Object__r.Label", objLabel);

        //filter and reset amount fields
        //this.resetFields(cmp, cmp.get("v.activeRollup.Detail_Object__r.QualifiedApiName"), "amount");

    },

    onChangeDetailField: function(cmp, detailField, label){
        //enables save button if detailField is not null
        if(detailField !== ''){
            cmp.set("v.isIncomplete", false);
        } else {
            cmp.set("v.isIncomplete", true);
        }

        cmp.set("v.activeRollup.Detail_Field__r.Label", label);
    },

    onChangeFilterGroup: function(cmp, label){
        //todo: not working yet
        cmp.set("v.activeRollup.Filter_Group__r.MasterLabel", label);
    },

    onChangeInteger: function (cmp) {
        //stores the selected years back integer value to be used when the page is in view mode
        var selectedInteger = cmp.get("v.activeRollup.Integer__c");
        var integerList = cmp.get("v.integerList");
        var label = this.retrieveFieldLabel(selectedInteger, integerList);
        cmp.set("v.selectedIntegerLabel", label);
    },

    onChangeOperation: function (cmp, operation) {
        //conditionally renders the yearly operation, use fiscal year, amount, date and detail fields
        console.log("in helper onChangeOperation");
        console.log('operation: ' + operation);
        var renderMap = cmp.get("v.renderMap");
        console.log(renderMap);

        //AMOUNT, DATE & DETAIL FIELD RENDERING
        renderMap = this.renderAmountField(cmp, operation, renderMap);
        renderMap = this.renderDateField(cmp, operation, renderMap);
        renderMap = this.renderDetailField(cmp, operation, renderMap);
        renderMap = this.renderFiscalYear(cmp, renderMap);

        if (operation !== '' && operation !== 'Donor_Streak' && operation !== 'Years_Donated') {
            renderMap["timeBoundOperation"] = true;
            var timeOperation = cmp.get("v.activeRollup.Yearly_Operation_Type__c");
        } else {
            renderMap["timeBoundOperation"] = false;
        }

        cmp.set("v.renderMap", renderMap);

        //set selected operation label to be available in view mode
        var operations = cmp.get("v.operations");
        var label = operations[operation];
        cmp.set("v.selectedOperationLabel", label);

        //disables save button if a detail field is required for a single result operation and detail field or operation isn't selected
        var detailField = cmp.get("v.activeRollup.Detail_Field__r.QualifiedApiName");
        if(operation !== ''){
            if(!renderMap["detailField"]){
                //if detail field isn't required, save button enables
                cmp.set("v.isIncomplete", false);
            } else if(detailField !== '' && detailField !== null){
                //if detail field is required, save button enables only if detail field is selected
                cmp.set("v.isIncomplete", false);
            } else {
                cmp.set("v.isIncomplete", true);
            }
        } else {
            cmp.set("v.isIncomplete", true);
        }

    },

    onChangeRollupType: function (cmp, detailObject, rollupLabel) {
        //renders filter group and operation
        //resets fields for the amount, detail and date fields based on the detail object
        var renderMap = cmp.get("v.renderMap");
        renderMap["filterGroup"] = true;
        renderMap["operation"] = true;
        cmp.set("v.renderMap", renderMap);

        //set detail object label explicitly since detail obj name is bound to rollup type field, but the label is not
        //var detailObject = cmp.get("v.activeRollup.Detail_Object__r.QualifiedApiName");
        var detailObjects = cmp.get("v.detailObjects");
        var detailLabel = this.retrieveFieldLabel(detailObject, detailObjects);
        cmp.set("v.activeRollup.Detail_Object__r.Label", detailLabel);
        //todo: not working yet
        cmp.set("v.selectedRollupType", {label: rollupLabel, name: detailObject});

        //reset amount fields
        this.resetFields(cmp, detailObject, 'amount');

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

        //reset detail fields by summary type
        //this.resetFields(cmp, detailObject, 'detail');
        this.filterDetailFieldsBySummaryField(cmp, detailObject);

    },

    onChangeSummaryField: function(cmp, label) {
        //renders rollupType field, filters allowed operations by field type
        //sets default rollup type for list of 1, sets concatenated rollup name
        var renderMap = cmp.get("v.renderMap");
        renderMap["rollupType"] = true;
        renderMap["description"] = true;
        cmp.set("v.renderMap", renderMap);

        var rollupTypes = cmp.get("v.rollupTypes");
        //sets rollup type automatically if there is only 1
        if(rollupTypes.length === 1){
            cmp.set("v.activeRollup.Detail_Object__r.QualifiedApiName", rollupTypes[0].name);
            cmp.set("v.selectedRollupType", {label: rollupTypes[0].label, name: rollupTypes[0].name});
            this.onChangeRollupType(cmp, rollupTypes[0].name, rollupTypes[0].label);
        }

        this.updateAllowedOperations(cmp);
        this.updateRollupName(cmp);
        cmp.set("v.activeRollup.Summary_Field__r.Label", label);
    },

    onChangeYearlyOperationsOptions: function(cmp, isOnChange){
        //fires when yearly operations options is changed or when set up
        //the isOnChange value is a boolean to determine if this is fired during a change (true) or during setup (false)
        console.log("in helper changeYearlyOperationsOptions");
        var operation = cmp.get("v.activeRollup.Yearly_Operation_Type__c");
        var renderMap = cmp.get("v.renderMap");
        if (operation === 'All_Time') {
            //disable fiscal year, disable integer, and reset values
            renderMap = this.renderFiscalYear(cmp, renderMap);
            renderMap["integerDays"] = false;
            renderMap["integerYears"] = false;
            if (isOnChange) {
                cmp.set("v.activeRollup.Use_Fiscal_Year__c", cmp.get("v.cachedRollup.Use_Fiscal_Year__c"));
                cmp.set("v.activeRollup.Integer__c", cmp.get("v.cachedRollup.Integer__c"));
            }
        } else if (operation === 'Years_Ago') {
            //enable fiscal year and integerYears
            renderMap = this.renderFiscalYear(cmp, renderMap);
            renderMap["integerDays"] = false;
            renderMap["integerYears"] = true;
            this.setIntegerYearList(cmp, 'Years_Ago');
            //set a default integer of 0
            if (isOnChange) {
                cmp.set("v.activeRollup.Integer__c", 0);
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
            }
        }
        //check to display or clear the dateField for Years_Ago or Days_Back
        renderMap = this.renderDateField(cmp, operation, renderMap);

        cmp.set("v.renderMap", renderMap);

        //set selected operation to be available in view mode
        var yearlyOperations = cmp.get("v.yearlyOperations");
        var label = this.retrieveFieldLabel(operation, yearlyOperations);
        cmp.set("v.selectedYearlyOperationLabel", label);
    },

    renderAmountField: function(cmp, operation, renderMap){
        //conditionally render amount field based on the selected operation
        //returns updated renderMap
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
            if(cmp.get("v.activeRollup.Detail_Object__r.QualifiedApiName") === 'npe01__OppPayment__c'){
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

    renderDateField: function(cmp, operation, renderMap){
        //conditionally render date field based on the selected operation
        //this function also checks for yearly operations
        //returns updated renderMap
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

    renderDetailField: function(cmp, operation, renderMap){
        //conditionally render detail field based on the selected operation
        //detail is intended for use with Single Result Operations
        //returns updated renderMap
        if(operation === 'First'
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

    renderFiscalYear: function (cmp, renderMap) {
        //conditionally render fiscal year checkbox based on the selected operation and yearly operation
        //both operations are retrieved instead of passed since only 1 would be available
        //returns updated renderMap
        var operation = cmp.get("v.activeRollup.Operation__c");
        var yearlyOperation = cmp.get("v.activeRollup.Yearly_Operation_Type__c");

        if (operation === 'Donor_Streak'
            || operation === 'Years_Donated'
            || operation === 'Best_Year'
            || operation === 'Best_Year_Total'
            || yearlyOperation === 'Years_Ago') {
            //enable fiscal year
            renderMap["fiscalYear"] = true;
        } else {
            //disable detail field and and clear values
            renderMap["fiscalYear"] = false;
            cmp.set("v.activeRollup.Use_Fiscal_Year__c", cmp.get("v.cachedRollup.Use_Fiscal_Year__c"));
        }

        return renderMap;

    },

    resetFields: function(cmp, object, context){

        console.log("Fired field reset for context ["+context+"] and object ["+object+"]");
        var newFields = cmp.get("v.objectDetails")[object];

        //console.log('new fields: '+newFields);

        if(newFields === undefined){
            newFields = [{name: 'None', label: cmp.get("v.labels.noFields")}];
        }

        if (context === 'detail'){
            cmp.set("v.detailFields", newFields);
        } else if (context === 'summary') {
            console.log('assigning summary fields');
            cmp.set("v.summaryFields", newFields);
            console.log('summary fields: '+cmp.get("v.summaryFields"));
        } else if (context === 'date') {
            newFields = this.filterFieldsByType(cmp, ["DATE"], newFields);
            cmp.set("v.dateFields", newFields);
        } else if (context === 'amount') {
            newFields = this.filterFieldsByType(cmp, ["DOUBLE", "CURRENCY"], newFields);
            cmp.set("v.amountFields", newFields);
        }
    },

    resetAllFields: function(cmp){
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

    resetRollupTypes: function(cmp){

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
        }

        cmp.set("v.rollupTypes", templateList);
    },

    restructureResponse: function(resp){
        return JSON.parse(JSON.stringify(resp));
    },

    retrieveFieldLabel: function(apiName, entityList){
        //retrieves the label of an entity (field, operation, etc) based on the api name from a LIST of objects with name and label entries
        //apiName is the name of the field. ex: 'General_Account_Unit__c'
        //label is translatable label of the entity. ex: 'General Account Unit'
        var label;
        for(var i=0; i<entityList.length; i++){
            if(entityList[i].name === apiName){
                label = entityList[i].label;
                break;
            }
        }
        return label;
    },

    saveRollup: function(cmp, activeRollup){

    },

    setRollupType: function(cmp){
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
        }

        cmp.set("v.selectedRollupType", rollupType);
        console.log(cmp.get("v.selectedRollupType"));
    },

    setIntegerYearList: function(cmp){
        var integerList = [];
        var timeLabel = cmp.get("v.selectedYearlyOperationLabel");

        integerList.push({name: 0, label: 'This Year'});
        integerList.push({name: 1, label: 'Last Year'});
        for(var i=2; i<21; i++) {
            integerList.push({name: i, label: i + ' Years Ago'});
        }

        cmp.set("v.integerList", integerList);
    },

    updateAllowedOperations: function(cmp){

        //start with all operations
        var ops = cmp.get("v.operations");
        console.log(JSON.stringify(ops));

        var field = cmp.get("v.activeRollup.Summary_Field__r.QualifiedApiName");
        var summaryFields = cmp.get("v.summaryFields");

        var type;
        for (var i = 0; i < summaryFields.length; i++) {
            if (summaryFields[i].name === field) {
                type = summaryFields[i].type;
                break;
            }
        }
        console.log(type);

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

        console.log(JSON.stringify(allowedOps));

        cmp.set("v.allowedOperations", allowedOps);

    },

    updateRollupName: function(cmp){
        //sets the rollup name with a simple concatenation of the summary object and summary field
        //todo: can't get this to bubble up to the main page, probably due to the dot notation
        var summaryObjectAPI = cmp.get("v.activeRollup.Summary_Object__r.QualifiedApiName");
        var summaryObjects = cmp.get("v.summaryObjects");
        var summaryObjectName = this.retrieveFieldLabel(summaryObjectAPI, summaryObjects);

        var summaryFieldAPI = cmp.get("v.activeRollup.Summary_Field__r.QualifiedApiName");
        var summaryFields = cmp.get("v.summaryFields");
        var summaryFieldName = this.retrieveFieldLabel(summaryFieldAPI, summaryFields);

        var label = summaryObjectName + ': ' + summaryFieldName;

        cmp.set("v.activeRollup.MasterLabel", label);
    }
})