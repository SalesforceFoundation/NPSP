({
    setObjectAndFieldDependencies: function(cmp) {
        //set list of objects and get data type for all
        //TODO: set proper labels
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
                    console.log("got a response");
                    //TODO: set detailFields here? could depend on mode + first value
                    console.log('Before calling reset details');
                    var detailObject = cmp.get("v.activeRollup.Detail_Object__r.QualifiedApiName");
                    var summaryObject = cmp.get("v.activeRollup.Summary_Object__r.QualifiedApiName");
                    this.resetDetailFields(cmp, detailObject);
                    this.resetSummaryFields(cmp, summaryObject);
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
    resetSummaryFields: function(cmp, summaryObject){
        //TODO: this needs to handle detail field, summary object && detail object
        console.log("Fired summary field reset");

        //this code is getting all fields + type, not all fields for given detail object
        var objectDetails = cmp.get("v.objectDetails");
        var summaryFieldMapForObject = objectDetails[summaryObject];
        var newSummaryFields = [];

        for(var i=0; i<summaryFieldMapForObject.length; i++){
            var name = summaryFieldMapForObject[i].name;
            var label = summaryFieldMapForObject[i].label;
            var datatype = summaryFieldMapForObject[i].type;
            var fieldObj = {label: label, name: name, type: datatype};
            //newDetailFields.push(summaryFieldMapForObject[i]);
            newSummaryFields.push(fieldObj);
        }
        //todo: 2 attributes?
        cmp.set("v.summaryFields", newSummaryFields);
    },
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
    }
})