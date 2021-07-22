({
    /*******************************************************************************
    * @description Receives an event from lightning web component geTemplateBuilder
    * to open a modal using the aura overlay library. We're opting to use this library
    * to get out-of-the-box accessibility modal features like focus trapping,
    * input focus, and tabbing.
    */
    handleShowModal: function (component, event, helper) {
        $A.createComponents([
            ["c:geTemplateBuilderSectionModalBody", { modalData: event.getParams('section') }]
        ],
            function (components, status, errorMessage) {
                if (status === "SUCCESS") {
                    const modalBody = components[0];

                    let modalReference = component.find('overlayLib').showCustomModal({
                        header: $A.get('$Label.c.geHeaderFormFieldsModalSectionSettings'),
                        body: modalBody,
                        showCloseButton: true,
                        cssClass: component.getName() + ' customModal'
                    });

                    component.set('v.modal', modalReference);
                }
            }
        );
    },

    /*******************************************************************************
    * @description Action for the aura change handler on the attribute
    * 'sectionBeingEdited'. Fires a public method 'notify' on the lightning web component
    * geTemplateBuilder and passes that change down to be handled there.
    */
    handleSectionModalEvent: function (component, event, helper) {
        const details = event.getParams();

        if (details.action === 'delete' || details.action === 'save') {
            component.find('templateBuilder').notify(details);
        }

        component.get('v.modal').then(modal => {
            modal.close();
        });
    }
})
