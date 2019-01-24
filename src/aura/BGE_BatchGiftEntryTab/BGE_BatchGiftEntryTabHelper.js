({
    doInit: function(component) {
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
        $A.enqueueAction(action);
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