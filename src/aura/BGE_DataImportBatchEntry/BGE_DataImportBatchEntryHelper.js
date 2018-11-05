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
        columns.push({label: 'Donor', fieldName: 'donorLink', type: 'url', editable: false, typeAttributes: {label: {fieldName: 'donorName'}}});

        dataColumns.forEach(function(col){
            columns.push({label: col.label,
                fieldName: col.fieldName,
                type: col.type,
                editable: !col.readOnly,
                typeAttributes: JSON.parse(col.typeAttributes)});
        });

        columns.push({
            type: 'action',
            typeAttributes: {
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
                dataImportFields.push({
                    label: field.label,
                    name: field.fieldName,
                    options: field.options,
                    value: field.defaultValue
                });
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
        var errors = [];
        responseRows.forEach(function(currentRow) {
            var row = currentRow.record;
            row.donorName = currentRow.donorName;
            row.donorLink = currentRow.donorLink;
            row.matchedRecordUrl = currentRow.matchedRecordUrl;
            row.matchedRecordLabel = currentRow.matchedRecordLabel;
            row.errors = currentRow.errors;
            rows.push(row);

            //get payment and opportunity error information if import failed
            if (row.errors.length > 0) {
                var rowError = {
                    id: row.Id,
                    title: $A.get('$Label.c.PageMessagesError'),
                    messages: row.errors
                };
                errors.push(rowError);
            }
        });

        if (errors) {
            this.handleTableErrors(component, errors);
        }

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
        fields.push('Name');
        component.set('v.batchFields', fields);
    },

    /**
     * @description: handles the display or clearing of errors from the results of dry run
     * @param rowErrors: object with row Id, title, and list of associated messages
     */
    handleTableErrors: function(component, rowErrors) {
        var tableErrors = { rows: {}, table: {}, size: 0 };

        rowErrors.forEach(function(error) {
            var rowError = {
                title: error.title,
                messages: error.messages
            };
            tableErrors.rows[error.id] = rowError;
        });

        tableErrors.size = rowErrors.length;

        component.set("v.errors", tableErrors);
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