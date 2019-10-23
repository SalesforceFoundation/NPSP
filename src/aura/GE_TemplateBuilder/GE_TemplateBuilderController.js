({
    handleShowModal: function (component, event, helper) {
        component.set('v.sectionBeingEdited', event.getParams('section'));

        $A.createComponents([
            ["c:tempModalProxy", { sectionBeingEdited: component.getReference('v.sectionBeingEdited') }]
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
                    });
                }
            }
        );
    },

    handleSectionModalEvent : function(component, event, helper) {
        const sectionBeingEdited = component.get('v.sectionBeingEdited');

        if (sectionBeingEdited.action === 'delete' || sectionBeingEdited.action === 'save') {
            component.find('templateBuilder').notify(component.get('v.sectionBeingEdited'));
        }
    }
})