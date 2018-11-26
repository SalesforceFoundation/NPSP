({
    /**
     * @description: called during render to place the focus on SelectOpenDonation link if present
     */
    callFocus: function(component){
        let openDonationsLink = document.getElementById('selectMatchLink');
        if (openDonationsLink) {
            openDonationsLink.focus();
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
        component.set('v.donationOptions', []);
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
     * @description: alerts parent component that record is saved and needs to be reset
     */
    openMatchModal: function(component, event, helper) {
        const selectedDonation = component.get('v.selectedDonationId');
        $A.createComponents([
            ["lightning:radioGroup", {
                'aura:id': 'donationOptions',
                'name': 'donationOptions',
                'label': $A.get('$Label.c.stgNavDonations'),
                'options': component.get('v.donationOptions'),
                'variant': 'label-hidden',
                'value': selectedDonation
            }]
            ],
            function(components, status, errorMessage) {
                if (status === 'SUCCESS') {
                    component.set('v.matchingModalPromise', component.find('overlayLib').showCustomModal({
                        header: component.get('v.matchingModalHeader'),
                        body: components[0],
                        footer: component.get('v.matchingModalFooter'),
                        showCloseButton: true
                    }));
                } else if (status === 'INCOMPLETE') {
                    const message = {title: $A.get('$Label.c.PageMessagesError'), errorMessage: $A.get('$Label.c.stgUnknownError')};
                    helper.sendMessage('onError', message);
                }
                else if (status === 'ERROR') {
                    const message = {title: $A.get('$Label.c.PageMessagesError'), errorMessage: errorMessage};
                    helper.sendMessage('onError', message);
                }
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
        component.set('v.donationOptions', []);
    }

})