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
        var availableTemplateFieldsView = helper.AvailableTemplateFieldsView(component, model);
        component.set('v.availableTemplateFields', availableTemplateFieldsView);
        var activeTemplateFieldsView = helper.ActiveTemplateFieldsView(component, model);
        component.set('v.activeTemplateFields', activeTemplateFieldsView);

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

    /******************************** Template Fields Controller Functions *****************************/


    /* ***************************************************************
     * @Description. Increases selected field activeSortOrder by 1 in the
     * Template Fields Model, and moves neighbor fields up.
     *****************************************************************/
    moveFieldsDown: function (component, event, helper) {
        var model = component.get('v.model');
        model.getTemplateFields().moveSelectedDown();
    },

    /* ***************************************************************
     * @Description. Decreases selected field activeSortOrder by 1 in the
     * Template Fields Model, and moves neighbor fields down.
     *****************************************************************/
    moveFieldsUp: function (component, event, helper) {
        var model = component.get('v.model');
        model.getTemplateFields().moveSelectedUp();
    },

    /* ***************************************************************
     * @Description. Updates the selected (checked) available fields in the
     * Template Fields Model.
     *****************************************************************/
    selectAvailableTemplateFields: function (component, event, helper) {
        var selectedFields = {};
        event.getParam('selectedRows').forEach(function(selectedRow) {
            selectedFields[selectedRow.id] = selectedRow;
        });
        var model = component.get('v.model');
        model.getTemplateFields().selectAvailables(selectedFields);
    },

    /* ***************************************************************
     * @Description. Updates the selected (checked) active fields in the
     * Template Fields Model.
     *****************************************************************/
    selectActiveTemplateFields: function (component, event, helper) {
        var selectedFields = {};
        event.getParam('selectedRows').forEach(function(selectedRow) {
            selectedFields[selectedRow.id] = selectedRow;
        });
        var model = component.get('v.model');
        model.getTemplateFields().selectActives(selectedFields);
    },

    /* ***************************************************************
     * @Description. Updates the selected available fields in the 
     * Template Fields Model to active.
     *****************************************************************/
    updateToActive: function (component, event, helper) {
        var model = component.get('v.model');
        model.getTemplateFields().updateSelectedToActive();
    },

    /* ***************************************************************
     * @Description. Updates the selected active fields in the
     * Template Fields Model to available.
     *****************************************************************/
    updateToAvailable: function (component, event, helper) {
        var model = component.get('v.model');
        model.getTemplateFields().updateSelectedToAvailable();
    }
});