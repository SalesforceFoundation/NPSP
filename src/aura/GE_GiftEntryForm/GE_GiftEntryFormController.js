({
    handleEditBatch: function (component) {

        $A.createComponents([["c:geBatchWizard", {recordId: component.get('v.recordId')}]],
            function (components, status, errorMessage) {
                if (status === "SUCCESS") {
                    const modalBody = components[0];

                    let modalReference = component.find('overlayLib').showCustomModal({
                        body: modalBody,
                        cssClass: "slds-modal_large",
                    });

                    component.set('v.modal', modalReference);
                } else {
                    console.error(errorMessage);
                }
            }
        );
    }

});