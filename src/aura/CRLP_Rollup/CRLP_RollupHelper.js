({
    setObjectAndFieldDependencies: function(cmp) {
        //set list of objects and get data type for all
        console.log('is objDetails empty?? '+$A.util.isEmpty(cmp.get("v.objectDetails")));
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

            cmp.set("v.detailObjects", detailObjects);
            cmp.set("v.summaryObjects", summaryObjects);

            //put only the object names into a list
            var objectList = availableObjects.map(function(obj, index, array) {
                return obj.name;
            });

            var action = cmp.get("c.getFieldsByDataType");
            action.setParams({objectNames: objectList});
            console.log('obj list: '+objectList);

            action.setCallback(this, function (response) {
                var state = response.getState();
                console.log('STATE'+state);
                if (state === "SUCCESS") {
                    console.log('RESPONSE: '+response.getReturnValue());
                    var response = response.getReturnValue();
                    cmp.set("v.objectDetails", response);

                    this.resetSummaryObjects(cmp, cmp.get("v.activeRollup.Detail_Object__r.QualifiedApiName"));

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
        if(mode != null) {
            console.log("Mode is " + mode);
            console.log("In changeMode");

            //check operations to appropriately set "N/A" for date/amount field values
            this.changeOperationsOptions(cmp);
            this.changeYearlyOperationsOptions(cmp);

            //set readonly fields if mode is View, else allow user to make changes
            if(mode != "view"){
                cmp.set("v.isReadOnly",false);
                this.resetSummaryObjects(cmp,cmp.get("v.activeRollup.Detail_Object__r.QualifiedApiName"));
                if(!$A.util.isEmpty(cmp.get("v.objectDetails"))){
                    this.resetAllFields(cmp);
                }
            } else {
                cmp.set("v.isReadOnly", true);
                this.resetAllOperationsOptions(cmp);
            }
            //this checks that fields are set; this action only needs to be done once per rollup
            if($A.util.isEmpty(cmp.get("v.objectDetails"))){
                console.log("before set object field dependencies");
                this.setObjectAndFieldDependencies(cmp);
            }
        }
    },

    changeOperationsOptions: function(cmp){

        var operation = cmp.get("v.activeRollup.Operation__c");
        console.log(operation);
        var readOnlyMap = cmp.get("v.readOnlyMap");
        console.log(readOnlyMap);
        //todo: is this ok for translation?
        if (operation == 'Largest'
            || operation == 'Smallest'
            || operation == 'Best_Year'
            || operation == 'Best_Year_Total'
            || operation == 'Sum'
            || operation == 'Average') {
            //enable amount object and fields
            readOnlyMap["amount"] = false;
        } else if (operation == 'First'
            || operation == 'Last'
            || operation == 'Years_Donated'
            || operation == 'Donor_Streak'
            || operation == 'Count') {
            //disable amount object and fields
            readOnlyMap["amount"] = true;
            cmp.set("v.activeRollup.Amount_Field__r.Label", cmp.get("v.labels.na"));
            cmp.set("v.activeRollup.Amount_Field__r.QualifiedApiName", null);
        }
        cmp.set("v.readOnlyMap",readOnlyMap);

        var operations = cmp.get("v.operations");
        var label = this.resetOperationFieldLabel(cmp, operation, operations);
        cmp.set("v.selectedOperationLabel",label);

    },

    changeYearlyOperationsOptions: function(cmp){
        console.log("in helper changeYearlyOperationsOptions");
        var operation = cmp.get("v.activeRollup.Yearly_Operation_Type__c");
        var readOnlyMap = cmp.get("v.readOnlyMap");
        //todo: is this ok for translation?
        if (operation == 'All_Time') {
            //disable fiscal year and integer
            readOnlyMap["useFiscalYear"] = true;
            readOnlyMap["integer"] = true;
            readOnlyMap["dateField"] = true;
            cmp.set("v.activeRollup.Date_Field__r.Label",cmp.get("v.labels.na"));
            cmp.set("v.activeRollup.Date_Field__r.QualifiedApiName", null);
        } else if (operation == 'Years_Ago') {
            //enable fiscal year and integer
            readOnlyMap["useFiscalYear"] = false;
            readOnlyMap["integer"] = false;
            readOnlyMap["dateField"] = false;
        } else if (operation == 'Days_Back') {
            //disable fiscal year and enable integer
            readOnlyMap["useFiscalYear"] = true;
            readOnlyMap["integer"] = false;
            readOnlyMap["dateField"] = false;
        }
        cmp.set("v.readOnlyMap",readOnlyMap);

        var yearlyOperations = cmp.get("v.yearlyOperations");
        var label = this.resetOperationFieldLabel(cmp, operation, yearlyOperations);
        cmp.set("v.selectedYearlyOperationLabel",label);
    },

    resetSummaryObjects: function(cmp, detailObject){
        //todo: add if Necesary check?
        console.log('Fired summary object reset');
        console.log('TEST');
        var labels = cmp.get("v.labels");
        var newSummaryObjects;
        console.log("detail object is " + detailObject);
        //only set if object is selected, otherwise prompt for user to select a detail object
        if(detailObject == "Allocation__c"){
            newSummaryObjects = [{label: labels.gauLabel, name:'General_Accounting_Unit__c'}];
        } else if(detailObject == "npe01__OppPayment__c" || detailObject == "Partial_Soft_Credit__c"
            || detailObject == "Opportunity") {
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

    resetFields: function(cmp, object, context){

        console.log("Fired field reset for context: "+context);
        var test = cmp.get("v.objectDetails");
        var newFields = cmp.get("v.objectDetails")[object];

        if(newFields === undefined){
            newFields = [{name: 'None', label: cmp.get("v.labels.noFields")}];
        }

        if(context=='detail'){
            cmp.set("v.detailFields", newFields);
        } else if (context=='summary') {
            cmp.set("v.summaryFields", newFields);
        } else if (context=='date') {
            newFields = this.filterFieldsByType(cmp, ["DATE"], newFields);
            cmp.set("v.dateFields", newFields);
        } else if (context=='amount') {
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
            if (!(type == undefined || type == null)) {
                allFields.forEach(function (field) {
                    var datatype = field.type;
                    if (datatype == type) {
                        newFields.push(field);
                    }
                });
            }
        });
        console.log("newFields");
        console.log(newFields);
        return newFields;
    },
    filterSummaryFieldsByDetailField: function(cmp, detailField, summaryObject){

        //need to get all summary fields, or we filter on a subset of all options
        var allFields = cmp.get("v.objectDetails")[summaryObject];
        var newFields = [];

        console.log(summaryObject);

        //checks if summary field is set
        if(allFields != undefined) {

            //loop over all detail fields to get the type of selected field
            var detailFields = cmp.get("v.detailFields");
            console.log(detailFields);
            var type;
            for (var i = 0; i < detailFields.length; i++) {
                if (detailFields[i].name == detailField) {
                    type = detailFields[i].type;
                    break;
                }
            }
            //TODO: maybe check if type is the same to see if need to filter?
            console.log("Type is " + type);
            if(type == undefined){
                newFields = allFields;
            } else {
                newFields = this.filterFieldsByType(cmp, [type], allFields);
            }

            console.log("new fields returned");
            console.log(newFields);

            if (newFields.length > 0) {
                cmp.set("v.summaryFields", newFields);
            } else {
                //TODO: get/set better label messaging; this would need tooltip help
                //var na = cmp.get("v.labels.na");
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
    resetRollup: function(cmp) {

        //TODO: refactor this: consider caching rolllup, and review what is necessary
        var activeRollupId = cmp.get("v.activeRollup.Id");
        var action = cmp.get("c.getRollupById");
        action.setParams({id: activeRollupId});

        action.setCallback(this, function (response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var response = response.getReturnValue();
                cmp.set("v.activeRollup", response);
                var activeRollupMap = cmp.get("v.activeRollup");

                //need to reset all fields to match the selected objects
                this.resetAllFields(cmp);

                //this converts values to a user-friendly format
                //todo: determine if necessary and how to do this so that the selected value of the lightning select tags work
                if (!$A.util.isUndefined(cmp.get("v.activeRollup.Yearly_Operation_Type__c"))) {
                    //cmp.set("v.activeRollup.Yearly_Operation_Type__c", cmp.get("v.activeRollup.Yearly_Operation_Type__c").replace(/_/g, ' '));
                }
                if (!$A.util.isUndefined(cmp.get("v.activeRollup.Operation__c"))) {
                    //cmp.set("v.activeRollup.Operation__c", cmp.get("v.activeRollup.Operation__c").replace(/_/g, ' '));
                }

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

    resetAllOperationsOptions: function(cmp){
        console.log("In reset all operations");
        var readOnlyMap = cmp.get("v.readOnlyMap");
        readOnlyMap["useFiscalYear"] = true;
        readOnlyMap["integer"] = true;
        readOnlyMap["amount"] = true;
        readOnlyMap["dateField"] = true;
        cmp.set("v.readOnlyMap",readOnlyMap);
        console.log('Amount read only? ' + readOnlyMap.amount);
        console.log("complete all operations reset");
    },
    resetOperationFieldLabel: function(cmp, operation, operationList){
        var label;
        for(var i=0; i<operationList.length; i++){
            console.log(operationList[i].name);
            if(operationList[i].name == operation){
                label = operationList[i].label;
                break;
            }
        }
        return label;
    }
})