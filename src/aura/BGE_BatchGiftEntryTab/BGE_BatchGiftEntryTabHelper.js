({
    /******************************** Init Functions *****************************/

    doInit: function(component) {
        var action = component.get('c.getTabModel');
        action.setCallback(this, function (response) {
            const state = response.getState();
            if (state === 'SUCCESS') {
                let model = JSON.parse(response.getReturnValue());
                this.setColumns(component, model.columns);
                this.concatBatchRows(component, this.processBatchRows(model.batches));
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
        component.set('v.batchListColumns', responseColumns);
    },

    /******************************** Data Loading Functions *****************************/

    /**
     * @description: gets another set of Data Import Batch records from the server for loading into datatable
     */
    getMoreBatchRows: function(component, event) {
        let batchData = component.get('v.batchData');
        let sortBy = component.get('v.sortBy');
        let sortDir = component.get('v.sortDir');
        let action = component.get('c.getIncrementalTabModel');
        action.setParams({
            "offset": batchData.length,
            "sortBy": sortBy,
            "sortDir": sortDir
        });
        action.setCallback(this, function (response) {
            const state = response.getState();
            if (state === 'SUCCESS') {
                let model = JSON.parse(response.getReturnValue());
                this.concatBatchRows(component, this.processBatchRows(model.batches));
                this.setTotalNumberOfRows(component, model.totalNumberOfRows);
            } else {
                this.handleApexErrors(component, response.getError());
            }
            event.getSource().set('v.isLoading', false);
        });
        $A.enqueueAction(action);
    },

    /**
     * @description: when sort is changed, go back to initial load size, re-fetch new first batch, replace batchData
     */
    fetchSortedData: function(component, event) {
        let sortBy = component.get('v.sortBy');
        let sortDir = component.get('v.sortDir');
        let action = component.get('c.getReSortedData');
        action.setParams({
            "sortBy": sortBy,
            "sortDir": sortDir
        });
        action.setCallback(this, function (response) {
            const state = response.getState();
            if (state === 'SUCCESS') {
                let model = JSON.parse(response.getReturnValue());
                this.replaceBatchRows(component, this.processBatchRows(model.batches));
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
     * @param responseRows: list of Data Import Batch records
     */
    processBatchRows: function(responseRows) {
        responseRows.forEach(function (currentRow) {
            currentRow.batchLink = '/' + currentRow.Id;
            currentRow.CreatedById = currentRow.CreatedBy.Name;
            currentRow.LastModifiedById = currentRow.LastModifiedBy.Name;
            currentRow.OwnerId = currentRow.Owner.Name;
        });
        return responseRows;
    },

    /**
     * @description: concatenates incremental rows from server onto batchData
     * @param batchRows: list of Data Import Batch records
     */
    concatBatchRows: function(component, batchRows) {
        let data = component.get('v.batchData');
        if (!data) {
            data = [];
        }
        data = data.concat(batchRows);
        this.replaceBatchRows(component, data);
    },

    /**
     * @description: replaces batchData with fresh rows from server
     * @param batchRows: list of Data Import Batch records
     */
    replaceBatchRows: function(component, batchRows) {
        component.set('v.batchData', batchRows);
    },

    /**
     * @description: sets the total number of Data Import Batch rows for use in infinite scroll calculations
     */
    setTotalNumberOfRows: function(component, totalNumberOfRows) {
        component.set('v.totalNumberOfRows', totalNumberOfRows);
    },

    /******************************** User Interaction Functions *****************************/

    /**
     * @description: checks that user has all necessary permissions and then launches modal or displays error
     */
    checkFieldPermissions: function(component) {
        var action = component.get('c.checkFieldPermissions');
        action.setCallback(this, function (response) {
            var state = response.getState();
            if (state === 'SUCCESS') {
                if (!component.get('v.modalOpen')) {
                    //necessary to put here to prevent nested modals from rapid button clicks
                    component.set('v.modalOpen', true);
                    this.openNewBatchWizard(component);
                }
            } else if (state === 'ERROR') {
                this.handleApexErrors(component, response.getError());
            }
        });
        $A.enqueueAction(action);
    },

    /**
     * @description: opens New Batch Wizard in modal if not already open
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