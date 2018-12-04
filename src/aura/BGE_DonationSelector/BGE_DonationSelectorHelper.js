({
    /**
     * @description: sets the donation selection and closes the modal
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