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
    onNewBatchClick: function(component, event, helper) {
        helper.checkFieldPermissions(component);
    },

    loadMoreData: function (component, event, helper) {
        debugger;
        if (component.get('v.batchData').length >= component.get('v.totalNumberOfRows')) {
            component.set('v.enableInfiniteLoading', false);
        } else {
            helper.getMoreBatchRows(component);
        }
    },

})