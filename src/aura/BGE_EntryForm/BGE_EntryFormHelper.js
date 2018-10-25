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
        var error = $A.get('$Label.c.exceptionRequiredField') + missingFields.join(',') + '.';
        var message = {title: $A.get('$Label.c.PageMessagesError'), errorMessage: error};
        this.sendMessage(channel, message);
    },

    /**
     * @description: adds necessary hidden fields to the Data Import record before submitting.
     * @return: validity Object with Boolean for validity and an array of any missing fields to display
     */
    validateFields: function(component, event) {
        debugger;
        var validity = {isValid: true, missingFields: [], badFormatFields: []};

        //iterate through all fields, starting with static recordLookup
        var lookupValue;
        if (component.get("v.donorType") === 'Contact1') {
            lookupValue = component.find("contactLookup").get("v.value");
        } else {
            lookupValue = component.find("accountLookup").get("v.value");
        }
        if (!lookupValue) {
            validity.isValid = false;
            var labels = component.get("v.labels");
            var donor = (component.get("v.donorType") === 'Contact1') ? labels.contactObject : labels.accountObject;
            validity.missingFields.push(donor);
        }

        var dynamicInputFields = component.find("dynamicInputFields");
        var requiredFields = component.get("v.requiredFields");

        //if field is required and value missing, add label to missingFields
        dynamicInputFields.forEach(function(field) {
            //check for requiredness
            var fieldName = field.get("v.fieldName")
            if (requiredFields.includes(fieldName)) {
                var fieldValue = field.get("v.value");
                if (fieldValue == '' || fieldValue == null) {
                    validity.missingFields.push(fieldName);
                }
            }
            //todo: check for data formatting... good luck!
            //see ticket for notes on possible ideas..
        });

        //if field formats are invalid or fields are missing, set isValid as false
        if (validity.missingFields.length != 0 || validity.badFormatFields != 0) {
            validity.isValid = false;
        }

        return validity;
    }

})