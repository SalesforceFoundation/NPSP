({
    /******************************** Init Functions *****************************/

    doInit: function(component) {
        var action = component.get('c.getTableModel');
        action.setCallback(this, function (response) {
            const state = response.getState();
            if (state === 'SUCCESS') {
                let model = JSON.parse(response.getReturnValue());
                this.setColumns(component, model.columns);
                this.loadBatchRows(component, [], model.batches);
                this.setTotalNumberOfRows(component, model.totalNumberOfRows);
            } else {
                this.handleApexErrors(component, response.getError());
            }
        });
        $A.enqueueAction(action);
    },

    /**
     * @description: loads the columns for the datatable
     */
    setColumns: function(component, responseColumns) {
        responseColumns.forEach(function(col){
           if (col.type === 'number') {
               col.cellAttributes = {alignment: "left"};
           } else if (col.fieldName === 'batchLink') {
               col.typeAttributes = {label:{fieldName:"Name"},target:"self"};
           }
        });

        responseColumns.push({
            type: 'action',
            typeAttributes: {
                rowActions: [{
                    label: $A.get('$Label.c.bgeCopyBatchSetupButton'),
                    name: 'copySetup'
                }]
            }
        });

        component.set('v.batchListColumns', responseColumns);
    },

    /******************************** Data Loading Functions *****************************/

    /**
     * @description: gets another set of Data Import Batch records from the server for loading into datatable
     */
    getBatchRows: function(component, event) {
        let batchData = component.get('v.batchData');
        let sortBy = component.get('v.sortBy');
        let sortDirection = component.get('v.sortDirection');
        let action = component.get('c.getSortedData');
        action.setParams({
            "offset": batchData.length,
            "sortBy": sortBy,
            "sortDirection": sortDirection
        });
        action.setCallback(this, function (response) {
            const state = response.getState();
            if (state === 'SUCCESS') {
                let model = JSON.parse(response.getReturnValue());
                this.loadBatchRows(component, batchData, model.batches);
                this.setTotalNumberOfRows(component, model.totalNumberOfRows);
            } else {
                this.handleApexErrors(component, response.getError());
            }
            event.getSource().set('v.isLoading', false);
        });
        $A.enqueueAction(action);
    },

    /**
     * @description: loads Batch Rows into datatable data and creates field data for link and user fields
     * @param baseRows: list of existing Data Import Batch records to concatenate onto
     * @param responseRows: list of Data Import Batch records
     */
    loadBatchRows: function(component, baseRows, responseRows) {
        responseRows.forEach(function (currentRow) {
            currentRow.batchLink = '/' + currentRow.Id;
            currentRow.CreatedById = currentRow.CreatedBy.Name;
            currentRow.LastModifiedById = currentRow.LastModifiedBy.Name;
            currentRow.OwnerId = currentRow.Owner.Name;
        });
        let data = baseRows.concat(responseRows);
        component.set('v.batchData', data);
    },

    /**
     * @description: sets the total number of Data Import Batch rows for use in infinite scroll calculations
     */
    setTotalNumberOfRows: function(component, totalNumberOfRows) {
        component.set('v.totalNumberOfRows', totalNumberOfRows);
    },

    /******************************** User Interaction Functions *****************************/

    /**
     * @description: performs field permissions check and then opens New Batch Wizard
     */
    handleNewBatchClick: function(component) {
        this.checkFieldPermissions(component, function () {
            return this.openNewBatchWizard(component);
        }.bind(this));
    },

    /**
     * @description: handler for row actions from Batch table
     */
    handleRowAction: function(component, event) {
        let rowAction = event.getParam('action');
        switch (rowAction.name) {
            case 'copySetup':
                const sourceBatchId = event.getParam('row').Id;
                this.checkFieldPermissions(component, function () {
                    return this.openNewBatchWizard(component, sourceBatchId);
                }.bind(this));
                break;
        }
    },

    /**
     * @description: checks that user has all necessary permissions and then calls onSuccess function
     * @param: sourceBatchId Id of Batch record to be copied - optional
     */
    checkFieldPermissions: function(component, onSuccess) {
        var action = component.get('c.checkFieldPermissions');
        action.setCallback(this, function (response) {
            var state = response.getState();
            if (state === 'SUCCESS') {
                onSuccess();
            } else if (state === 'ERROR') {
                this.handleApexErrors(component, response.getError());
            }
        });
        $A.enqueueAction(action);
    },

    /**
     * @description: opens New Batch Wizard in modal
     * @param: sourceBatchId Id of Batch record to be copied - optional
     */
    openNewBatchWizard: function(component, sourceBatchId) {
        if (component.get('v.modalOpen')) {
            return;
        }
        component.set('v.modalOpen', true);

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
                ['c:BGE_ConfigurationWizard', {sObjectName: 'DataImportBatch__c', sourceBatchId: sourceBatchId}],
                ['c:modalHeader', {header: $A.get('$Label.c.bgeBatchInfoWizard')}],
                ['c:modalFooter', {progressStepLabels: progressStepLabels}]
            ],
            function (components, status, errorMessage) {
                if (status === 'SUCCESS') {
                    modalBody = components[0];
                    modalHeader = components[1];
                    modalFooter = components[2];
                    component.find('overlayLib').showCustomModal({
                        body: modalBody,
                        header: modalHeader,
                        footer: modalFooter,
                        showCloseButton: true,
                        cssClass: 'slds-modal_large',
                        closeCallback: function () {
                            component.set('v.modalOpen', false);
                        }
                    })
                } else {
                    component.set('v.modalOpen', false);
                    this.showToast(component, $A.get('$Label.c.PageMessagesError'), errorMessage, 'error');
                }
            }
        );

    },

    /******************************** Utility Functions *****************************/

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
    }
})