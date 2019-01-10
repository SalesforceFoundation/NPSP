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
            var possibleError = '';
            var step = component.get('v.batchMetadata.progressIndicatorStep');

            // check validity and load values
            if (step === '0') {
                // model.getBatchInfo().load(component.get('v.batchInfo'));
                // isValid = model.getBatchInfo().isValid();
                // possibleError = component.get('v.batchMetadata.labels.missingNameDescriptionError');
            } else if (step === '1') {
                helper.updateToActive(component);
                helper.updateBatchFieldOptions(component);
                // possibleError = model.getAvailableFields().getRequiredFieldErrors();
                // isValid = (possibleError.length === 0);
            } else if (step === '2') {
                // isValid = model.getAvailableFields().getDefaultFieldValidity(component);
                // var fieldOptions = component.get('v.batchFieldOptions.fieldGroups');
                // ----> model.getAvailableFields().updateBatchFieldOptions(fieldOptions);
                helper.commitBatchFieldOptionsToEveryField(component);
            } else if (step === '3') {
                // todo: add validation for processing settings
                // model.getBatchInfo().load(component.get('v.batchInfo'));
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