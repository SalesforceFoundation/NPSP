({

    /******************************** Template Details Controller Functions *****************************/

    /**
     * @description Constructs the Model Module, and the View Modules.
     */
    doInit: function (component, event, helper) {
        var bgeTemplateController = helper.BGETemplateController(component);

        var model = helper.TemplateDetailsModel();
        model.setBackendController(bgeTemplateController);
        component.set('v.model', model);

        var templateInfoView = helper.TemplateInfoView(component, model);
        component.set('v.templateInfo', templateInfoView);
        var templateMetadataView = helper.TemplateMetadataView(component, model);
        component.set('v.templateMetadata', templateMetadataView);
        var templateFieldsView = helper.TemplateFieldsView(component, model);
        component.set('v.templateFields', templateFieldsView);
        var templateFieldOptionsView = helper.TemplateFieldOptionsView(component, model);
        component.set('v.templateFieldOptions', templateFieldOptionsView);

        model.init(component);
    },

    /**
     * @description Navigates from View to Edit mode.
     */
    changeModeToEdit: function(component, event, helper) {
        var model = component.get('v.model');
        model.getTemplateMetadata().setMode('edit');
    },

    /**
     * @description handles User Input from ltng:sendMessage and onclick handlers
     * must be explicit about channel because other messages may be sent
     */
    handleUserInput: function(component, event, helper) {
        // check if user input came from ltng:sendMessage or an onclick handler
        var task;
        if (event.getSource().getLocalId()) {
            task = event.getSource().getLocalId();
        } else if (event.getParam('channel')) {
            task = event.getParam('channel');
        }

        var model = component.get('v.model');

        // handle cancel
        if (task === 'cancel' || task === 'backToTemplates') {

            //Set off init here to reset view
            var mode = component.get('v.templateMetadata.mode');
            if (mode === 'edit') {
                model.init(component);
            }
            model.getTemplateMetadata().cancel();

        } else if (task === 'next' || task === 'back' || task === 'save') {

            var isValid = true;
            var possibleError = '';
            var step = component.get('v.templateMetadata.progressIndicatorStep');

            // check validity and load values
            if (step === '1') {
                model.getTemplateInfo().load(component.get('v.templateInfo'));
                isValid = model.getTemplateInfo().isValid();
                possibleError = component.get('v.templateMetadata.labels.missingNameDescriptionError');
            } else if (step === '2') {
                //handle template selection and copying here
            } else if (step === '3') {
                model.getTemplateFields().updateToActive(component.get('v.templateFields').fieldGroups);
                possibleError = model.getTemplateFields().getRequiredFieldErrors();
                isValid = (possibleError.length === 0);
            } else if (step === '4') {
                isValid = model.getTemplateFields().getDefaultFieldValidity(component);
                var fieldOptions = component.get('v.templateFieldOptions.fieldGroups');
                model.getTemplateFields().updateTemplateFieldOptions(fieldOptions);
            } else if (step === '5') {
                //todo: add validation for processing settings
                model.getTemplateInfo().load(component.get('v.templateInfo'));
            }

            // proceed or display error
            if (isValid) {
                if (task === 'next') {
                    model.getTemplateMetadata().nextStep();
                } else if (task === 'back') {
                    model.getTemplateMetadata().backStep();
                } else if (task === 'save') {
                    model.getTemplateMetadata().togglePendingSave();
                    model.getTemplateInfo().load(component.get('v.templateInfo'));
                    model.save();
                }
            } else {
                model.getTemplateMetadata().showError(possibleError);
            }
        } else if (task === 'showAdvanced') {
            var step = component.get('v.templateMetadata.progressIndicatorStep');
            if (step === '5') {
                model.getTemplateInfo().load(component.get('v.templateInfo'));
                model.getTemplateMetadata().toggleShowAdvanced();
            }
        }
    },

});