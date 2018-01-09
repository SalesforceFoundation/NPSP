({
    setObjectAndFieldDependencies: function(cmp) {
        //set list of objects and get data type for all
        //TODO: check if dependencies are necessary; also, labels?
        //Thought: the items need to be singled quoted for Apex, maybe?
        //var detailObjects = ['Opportunity', 'Partial_Soft_Credit__c', 'npe01__OppPayment__c', 'Allocation__c'];
        console.log("In the helper function");
        var detailObjects = {'Opportunity': 'Opportunity', 'Partial Soft Credit' : 'Partial_Soft_Credit__c',
                            'Payment': 'npe01__OppPayment__c', 'Allocation': 'Allocation__c'};
        var detailObjects2 = [{label: 'Opportunity', label: 'Opportunity'}, {label:'Partial Soft Credit', name: 'Partial_Soft_Credit__c'}
                            , {label: 'Payment', name: 'npe01__OppPayment__c'}
                            , {label: 'Allocation', name: 'Allocation__c'}];
        var summaryObjects = [{'Account': 'Account', 'Contact': 'Contact',
                            'General Accounting Unit': 'General_Accounting_Unit__c'}];
        var availableObjects = detailObjects.concat(summaryObjects);

        cmp.set("v.detailObjects", detailObjects2);
        console.log(detailObjects2);
        cmp.set("v.summaryObjects", summaryObjects);

        var action = cmp.get("c.getFieldsByDataType");
        action.setParams({objectNames: availableObjects.values()});

        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                //cmp.set("v.objectDetails", response.getReturnValue());
                console.log(response.getReturnValue());
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
})