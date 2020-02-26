({
    handleEditBatch: function (component) {

        const closeModal = function (component) {
            component.find('giftEntryFormOverlayLib').notifyClose();
        };

        $A.createComponents([["c:geBatchWizard", {
                recordId: component.get('v.recordId'),
                dedicatedListenerEventName: 'geBatchWizardFormEvent',
            }]],
            function (components, status, errorMessage) {
                if (status === "SUCCESS") {
                    let modalReference =
                        component.find('giftEntryFormOverlayLib').showCustomModal({
                            body: components[0],
                            cssClass: component.getName() + " slds-modal_large custom-modal",
                            closeModal: closeModal,
                        });
                    component.set('v.modal', modalReference);
                } else {
                    console.error(errorMessage);
                }
            }
        );
    },

    closeModal: function (component) {
        const modalReference = component.get('v.modal');
        if (modalReference) {
            modalReference.then(modal => {
                modal.close();
            });
        }
    },

    handleReviewDonationsModal: function (component, event, helper) {
        const payload = event.getParams('detail');

        $A.createComponents([[`c:${payload.modalProperties.componentName}`, payload.componentProperties]],
            function (components, status, errorMessage) {
                if (status === "SUCCESS") {
                    const modalBody = components[0];

                    let modalReference = component.find('giftEntryFormOverlayLib').showCustomModal({
                        header: payload.modalProperties.header || '',
                        showCloseButton: payload.modalProperties.showCloseButton || true,
                        cssClass: component.getName() + ' custom-modal ' + payload.modalProperties.cssClass,
                        closeCallback: payload.modalProperties.closeCallback || function () {
                            component.set('v.isLoading', false);
                        },
                        body: modalBody,
                    });

                    component.set('v.modal', modalReference);
                } else {
                    console.error(errorMessage);
                }
            }
        );
    }

});