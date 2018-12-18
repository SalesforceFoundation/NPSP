({

    /******************************** Batch Details Controller Functions *****************************/

    /**
     * @description Constructs the Model Module, and the View Modules.
     */
    doInit: function (component, event, helper) {
        var bgeBatchController = helper.BGEBatchController(component);

        var model = helper.DetailsModel();
        model.setBackendController(bgeBatchController);
        component.set('v.model', model);

        var batchInfoView = helper.BatchInfoView(component, model);
        component.set('v.batchInfo', batchInfoView);
        var batchMetadataView = helper.BatchMetadataView(component, model);
        component.set('v.batchMetadata', batchMetadataView);
        var batchFieldsView = helper.BatchFieldsView(component, model);
        component.set('v.availableFields', batchFieldsView);
        var batchFieldOptionsView = helper.BatchFieldOptionsView(component, model);
        component.set('v.batchFieldOptions', batchFieldOptionsView);

        model.init(component);
    },

    /**
     * @description Navigates from View to Edit mode.
     */
    changeModeToEdit: function(component, event, helper) {
        var model = component.get('v.model');
        model.getBatchMetadata().setMode('edit');
    },

    /**
     * @description handles ltng:sendMessage
     * must be explicit about channel because other messages may be sent
     */
    handleSendMessage: function(component, event, helper) {
        const task = event.getParam('channel');
        let model = component.get('v.model');

        // handle cancel
        if (task === 'cancel') {

            //Set off init here to reset view
            var mode = component.get('v.batchMetadata.mode');
            if (mode === 'edit') {
                model.init(component);
            }
            model.getBatchMetadata().cancel();

        } else if (task === 'next' || task === 'back' || task === 'save') {

            var isValid = true;
            var possibleError = '';
            var step = component.get('v.batchMetadata.progressIndicatorStep');

            // check validity and load values
            if (step === '1') {
                model.getBatchInfo().load(component.get('v.batchInfo'));
                isValid = model.getBatchInfo().isValid();
                possibleError = component.get('v.batchMetadata.labels.missingNameDescriptionError');
            } else if (step === '2') {
                //handle template selection and copying here
            } else if (step === '3') {
                model.getAvailableFields().updateToActive(component.get('v.availableFields').fieldGroups);
                possibleError = model.getAvailableFields().getRequiredFieldErrors();
                isValid = (possibleError.length === 0);
            } else if (step === '4') {
                isValid = model.getAvailableFields().getDefaultFieldValidity(component);
                var fieldOptions = component.get('v.batchFieldOptions.fieldGroups');
                model.getAvailableFields().updateBatchFieldOptions(fieldOptions);
            } else if (step === '5') {
                //todo: add validation for processing settings
                model.getBatchInfo().load(component.get('v.batchInfo'));
            }

            // proceed or display error
            if (isValid) {
                if (task === 'next') {
                    model.getBatchMetadata().nextStep();
                } else if (task === 'back') {
                    model.getBatchMetadata().backStep();
                } else if (task === 'save') {
                    model.getBatchMetadata().togglePendingSave();
                    model.getBatchInfo().load(component.get('v.batchInfo'));
                    model.save();
                }
            } else {
                model.getBatchMetadata().showError(possibleError);
            }
        }
    },

});