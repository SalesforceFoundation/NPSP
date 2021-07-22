({
    /**
     * @description: sends the donation selection as a message and closes the modal
     */
    processDonationSelection: function(component, selectedDonation) {
        let sendMessage = $A.get('e.ltng:sendMessage');
        sendMessage.setParams({
            'channel': 'selectedDonation',
            'message': selectedDonation
        });
        sendMessage.fire();

        component.find('overlayLibSelector').notifyClose();
    },

})