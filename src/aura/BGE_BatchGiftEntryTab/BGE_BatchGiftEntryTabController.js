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

    /**
     * @description: handles infinite scroll when user scrolls to the bottom of the datatable
     */
    loadMoreData: function (component, event, helper) {
        event.getSource().set('v.isLoading', true);
        if (component.get('v.batchData').length >= component.get('v.totalNumberOfRows')) {
            component.set('v.enableInfiniteLoading', false);
            event.getSource().set('v.isLoading', false);
        } else {
            helper.getBatchRows(component, event);
        }
    },

    /**
     * @description: sorts the data by the field name and current direction
     */
    sortByColumns: function(component, event, helper) {
        component.set('v.enableInfiniteLoading', true);

        const fieldNameEventParam = event.getParam('fieldName');
        const fieldName = fieldNameEventParam === 'batchLink' ? 'Name' : fieldNameEventParam;
        const sortEventParam = event.getParam('sortDirection');
        const sortDirection = sortEventParam ? sortEventParam : 'asc';

        component.set('v.sortBy', fieldName);
        component.set('v.sortDirection', sortDirection);

        component.set('v.batchData',[]);
        helper.getBatchRows(component, event);
    }

})