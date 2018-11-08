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

    handleButtonClick: function(component, event, helper) {
        // opt 1: button came from our own component
        var buttonClick = event.getSource().getLocalId();
        // opt 2: button came from a ltng:sendMessage
        // must be explicit about channel because other messages may be sent
        var channel = event.getParam('channel');
        var model = component.get('v.model');

        if (channel === 'next' || buttonClick === 'next') {
            var step = component.get('v.templateMetadata.progressIndicatorStep');
            if (step === '1') {
                var templateInfoData = component.get('v.templateInfo');
                model.getTemplateInfo().load(templateInfoData);
                model.getTemplateMetadata().nextStep(model.getTemplateInfo().isValid(),
                    component.get('v.templateMetadata.labels.missingNameDescriptionError'));
            } else if (step === '2') {
                //handle template selection and copying here
            } else if (step === '3') {
                var templateFields = component.get('v.templateFields');
                model.getTemplateFields().updateToActive(templateFields.fieldGroups);
                var errors = model.getTemplateFields().getRequiredFieldErrors();
                model.getTemplateMetadata().nextStep(errors.length === 0, errors);
            } else if (step === '4') {
                //handle customize field options for batch gift entry here
            } else if (step === '5') {
                //handle matching rules here
            }
        } else if (channel === 'back' || buttonClick === 'back') {
            model.getTemplateMetadata().backStep();
        } else if (buttonClick === 'cancel' || buttonClick === 'backToTemplates') {
            //Set off init here to reset view
            var mode = component.get('v.templateMetadata.mode');
            if (mode === 'edit') {
                model.init(component);
            }
            model.getTemplateMetadata().cancel();
        } else if (channel === 'save' || buttonClick === 'save') {
            var fieldOptions = component.get('v.templateFieldOptions.fieldGroups');
            model.getTemplateFields().updateTemplateFieldOptions(fieldOptions);

            //todo: add validation
            model.save();
        }
    },

});