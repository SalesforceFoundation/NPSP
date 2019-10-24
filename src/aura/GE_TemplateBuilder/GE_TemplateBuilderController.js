({
    /*******************************************************************************
    * @description Receives an event from geTemplateBuilder to open a modal through
    * the aura overlay library. We're opting to use this library to get out-of-the-box
    * acccessibility modal features like focus trapping, input focus, and tabbing.
    *
    * This method sets a two-way bound aura attribute 'sectionBeingEdited' on this
    * and the GE_ModalProxy aura components. The GE_ModalProxy component is a container
    * for the lightning web component utilModal. GE_ModalProxy receives events from utilModal
    * for actions (save, cancel, delete), GE_ModalProxy sets the 'sectionBeingEdited' aura
    * attribute, and GE_TemplateBuilder listens for that change via an aura change handler on
    * the attribute 'sectionBeingEdited'. When a change occurs on 'sectionBeingEdited' we fire
    * a public method on geTemplateBuilder to handle the change.
    */
    handleShowModal: function (component, event, helper) {
        $A.createComponents([
            ["c:utilModal", { modalData: event.getParams('section') }]
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
                        /* We have to use the overlay reference returned by
                        *  overlay library's showCustomModal promise in order
                        *  to close the modal. Reference is lost otherwise.
                        */
                        const eventListener = function(event) {
                            window.removeEventListener('utilModalEvent', eventListener);
                            const modalData = event.detail;
                            if (modalData.action === 'save' || modalData.action === 'delete') {
                                component.find('templateBuilder').notify(modalData);
                            }
                            overlay.close();
                        }

                        window.addEventListener('utilModalEvent', eventListener);
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