({
    /*******************************************************************************
    * @description Receives an event from lightning web component geTemplates
    * to open a modal using the aura overlay library. We're opting to use this library
    * to get out-of-the-box accessibility modal features like focus trapping,
    * input focus, and tabbing.
    */
    handleShowModal: function (component, event, helper) {
        const payload = event.getParams('detail');
        const config = {
            cssClass: 'slds-m-bottom_medium slds-p-horizontal_small',
            name: payload.name,
            options: payload.options,
            values: payload.values,
            sourceLabel: payload.sourceLabel,
            selectedLabel: payload.selectedLabel,
            showModalFooter: true,
            dedicatedListenerEventName: 'geGiftEntryModalEvent'
        }

        $A.createComponents([["c:utilDualListbox", config]],
            function (components, status, errorMessage) {
                if (status === "SUCCESS") {
                    const modalBody = components[0];

                    let modalReference = component.find('overlayLib').showCustomModal({
                        header: $A.get("$Label.c.geHeaderCustomTableHeaders"),
                        body: modalBody,
                        showCloseButton: true,
                        cssClass: component.getName() + ' customModal'
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
    }
})
