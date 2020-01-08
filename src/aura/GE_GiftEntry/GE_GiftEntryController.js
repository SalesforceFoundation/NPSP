({
    /*******************************************************************************
    * @description Receives an event from lightning web component geTemplates
    * to open a modal using the aura overlay library. We're opting to use this library
    * to get out-of-the-box accessibility modal features like focus trapping,
    * input focus, and tabbing.
    */
    handleShowModal: function (component, event, helper) {
        const payload = event.getParams('detail');

        $A.createComponents([[`c:${payload.modalProperties.componentName}`, payload.componentProperties]],
            function (components, status, errorMessage) {
                if (status === "SUCCESS") {
                    const modalBody = components[0];

                    let modalReference = component.find('overlayLib').showCustomModal({
                        header: payload.modalProperties.header || '',
                        showCloseButton: payload.modalProperties.showCloseButton || true,
                        cssClass: component.getName() + ' custom-modal ' + payload.modalProperties.cssClass,
                        closeCallback: payload.modalProperties.closeCallback || {},
                        body: modalBody,
                    });

                    component.set('v.modal', modalReference);
                } else {
                    console.error(errorMessage);
                }
            }
        );
    },

    /*******************************************************************************
    * @description Handles receipt of events from utilDedicatedListener component
    * and notifies the geTemplates component.
    */
    handleModalEvent: function (component, event, helper) {
        const details = event.getParams('detail');

        if (details.action === 'save') {
            component.find('giftEntry').notify(details);
        }

        component.get('v.modal').then(modal => {
            modal.close();
        });
    },

    /*******************************************************************************
    * @description Handles receipt of events from utilDedicatedListener component
    * and notifies the geTemplates component.
    */
    handleBatchWizardEvent: function (component, event, helper) {
        console.log('************--- handleBatchWizardEvent');
        const details = event.getParams('detail');

        component.get('v.modal').then(modal => {
            modal.close();
        });
    }
})
