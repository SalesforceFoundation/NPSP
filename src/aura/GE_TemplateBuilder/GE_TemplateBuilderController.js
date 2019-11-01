({
    /*******************************************************************************
    * @description Receives an event from lightning web component geTemplateBuilder
    * to open a modal using the aura overlay library. We're opting to use this library
    * to get out-of-the-box acccessibility modal features like focus trapping,
    * input focus, and tabbing.
    *
    * In the then() method of the showCustomModal promise, we register
    * an event listener for custom event 'geTemplateBuilderSectionModalBodyEvent' which gets
    * dispatched from the modal's body lightning web component 'geTemplateBuilderSectionModalBody'.
    */
    handleShowModal: function (component, event, helper) {
        $A.createComponents([
            ["c:geTemplateBuilderSectionModalBody", { modalData: event.getParams('section') }]
        ],
            function (components, status, errorMessage) {
                if (status === "SUCCESS") {
                    const modalBody = components[0];

                    component.find('overlayLib').showCustomModal({
                        header: 'Edit Section',
                        body: modalBody,
                        showCloseButton: true,
                        cssClass: component.getName() + ' customModal',
                        closeCallback: function () {
                        }
                    }).then((overlay) => {
                        /* We're adding an event listener here because we need
                        * the 'overlay' reference returned by the then() method
                        * in order to close the modal. Reference is lost otherwise.
                        */

                        const eventListener = function(event) {
                            window.removeEventListener('geTemplateBuilderSectionModalBodyEvent', eventListener);
                            const modalData = event.detail;
                            if (modalData.action === 'save' || modalData.action === 'delete') {
                                component.find('templateBuilder').notify(modalData);
                            }
                            overlay.close();
                        }

                        window.addEventListener('geTemplateBuilderSectionModalBodyEvent', eventListener);
                    });
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
        const sectionBeingEdited = component.get('v.sectionBeingEdited');

        if (sectionBeingEdited.action === 'delete' || sectionBeingEdited.action === 'save') {
            component.find('templateBuilder').notify(component.get('v.sectionBeingEdited'));
        }
    }
})