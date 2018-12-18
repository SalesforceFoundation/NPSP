({
    /**
     * @description: instantiates component. Only called when component is first loaded.
     */
    doInit: function (component, event) {
        var action = component.get('c.isOrgNamespaced');
        action.setCallback(this, function (response) {
            var state = response.getState();
            if (state === 'SUCCESS') {
                var isOrgNamespaced = JSON.parse(response.getReturnValue());
                if (isOrgNamespaced) {
                    var listViewNamespaced = {
                        'objectApiName': 'npsp__DataImportBatch__c',
                        'listName': 'npsp__Gift_Batches',
                        'isLoaded': true
                    };
                    component.set('v.listView', listViewNamespaced);
                } else {
                    var listViewUnnamespaced = {
                        'objectApiName': 'DataImportBatch__c',
                        'listName': 'Gift_Batches',
                        'isLoaded': true
                    };
                    component.set('v.listView', listViewUnnamespaced);
                }
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

        let progressStepLabels = [$A.get('$Label.c.bgeBatchOverviewWizard'),
            $A.get('$Label.c.bgeBatchSelectFields'),
            $A.get('$Label.c.bgeBatchSetFieldOptions'),
            $A.get('$Label.c.bgeBatchSetBatchOptions')];

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
    }

})