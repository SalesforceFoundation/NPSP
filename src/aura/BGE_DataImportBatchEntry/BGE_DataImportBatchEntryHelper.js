({
    /**
     * @description: creates the form component
     */
    createEntryForm: function (component) {
        $A.createComponent(
            'c:BGE_EntryForm',
            {
                'aura:id': 'entryForm',
                'labels': component.get('v.labels'),
                'donorType': component.get('v.donorType'),
                'recordId': component.get('v.recordId'),
                'dataImportFields': component.get('v.dataImportFields')
            },
            function(newComponent, status, errorMessage){
                //Add the new component to the body array
                if (status === 'SUCCESS') {
                    var body = component.get('v.entryFormBody');
                    body.push(newComponent);
                    component.set('v.entryFormBody', body);
                }
                else if (status === 'INCOMPLETE') {
                    this.showToast(component, $A.get('$Label.c.PageMessagesError'), $A.get('$Label.c.stgUnknownError'), 'error');
                }
                else if (status === 'ERROR') {
                    this.showToast(component, $A.get('$Label.c.PageMessagesError'), errorMessage, 'error');
                }
            }
        );
    },

    /**
     * @description: creates the configuration modal
     */
    createModal: function (component) {
        var modalBody;
        var modalHeader;
        var modalFooter;

        $A.createComponents([
                ['c:BGE_Wizard',{sObjectName: component.get('v.sObjectName'), recordId: component.get('v.recordId')}],
                ['c:modalHeader',{header: $A.get('$Label.c.bgeBatchOverviewWizard')}],
                ['c:modalFooter',{}]
            ],
            function(components, status){
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
                        closeCallback: function() {
                        }
                    })
                }
            }
        );
    },

    /**
     * @description: retrieves the model information. If successful, sets the model and creates child component; otherwise alerts user.
     */
    getModel: function(component) {
        var action = component.get('c.getDataImportModel');
        action.setParams({batchId: component.get('v.recordId')});
        action.setCallback(this, function (response) {
            var state = response.getState();
            if (state === 'SUCCESS') {
                var response = JSON.parse(response.getReturnValue());
                this.setModel(component, response);
                this.createEntryForm(component, response);
            } else {
                this.showToast(component, $A.get('$Label.c.PageMessagesError'), response.getReturnValue(), 'error');
            }
            this.hideSpinner(component);
        });
        $A.enqueueAction(action);
    },

    /**
     * @description: saves inline edits from dataTable.
     * @param values: changed values in the table
     */
    handleTableSave: function(component, draftValues) {
        this.showSpinner(component);
        var action = component.get('c.updateDataImports');
        action.setParams({dataImports: draftValues, batchId: component.get('v.recordId')});
        action.setCallback(this, function (response) {
            var state = response.getState();
            if (state === 'SUCCESS') {
                this.showToast(component, $A.get('$Label.c.PageMessagesConfirm'), $A.get('$Label.c.bgeGridGiftUpdated'), 'success');
                var responseRows = response.getReturnValue();
                this.setDataTableRows(component, responseRows);
                this.setTotals(component, responseRows);

                //call dry run in callback to speed up refresh of datatable rows
                var recordIds = [];
                draftValues.forEach(function(draftVal){
                    recordIds.push(draftVal.Id);
                });
                this.runDryRun(component, recordIds);
            } else {
                this.showToast(component, $A.get('$Label.c.PageMessagesError'), response.getReturnValue(), 'error');
            }
            this.hideSpinner(component);
        });
        $A.enqueueAction(action);
    },

    /**
     * @description: starts the BDI dry run to verify DataImport__c matches
     * @param recordIds: list of DataImport__c RecordIds to check for dry run
     */
    runDryRun: function(component, recordIds) {
        var action = component.get('c.runDryRun');
        var batchId = component.get('v.recordId');
        action.setParams({dataImportIds: recordIds, batchId: batchId});
        action.setCallback(this, function (response) {
            var state = response.getState();
            if (state === 'SUCCESS') {
                var responseRows = response.getReturnValue();
                this.setDataTableRows(component, responseRows);
                this.setTotals(component, responseRows);
            } else {
                this.showToast(component, $A.get('$Label.c.PageMessagesError'), response.getReturnValue(), 'error');
            }
        });
        $A.enqueueAction(action);
    },

    /**
     * @description: sets column with a derived Donor field, any columns passed from Apex, and Delete action.
     * @param dataColumns: custom Column class data passed from the Apex controller.
     */
    setColumns: function(component, dataColumns) {
        var columns = [];
        columns.push({label: 'Donor', fieldName: 'donor', type: 'text', editable: false});

        dataColumns.forEach(function(col){
            columns.push({label: col.label, fieldName: col.fieldName, type: col.type, editable: !col.readOnly});
        });

        columns.push({
            type: 'action', typeAttributes: {
                rowActions: [{
                    label: 'Delete',
                    name: 'delete',
                    title: 'Delete'
                }]
            }
        });

        component.set('v.columns', columns);
    },

    /**
     * @description: sets data import fields for dynamic use in the recordEditForm.
     * @param dataColumns: custom Column class data passed from the Apex controller.
     */
    setDataImportFields: function (component, dataColumns) {
        var dataImportFields = [];

        dataColumns.forEach(function(field){
            if (!field.readOnly) {
                dataImportFields.push({label: field.label, name: field.fieldName});
            }
        });

        component.set('v.dataImportFields', dataImportFields);
    },

    /**
     * @description: flattens the DataImportRow class data to include donor information at the same level as the rest of the DataImport__c record.
     * @param responseRows: custom DataImportRow class data passed from the Apex controller.
     */
    setDataTableRows: function(component, responseRows) {
        var rows = [];
        responseRows.forEach(function(currentRow) {
            var row = currentRow.record;
            row.donor = currentRow.donor;
            rows.push(row);
        });

        component.set('v.data', rows);
    },

    /**
     * @description: sets data import fields to use dynamically in the recordEditForm.
     * @param model: full DataImportModel from the Apex controller
     */
    setModel: function (component, model) {
        component.set('v.labels', model.labels);
        this.setDataServiceFields(component, model.labels);
        this.setDataTableRows(component, model.dataImportRows);
        this.setTotals(component, model.dataImportRows);
        this.setColumns(component, model.columns);
        this.setDataImportFields(component, model.columns);
        component.set('v.isNamespaced', Boolean(model.isNamespaced));
        component.set('v.isLoaded', true);
    },

    /**
     * @description: sets the data service fields to use the correct field labels depending on namespacing
     * @param labels: all labels for the app
     */
    setDataServiceFields: function(component, labels) {
        var fields = [];
        fields.push(labels.expectedCountField);
        fields.push(labels.expectedTotalField);
        component.set('v.batchFields', fields);
    },

    /**
     * @description: Calculates actual totals from queried Data Import rows
     * @param rows: rows returned from the Apex controller
     */
    setTotals: function (component, rows) {
        var countGifts = 0;
        var totalGiftAmount = 0;
        rows.forEach(function (currentRow) {
            var row = currentRow.record;
            countGifts += 1;
            var amount = row[component.get('v.labels.donationAmountField')];
            if (amount) {
                totalGiftAmount += amount;
            }
        });
        var totals = component.get('v.totals');
        totals.countGifts = countGifts;
        totals.totalGiftAmount = totalGiftAmount;
        component.set('v.totals', totals);
    },

    /**
     * @description: displays standard toast to user based on success or failure of their action
     * @param title: Title displayed in toast
     * @param message: body of message to display
     * @param type: configures type of toast
     */
    showToast: function(component, title, message, type) {
        var mode = (type === 'Error') ? 'sticky' : 'pester';

        component.find('notifLib').showToast({
            'variant': type,
            'mode': mode,
            'title': title,
            'message': message
        });
    },

    /**
     * @description: shows lightning:dataTable spinner
     */
    showSpinner: function (component) {
        var spinner = component.find('dataTableSpinner');
        $A.util.removeClass(spinner, 'slds-hide');
    },

    /**
     * @description: hides lightning:dataTable spinner
     */
    hideSpinner: function (component) {
        var spinner = component.find('dataTableSpinner');
        $A.util.addClass(spinner, 'slds-hide');
    }

})