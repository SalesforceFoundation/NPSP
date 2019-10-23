({
    /*******************************************************************************
    * @description Receives event from child component utilModal and sets the
    * two-way bound aura attribute sectionBeingEdited. An aura change handler
    * on the parent aura component GE_TemplateBuilder handles sending this data
    * change down to the top level lwc geTemplateBuilder.
    */
    handleSave : function(component, event, helper) {
        component.set('v.sectionBeingEdited', event.getParams('section'));
        component.find("overlayLib").notifyClose();
    },

    /*******************************************************************************
    * @description Receives event from child component utilModal and closes the modal
    * created from the overlay library.
    */
    handleCancel : function(component, event, helper) {
        component.find("overlayLib").notifyClose();
    }
})
