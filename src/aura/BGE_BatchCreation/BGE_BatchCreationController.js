({
    save: function (component, event, helper) {

        var newBatch = component.get('v.createBatch');
        var message = "Please review the following fields:\n";
        var fields = [];

        // Check fields population
        var result = helper.checkFieldsPopulation(component, message, fields);

        if (result){

            $A.createComponent(
                "c:BGE_BatchContainer",
                {
                    'showTemplateSelection': true,
                    'showProgressBar': true,
                    'processStage': 'selectBatchStage',
                    'associatedBatch': newBatch,
                    'fromCreation': true
                },

                function (newComp) {
                    var content = component.find("body");
                    content.set("v.body", newComp);
                });
        }
        
    },
    
    nextToInitial : function(component, event, helper) {
        
        $A.createComponent(
            "c:BGE_Initial",
            {},

            function(newComp) {
            var content = component.find("body");
            content.set("v.body", newComp);
        });
    }
})