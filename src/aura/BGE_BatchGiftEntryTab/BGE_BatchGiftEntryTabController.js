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

    /**
     * @description: sorts the data by the field name and current direction
     */
    sortByColumns: function(component, event, helper) {
        const fieldName = event.getParam('fieldName');
        const sortEventParam = event.getParam('sortDirection');
        const sortDirection = sortEventParam ? sortEventParam : 'asc';

        helper.sortBatchData(component, fieldName, sortDirection);

        component.set("v.batchData.sortedBy", fieldName);
        component.set("v.batchData.sortedDirection", sortDirection);
    }

})