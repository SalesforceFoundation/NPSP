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
     * @description: displays standard toast to user based on success or failure of their action
     * @param missingFields: Array of missing fields
     */
    sendErrorToast: function(component, missingFields) {
        var channel = 'onError';
        var error = $A.get('$Label.c.exceptionRequiredField') + '<br/><ul>';
        missingFields.forEach(function(field) {
            error += '<li>' + field + '</li>';
        });
        error += '</ul>';
        var message = {title: $A.get('$Label.c.PageMessagesError'), errorMessage: error};
        this.sendMessage(channel, message);
    },

    /**
     * @description: adds necessary hidden fields to the Data Import record before submitting.
     * @return: validity Object with Boolean for validity and an array of any missing fields to display
     */
    validateFields: function(component, event) {
        var isValid = {isValid: true, missingFields: []};

        //iterate through all fields
        var lookupValue = component.find("recordLookup").get("v.value");

        if (!lookupValue) {
            isValid = false;
        }

        //if field is required and value missing, add label to missingFields

        //if field format is invalid, set isValid as false

        return isValid;
    }

})