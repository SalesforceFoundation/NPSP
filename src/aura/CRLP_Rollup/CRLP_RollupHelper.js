({
    setObjectAndFieldDependencies: function(cmp) {
        console.log("In setObjectAndFieldDependencies");

        //set list of objects and get data type for all
        if($A.util.isEmpty(cmp.get("v.objectDetails"))) {

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

            //cmp.set("v.detailObjects", detailObjects);
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

                    //this.resetSummaryObjects(cmp, cmp.get("v.activeRollup.Detail_Object__r.QualifiedApiName"));

                    console.log('Before calling reset details');
                    //need to reset fields to populate the selected objects
                    this.resetAllFields(cmp);

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

            //for create we don't need to set anything yet since mode will be changed to clone before viewing page
            if(mode !== "create") {
                //check operations to appropriately set "N/A" for date/amount field values
                this.updateDependentOperations(cmp);
                this.changeYearlyOperationsOptions(cmp, false);

                //set readonly fields if mode is View, else allow user to make changes
                if (mode === "view") {
                    cmp.set("v.isReadOnly", true);
                } else {
                    cmp.set("v.isReadOnly", false);
                    //this.resetSummaryObjects(cmp, cmp.get("v.activeRollup.Detail_Object__r.QualifiedApiName"));
                    if (!$A.util.isEmpty(cmp.get("v.objectDetails"))) {
                        this.resetAllFields(cmp);
                    }
                }
                if(mode === "clone"){
                    cmp.set("v.activeRollupId", null);
                }
            } else {
                cmp.set("v.isIncomplete",true);
                cmp.set("v.isReadOnly", false);
            }
        }
    },

    //NEW ONE FEB 22
    onChangeSummaryObjectHelper: function(cmp) {
        //TODO: do we need this mode check?
        if(cmp.get("v.mode") !== 'view') {
            console.log("hitting onChangeSummaryObjectHelper");

            //TODO: set available summary fields based on selected summary object


            //set new summary objects based on selected value
            var object = cmp.get("v.activeRollup.Detail_Object__r.QualifiedApiName");
            console.log('object: ' + object);
            //this.resetSummaryObjects(cmp, object);

            //set new detail fields based on new selected detail object
            this.resetFields(cmp, object, 'detail');
            cmp.set("v.activeRollup.Detail_Field__r.QualifiedApiName", null);
            cmp.set("v.activeRollup.Amount_Field__r.QualifiedApiName", null);
            cmp.set("v.activeRollup.Date_Field__r.QualifiedApiName", null);

            //remove summary fields since no summary object is selected
            var newFields = [{name: 'None', label: cmp.get("v.labels.noFields")}];
            cmp.set("v.summaryFields", newFields);
            console.log("reset summary fields");

            //reset amount fields to match detail
            //TODO: reset entity label
            var objLabel;
            var detailObjects = cmp.get("v.detailObjects");

            for(var i=0; i<detailObjects.length; i++){
                if(detailObjects[i].name === object){
                    objLabel = detailObjects[i].label;
                    break;
                }
            }

            //change detail object labels to correctly show selected detail object in amount field
            cmp.set("v.activeRollup.Detail_Object__r.Label", objLabel);

            //filter and reset amount fields
            helper.resetFields(cmp, cmp.get("v.activeRollup.Detail_Object__r.QualifiedApiName"), "amount");

            //set date object label and api name based on the selected detail object then reset fields + selected value
            if(object === 'npe01__OppPayment__c'){
                cmp.set("v.activeRollup.Date_Object__r.Label", cmp.get("v.labels.paymentLabel"));
                cmp.set("v.activeRollup.Date_Object__r.QualifiedApiName", "npe01__OppPayment__c");
            } else {
                cmp.set("v.activeRollup.Date_Object__r.Label", cmp.get("v.labels.opportunityLabel"));
                cmp.set("v.activeRollup.Date_Object__r.QualifiedApiName", "Opportunity");
            }
            helper.resetFields(cmp, cmp.get("v.activeRollup.Date_Object__r.QualifiedApiName"), "date");
        }
    },

    updateDependentOperations: function(cmp){
        console.log("in helper changeOperationsOptions");
        var operation = cmp.get("v.activeRollup.Operation__c");
        console.log(operation);
        var renderMap = cmp.get("v.renderMap");
        console.log(renderMap);
        //todo: is this ok for translation?
        if (operation === 'Largest'
            || operation === 'Smallest'
            || operation === 'Best_Year'
            || operation === 'Best_Year_Total'
            || operation === 'Sum'
            || operation === 'Average') {
            //enable amount field
            renderMap["amount"] = true;
        } else if (operation === 'First'
            || operation === 'Last'
            || operation === 'Years_Donated'
            || operation === 'Donor_Streak'
            || operation === 'Count'
            || operation === null) {
            //disable amount field
            renderMap["amount"] = false;
            cmp.set("v.activeRollup.Amount_Field__r.Label", cmp.get("v.labels.na"));
            cmp.set("v.activeRollup.Amount_Field__r.QualifiedApiName", null);
        }
        cmp.set("v.renderMap",renderMap);

        var operations = cmp.get("v.operations");
        var label = this.resetOperationFieldLabel(cmp, operation, operations);
        cmp.set("v.selectedOperationLabel",label);

    },

    updateAllowedOperations: function(cmp){

        //start with all operations
        var ops = cmp.get("v.operations");
        console.log(ops);

        var field = cmp.get("v.activeRollup.Summary_Field__r.QualifiedApiName");

        var summaryFields = cmp.get("v.summaryFields");
        console.log(summaryFields);
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

        if (type === 'NUMBER') {
            allowedOps.push({name: 'Count', label: ops['Count']});
            allowedOps.push({name: 'Sum', label: ops['Sum']});
            allowedOps.push({name: 'Average', label: ops['Average']});
            allowedOps.push({name: 'Best_Year', label: ops['Best_Year']});
            allowedOps.push({name: 'Best_Year_Total', label: ops['Best_Year_Total']});
            allowedOps.push({name: 'Current_Streak', label: ops['Current_Streak']});
            allowedOps.push({name: 'Donor_Streak', label: ops['Donor_Streak']});
        } else if (type === 'CURRENCY'){
            allowedOps.push({name: 'Sum', label: ops['Sum']});
            allowedOps.push({name: 'Average', label: ops['Average']});
            allowedOps.push({name: 'Best_Year', label: ops['Best_Year']});
            allowedOps.push({name: 'Best_Year_Total', label: ops['Best_Year_Total']});
        } else if (type === 'TEXT') {
            allowedOps.push({name: 'Best_Year', label: ops['Best_Year']});
            allowedOps.push({name: 'Years_Donated', label: ops['Years_Donated']});
        }

        cmp.set("v.allowedOperations", allowedOps);

    },

    changeYearlyOperationsOptions: function(cmp, isOnChange){
        console.log("in helper changeYearlyOperationsOptions");
        var operation = cmp.get("v.activeRollup.Yearly_Operation_Type__c");
        var renderMap = cmp.get("v.renderMap");
        if (operation === 'All_Time') {
            //disable fiscal year and integer and reset values
            renderMap["useFiscalYear"] = false;
            renderMap["integer"] = false;
            if(isOnChange){
                cmp.set("v.activeRollup.Use_Fiscal_Year__c", cmp.get("v.cachedRollup.Use_Fiscal_Year__c"));
                cmp.set("v.activeRollup.Integer__c", cmp.get("v.cachedRollup.Integer__c"));
            }
        } else if (operation === 'Years_Ago') {
            //enable fiscal year and integer
            renderMap["useFiscalYear"] = true;
            renderMap["integer"] = true;
        } else if (operation === 'Days_Back') {
            //disable fiscal year and enable integer
            renderMap["useFiscalYear"] = false;
            renderMap["integer"] = true;
            if(isOnChange){
                cmp.set("v.activeRollup.Use_Fiscal_Year__c", cmp.get("v.cachedRollup.Use_Fiscal_Year__c"));
            }
        } else {
            //default to not showing these fields and reset values
            renderMap["useFiscalYear"] = false;
            renderMap["integer"] = false;
            if(isOnChange){
                cmp.set("v.activeRollup.Use_Fiscal_Year__c", cmp.get("v.cachedRollup.Use_Fiscal_Year__c"));
                cmp.set("v.activeRollup.Integer__c", cmp.get("v.cachedRollup.Integer__c"));
            }
        }
        cmp.set("v.renderMap",renderMap);

        var yearlyOperations = cmp.get("v.yearlyOperations");
        var label = this.resetOperationFieldLabel(cmp, operation, yearlyOperations);
        cmp.set("v.selectedYearlyOperationLabel",label);
    },

    /*resetSummaryObjects: function(cmp, detailObject){
        //todo: add if Necesary check?
        console.log('Fired summary object reset');
        console.log('TEST');
        var labels = cmp.get("v.labels");
        var newSummaryObjects;
        console.log("detail object is " + detailObject);
        //only set if object is selected, otherwise prompt for user to select a detail object
        if(detailObject === "Allocation__c"){
            newSummaryObjects = [{label: labels.gauLabel, name:'General_Accounting_Unit__c'}];
        } else if(detailObject === "npe01__OppPayment__c" || detailObject === "Partial_Soft_Credit__c"
            || detailObject === "Opportunity") {
            newSummaryObjects = [{label: labels.accountLabel, name: 'Account'}
                , {label: labels.contactLabel, name: 'Contact'}];
        } else {
            //todo: add a better label
            newSummaryObjects = [{name: 'None', label: cmp.get("v.labels.noObjects")}];
        }
        console.log(newSummaryObjects);
        cmp.set("v.summaryObjects", newSummaryObjects);
        console.log("End summary object reset");
    },
*/
    resetFields: function(cmp, object, context){

        console.log("Fired field reset for context ["+context+"] and object ["+object+"]");
        var newFields = cmp.get("v.objectDetails")[object];

        console.log('new fields: '+newFields);

        if(newFields === undefined){
            newFields = [{name: 'None', label: cmp.get("v.labels.noFields")}];
        }

        if(context === 'detail'){
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

        var detailObject = cmp.get("v.activeRollup.Detail_Object__r.QualifiedApiName");
        this.resetFields(cmp, detailObject, 'detail');

        var summaryObject = cmp.get("v.activeRollup.Summary_Object__r.QualifiedApiName");
        this.resetFields(cmp, summaryObject, 'summary');

        //detail object is the provided object for amount fields because detail and amount object are ALWAYS the same
        this.resetFields(cmp, detailObject, 'amount');

        var dateObject = cmp.get("v.activeRollup.Date_Object__r.QualifiedApiName");
        this.resetFields(cmp, dateObject, 'date');
    },
    filterFieldsByType: function(cmp, typeList, allFields) {
        //if type is null, no detail field is selected
        console.log("filter fields by type function");
        var newFields = [];

        typeList.forEach(function(type){
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

    filterSummaryFieldsByDetailField: function(cmp, detailField, summaryObject){

        //need to get all summary fields, or we filter on a subset of all options
        var allFields = cmp.get("v.objectDetails")[summaryObject];
        var newFields = [];

        console.log(summaryObject);

        //checks if summary field is set
        if(allFields !== undefined) {

            //loop over all detail fields to get the type of selected field
            var detailFields = cmp.get("v.detailFields");
            console.log(detailFields);
            var type;
            for (var i = 0; i < detailFields.length; i++) {
                if (detailFields[i].name === detailField) {
                    type = detailFields[i].type;
                    break;
                }
            }
            //TODO: maybe check if type is the same to see if need to filter?
            console.log("Type is " + type);
            //if type is undefined, return all fields
            if(type === undefined){
                newFields = allFields;
            } else {
                newFields = this.filterFieldsByType(cmp, [type], allFields);
            }

            if (newFields.length > 0) {
                cmp.set("v.summaryFields", newFields);
            } else {
                //TODO: get/set better label messaging
                newFields = [{name: 'None', label: cmp.get("v.labels.noFields")}];
                cmp.set("v.summaryFields", newFields);
            }
        } else {
            newFields = [{name: 'None', label: cmp.get("v.labels.noFields")}];
            cmp.set("v.summaryFields", newFields);
        }
        //reset field to null regardless of summary object value
        cmp.set("v.activeRollup.Summary_Field__r.QualifiedApiName",null);
    },

    resetOperationFieldLabel: function(cmp, operation, operationList){
        var label;
        for(var i=0; i<operationList.length; i++){
            if(operationList[i].name === operation){
                label = operationList[i].label;
                break;
            }
        }
        return label;
    },
    saveRollup: function(cmp, activeRollup){

    }
})