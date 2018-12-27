({
    /**
     * @description: instantiates component. Only called when component is first loaded.
     */
    doInit: function (component, event, helper) {
        helper.getModel(component);
    },

    /**
     * @description: handles selected row action in the datatable. Current option list: delete.
     */
    handleRowAction: function (component, event, helper) {
        let rowAction = event.getParam('action');
        var row = event.getParam('row');
        switch (rowAction.name) {
            case 'delete':
                helper.handleDeleteRowAction(component, row);
                break;
            case 'view':
                helper.handleViewRowAction(component, row);
                break;
        }
    },

    /**
     * @description: handles ltng:sendMessage from child component
     */
    handleMessage: function(component, event, helper) {
        var message = event.getParam('message');
        var channel = event.getParam('channel');

        if (channel === 'onSuccess') {
            helper.runDryRun(component, [message.recordId]);
            helper.showToast(component, $A.get('$Label.c.PageMessagesConfirm'), $A.get('$Label.c.bgeGridGiftSaved'), 'success');
            helper.createEntryForm(component);
        } else if (channel === 'onCancel') {
            helper.createEntryForm(component);
        } else if (channel === 'setDonorType') {
            component.set('v.donorType', message.donorType);
        } else if (channel === 'hideFormSpinner') {
            helper.hideFormSpinner(component);
        } else if (channel === 'showFormSpinner') {
            helper.showFormSpinner(component);
        } else if (channel === 'onError') {
            helper.showToast(component, message.title, message.errorMessage, 'error');
        }
    },

    /**
     * @description: cell change handler for lightning:dataTable
     * Saves updated cell value and re-runs Dry Run on that row.
     */
    onCellChange: function (component, event, helper) {
        var values = event.getParam('draftValues');
        // validation would happen here
        helper.handleTableSave(component, values);
        component.find('dataImportRowsDataTable').set('v.draftValues', null);
    },

    /**
     * @description: checks that user has all necessary permissions and then launches modal or displays error
     */
    onEditClick: function(component, event, helper) {
        helper.checkFieldPermissions(component, event, helper);
    },

    /**
     * @description: called when the 'Process Batch' button is clicked
     */
    processBatch: function(component, event, helper) {
        helper.processBatch(component);
    }

})