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
        //this works like a doInit in this case; a doInit is not necessary
        //we check to see if mode is null since the change handler is called when mode is cleared in the container
        var mode = cmp.get("v.mode");
        console.log(mode);
        if(mode != null) {
            console.log("Mode is " + mode);
            console.log("In changeMode");
            //set readonly fields if mode is View, else allow user to make changes
            if(mode != "view"){
                cmp.set("v.isReadOnly",false);
                this.changeYearlyOperationsOptions(cmp);
            } else {
                cmp.set("v.isReadOnly", true);
                this.resetYearlyOperationsOptions(cmp);
            }
            //this checks that fields are set; this action only needs to be done once per rollup
            if($A.util.isEmpty(cmp.get("v.objectDetails"))){
                this.setObjectAndFieldDependencies(cmp);
            } else {
                //TODO: this is what's causing the mode to change. there's something wrong with the change handler that seems to be blocking this.
                //this.resetAllFields(cmp);
            }
        }
    },

    changeYearlyOperationsOptions: function(cmp){

        var operation = cmp.get("v.activeRollup.Yearly_Operation_Type__c");
        //cmp.set(operation, cmp.get("v.activeRollup.Yearly_Operation_Type__c").replace(/_/g, ' '));
        console.log(operation);
        var readOnlyMap = cmp.get("v.readOnlyMap");
        console.log(readOnlyMap);
        //todo: is this ok for translation?
        if (operation == 'All_Time') {
            //disable fiscal year and integer
            readOnlyMap["useFiscalYear"] = true;
            readOnlyMap["integer"] = true;
        } else if (operation == 'Years_Ago') {
            //enable fiscal year and integer
            readOnlyMap["useFiscalYear"] = false;
            readOnlyMap["integer"] = false;
        } else if (operation == 'Days_Back') {
            //disable fiscal year and enable integer
            readOnlyMap["useFiscalYear"] = true;
            readOnlyMap["integer"] = false;
        }
        cmp.set("v.readOnlyMap",readOnlyMap);
        console.log("Read Only Map is ");
        console.log(readOnlyMap.useFiscalYear);
        console.log(readOnlyMap.integer);
    },

    resetSummaryObjects: function(cmp, detailObject){
        //todo: add if Necesary check?
        console.log('Fired summary object reset');
        console.log('TEST');
        var labels = cmp.get("v.labels");
        var newSummaryObjects;
        console.log("detail object is " + detailObject);
        if(detailObject == "Allocation__c"){
            newSummaryObjects = [{label: labels.gauLabel, name:'General_Accounting_Unit__c'}];

        } else {
            //todo: add correct labels
            newSummaryObjects = [{label: labels.accountLabel, name: 'Account'}
                , {label: labels.contactLabel, name: 'Contact'}];
        }
        console.log(newSummaryObjects);
        cmp.set("v.summaryObjects", newSummaryObjects);
        //bb shenanigans
        cmp.set("v.activeRollup.Summary_Object__r.QualifiedApiName",null);
        console.log(cmp.get("v.activeRollup.Summary_Object__r.QualifiedApiName"));
        console.log("End summary object reset");
    },
    resetFields: function(cmp, object, context){

        console.log("Fired field reset for context: "+context);
        var test = cmp.get("v.objectDetails");
        //console.log(test);
        var newFields = cmp.get("v.objectDetails")[object];
        //console.log(newFields);

        if(context=='detail'){
            cmp.set("v.detailFields", newFields);
            //console.log('detail fields reset');
        } else if (context=='summary') {
            cmp.set("v.summaryFields", newFields);
        } else if (context=='date') {
            cmp.set("v.dateFields", newFields);
        } else if (context=='amount') {
            cmp.set("v.amountFields", newFields);
        }
    },
    resetAllFields: function(cmp){

        var detailObject = cmp.get("v.activeRollup.Detail_Object__r.QualifiedApiName");
        this.resetFields(cmp, detailObject, 'detail');

        var summaryObject = cmp.get("v.activeRollup.Summary_Object__r.QualifiedApiName");
        this.resetFields(cmp, summaryObject, 'summary');

        var amountObject = cmp.get("v.activeRollup.Amount_Object__r.QualifiedApiName");
        this.resetFields(cmp, amountObject, 'amount');

        var dateObject = cmp.get("v.activeRollup.Date_Object__r.QualifiedApiName");
        this.resetFields(cmp, dateObject, 'date');
    },
    filterSummaryFieldsByDetailField: function(cmp, detailField, summaryObject){
        //loop over all detail fields to get the type of selected field
        var detailFields = cmp.get("v.detailFields");
        var type;
        for(var i=0; i<detailFields.length; i++){
            if(detailFields[i].name == detailField){
                type = detailFields[i].type;
                break;
            }
        }
        //TODO: maybe check if type is the same to see if need to filter?
        console.log("Type is " + type);
        //need to get all summary fields, or we filter on a subset of all options
        var allFields = cmp.get("v.objectDetails")[summaryObject];
        var newFields = [];

        //if type is null, no detail field is selected
        if(type==undefined || type==null){
            newFields = allFields;
        } else{
            allFields.forEach(function(field){
                var datatype = field.type;
                if(datatype==type){
                    newFields.push(field);
                }
            });
        }

        if(newFields.length > 0){
            cmp.set("v.summaryFields", newFields);
        } else {
            //TODO: get/set better label messaging; this would need tooltip help
            //var na = cmp.get("v.labels.na");
            newFields = [{name: 'None', label: "No eligible fields found."}];
            cmp.set("v.summaryFields", newFields);
        }
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
    resetAllFields: function(cmp){

        var detailObject = cmp.get("v.activeRollup.Detail_Object__r.QualifiedApiName");
        this.resetFields(cmp, detailObject, 'detail');

        var summaryObject = cmp.get("v.activeRollup.Summary_Object__r.QualifiedApiName");
        this.resetFields(cmp, summaryObject, 'summary');

        var amountObject = cmp.get("v.activeRollup.Amount_Object__r.QualifiedApiName");
        this.resetFields(cmp, amountObject, 'amount');

        var dateObject = cmp.get("v.activeRollup.Date_Object__r.QualifiedApiName");
        this.resetFields(cmp, dateObject, 'date');
    },

    resetFields: function(cmp, object, context){

        console.log("Fired field reset for context: "+context);
        var test = cmp.get("v.objectDetails");
        console.log("objectDetails: "+test);
        var newFields = cmp.get("v.objectDetails")[object];
        //console.log(newFields);

        if(context=='detail'){
            cmp.set("v.detailFields", newFields);
            //console.log('detail fields reset');
        } else if (context=='summary') {
            cmp.set("v.summaryFields", newFields);
        } else if (context=='date') {
            cmp.set("v.dateFields", newFields);
        } else if (context=='amount') {
            cmp.set("v.amountFields", newFields);
        }
    },
 /*   resetSummaryObjects: function(cmp, detailObject){
        //todo: add if Necesary check?
        console.log('Fired summary object reset');
        var labels = cmp.get("v.labels");
        var newSummaryObjects;
        if(detailObject == "Allocation__c"){
            newSummaryObjects = [{label: labels.gauLabel, name:'General_Accounting_Unit__c'}];

        } else {
            //todo: add correct labels
            newSummaryObjects = [{label: labels.accountLabel, name: 'Account'}
                , {label: labels.contactLabel, name: 'Contact'}];
        }
        cmp.set("v.summaryObjects", newSummaryObjects);
        console.log("End summary object reset");
    },*/
    resetYearlyOperationsOptions: function(cmp){
        console.log("In reset yearly operations");
        var readOnlyMap = cmp.get("v.readOnlyMap");
        readOnlyMap["useFiscalYear"] = true;
        readOnlyMap["integer"] = true;
        //cmp.set(readOnlyMap, newMap);
        console.log("complete yearly operations reset");
    }
})