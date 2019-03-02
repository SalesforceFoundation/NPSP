({
    /**
     * @description: clears all info on user-selected open donation
     */
    clearDonationSelectionOptions: function(component) {
        component.set('v.selectedDonation', null);
        component.set('v.openOpportunities', null);
        component.set('v.unpaidPayments', null);
    },

    /**
     * @description: sets the value of the selected donation
     */
    setDonation: function(component, selectedDonation) {
        component.set('v.selectedDonation', selectedDonation);
    },

    /**
     * @description: handle apex errors on the page by displaying a toast with the returned information
     */
    handleApexErrors: function(component, errors) {
        let message = $A.get('$Label.c.stgUnknownError');
        if (errors) {
            if (errors[0] && errors[0].message) {
                message = errors[0].message;
            }
        }
        this.sendMessage('onError', {title: $A.get('$Label.c.PageMessagesError'), errorMessage: message});
    },

    /**
     * @description: adds hidden and non-lightning:inputfield fields to the Data Import record before submitting.
     * @return: Object rowFields with hidden fields added
     */
    getRowWithHiddenFields: function (component, event) {
        let rowFields = event.getParam('fields');
        const labels = component.get('v.labels');

        const recId = component.get('v.recordId');
        rowFields[labels.batchIdField] = recId;

        // add donor type hidden fields
        const donorType = component.get('v.donorType');
        rowFields[labels.donationDonor] = donorType;

        // add any picklist fields manually, because they use lightning:select
        const dynamicInputFields = component.find('dynamicInputFields');
        const dataImportFields = component.get('v.dataImportFields');

        //dataImportFields and dynamicInputFields have the same order, so can loop both to get the value
        for (let i=0; i<dataImportFields.length; i++) {
            if (dataImportFields[i].options && dataImportFields[i].options.length > 0) {
                var fieldValue = dynamicInputFields[i].get('v.value');
                var fieldName = dataImportFields[i].name;
                rowFields[fieldName] = fieldValue;
            }
        }

        // assign opportunity/payment lookup and import status
        const selectedDonation = component.get('v.selectedDonation');
        const userSelectedMatch = $A.get('$Label.c.bdiMatchedByUser');
        const userSelectedNewOpp = $A.get('$Label.c.bdiMatchedByUserNewOpp');
        const applyNewPayment = $A.get('$Label.c.bdiMatchedApplyNewPayment');

        //set status fields to prevent dry run overwrite of lookup fields
        //else status fields are left null to allow for dry run in grid
        if (selectedDonation) {
            if (selectedDonation.attributes.type === 'Opportunity') {
                rowFields[labels.opportunityImportedLookupField] = selectedDonation.Id;
                if (selectedDonation.applyPayment) {
                    // Apply New Payment
                    rowFields[labels.opportunityImportedStatusField] = applyNewPayment;
                } else {
                    // Update Opportunity
                    rowFields[labels.opportunityImportedStatusField] = userSelectedMatch;
                }
            } else {
                // Update Payment
                rowFields[labels.paymentImportedLookupField] = selectedDonation.Id;
                rowFields[labels.paymentImportedStatusField] = userSelectedMatch;
                rowFields[labels.opportunityImportedLookupField] = selectedDonation.npe01__Opportunity__c;
                rowFields[labels.opportunityImportedStatusField] = userSelectedMatch;
            }
        } else if (selectedDonation === '') {
            //create new opportunity if selectedDonation is set as empty string
            rowFields[labels.opportunityImportedStatusField] = userSelectedNewOpp;
        }

        return rowFields;
    },

    /**
     * @description: queries open donations for upcoming donations
     * @return: void
     */
    queryOpenDonations: function(component, donorId) {
        const donorType = component.get('v.donorType');

        let action = component.get('c.getOpenDonations');
        action.setParams({donorId: donorId, donorType: donorType});
        action.setCallback(this, function (response) {
            const state = response.getState();
            if (state === 'SUCCESS') {
                const openDonations = JSON.parse(response.getReturnValue());
                component.set('v.openOpportunities', openDonations.openOpportunities);
                component.set('v.unpaidPayments', openDonations.unpaidPayments);
            } else {
                this.handleApexErrors(component, response.getError());
            }
            this.sendMessage('hideFormSpinner', '');
        });
        $A.enqueueAction(action);
    },

    /**
     * @description: sends error toast to parent component notifying user of missing fields
     * @param missingFields: Array of missing fields
     */
    sendErrorToast: function(component, missingFields) {
        let channel = 'onError';
        let error = $A.get('$Label.c.exceptionRequiredField') + ' ' + missingFields.join(', ') + '.';
        let message = {title: $A.get('$Label.c.PageMessagesError'), errorMessage: error};
        this.sendMessage(channel, message);
    },

    /**
     * @description: send a message to other components
     */
    sendMessage: function (channel, message) {
        let sendMessage = $A.get('e.ltng:sendMessage');
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
        let validity = {isValid: true, missingFields: []};

        const hasDonor = this.verifyRowHasDonor(component, rowFields);
        if (!hasDonor) {
            const labels = component.get("v.labels");
            const missingDonor = (component.get("v.donorType") === 'Contact1') ? labels.contactObject : labels.accountObject;
            validity.missingFields.push(missingDonor);
        }

        let missingRequiredFields = this.verifyRequiredFields(component, rowFields);
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
        let missingFields = [];
        const dataImportFields = component.get('v.dataImportFields');
        let dynamicInputFields = component.find('dynamicInputFields');

        if (! Array.isArray(dynamicInputFields)) {
            dynamicInputFields = [dynamicInputFields];
        }

        //dataImportFields and dynamicInputFields have the same order, so can loop both to check validity
        for (let i=0; i<dataImportFields.length; i++) {
            if (dataImportFields[i].required) {
                const fieldValue = dynamicInputFields[i].get('v.value');
                if (fieldValue === '' || fieldValue === null || (Array.isArray(fieldValue) && !fieldValue.length) ) {
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
        let hasDonor = true;
        let lookupValue;

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