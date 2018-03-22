({
    minBatch: 0,
    getBatches : function(component, page) {

        var searchKey = window.location.hash.substr(1);
        page = page || 1;

        var action = component.get("c.getBatchesList");
        action.setParams({
            "searchKey": searchKey,
            "pageNumber": page
            //"minAlcohol": this.minAlcohol, 
        });
        action.setCallback(this, function(response){
            var state = response.getState();
            if (state === "SUCCESS") {

                var result = response.getReturnValue();
                component.set("v.batches", result.batches);//The attribute that you are iterating has to be set here
                component.set("v.page", result.page);
                component.set("v.total", result.total);
                component.set("v.pages", Math.ceil(result.total/5));
            }
        });
        $A.enqueueAction(action);
    }
})