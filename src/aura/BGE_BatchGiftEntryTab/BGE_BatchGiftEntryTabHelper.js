({
    doInit: function(component) {
        /*
        let testColumns = 'Name,Batch_Description__c,CreatedById,CreatedDate';
        var columns = [
            {label: 'Name', fieldName: 'Name', type: 'text'},
            {label: 'Description', fieldName: 'Batch_Description__c', type: 'text'},
        ];

        columns.push({label: 'Created By', fieldName: 'CreatedById', type: 'url', editable: false, typeAttributes: {label: {fieldName: 'CreatedBy.Name'}}});
        columns.push({label: 'Created Date', fieldName: 'CreatedDate', type: 'date'});

        component.set('v.batchListColumns',columns);
        */

        var action = component.get('c.getTabModel');
        action.setCallback(this, function (response) {
            const state = response.getState();
            if (state === 'SUCCESS') {
                let model = JSON.parse(response.getReturnValue());

                // TODO: separate load columns function
                var columns = [];
                console.log(JSON.stringify(model.batches));
                columns.push({
                    // TODO: make this a real label
                    label: 'Batch',
                    fieldName: 'batchLink',
                    type: 'url',
                    typeAttributes: {label:{fieldName:"Name"},target:"_blank"}
                });
                model.columns.forEach(function(col){
                    columns.push(col);
                });
                component.set('v.batchListColumns',columns);

                this.loadBatchRows(component, model.batches);
            } else {
                this.handleApexErrors(component, response.getError());
            }
        });
        $A.enqueueAction(action)


        /*
        var action = component.get('c.getNamespacedListView');
        action.setCallback(this, function (response) {
            const state = response.getState();
            if (state === 'SUCCESS') {
                let namespacedListView = response.getReturnValue();
                $A.createComponent(
                    "lightning:listView",
                    {
                        "objectApiName": namespacedListView.objectApiName,
                        "listName": namespacedListView.listName,
                        "showActionBar": false,
                        "enableInlineEdit": false,
                        "showRowLevelActions": false
                    },
                    function (listView, status, errorMessage) {
                        if (status === "SUCCESS") {
                            let body = component.get("v.body");
                            body.push(listView);
                            component.set("v.body", body);
                        } else {
                            this.showToast(component, $A.get('$Label.c.PageMessagesError'), errorMessage, 'error');
                        }
                    }
                );
            } else {
                this.handleApexErrors(component, response.getError());
            }
        });
        $A.enqueueAction(action);*/
    },

    /**
     * @description: loads Batch Rows into datatable data
     * @param batches: list of BatchRow wrappers
     */
    loadBatchRows: function(component, responseRows) {
        responseRows.forEach(function(currentRow) {
            currentRow.batchLink = '/' + currentRow.Id;
            currentRow.CreatedByName = currentRow.CreatedBy.Name;
        });
        component.set('v.batchData', responseRows);
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