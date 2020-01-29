({
    handleEditBatch: function (component) {

        const closeModal = function (component) {
            component.find('giftEntryFormOverlayLib').notifyClose();
        };

        $A.createComponents([["c:geBatchWizard", {
                recordId: component.get('v.recordId'),
                dedicatedListenerEventName: 'geBatchWizardEvent',
            }]],
            function (components, status, errorMessage) {
                if (status === "SUCCESS") {
                    let modalReference =
                        component.find('giftEntryFormOverlayLib').showCustomModal({
                            body: components[0],
                            cssClass: "slds-modal_large",
                            closeModal: closeModal,
                        });
                    component.set('v.modal', modalReference);
                } else {
                    console.error(errorMessage);
                }
            }
        );
    },

    handleBatchWizardEvent: function (component) {
        component.get('v.modal').then(modal => {
            modal.close();
        });
    },

});