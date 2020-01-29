({
    
    doInit: function(cmp) {
        var action = cmp.get("c.createDefaultTemplate");

        action.setCallback(this, function(response) {
            var state = response.getState();

            if (state === "SUCCESS") {

                cmp.set('v.finishedInit', true);
            }
            else if (state === "INCOMPLETE") {
                // do something
            }
            else if (state === "ERROR") {
                var errors = response.getError();
                
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        console.log("Error message: " + 
                                 errors[0].message);
                    }
                } else {
                    console.log("Unknown error");
                }
            }
        });

        $A.enqueueAction(action);
    },    
    
    /*******************************************************************************
    * @description Receives an event from lightning web component geTemplates
    * to open a modal using the aura overlay library. We're opting to use this library
    * to get out-of-the-box accessibility modal features like focus trapping,
    * input focus, and tabbing.
    */
    handleShowModal: function (component, event, helper) {
        component.set('v.isLoading', true);
        const payload = event.getParams('detail');

        $A.createComponents([[`c:${payload.modalProperties.componentName}`, payload.componentProperties]],
            function (components, status, errorMessage) {
                if (status === "SUCCESS") {
                    const modalBody = components[0];

                    let modalReference = component.find('overlayLib').showCustomModal({
                        header: payload.modalProperties.header || '',
                        showCloseButton: payload.modalProperties.showCloseButton || true,
                        cssClass: component.getName() + ' custom-modal ' + payload.modalProperties.cssClass,
                        closeCallback: payload.modalProperties.closeCallback || function() {
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
    },

    /*******************************************************************************
    * @description Handles receipt of events from utilDedicatedListener component
    * and notifies the geTemplates component.
    */
    handleModalEvent: function (component, event, helper) {
        const details = event.getParams('detail');

        if (details) {
            component.find('giftEntryHome').notify(details);
        }

        component.get('v.modal').then(modal => {
            modal.close();
            component.set('v.isLoading', true);
        });
    },

    /*******************************************************************************
    * @description Handles receipt of events from utilDedicatedListener component
    * and notifies the geTemplates component.
    */
    handleBatchWizardEvent: function (component, event, helper) {
        component.get('v.modal').then(modal => {
            modal.close();
            component.set('v.isLoading', true);
        });
    },

    handleNewSingleGift: function(component, event){
        component.set('v.isGiftEntryMode', true);
    },

})
