({
    doInit: function(component) {
        var action = component.get('c.getTabModel');
        action.setCallback(this, function (response) {
            const state = response.getState();
            if (state === 'SUCCESS') {
                let model = JSON.parse(response.getReturnValue());
                this.setColumns(component, model.columns);
                component.set('v.totalNumberOfRows', model.totalNumberOfRows);
                this.setBatchRows(component, model.batches);
            } else {
                this.handleApexErrors(component, response.getError());
            }
        });
        $A.enqueueAction(action);
    },

    setColumns: function(component, responseColumns) {
        var columns = [];
        columns.push({
            // TODO: make this a real label
            label: 'Batch',
            fieldName: 'batchLink',
            type: 'url',
            typeAttributes: {label:{fieldName:"Name"},target:"_blank"}
        });
        responseColumns.forEach(function(col){
            columns.push(col);
        });
        component.set('v.batchListColumns',columns);
    },

    getMoreBatchRows: function(component, event) {
        let offset = component.get('v.batchData').length;
        let rowsToLoad = 50;
        let action = component.get('c.getBatches');
        action.setParams({
            "queryAmount": rowsToLoad,
            "offset": offset
        });
        action.setCallback(this, function (response) {
            const state = response.getState();
            if (state === 'SUCCESS') {
                let batches = response.getReturnValue();
                this.setBatchRows(component, batches);
            } else {
                this.handleApexErrors(component, response.getError());
            }
            event.getSource().set("v.isLoading", false);
        });
        $A.enqueueAction(action);
    },

    /**
     * @description: loads Batch Rows into datatable data
     * @param batches: list of BatchRow wrappers
     */
    setBatchRows: function(component, responseRows) {
        responseRows.forEach(function(currentRow) {
            console.log(JSON.stringify(responseRows));
            currentRow.batchLink = '/' + currentRow.Id;
            currentRow.CreatedByName = currentRow.CreatedBy.Name;
        });
        let data = component.get('v.batchData');
        if (!data) {
            data = [];
        }
        data = data.concat(responseRows);
        component.set('v.batchData', data);
    },

    /**
     * @description: handles the display of errors from an apex callout
     * @param errors: list of potential errors passed back from apex
     */
    handleApexErrors: function(component, errors) {
        let message;
        if (errors && errors[0] && errors[0].message) {
            message = errors[0].message;
        } else {
            message = 'Unknown error';
        }
        this.showToast(component, $A.get('$Label.c.PageMessagesError'), message, 'error');
    },

    /**
     * @description: checks that user has all necessary permissions and then launches modal or displays error
     */
    checkFieldPermissions: function(component) {
        var action = component.get('c.checkFieldPermissions');
        action.setCallback(this, function (response) {
            var state = response.getState();
            if (state === 'SUCCESS') {
                this.openNewBatchWizard(component);
            } else if (state === 'ERROR') {
                console.log(response.getError());
                this.handleApexErrors(component, response.getError());
            }
        });
        $A.enqueueAction(action);
    },

    /**
     * @description: opens New Batch Wizard in modal
     */
    openNewBatchWizard: function(component) {
        let modalBody;
        let modalHeader;
        let modalFooter;

        let progressStepLabels = [
            $A.get('$Label.c.bgeBatchOverviewWizard'),
            $A.get('$Label.c.bgeBatchSelectFields'),
            $A.get('$Label.c.bgeBatchSetFieldOptions'),
            $A.get('$Label.c.bgeBatchSetBatchOptions')
        ];

        $A.createComponents([
                ['c:BGE_ConfigurationWizard', {sObjectName: 'DataImportBatch__c'}],
                ['c:modalHeader', {header: $A.get('$Label.c.bgeBatchInfoWizard')}],
                ['c:modalFooter', {progressStepLabels: progressStepLabels}]
            ],
            function(components, status, errorMessage){
                if (status === 'SUCCESS') {
                    modalBody = components[0];
                    modalHeader = components[1];
                    modalFooter = components[2];
                    component.find('overlayLib').showCustomModal({
                        body: modalBody,
                        header: modalHeader,
                        footer: modalFooter,
                        showCloseButton: true,
                        cssClass: 'slds-modal_large'
                    })
                } else {
                    this.showToast(component, $A.get('$Label.c.PageMessagesError'), errorMessage, 'error');
                }
            }
        );
    },

    /**
     * @description: displays standard toast to user based on success or failure of their action
     * @param title: title displayed in toast
     * @param message: body of message to display
     * @param type: configures type of toast
     */
    showToast: function(component, title, message, type) {
        var mode = (type === 'error') ? 'sticky' : 'pester';

        component.find('notifLib').showToast({
            'variant': type,
            'mode': mode,
            'title': title,
            'message': message
        });
    },

})