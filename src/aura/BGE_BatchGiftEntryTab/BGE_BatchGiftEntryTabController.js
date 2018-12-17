({
    /**
     * @description: instantiates component. Only called when component is first loaded.
     */
    doInit: function (component, event) {
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
                const errors = response.getError();
                let message;
                if (errors && errors[0] && errors[0].message) {
                    message = errors[0].message;
                } else {
                    message = 'Unknown error';
                }
                component.find('notifLib').showToast({
                    'variant': 'error',
                    'mode': 'sticky',
                    'title': $A.get('$Label.c.PageMessagesError'),
                    'message': message
                });
            }
        });
        $A.enqueueAction(action);
    },

    /**
     * @description: creates the configuration modal
     */
    openNewBatchWizard:function(component, event) {
        var modalBody;
        var modalHeader;
        var modalFooter;

        $A.createComponents([
                ['c:BGE_ConfigurationWizard', {sObjectName: 'DataImportBatch__c'}],
                ['c:modalHeader', {header: $A.get('$Label.c.bgeBatchInfoWizard')}],
                ['c:modalFooter', {}]
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
    }

})