({
    doInit: function(component, event, helper){
        helper.init(component);
    },

    /**
     * @description handles ltng:sendMessage
     * must be explicit about channel because other messages may be sent
     */
    handleSendMessage: function(component, event, helper) {
        const task = event.getParam('channel');
        let model = component.get('v.model');

        if (task === 'next' || task === 'back' || task === 'save') {

            var isValid = true;
            // var possibleError = '';
            var step = component.get('v.batchMetadata.progressIndicatorStep');

            // check validity and load values
            if (step === '0') {
                isValid = helper.checkBatchInfoValidity(component); 
            } else if (step === '1') {
                helper.updateToActive(component);
                helper.updateBatchFieldOptions(component);
                // note: all required fields are set by the model so checking validity is not needed. 
                // This could change.
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
                    helper.togglePendingSave(component);
                    //model.getBatchInfo().load(component.get('v.batchInfo'));
                    helper.saveRecord(component);
                }
            } else {
                helper.showError(component);
                //model.getBatchMetadata().showError(possibleError);
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