({
    /*
    * Use renderModal boolean to minic a render event to allow HTML to focus onto the modal
    */
    afterRender: function (component, helper) {
        this.superAfterRender();
        component.set('v.renderModal', true);
    }
})