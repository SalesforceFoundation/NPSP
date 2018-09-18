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
        helper.showSpinner(component);
        var action = event.getParam('action');
        var row = event.getParam('row');
        switch (action.name) {
            case 'delete':
                var action = component.get('c.deleteDataImportRow');
                action.setParams({batchId: component.get('v.recordId'), dataImportId: row.Id});
                action.setCallback(this, function (response) {
                    var state = response.getState();
                    if (state === 'SUCCESS') {
                        var response = JSON.parse(response.getReturnValue());
                        helper.setDataTableRows(component, response);
                        helper.setTotals(component, response);
                        helper.showToast(component, $A.get('$Label.c.PageMessagesConfirm'), $A.get('$Label.c.bgeGridGiftDeleted'), 'success');
                    } else {
                        helper.showToast(component, $A.get('$Label.c.PageMessagesError'), response.getReturnValue(), 'error');
                    }
                    helper.hideSpinner(component);
                });
                $A.enqueueAction(action);
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
            helper.runDryRun(component, message.recordId);
            // todo: determine if this can be called separately and rundryrun return void, or if we need rundryrun to return the rows
            // currently rundryrun is returning things itself, but it is repetitive.
            //helper.getDIs(component);
            helper.showToast(component, $A.get('$Label.c.PageMessagesConfirm'), $A.get('$Label.c.bgeGridGiftSaved'), 'success');
            helper.createEntryForm(component);
        } else if (channel === 'onCancel') {
            helper.createEntryForm(component);
        } else if (channel === 'setDonorType') {
            component.set('v.donorType', message);
        } else if (channel === 'hideFormSpinner') {
            var spinner = component.find('formSpinner');
            $A.util.addClass(spinner, 'slds-hide');
        }
    },

    /**
     * @description: callback function for lightning:recordEditForm. Queries DataImport__c records,
     * shows toast, and clears recordEditForm.
     */
    onTableSave: function (component, event, helper) {
        var values = event.getParam('draftValues');
        // validation would happen here
        helper.handleTableSave(component, values);
        component.find('dataImportRowsDataTable').set('v.draftValues', null);
    },

})