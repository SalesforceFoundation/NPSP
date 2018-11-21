({

    /**
     * @description: adds hidden and non-lightning:inputfield fields to the Data Import record before submitting.
     * @return: Object rowFields with hidden fields added
     */
    getRowWithHiddenFields: function (component, event) {
        var rowFields = event.getParam('fields');

        var recId = component.get('v.recordId');
        var batchField = component.get('v.labels.batchIdField');
        rowFields[batchField] = recId;

        // add donor type hidden fields
        var donorType = component.get('v.donorType');
        var donorField = component.get('v.labels.donationDonor');
        rowFields[donorField] = donorType;

        // add any picklist fields manually, because they use lightning:select
        var dynamicInputFields = component.find('dynamicInputFields');
        var dataImportFields = component.get('v.dataImportFields');

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
     * @description: removes open donation values
     * @return: void
     */
    removeOpenDonations: function(component) {
        component.set('v.openOpportunities', []);
        component.set('v.unpaidPayments', []);
    },

    /**
     * @description: queries open donations for upcoming donations
     * @return: void
     */
    queryOpenDonations: function (component) {
        let donorType = component.get('v.donorType');
        let donorId;
        if (donorType === 'Contact1') {
            donorId = component.find('contactLookup').get('v.value');
        } else if (donorType === 'Account1') {
            donorId = component.find('accountLookup').get('v.value');
        }

        var action = component.get('c.getOpenDonations');
        action.setParams({donorId: donorId, donorType: donorType});
        action.setCallback(this, function (response) {
            var state = response.getState();
            if (state === 'SUCCESS') {
                var openDonations = JSON.parse(response.getReturnValue());
                console.log(response);
                // call another function here to create the scoped notification
                component.set('v.openOpportunities', openDonations.openOpportunities);
                component.set('v.unpaidPayments', openDonations.unpaidPayments);

                let options = [{'label': 'None, create a new opportunity', 'value': 'none'}];

                openDonations.openOpportunities.forEach(function(opp) {
                    const label = opp.Name + ' (' + opp.StageName + ')';
                    const value = opp.Id;
                    options.push({'label': label, 'value': value});
                    //let option = {'label': opp.}
                });

                openDonations.unpaidPayments.forEach(function(pmt) {
                    const label = pmt.Name + ' (' + pmt.npe01__Opportunity__r.Name + ', ' + pmt.npe01__Scheduled_Date__c + ')';
                    const value = pmt.Id;
                    options.push({'label': label, 'value': value});
                });

                component.set('v.options', options);

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