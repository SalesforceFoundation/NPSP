({
    /**
     * @description: instantiates component. Only called when component is first loaded.
     */
    doInit: function(component, event, helper) {
        helper.doInit(component);
    },

    /**
     * @description: checks that user has all necessary permissions and then launches modal or displays error
     */
    openNewBatchWizard:function(component, event, helper) {
        helper.openNewBatchWizard(component);
    }

})