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
     * @description: adds necessary hidden and non-lightning:inputfield fields to the Data Import record before submitting.
     * beacuse only lightning:inputfield fields are picked up automatically on submit
     */
    addExtraFields: function (component, event) {
        var eventFields = event.getParam('fields');
        console.log(JSON.stringify(eventFields));
        var recId = component.get('v.recordId');
        var batchField = component.get('v.labels.batchIdField');
        eventFields[batchField] = recId;

        // add donor type hidden fields
        var donorType = component.get('v.donorType');
        var donorField = component.get('v.labels.donationDonor');
        eventFields[donorField] = donorType;

        // add any picklist fields manually, because they use lightning:select
        var dynamicInputFields = component.find('dynamicInputFields');
        var dataImportFields = component.get('v.dataImportFields');

        //dataImportFields and dynamicInputFields have the same order, so can loop both to check validity
        for (var i=0; i<dataImportFields.length; i++) {
            if (dataImportFields[i].options && dataImportFields[i].options.length > 0) {
                var fieldValue = dynamicInputFields[i].get('v.value');
                var fieldName = dataImportFields[i].name;
                console.log(dynamicInputFields[i].get('v.fieldName'));
                eventFields[fieldName] = fieldValue;
            }
        }

        return eventFields;
    }

})