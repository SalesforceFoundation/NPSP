({
    /**
     * @description: adds necessary hidden fields to the Data Import record before submitting.
     * @return: Object rowFields with hidden fields added
     */
    getRowWithHiddenFields: function (component, event) {
        var rowFields = event.getParam('fields');

        var recId = component.get('v.recordId');
        var batchField = component.get('v.labels.batchIdField');
        rowFields[batchField] = recId;

        var donorType = component.get('v.donorType');
        var donorField = component.get('v.labels.donationDonor');
        rowFields[donorField] = donorType;

        return rowFields;
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
     * @description: checks for required fields and gathers error messages before submitting
     * @return: validity Object with Boolean for validity and an array of any missing fields to display
     */
    validateFields: function(component, rowFields) {
        var validity = {isValid: true, missingFields: []};

        //check for missing donor first
        var hasDonor = this.verifyRowHasDonor(component, rowFields);
        if (!hasDonor) {
            var labels = component.get("v.labels");
            var missingDonor = (component.get("v.donorType") === 'Contact1') ? labels.contactObject : labels.accountObject;
            validity.missingFields.push(missingDonor);
        }

        var dataImportFields = component.get("v.dataImportFields");
        var dynamicInputFields = component.find("dynamicInputFields");

        //dataImportFields and dynamicInputFields have the same order, so can loop both to check validity
        for (var i=0; i<dataImportFields.length; i++) {
            if (dataImportFields[i].required) {
                var fieldValue = dynamicInputFields[i].get("v.value");
                if (fieldValue === '' || fieldValue === null) {
                    validity.missingFields.push(dataImportFields[i].label);
                }
            }
        }

        //if field formats are invalid or fields are missing, set isValid as false
        if (validity.missingFields.length !== 0) {
            validity.isValid = false;
        }

        return validity;
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