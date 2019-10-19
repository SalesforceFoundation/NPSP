({
    handleShowModal: function (component, event, helper) {
        console.log('handleShowModal');
        console.log(JSON.stringify(event.getParams('section')));
        console.log('Event: ', JSON.parse(JSON.stringify(event)));
        component.set('v.sectionBeingEdited', event.getParams('section'));

        $A.createComponents([
            ["c:utilModal", { modalData: component.getReference('v.sectionBeingEdited') }]
        ],
            function (components, status, errorMessage) {
                console.log('Components: ', components);
                console.log('Status: ', status);
                console.log('Error Message: ', errorMessage);

                if (status === "SUCCESS") {
                    const modalBody = components[0];

                    component.find('overlayLib').showCustomModal({
                        header: 'Edit Section',
                        body: modalBody,
                        showCloseButton: true,
                        cssClass: component.getName() + ' customModal',
                        closeCallback: function () {
                            console.log('close modal callback');
                        }
                    });
                }
            }
        );
    },

    handleLwcPublicMethod : function(component, event, helper) {
        console.log('find and call public method on child lwc');
        const sectionBeingEdited = component.get('v.sectionBeingEdited');
        if (sectionBeingEdited.action === 'delete' || sectionBeingEdited.action === 'save') {
            component.find('templateBuilder').callable(component.get('v.sectionBeingEdited'));
        }
    }
})