({
    /**
     * @description: handles ltng:sendMessage from child component
     */
    handleMessage: function(component, event) {
        var channel = event.getParam('channel');
        var message = event.getParam('message');

        if (channel === 'setStep') {
            component.set('v.currentStep', message);
        } else if (channel === 'setError') {
            component.set('v.hasError', message);
        } else if (channel === 'pendingSave') {
            component.set('v.pendingSave', message);
        }
    },

    /**
     * @description: sends back event to modal
     */
    back: function(component, event, helper) {
        helper.sendMessage(component, 'back');
    },

    /**
     * @description: closes the modal directly
     */
    cancel: function(component, event, helper) {
        component.find("overlayLib").notifyClose();
    },

    /**
     * @description: sends next event to modal
     */
    next: function(component, event, helper) {
        helper.sendMessage(component, 'next');
    },

    /**
     * @description: sends save event to modal
     */
    save: function(component, event, helper) {
        component.set('v.pendingSave', true);
        helper.sendMessage(component, 'save');
    }

})