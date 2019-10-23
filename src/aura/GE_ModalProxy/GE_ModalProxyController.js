({
    handleSave : function(component, event, helper) {
        component.set('v.sectionBeingEdited', event.getParams('section'));
        component.find("overlayLib").notifyClose();
    },

    handleCancel : function(component, event, helper) {
        component.find("overlayLib").notifyClose();
    }
})
