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

            action.setCallback(this, function (response) {
                var state = response.getState();
                if (state === "SUCCESS") {
                    var response = response.getReturnValue();
                    cmp.set("v.objectDetails", response);

                    console.log('Before calling reset details');

                    var detailObject = cmp.get("v.activeRollup.Detail_Object__r.QualifiedApiName");
                    this.resetFields(cmp, detailObject, 'detail');

                    var summaryObject = cmp.get("v.activeRollup.Summary_Object__r.QualifiedApiName");
                    this.resetFields(cmp, summaryObject, 'summary');

                    var amountObject = cmp.get("v.activeRollup.Amount_Object__r.QualifiedApiName");
                    this.resetFields(cmp, amountObject, 'amount');

                    var dateObject = cmp.get("v.activeRollup.Date_Object__r.QualifiedApiName");
                    this.resetFields(cmp, dateObject, 'date');

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

            $A.enqueueAction(action);
        }
    },

    resetSummaryObjects: function(cmp, detailObject){
        //todo: add ifNecesary check?
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
        console.log(newSummaryObjects);
        cmp.set("v.summaryObjects", newSummaryObjects);
        console.log("End summary object reset");
    },
    resetFields: function(cmp, object, context){

        console.log("Fired field reset for context: "+context);
        var newFields = cmp.get("v.objectDetails")[object];

        if(context=='detail'){
            cmp.set("v.detailFields", newFields);
        } else if (context=='summary') {
            cmp.set("v.summaryFields", newFields);
        } else if (context=='date') {
            cmp.set("v.dateFields", newFields);
        } else if (context=='amount') {
            cmp.set("v.amountFields", newFields);
        }
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
        //TODO: will type ever be blank?
        console.log("Type is " + type);
        //need to get all summary fields, or we filter on a subset of all options
        var allFields = cmp.get("v.objectDetails")[summaryObject];
        console.log(allFields);
        var newFields = [];

        allFields.forEach(function(field){
            var datatype = field.type;
            if(datatype==type){
                newFields.push(field);
            }
        });
        console.log(newFields);
        if(newFields.length > 0){
            cmp.set("v.summaryFields", newFields);
        } else {
            //TODO: get/set better label messaging; this would need tooltip help
            //var na = cmp.get("v.labels.na");
            newFields = [{name: 'None', label: "No eligible fields found."}];
            cmp.set("v.summaryFields", newFields);
        }
    }
})