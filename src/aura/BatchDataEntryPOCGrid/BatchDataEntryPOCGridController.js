({

    nextToValidateAndCommit: function (component, event, helper) {
        alert('CONTINUE TO VALIDATION');
        helper.continueToValidationHelper(component);
		alert("SET COMPONENT");
        component.set("v.processStage", "commitBatchStage");
    },

    nextToCommit: function (component, event, helper) {

        helper.continueToCommitHelper(component);
        component.set("v.processStage", "commitBatchStage");
    },

    nextToBatchSelection: function (component, event, helper) {

        $A.createComponent(
            "c:BGE_BatchSelection",
            {},

            function (newComp) {
                var content = component.find("body");
                content.set("v.body", newComp);
            });
    },

})