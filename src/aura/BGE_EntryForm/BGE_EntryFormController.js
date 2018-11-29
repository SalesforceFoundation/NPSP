({
    /**
     * @description: called during render to place the focus on SelectOpenDonation link if present
     */
    callFocus: function(component){
        let openDonationsLink = document.getElementById('selectMatchLink');
        if (openDonationsLink && !component.get('v.selectedDonationId')) {
            openDonationsLink.focus();
        } else if (openDonationsLink) {
            component.find('donorType').focus();
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
     * @description:
     */
    /* for next ticket:
    handleApplyPaymentSelection: function(component, event, helper) {
        const selectedDonation = event.getSource().get('v.value');
        selectedDonation.applyPayment = true;
        helper.processDonationSelection(component, selectedDonation);

    },*/

    /**
     * @description: handles none option to create a new opportunity and prevent dry run
     */
    handleNoneDonationSelection: function(component, event, helper) {
        const selectedDonation = '';
        helper.processDonationSelection(component, selectedDonation);

    },

    /**
     * @description: handles selected donation option to select the payment or opportunity and prevent dry run
     */
    handleDonationSelection: function(component, event, helper) {
        const selectedDonation = event.getSource().get('v.value');
        helper.processDonationSelection(component, selectedDonation);

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
        var lookupField = component.get('v.donorType') === 'Contact1' ? 'contactLookup' : 'accountLookup';
        var lookupValue = component.find(lookupField).get('v.value');
        var lookupValueIsValidId = lookupValue.length === 18;

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
        var completeRow = helper.getRowWithHiddenFields(component, event);
        var validity = helper.validateFields(component, completeRow);

        if (validity.isValid) {
            component.find('recordEditForm').submit(completeRow);
        } else if (validity.missingFields.length !== 0) {
            helper.sendErrorToast(component, validity.missingFields);
        } else {
            //do nothing since data format errors display inline
        }
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
        component.set('v.matchingModalPromise', component.find('overlayLib').showCustomModal({
            header: component.get('v.matchingModalHeader'),
            body: component.get('v.matchingModalBody'),
            showCloseButton: true,
            cssClass: 'slds-modal_large'
        }));
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