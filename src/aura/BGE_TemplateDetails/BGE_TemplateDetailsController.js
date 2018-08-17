({

    /******************************** Template Details Controller Functions *****************************/

    /* ***************************************************************
     * @Description. Constructs the Model Module, and the View Modules.
     *****************************************************************/
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

    /* ***************************************************************
     * @Description. Cancels creation or view of the template by
     * navigating to object home. Cancels edit by querying model data.
     *****************************************************************/
    cancel: function(component, event, helper) {
        var model = component.get('v.model');
        var mode = component.get("v.templateMetadata.mode");
        //Create/Edit modes invoke cancel from the button; view does so from 'Back to Templates' button
        if (mode === 'create' || mode === 'view') {
            //navigate to record home
            var homeEvent = $A.get("e.force:navigateToObjectHome");
            homeEvent.setParams({
                "scope": component.get("v.templateMetadata.labels.batchTemplateObject")
            });
            homeEvent.fire();
        } else if (mode === 'edit') {
            model.getTemplateMetadata().clearError();
            model.getTemplateMetadata().setDataTableChanged(false);
            model.getTemplateMetadata().setMode('view');
            model.init(component);
        }
    },

    /* ***************************************************************
     * @Description. Navigates from View to Edit mode.
     *****************************************************************/
    changeModeToEdit: function(component, event, helper) {
        var model = component.get("v.model");
        model.getTemplateMetadata().setMode("edit");
    },

    /* ***************************************************************
     * @Description. Saves the full Batch Template record after step 3
     *****************************************************************/
    save: function(component, event, helper) {
        var model = component.get("v.model");
        model.save();
    },


    /* ***************************************************************
    * @Description. Saves field options from step 3 to the model
    *****************************************************************/
    saveFieldOptions: function(component, event, helper) {
        var model = component.get("v.model");
        model.getTemplateMetadata().setDataTableChanged(false);
        model.getTemplateFields().updateTemplateFieldOptions(event.getParam("draftValues"));
    },

    /* ***************************************************************
    * @Description. Logs any changes to data table to disable primary save button
    *****************************************************************/
    logDataTableChange: function(component, event, helper) {
        var model = component.get("v.model");
        var dataTableChanged = component.get("v.templateMetadata.dataTableChanged");
        if (!dataTableChanged) {
            // oncellchange seems to be broken, so we have to set the view directly
            component.set("v.templateMetadata.dataTableChanged", true);
            // this updates the model, but does not call the notifier
            model.getTemplateMetadata().setDataTableChanged(true);
        }
    },

    /* ***************************************************************
    * @Description. Cancels any changes to data table to re-enable primary save button
    *****************************************************************/
    cancelDataTableChanges: function(component, event, helper) {
        var model = component.get("v.model");
        model.getTemplateMetadata().setDataTableChanged(false);
    },

    /* ***************************************************************
    * @Description. Moves to next wizard step
    *****************************************************************/
    next: function(component, event, helper) {
        var model = component.get("v.model");
        var step = component.get("v.templateMetadata.progressIndicatorStep");

        if (step === '1') {
            var templateInfoData = component.get("v.templateInfo");
            model.getTemplateInfo().load(templateInfoData);
            if (model.getTemplateInfo().isValid()) {
                model.getTemplateMetadata().clearError();
                model.getTemplateMetadata().stepUp();
            } else {
                model.getTemplateMetadata().showError(component.get("v.templateMetadata.labels.missingNameDescriptionError"));
            }
        } else if (step === '2') {
            var templateFields = component.get("v.templateFields");
            model.getTemplateFields().updateToActive(templateFields.fieldGroups);
            var errors = model.getTemplateFields().getRequiredFieldErrors();
            if (!errors) {
                model.getTemplateMetadata().clearError();
                model.getTemplateMetadata().stepUp();
            } else {
                model.getTemplateMetadata().showError(errors);
            }
        }
    },

    /* ***************************************************************
    * @Description. Moves to previous wizard step
    *****************************************************************/
    back: function(component, event, helper) {
        var model = component.get('v.model');
        model.getTemplateMetadata().clearError();
        model.getTemplateMetadata().setDataTableChanged(false);
        model.getTemplateMetadata().stepDown();
    },

    /******************************** Template Fields Controller Functions *****************************/

});