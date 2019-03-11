({
    /******************************** Init Functions *****************************/

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
                component.find('forceRecordCmp').reloadRecord(true);
            } else {
                this.handleApexErrors(component, response.getError());
                this.hideFormSpinner(component);
            }
            this.hideSpinner(component);
        });
        $A.enqueueAction(action);
    },

    /**
     * @description: sets data import fields to use dynamically in the recordEditForm.
     * @param model: full DataImportModel from the Apex controller
     */
    setModel: function (component, model) {
        component.set('v.isNamespaced', Boolean(model.isNamespaced));
        component.set('v.labels', model.labels);
        this.setColumns(component, model.columns);
        this.setDataServiceFields(component, model.labels);
        this.setDataTableRows(component, [], model.dataImportRows);
        this.setTotals(component, model);
        this.setDataImportFields(component, model.columns);
        component.set('v.isLoaded', true);
    },

    /**
     * @description: sets column with a derived Donor field, any columns passed from Apex, and Delete action.
     * @param dataColumns: custom Column class data passed from the Apex controller.
     */
    setColumns: function(component, dataColumns) {
        var columns = [];
        var referenceFields = [];
        columns.push({
            label: 'Donor',
            fieldName: 'donorLink',
            type: 'url',
            editable: false,
            typeAttributes: {label: {fieldName: 'donorName'}}});

        dataColumns.forEach(function(col){
            if (col.type !== 'reference') {
                columns.push({
                    label: col.label,
                    fieldName: col.fieldName,
                    type: col.type,
                    editable: !col.readOnly,
                    typeAttributes: JSON.parse(col.typeAttributes)
                });
            } else {
                referenceFields.push(col.fieldName);
            }
        });

        columns.push({
            type: 'action',
            typeAttributes: {
                rowActions: [
                    {
                        label: $A.get('$Label.c.bgeActionView'),
                        name: 'view',
                        title: $A.get('$Label.c.bgeActionView')
                    },
                    {
                        label: $A.get('$Label.c.bgeActionDelete'),
                        name: 'delete',
                        title: $A.get('$Label.c.bgeActionDelete')
                    }
                ]
            }
        });

        component.set('v.columns', columns);
        component.set('v.referenceFields', referenceFields);
    },

    /**
     * @description: sets data import fields for dynamic use in the recordEditForm.
     * Excludes read-only fields, except reference fields which are read-only in grid but editable in form.
     * This logic may need to be revisited as requirements get more complex. (Grid-only, Form-only, etc)
     * For now, it works and minimizes Column attributes.
     * @param dataColumns: custom Column class data passed from the Apex controller.
     */
    setDataImportFields: function (component, dataColumns) {
        var dataImportFields = [];

        dataColumns.forEach(function(field){
            if (!field.readOnly || field.type == 'reference') {
                dataImportFields.push({
                    label: field.label,
                    name: field.fieldName,
                    options: field.options,
                    required: field.required,
                    value: field.defaultValue,
                    type: field.type
                });
            }
        });

        component.set('v.dataImportFields', dataImportFields);
    },

    /**
     * @description: sets the data service fields to use the correct field labels depending on namespacing
     * @param labels: all labels for the app
     */
    setDataServiceFields: function(component, labels) {
        var fields = [];
        fields.push(labels.expectedCountField);
        fields.push(labels.expectedTotalField);
        fields.push(labels.requireTotalMatch);
        fields.push('Name');
        component.set('v.batchFields', fields);
    },

    /**
     * @description: creates the data entry form component
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

    /******************************** Datatable Infinite Load Functions *****************************/

    /**
     * @description: retrieves additional rows to support infinite loading in data import datatable
     */
    getDataImportRows: function(component, event) {
        let data = component.get('v.data');
        let action = component.get('c.getDataImportRows');
        action.setParams({
            batchId: component.get('v.recordId'),
            offset: data.length
        });
        action.setCallback(this, function (response) {
            const state = response.getState();
            if (state === 'SUCCESS') {
                let responseRows = response.getReturnValue();
                this.setDataTableRows(component, data, responseRows);
            } else {
                this.handleApexErrors(component, response.getError());
            }
            event.getSource().set('v.isLoading', false);
        });
        $A.enqueueAction(action);
    },

    /**
     * @description: sets rows and row-level errors in the datatable
     * @param baseRows: an empty array if table is fresh or a list of existing rows for infinite scroll
     * @param responseRows: custom DataImportRow class data passed from the Apex controller.
     */
    setDataTableRows: function(component, baseRows, responseRows) {
        let rows = [];
        let errors = [];

        for (let i=0; i<responseRows.length; i++) {
            const row = this.flattenDataImportRow(component, responseRows[i]);
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
        }

        if (errors) {
            this.handleNewTableErrors(component, errors);
        }

        let data = baseRows.concat(rows);
        component.set('v.data', data);
    },

    /******************************** Insert and Update Functions *****************************/

    /**
     * @description: starts the BDI dry run to verify DataImport__c matches
     * @param recordIds: list of DataImport__c RecordIds to check for dry run
     */
    runNewRecordDryRun: function(component, recordId) {
        var action = component.get('c.runDryRun');
        var batchId = component.get('v.recordId');
        this.showSpinner(component);
        action.setParams({dataImportId: recordId, batchId: batchId});
        action.setCallback(this, function (response) {
            var state = response.getState();
            if (state === 'SUCCESS') {
                this.afterDryRun(component, JSON.parse(response.getReturnValue()), true);
            } else {
                this.handleApexErrors(component, response.getError());
            }
            this.hideSpinner(component);
        });
        $A.enqueueAction(action);
    },

    /**
     * @description: saves inline edits from dataTable and completes dry run for the record
     * @param draftValues: changed values in the table with IDs and any changed values by API name
     */
    handleRowEdit: function(component, draftValue) {
        this.showSpinner(component);
        var action = component.get('c.updateAndDryRunRow');
        action.setParams({dataImport: draftValue, batchId: component.get('v.recordId')});
        action.setCallback(this, function (response) {
            var state = response.getState();
            if (state === 'SUCCESS') {
                this.showToast(component, $A.get('$Label.c.PageMessagesConfirm'), $A.get('$Label.c.bgeGridGiftUpdated'), 'success');
                this.afterDryRun(component, JSON.parse(response.getReturnValue()), false);
            } else {
                this.handleApexErrors(component, response.getError());
            }
            this.hideSpinner(component);
        });
        $A.enqueueAction(action);
    },

    /**
     * @description: set new total amount and count variables and update data table after dry run completes
     * @param updatedRecord: DataImport__c record that needs to be updated in the table
     * @param isNewRecord: flag to indicate if record is new or existing
     */
    afterDryRun: function(component, model, isNewRecord) {
        this.setTotals(component, model);
        if (model.dataImportRows.length > 0) {
            //we only process one record at a time, but the model passes back a list
            let newRecord = model.dataImportRows[0];
            this.updateDataTableAfterDryRun(component, newRecord, isNewRecord);
        }
    },

    /**
     * @description: insert or update record and possible error into the table data
     * @param updatedRecord: DataImport__c record that needs to be updated in the table
     * @param isNewRecord: flag to indicate if record needs to be inserted or replaced
     */
    updateDataTableAfterDryRun: function (component, updatedRecord, isNewRecord) {
        let tableRow = this.flattenDataImportRow(component, updatedRecord);
        let hasError = false;

        //get payment and opportunity error information if import failed
        if (tableRow.errors.length > 0) {
            hasError = true;
            let rowError = {
                id: tableRow.Id,
                title: $A.get('$Label.c.PageMessagesError'),
                messages: tableRow.errors
            };
            this.handleNewTableErrors(component, [rowError]);
        }

        if (isNewRecord) {
            this.insertTableRow(component, tableRow);
        } else {
            this.replaceTableRow(component, tableRow);
            if (!hasError) {
                this.clearOldTableErrors(component, tableRow.Id);
            }
        }
    },

    /**
     * @description: inserts the new row into the first spot on the table
     * @param tableRow: flattened row for insert into the table
     */
    insertTableRow: function(component, tableRow) {
        let rows = component.get('v.data');
        rows.unshift(tableRow);
        component.set('v.data', rows);
    },

    /**
     * @description: finds the index of the row and replaces it with the updated row
     * @param tableRow: flattened row for insert into the table
     */
    replaceTableRow: function(component, tableRow) {
        let rows = component.get('v.data');
        for (let i = 0; i < rows.length; i++) {
            if (rows[i].Id === tableRow.Id) {
                rows[i] = tableRow;
                break;
            }
        }
        component.set('v.data', rows);
    },

    /******************************** Table Error Functions *****************************/

    /**
     * @description: handles the display or clearing of errors from the results of dry run
     * @param rowErrors: list of objects with row Id, title, and list of associated messages
     */
    handleNewTableErrors: function(component, newErrors) {
        let tableErrors = component.get('v.errors');
        if (!tableErrors) {
            tableErrors = { rows: {}, table: {}, size: 0 };
        }

        newErrors.forEach(function(error) {
            //only insert new errors
            if (!tableErrors.rows.hasOwnProperty(error.id)) {
                const rowError = {
                    title: error.title,
                    messages: error.messages
                };
                tableErrors.rows[error.id] = rowError;
            }
        });

        tableErrors.size = newErrors.length;

        component.set('v.errors', tableErrors);
    },

    /**
     * @description: deletes rowID property in the row Object on the table if a row is updated or deleted
     * @param rowId: Id of the row with the error that needs clearing
     */
    clearOldTableErrors: function(component, rowId) {
        let tableErrors = component.get('v.errors');
        if (!tableErrors) {
            tableErrors = { rows: {}, table: {}, size: 0 };
        }
        if (tableErrors.rows.hasOwnProperty(rowId)) {
            delete tableErrors.rows[rowId];
            let errorSize = tableErrors.size > 1 ? tableErrors.size - 1 : 0;
            tableErrors.size = errorSize;
            component.set('v.errors', tableErrors);
        }
    },

    /******************************** Process Batch Functions *****************************/

    /**
     * @description: redirects the user to the Process Batch page if validity conditions are met
     */
    processBatch: function(component) {
        let userCanProcessBatch = (this.tableHasNoDryRunErrors(component) && this.totalsMatchIfRequired(component));

        if (userCanProcessBatch) {
            const batchId = component.get('v.recordId');
            const bdiBatchClass = component.get('v.labels.bdiBatchClass');
            let url = '/apex/' + bdiBatchClass + '?batchId=' + batchId + '&retURL=' + batchId;
            let urlEvent = $A.get('e.force:navigateToURL');
            urlEvent.setParams({
                'url': url
            });
            urlEvent.fire();
        }
    },

    /**
     * @description: if totals are required, verifies that totals match. Otherwise, shows an error toast and returns false.
     * @return: boolean indicating if table has errors
     */
    tableHasNoDryRunErrors: function(component) {
        const errors = component.get('v.errors');
        let tableHasNoDryRunErrors = true;

        if (errors && errors.size > 0) {
            this.showToast(component, $A.get('$Label.c.PageMessagesError'), $A.get('$Label.c.bgeGridErrorFromDryRun'), 'error');
            tableHasNoDryRunErrors = false;
        }
        return tableHasNoDryRunErrors;
    },

    /**
     * @description: if totals are required, verifies that totals match. Otherwise, shows an error toast and returns false.
     * @return: boolean indicating if totals match if required
     */
    totalsMatchIfRequired: function(component) {
        const totals = component.get('v.totals');
        const record = component.get('v.record');
        const labels = component.get('v.labels');

        let totalsMatchIfRequired = true;

        if (record[labels.requireTotalMatch]) {
            if (record[labels.expectedCountField] == 0 && record[labels.expectedTotalField] == 0) {
                this.showToast(component, $A.get('$Label.c.PageMessagesError'), $A.get('$Label.c.bgeGridWarningRequiredTotalsExpected'), 'warning');
                totalsMatchIfRequired = false;
            }

            if ((record[labels.expectedTotalField] != 0 && totals.totalGiftAmount != record[labels.expectedTotalField]) ||
                (record[labels.expectedCountField] != 0 && totals.countGifts != record[labels.expectedCountField])) {
                this.showToast(component, $A.get('$Label.c.PageMessagesError'), $A.get('$Label.c.bgeGridErrorRequiredTotalsExpected'), 'error');
                totalsMatchIfRequired = false;
            }
        }

        return totalsMatchIfRequired;
    },

    /******************************** Edit Batch Modal Functions *****************************/

    /**
     * @description: checks that user has all necessary permissions and then launches modal or displays error
     */
    checkFieldPermissions: function(component, event, helper) {
        var action = component.get('c.checkFieldPermissions');
        action.setCallback(this, function (response) {
            var state = response.getState();
            if (state === 'SUCCESS') {
                this.openBatchWizard(component, event);
            } else if (state === 'ERROR') {
                this.handleApexErrors(component, response.getError());
            }
        });
        $A.enqueueAction(action);
    },

    /**
     * @description: opens the batch wizard modal for edit mode of the component
     */
    openBatchWizard: function(component, event) {
        let modalBody;
        let modalHeader;
        let modalFooter;
        const batchId = component.get('v.recordId');

        let progressStepLabels = [
            $A.get('$Label.c.bgeBatchOverviewWizard'),
            $A.get('$Label.c.bgeBatchSelectFields'),
            $A.get('$Label.c.bgeBatchSetFieldOptions'),
            $A.get('$Label.c.bgeBatchSetBatchOptions')
        ];

        $A.createComponents([
                ['c:BGE_ConfigurationWizard', {sObjectName: 'DataImportBatch__c', recordId: batchId}],
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

    /******************************** Row-Level Action Functions *****************************/

    /**
     * @description: Navigates to the record view of the Data Import record
     * @param row: Information about which row the action was called from
     */
    handleViewRowAction: function(component, row) {
        let navEvt = $A.get("e.force:navigateToSObject");
        navEvt.setParams({
            recordId: row.Id,
            slideDevName: 'detail'
        });
        navEvt.fire();
    },

    /**
     * @description: Deletes the data import record displayed in a given row
     * @param row: Information about which row the action was called from
     */
    handleDeleteRowAction: function(component, row) {
        this.showSpinner(component);
        let action = component.get('c.deleteDataImportRow');
        action.setParams({batchId: component.get('v.recordId'), dataImportId: row.Id});
        action.setCallback(this, function (response) {
            const state = response.getState();
            if (state === 'SUCCESS') {
                const model = JSON.parse(response.getReturnValue());
                this.removeDataImportRow(component, row);
                this.clearOldTableErrors(component, row.Id);
                this.setTotals(component, model);
                this.showToast(component, $A.get('$Label.c.PageMessagesConfirm'), $A.get('$Label.c.bgeGridGiftDeleted'), 'success');
            } else {
                this.handleApexErrors(component, response.getError());
            }
            this.hideSpinner(component);
        });
        $A.enqueueAction(action);
    },

    /**
     * @description: Removes the selected row from the datatable
     * @param row: Selected row that has been deleted from the server
     */
    removeDataImportRow: function(component, row) {
        let rows = component.get('v.data');
        const rowIndex = rows.indexOf(row);
        rows.splice(rowIndex, 1);
        component.set('v.data', rows);
    },

    /******************************** Utility Functions *****************************/

    /**
     * @description: flattens the DataImportRow class data to include donor information at the same level as the rest of the DataImport__c record.
     * @param currentRow: custom DataImportRow class data passed from the Apex controller.
     * @return Object row
     */
    flattenDataImportRow: function(component, currentRow) {
        const referenceFields = component.get('v.referenceFields');

        let row = currentRow.record;
        row.donorName = currentRow.donorName;
        row.donorLink = currentRow.donorLink;
        row.matchedRecordUrl = currentRow.matchedRecordUrl;
        row.matchedRecordLabel = currentRow.matchedRecordLabel;
        row.errors = currentRow.errors;

        // reformat lookups to display as links in datatable
        referenceFields.forEach(function(fieldName) {
            if (row[fieldName]) {
                let linkFieldLabel = fieldName + '_label';
                let linkFieldName = fieldName + '_link';
                let relationshipName = fieldName.slice(0, -1) + 'r';
                // The relationship will have exactly two attributes:
                // Id and the name field (e.g., Name, CaseNumber, etc.)
                // They are sorted alphabetically, so references to different objects may have
                // these attributes in differring orders. Iterate to find and use the non-Id value.
                Object.keys(row[relationshipName]).forEach(function(key,index) {
                    if (key !== 'Id') {
                        row[linkFieldLabel] = row[relationshipName][key];
                    }
                });
                row[linkFieldName] = '/' + row[fieldName];
            }
        });

        return row;
    },

    /**
     * @description: Sets the total number and amount of Data Import Batch rows
     * @param model: Apex model for the batch entry component
     */
    setTotals: function (component, model) {
        var totals = component.get('v.totals');
        totals.countGifts = model.totalCountOfRows;
        totals.totalGiftAmount = model.totalRowAmount;
        component.set('v.totals', totals);
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

    /**
     * @description: shows spinner over BGE_EntryForm component
     */
    showFormSpinner: function (component) {
        var spinner = component.find('formSpinner');
        $A.util.removeClass(spinner, 'slds-hide');
    },

    /**
     * @description: shows spinner over lightning:dataTable component
     */
    showSpinner: function (component) {
        var spinner = component.find('dataTableSpinner');
        $A.util.removeClass(spinner, 'slds-hide');
    },

    /**
     * @description: hides spinner over BGE_EntryForm component
     */
    hideFormSpinner: function (component) {
        var spinner = component.find('formSpinner');
        $A.util.addClass(spinner, 'slds-hide');
    },

    /**
     * @description: hides spinner over lightning:dataTable component
     */
    hideSpinner: function (component) {
        var spinner = component.find('dataTableSpinner');
        $A.util.addClass(spinner, 'slds-hide');
    }

})