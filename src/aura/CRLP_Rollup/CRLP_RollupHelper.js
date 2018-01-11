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
            var summaryObjects = [{label: 'Account', name: 'Account'}
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
        var newSummaryObjects;
        if(detailObject == "Allocation__c"){
            //todo: add correct labels
            newSummaryObjects = [{label: 'General Accounting Unit', name:'General_Accounting_Unit__c'}];

        } else {
            //todo: add correct labels
            newSummaryObjects = [{label: 'Account', name: 'Account'}
                , {label: 'Contact', name: 'Contact'}];
        }
        console.log(newSummaryObjects);
        cmp.set("v.summaryObjects", newSummaryObjects);
        console.log("End summary object reset");
    },
    resetFields: function(cmp, object, context){

        console.log("Fired field reset for context: "+context);

        //this code is getting all fields + type, not all fields for given detail object
        var objectDetails = cmp.get("v.objectDetails");
        var fieldMapForObject = objectDetails[object];
        console.log('fieldMapForObject:');
        console.log(fieldMapForObject);
        var newFields = [];

        for(var i=0; i<fieldMapForObject.length; i++){
            var name = fieldMapForObject[i].name;
            var label = fieldMapForObject[i].label;
            var datatype = fieldMapForObject[i].type;
            var fieldObj = {label: label, name: name, type: datatype};
            newFields.push(fieldObj);
        }

        if(context=='detail'){
            cmp.set("v.detailFields", newFields);
        } else if (context=='summary') {
            cmp.set("v.summaryFields", newFields);
        } else if (context=='date') {
            cmp.set("v.dateFields", newFields);
        } else if (context=='amount') {
            cmp.set("v.amountFields", newFields);
        }
    }

    /*,
    resetDetailFields: function(cmp, detailObject){
        console.log("Fired detail field reset");
        //TODO: detail field list needs refinement in controller, not here

        //this code is getting all fields + type, not all fields for given detail object
        var objectDetails = cmp.get("v.objectDetails");
        var detailFieldMapForObject = objectDetails[detailObject];
        var newDetailFields = [];

        for(var i=0; i<detailFieldMapForObject.length; i++){
            var name = detailFieldMapForObject[i].name;
            var label = detailFieldMapForObject[i].label;
            var datatype = detailFieldMapForObject[i].type;
            var fieldObj = {label: label, name: name, type: datatype};
            newDetailFields.push(fieldObj);
        }
        //todo: 2 attributes?
        cmp.set("v.detailFields", newDetailFields);
    }*/
})