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
    }

})