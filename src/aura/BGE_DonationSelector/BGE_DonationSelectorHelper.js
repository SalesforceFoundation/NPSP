({
    /**
     * @description: sets the donation selection and closes the modal
     */
    processDonationSelection: function(component, selectedDonation) {
        component.set('v.selectedDonation', selectedDonation);

        let sendMessage = $A.get('e.ltng:sendMessage');
        sendMessage.setParams({
            'channel': 'closeDonationModal',
            'message': selectedDonation
        });
        sendMessage.fire();
    },

})