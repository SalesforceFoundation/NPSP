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
     * @description: closes match modal
     */
    closeModal: function (component, event, helper) {
        helper.closeDonationModal(component);
    },

    handleDonationSelection: function(component, event, helper) {
        //if null, then it's none
        const donationField = component.find('donationOptions');
        let donationId;
        //need an array check because the destroy is not removing the reference in the find() map
        //see: https://salesforce.stackexchange.com/questions/227712/lightning-component-findauraid-returns-an-array-consisting-of-one-element
        if (Array.isArray(donationField)) {
            donationId = donationField[0].get('v.value');
        } else {
            donationId = donationField.get('v.value');
        }
        component.set('v.selectedDonationId', donationId);
        helper.closeDonationModal(component);
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
        // todo: how to maintain previously-selected option if they re-enter the modal?
        // const selectedDonation = component.get('v.selectedDonationId');
        component.find('overlayLib').showCustomModal({
            header: component.get('v.matchingModalHeader'),
            body: component.get('v.matchingModalBody'),
            //body: components[0],
            //footer: component.get('v.matchingModalFooter'),
            showCloseButton: true,
            cssClass: 'slds-modal_large'
        });
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