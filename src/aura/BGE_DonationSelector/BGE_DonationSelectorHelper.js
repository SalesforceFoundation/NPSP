({

    /**
     * @description: sets the donation selection and closes the modal
     */
    processDonationSelection: function(component, selectedDonation) {
        component.set('v.selectedDonation', selectedDonation);
        this.sendMessage('closeDonationSelectorModal',null);
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
    }

})