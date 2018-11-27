({
    /**
     * @description: clears all info on user-selected open donation
     */
    clearDonationSelectionOptions: function(component) {
        component.set('v.donationOptions', null);
        component.set('v.selectedDonationId', null);
        component.set('v.openDonations', null);
    },

    /**
     * @description: closes the donation modal
     */
    closeDonationModal: function(component) {
        component.get('v.matchingModalPromise').then(function(modal) {
            modal.close();
        });
    },

    /**
     * @description: adds hidden and non-lightning:inputfield fields to the Data Import record before submitting.
     * @return: Object rowFields with hidden fields added
     */
    getRowWithHiddenFields: function (component, event) {
        var rowFields = event.getParam('fields');
        const labels = component.get('v.labels');

        var recId = component.get('v.recordId');
        rowFields[labels.batchIdField] = recId;

        // add donor type hidden fields
        var donorType = component.get('v.donorType');
        rowFields[labels.donationDonor] = donorType;

        // add any picklist fields manually, because they use lightning:select
        var dynamicInputFields = component.find('dynamicInputFields');
        var dataImportFields = component.get('v.dataImportFields');

        // add opportunity/payment lookup and import status
        const selectedDonationId = component.get('v.selectedDonationId');
        const userSelectedMatch = $A.get('$Label.c.bdiMatchedByUser');
        if (selectedDonationId === '') {
            rowFields[labels.opportunityImportedStatusField] = userSelectedMatch;
        } else if (selectedDonationId && selectedDonationId.substring(0, 3) === '006') {
            rowFields[labels.opportunityImportedLookupField] = selectedDonationId;
            rowFields[labels.opportunityImportedStatusField] = userSelectedMatch;
        } else if (selectedDonationId) {
            rowFields[labels.paymentImportedLookupField] = selectedDonationId;
            rowFields[labels.paymentImportedStatusField] = userSelectedMatch;
            const openDonations = component.get('v.openDonations');
            for (let i = 0; i < openDonations.unpaidPayments.length; i++) {
                if (openDonations.unpaidPayments[i].Id === selectedDonationId) {
                    rowFields[labels.opportunityImportedLookupField] = openDonations.unpaidPayments[i].npe01__Opportunity__c;
                    rowFields[labels.opportunityImportedStatusField] = userSelectedMatch;
                    break;
                }
            }
        }

        //dataImportFields and dynamicInputFields have the same order, so can loop both to get the value
        for (var i=0; i<dataImportFields.length; i++) {
            if (dataImportFields[i].options && dataImportFields[i].options.length > 0) {
                var fieldValue = dynamicInputFields[i].get('v.value');
                var fieldName = dataImportFields[i].name;
                rowFields[fieldName] = fieldValue;
            }
        }

        return rowFields;
    },

    /**
     * @description: queries open donations for upcoming donations
     * @return: void
     */
    queryOpenDonations: function (component, donorId) {
        const donorType = component.get('v.donorType');

        let action = component.get('c.getOpenDonations');
        action.setParams({donorId: donorId, donorType: donorType});
        action.setCallback(this, function (response) {
            const state = response.getState();
            if (state === 'SUCCESS') {
                const openDonations = JSON.parse(response.getReturnValue());
                openDonations.unpaidPayments.forEach(function(pmt) {
                    pmt.isSelected = false;
                });
                openDonations.openOpportunities.forEach(function(opp) {
                    opp.isSelected = false;
                });
                component.set('v.openDonations', openDonations);
                component.set('v.openOpportunities', openDonations.openOpportunities);
                component.set('v.unpaidPayments', openDonations.unpaidPayments);

            } else {
                this.showToast(component, $A.get('$Label.c.PageMessagesError'), response.getReturnValue(), 'error');
            }
            this.sendMessage('hideFormSpinner', '');
            document.getElementById("selectMatchLink").focus();
        });
        $A.enqueueAction(action);
    },

    /**
     * @description: sends error toast to parent component notifying user of missing fields
     * @param missingFields: Array of missing fields
     */
    sendErrorToast: function(component, missingFields) {
        var channel = 'onError';
        var error = $A.get('$Label.c.exceptionRequiredField') + ' ' + missingFields.join(', ') + '.';
        var message = {title: $A.get('$Label.c.PageMessagesError'), errorMessage: error};
        this.sendMessage(channel, message);
    },

    /**
     * @description: generic component used to send a message to parent component.
     */
    sendMessage: function (channel, message) {
        var sendMessage = $A.get('e.ltng:sendMessage');
        sendMessage.setParams({
            'channel': channel,
            'message': message
        });
        sendMessage.fire();
    },

    /**
     * @description: checks for Donor and other required fields and gathers error messages before submitting
     * @return: validity Object with Boolean for validity and an array of any missing fields to display
     */
    validateFields: function(component, rowFields) {
        var validity = {isValid: true, missingFields: []};

        var hasDonor = this.verifyRowHasDonor(component, rowFields);
        if (!hasDonor) {
            var labels = component.get("v.labels");
            var missingDonor = (component.get("v.donorType") === 'Contact1') ? labels.contactObject : labels.accountObject;
            validity.missingFields.push(missingDonor);
        }

        var missingRequiredFields = this.verifyRequiredFields(component, rowFields);
        if (missingRequiredFields.length != 0) {
            validity.missingFields = validity.missingFields.concat(missingRequiredFields);
        }

        if (validity.missingFields.length !== 0) {
            validity.isValid = false;
        }

        return validity;
    },

    /**
     * @description: checks for presence of fields that user has marked as required
     * @param rowFields: Object rowFields with updated hidden values
     * @return missingFields: list of any fields by label that are missing
     */
    verifyRequiredFields: function(component, rowFields) {
        var missingFields = [];
        var dataImportFields = component.get('v.dataImportFields');
        var dynamicInputFields = component.find('dynamicInputFields');

        if (! Array.isArray(dynamicInputFields)) {
            dynamicInputFields = [dynamicInputFields];
        }

        //dataImportFields and dynamicInputFields have the same order, so can loop both to check validity
        for (var i=0; i<dataImportFields.length; i++) {
            if (dataImportFields[i].required) {
                var fieldValue = dynamicInputFields[i].get('v.value');
                if (fieldValue === '' || fieldValue === null) {
                    missingFields.push(dataImportFields[i].label);
                }
            }
        }

        return missingFields;
    },

    /**
     * @description: checks for presence of a donor, which is always required
     * @param rowFields: Object rowFields with updated hidden values
     * @return hasDonor: Boolean to indicate if row has a donor
     */
    verifyRowHasDonor: function(component, rowFields) {
        var hasDonor = true;
        var lookupValue;

        if (component.get("v.donorType") === 'Contact1') {
            lookupValue = rowFields[component.get("v.labels.contactLookup")];
        } else if (component.get("v.donorType") === 'Account1') {
            lookupValue = rowFields[component.get("v.labels.accountLookup")];
        }

        if (!lookupValue || lookupValue.length !== 18) {
            hasDonor = false;
        }

        return hasDonor;
    }

})