({
    /**
     * @description: called during render to focus on open donation link if present and donation not selected
     */
    callFocus: function(component){
        let openDonationsLink = document.getElementById('selectOpenDonation');

        if (openDonationsLink && component.get('v.selectedDonation') == null) {
            openDonationsLink.focus();
        } else {
            let donorType = component.find('donorType');
            if (donorType) {
                donorType.focus();
            }
        }
    },

    /**
     * @description: alerts parent component that form needs to be reset
     */
    cancelForm: function (component, event, helper) {
        helper.sendMessage('onCancel', '');
        component.destroy();
    },

    /**
     * @description: listens for event listeners from other components
     */
    handleMessage: function (component, event, helper) {
        const message = event.getParam('message');
        const channel = event.getParam('channel');

        if (channel === 'selectedDonation') {
            helper.setDonation(component, message);
        }
    },

    /**
     * @description: alerts parent component that form is loaded
     */
    onFormLoad: function (component, event, helper) {
        helper.sendMessage('hideFormSpinner', '');
        component.find('donorType').focus();
    },

    /**
     * @description: alerts parent component that form is loaded
     */
    onDonorChange: function (component, event, helper) {
        helper.clearDonationSelectionOptions(component);
        const lookupField = component.get('v.donorType') === 'Contact1' ? 'contactLookup' : 'accountLookup';
        const lookupValue = component.find(lookupField).get('v.value');
        const lookupValueIsValidId = lookupValue.length === 18;

        if (lookupValueIsValidId) {
            helper.sendMessage('showFormSpinner', '');
            helper.queryOpenDonations(component, lookupValue);
        }
    },

    /**
     * @description: override submit function in recordEditForm to handle hidden fields and validation
     */
    onSubmit: function (component, event, helper) {
        event.preventDefault();
        component.set('v.pendingSave', true);
        var completeRow = helper.getRowWithHiddenFields(component, event);
        var validity = helper.validateFields(component, completeRow);

        if (validity.isValid) {
            component.find('recordEditForm').submit(completeRow);
        } else if (validity.missingFields.length !== 0) {
            helper.sendErrorToast(component, validity.missingFields);
        } else {
            //do nothing since data format errors display inline
        }
        component.set('v.pendingSave', false);
    },

    /**
     * @description: alerts parent component that record is saved and needs to be reset
     */
    onSuccess: function (component, event, helper) {
        var message = {'recordId': event.getParams().response.id};
        helper.sendMessage('onSuccess', message);
        component.destroy();
    },

    /**
     * @description: launches modal so user can select open donation
     */
    openMatchModal: function(component, event, helper) {
        let setModalOpenToFalse = function() {
            component.set('v.modalOpen', false);
        }

        if (!component.get('v.modalOpen')) {
            component.set('v.modalOpen', true);
            $A.createComponent('c:BGE_DonationSelector', {
                'aura:id': 'donationSelector',
                'name': 'donationSelector',
                'unpaidPayments': component.get('v.unpaidPayments'),
                'openOpportunities': component.get('v.openOpportunities'),
                'selectedDonation': component.get('v.selectedDonation'),
                'labels': component.get('v.labels')
            },
            function (newcomponent, status, errorMessage) {
                if (status === 'SUCCESS') {
                    component.find('overlayLib').showCustomModal({
                        header: component.get('v.donationModalHeader'),
                        body: newcomponent,
                        showCloseButton: true,
                        cssClass: 'slds-modal_large',
                        closeCallback: setModalOpenToFalse
                    });
                } else {
                    setModalOpenToFalse();
                    const message = {
                        title: $A.get('$Label.c.PageMessagesError'),
                        errorMessage: status === 'ERROR' ? errorMessage : $A.get('$Label.c.stgUnknownError')
                    };
                    helper.sendMessage('onError', message);
                }
            });
        }
    },

    /**
     * @description: sets the donor type and alerts the parent. Used to circumvent the unhelpful labeling of Account1/Contact1.
     */
    setDonorType: function (component, event, helper) {
        let donorType = event.getSource().get('v.value');
        component.set('v.donorType', donorType);

        let message = {'donorType': donorType};
        helper.sendMessage('setDonorType', message);
        helper.clearDonationSelectionOptions(component);
    }

})