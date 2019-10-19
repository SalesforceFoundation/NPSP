({
    handleSave : function(component, event, helper) {
        console.log('Handle Save Here');
        console.log(JSON.parse(JSON.stringify(event.getParams('section'))));
        component.set('v.sectionBeingEdited', event.getParams('section'));
        component.find("overlayLib").notifyClose();
    },

    handleCancel : function(component, event, helper) {
        console.log('Handle Cancel Here');
        component.find("overlayLib").notifyClose();
    }
})
