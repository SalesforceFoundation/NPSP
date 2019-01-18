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
        event.getSource().set("v.isLoading", true);
        if (component.get('v.batchData').length >= component.get('v.totalNumberOfRows')) {
            component.set('v.enableInfiniteLoading', false);
            event.getSource().set("v.isLoading", false);
        } else {
            helper.getMoreBatchRows(component, event);
        }
    },

})