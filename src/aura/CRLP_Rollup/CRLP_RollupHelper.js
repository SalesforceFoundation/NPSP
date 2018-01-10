({
    setObjectAndFieldDependencies: function(cmp) {
        //set list of objects and get data type for all
        //TODO: set proper labels
        if($A.util.isEmpty(cmp.get("v.objectDetails"))) {

            console.log("In the helper function");
            var detailObjects = [{label: 'Opportunity', name: 'Opportunity'}
                , {label: 'Partial Soft Credit', name: 'Partial_Soft_Credit__c'}
                , {label: 'Payment', name: 'npe01__OppPayment__c'}
                , {label: 'Allocation', name: 'Allocation__c'}];
            var summaryObjects = [{label: 'Account', name: 'Account'}
                , {label: 'Contact', name: 'Contact'}
                , {label: 'General Accounting Unit', name: 'General_Accounting_Unit__c'}];
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
                    console.log(response.getReturnValue());
                    //TODO: set detailFields here? could depend on mode + first value
                    var detailObject = cmp.get("v.activeRollup.Detail_Object__r.QualifiedApiName")
                    console.log('Before calling reset details');
                    this.resetDetailFields(cmp, detailObject);
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
    resetSummaryFields: function(cmp, detailObject, summaryObject){
        //TODO: this needs to handle detail field, summary object && detail object
        console.log("Fired summary field reset");
        var objectDetails = cmp.get("v.objectDetails");
        var detailFieldMapForObject = objectDetails[detailObject];
        var summaryFieldMapForObject = objectDetails[summaryObject];

    },
    resetDetailFields: function(cmp, detailObject){
        console.log("Fired detail field reset");
        //TODO: detail field list needs refinement in controller, not here

        //this code is getting all fields + type, not all fields for given detail object
        var objectDetails = cmp.get("v.objectDetails");
        var detailFieldMapForObject = objectDetails[detailObject];
        console.log('Detail Field Map for object: ');
        console.log(detailFieldMapForObject);
        var newDetailFields = [];

        for(var i=0; i<detailFieldMapForObject.length; i++){
            var name = detailFieldMapForObject[i].name;
            var label = detailFieldMapForObject[i].label;
            var datatype = detailFieldMapForObject[i].type;
            var fieldObj = {label: label, name: name, type: datatype};
            console.log(fieldObj);
            newDetailFields.push(fieldObj);
            console.log(newDetailFields);
        }
        //todo: 2 attributes?
        console.log(newDetailFields);
        cmp.set("v.detailFields", newDetailFields);
    }
})