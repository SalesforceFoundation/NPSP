({
    /**
     * @description: creates the form component
     */
    createEntryForm: function (component) {
        $A.createComponent(
            "c:BGE_EntryForm",
            {
                "aura:id": "entryForm",
                "labels": component.get("v.labels"),
                "donorType": component.get("v.donorType"),
                "recordId": component.get("v.recordId"),
                "dataImportFields": component.get("v.dataImportFields")
            },
            function(newComponent, status, errorMessage){
                //Add the new component to the body array
                if (status === "SUCCESS") {
                    var body = component.get("v.body");
                    body.push(newComponent);
                    component.set("v.body", body);
                }
                else if (status === "INCOMPLETE") {
                    console.log("No response from server or client is offline.")
                    // Show offline error
                }
                else if (status === "ERROR") {
                    console.log("Error: " + errorMessage);
                    // Show error message
                }
            }
        );
    },

    /**
     * @description: retrieves the dataImportRows and sets them to the table.
     */
    getDIs: function (component) {
        this.showSpinner(component);
        var action = component.get("c.getDataImports");
        action.setParams({batchId: component.get("v.recordId")});
        action.setCallback(this, function (response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var responseRows = response.getReturnValue();
                this.setDataTableRows(component, responseRows);
                this.setTotals(component, responseRows);
                var openRoad = component.find("openRoadIllustration");
                if (responseRows.length === 0) {
                    $A.util.removeClass(openRoad, "slds-hide");
                } else {
                    $A.util.addClass(openRoad, "slds-hide");
                }
            } else {
                this.showToast(component, 'Error', response.getReturnValue());
            }
            this.hideSpinner(component);
        });
        $A.enqueueAction(action);
    },

    /**
     * @description: retrieves the model information. If successful, sets the model; otherwise alerts user.
     */
    getModel: function(component) {
        var action = component.get("c.getDataImportModel");
        action.setParams({batchId: component.get("v.recordId")});
        action.setCallback(this, function (response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var response = JSON.parse(response.getReturnValue());
                this.setModel(component, response);
                this.createEntryForm(component, response);
            } else {
                this.showToast(component, 'Error', response.getReturnValue());
            }
            this.hideSpinner(component);
        });
        $A.enqueueAction(action);
    },

    /**
     * @description: saves inline edits from dataTable.
     */
    handleTableSave: function(component, values) {
        this.showSpinner(component);
        var action = component.get("c.updateDataImports");
        action.setParams({diList: values});
        action.setCallback(this, function (response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                this.getDIs(component);
                this.showToast(component, 'Success', 'Gifts successfully updated.');
            } else {
                this.showToast(component, 'Error', response.getReturnValue());
            }
            this.hideSpinner(component);
        });
        $A.enqueueAction(action);
    },

    /**
     * @description: sets column with a derived Donor field, any columns passed from Apex, and available actions.
     * @param dataColumns: custom Column class data passed from the Apex controller.
     */
    setColumns: function(component, dataColumns) {
        var columns = [];
        columns.push({label: 'Donor', fieldName: 'donor', type: 'text', editable: false});

        dataColumns.forEach(function(col){
            columns.push({label: col.label, fieldName: col.fieldName, type: col.type, editable: col.editable});
        });

        columns.push({type: 'action', typeAttributes: { rowActions: [{label: 'Delete', name: 'delete', title: 'Delete'}] }
        });

        component.set('v.columns', columns);
    },

    /**
     * @description: sets data import fields to use dynamically in the recordEditForm.
     * @param dataColumns: custom Column class data passed from the Apex controller.
     */
    setDataImportFields: function (component, dataColumns) {
        var dataImportFields = [];

        dataColumns.forEach(function(field){
            dataImportFields.push({label: field.label, name: field.fieldName});
        });

        component.set('v.dataImportFields', dataImportFields);
    },

    /**
     * @description: flattens the DataImportRow class data to include donor information at the same level as the rest of the DataImport__c record.
     * @param responseRows: custom DataImportRow class data passed from the Apex controller.
     */
    setDataTableRows: function(component, responseRows) {
        var rows = [];
        responseRows.forEach(function (currentRow) {
            var row = currentRow.record;
            row.donor = currentRow.donor;
            rows.push(row);
        });

        var openRoad = component.find("openRoadIllustration");
        if (responseRows.length === 0) {
            $A.util.removeClass(openRoad, "slds-hide");
        } else {
            $A.util.addClass(openRoad, "slds-hide");
        }

        component.set("v.data", rows);
    },

    /**
     * @description: sets data import fields to use dynamically in the recordEditForm.
     * @param dataColumns: custom Column class data passed from the Apex controller.
     */
    setModel: function (component, model) {
        component.set("v.labels", model.labels);
        this.setDataTableRows(component, model.dataImportRows);
        this.setTotals(component, model.dataImportRows);
        this.setColumns(component, model.columns);
        this.setDataImportFields(component, model.columns);
    },

    /**
     * @description: Calculates actual totals from queried Data Import records
     * @param rows: rows returned from the apex controller
     */
    setTotals: function (component, rows) {
        var countGifts = 0;
        var totalGiftAmount = 0;
        rows.forEach(function (currentRow) {
            var row = currentRow.record;
            countGifts += 1;
            totalGiftAmount += row[component.get("v.labels.donationAmountField")];
        });
        var totals = component.get("v.totals");
        totals.countGifts = countGifts;
        totals.totalGiftAmount = totalGiftAmount;
        component.set("v.totals", totals);
    },

    /**
     * @description: displays standard toast to user based on success or failure of their action
     * @param type: used for Title and Type on toast, depending on case
     * @param message: body of message to display
     */
    showToast: function(component, type, message) {
        var mode;
        if (type === 'Error') {
            mode = 'sticky';
        } else {
            mode = 'pester';
        }

        component.find('notifLib').showToast({
            "variant": type.toLowerCase(),
            "mode": mode,
            "title": type,
            "message": message
        });
    },

    /**
     * @description: shows lightning:dataTable spinner
     */
    showSpinner: function (component) {
        var spinner = component.find("dataTableSpinner");
        $A.util.removeClass(spinner, "slds-hide");
    },

    /**
     * @description: hides lightning:dataTable spinner
     */
    hideSpinner: function (component) {
        var spinner = component.find("dataTableSpinner");
        $A.util.addClass(spinner, "slds-hide");
    }

})