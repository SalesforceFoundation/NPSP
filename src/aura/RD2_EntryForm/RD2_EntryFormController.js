({
    handleShowModal: function (component, event, helper) {
        let recordId = component.get('v.recordId');
        let parentId;
        if (!recordId) {
            parentId = helper.getParentId();
            component.set('v.parentId', parentId);
        }
        
        $A.createComponent("c:rdEntryForm", {parentId, recordId},
        function(content, status, errorMessage) {
            if (status === "SUCCESS") {
                const modalBody = content;

                let modalReference = component.find('overlayLib').showCustomModal({
                    header: "New Recurring Donation",
                    body: modalBody,
                    cssClass: component.getName() + ' slds-modal_medium custom-modal',
                    showCloseButton: true,
                    closeCallback: function() {
                        helper.handleCloseModal(component);
                    }
                });
                component.set('v.modal', modalReference);
            } else {
                console.error(errorMessage);
            }
        });
    },

    handleModalEvent: function(component, event, helper) {
        const details = event.getParams('detail');

        if (details.action === 'success') {
            component.set('v.recordId', details.recordId);
        }

        helper.handleCloseModal(component);
    }
})
