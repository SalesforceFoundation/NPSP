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

        model.init(component);
    },

    /* ***************************************************************
     * @Description. Cancels creation or view of the template by
     * navigating to object home. Cancels edit by querying model data.
     *****************************************************************/
    cancel: function(component, event, helper) {
        var model = component.get('v.model');
        var mode = component.get("v.templateMetadata.mode");
        if (mode === 'create' || mode === 'view') {
            //navigate to record home
            var homeEvent = $A.get("e.force:navigateToObjectHome");
            homeEvent.setParams({
                "scope": component.get("v.templateMetadata.labels.batchTemplateObject")
            });
            homeEvent.fire();
        } else if (mode === 'edit') {
            model.getTemplateMetadata().setMode('view');
            model.init(component);
        }
    },

    /* ***************************************************************
     * @Description. Navigates from View to Edit mode.
     *****************************************************************/
    changeModeToEdit: function(component, event, helper) {
        var model = component.get('v.model');
        model.getTemplateMetadata().setMode('edit');
    },

    /* ***************************************************************
     * @Description. Saves the template information. 
     *****************************************************************/
    save: function(component, event, helper) {
        var templateInfoData = component.get("v.templateInfo");
        var model = component.get('v.model');
        model.getTemplateInfo().load(templateInfoData);
        model.save();
    },

    /* ***************************************************************
    * @Description. Moves to next wizard step
    *****************************************************************/
    next: function(component, event, helper) {
        var model = component.get('v.model');
        var step = component.get("v.templateMetadata.progressIndicatorStep");

        if (step === '1') {
            var templateInfoData = component.get("v.templateInfo");
            model.getTemplateInfo().load(templateInfoData);
            if (model.getTemplateInfo().isValid()) {
                model.getTemplateMetadata().stepUp(step);
            } else {
                model.getTemplateMetadata().setError(true, component.get("v.templateMetadata.labels.missingNameDescriptionError"));
            }
        } else if (step === '2') {
            var templateFields = component.get("v.templateFields");
            model.getTemplateFields().updateToActive(templateFields.fieldGroups);
            model.getTemplateMetadata().stepUp(step);
        }
    },

    /* ***************************************************************
    * @Description. Moves to previous wizard step
    *****************************************************************/
    back: function(component, event, helper) {
        var step = component.get("v.templateMetadata.progressIndicatorStep");
        var model = component.get('v.model');
        model.getTemplateMetadata().stepDown(step);
    },

    /******************************** Template Fields Controller Functions *****************************/

});