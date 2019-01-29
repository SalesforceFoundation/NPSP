({
    doInit: function(component, event, helper){
        helper.init(component);
    },

    /**
     * @description handles incoming ltng:sendMessage from footer
     * must be explicit about channel because other messages may be sent
     */
    handleSendMessage: function(component, event, helper) {
        const task = event.getParam('channel');

        if (task === 'next' || task === 'back' || task === 'save') {

            let isValid = true;
            const step = component.get('v.wizardMetadata.progressIndicatorStep');

            // check validity and load values
            if (step === '0') {
                isValid = helper.checkBatchInfoValidity(component);
            } else if (step === '1') {
                helper.updateToActive(component);
                helper.updateBatchFieldOptions(component);
                // note: all required fields are set by the model so checking validity is not currently necessary.
            } else if (step === '2') {
                helper.commitBatchFieldOptionsToEveryField(component);
                isValid = helper.checkBatchFieldOptionsValidity(component);
            } else if (step === '3') {
                isValid = helper.checkBatchProcessingSettingsValidity(component);
            }

            // proceed or display error
            if (isValid) {
                if (task === 'next') {
                    helper.nextStep(component);
                } else if (task === 'back') {
                    helper.backStep(component);
                } else if (task === 'save') {
                    // the footer disables the save button itself; don't need to set pendingSave here
                    helper.saveRecord(component);
                }
            } else {
                helper.showError(component);
                helper.sendMessage(component, 'pendingSave', false);
            }
        }
    },

    /**
     * @description hides or shows advanced options from user click on button
     */
    handleAdvancedOptionsToggle: function(component, event, helper) {
        helper.toggleShowAdvanced(component);
    },

    /**
     * @description update properties when date is or is not included in match fields
     */
    handleDonationMatchingRuleChange: function(component, event, helper) {
        helper.updateMatchOnDate(component);
    }
})