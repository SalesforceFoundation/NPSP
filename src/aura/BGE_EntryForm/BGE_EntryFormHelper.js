({
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
     * @description: adds necessary hidden fields to the Data Import record before submitting.
     */
    addHiddenFields: function (component, event) {
        var eventFields = event.getParam('fields');

        var recId = component.get('v.recordId');
        var batchField = component.get('v.labels.batchIdField');
        eventFields[batchField] = recId;

        var donorType = component.get('v.donorType');
        var donorField = component.get('v.labels.donationDonor');
        eventFields[donorField] = donorType;

        return eventFields;
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
     * @description: checks for presence of a donor, which is always required
     * @return: empty string or label of missing donor
     */
    validateDonor: function(component) {
        var lookupValue;
        var donorLabel = '';
        if (component.get("v.donorType") === 'Contact1') {
            lookupValue = component.find("contactLookup").get("v.value");
        } else {
            lookupValue = component.find("accountLookup").get("v.value");
        }
        if (!lookupValue) {
            var labels = component.get("v.labels");
            var donorLabel = (component.get("v.donorType") === 'Contact1') ? labels.contactObject : labels.accountObject;
        }
        return donorLabel;
    },

    /**
     * @description: checks for required fields and gathers error messages before submitting
     * @return: validity Object with Boolean for validity and an array of any missing fields to display
     */
    validateFields: function(component) {
        var validity = {isValid: true, missingFields: [], badFormatFields: []};

        //check for missing donor first
        var missingDonorLabel = this.validateDonor(component);
        if (missingDonorLabel) {
            validity.missingFields.push(missingDonorLabel);
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
        if (validity.missingFields.length !== 0 || validity.badFormatFields !== 0) {
            validity.isValid = false;
        }

        return validity;
    }

})