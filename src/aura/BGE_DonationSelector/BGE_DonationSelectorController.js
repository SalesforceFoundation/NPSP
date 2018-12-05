({

    /**
     * @description: handles none option to create a new opportunity and prevent dry run
     */
    handleNoneDonationSelection: function(component, event, helper) {
        const selectedDonation = '';
        helper.processDonationSelection(component, selectedDonation);
    },

    /**
     * @description: handles selected donation option to select the payment or opportunity and prevent dry run
     */
    handleDonationSelection: function(component, event, helper) {
        const selectedDonation = event.getSource().get('v.value');
        helper.processDonationSelection(component, selectedDonation);
    }

})