({
    callFocus: function(component){
        component.find("donorType").focus();
    },

    /**
     * @description: alerts parent component that form needs to be cleared
     */
    cancelForm: function (component, event, helper) {
        helper.sendMessage('onCancel', '');
        component.destroy();
    },

    /**
     * @description: hides spinner over form when form finishes loading
     */
    onFormLoad: function (component, event, helper) {
        helper.sendMessage('hideFormSpinner', '');
    },

    /**
     * @description: alerts parent component that record is saved
     */
    onSuccess: function (component, event, helper) {
        helper.sendMessage('onSuccess', '');
        component.destroy();
    },

    /**
     * @description: sets the donor type. Used to circumvent the unhelpful labeling of Account1/Contact1.
     */
    setDonorType: function (component, event, helper) {
        var donorType = event.getSource().get("v.value");
        component.set("v.donorType", donorType);
        helper.sendMessage('setDonorType', donorType);
    }

})