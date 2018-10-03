({
    handleMessage: function(component, event) {
        //todo: see if the entire set of progress steps can be dynamic (appears there might be a bug?) https://success.salesforce.com/ideaView?id=0873A000000TuFUQA0
        var channel = event.getParam('channel');
        var message = event.getParam('message');

        if (channel === 'setStep') {
            component.set('v.currentStep', message);
        } else if (channel === 'dataTableChanged') {
            component.set('v.dataTableChanged', message);
        }
    },

    back: function(component, event, helper) {
        helper.sendMessage(component, 'back', null);
    },

    cancel: function(component, event, helper) {
        helper.sendMessage(component, 'cancel', null);
    },

    next: function(component, event, helper) {
        helper.sendMessage(component, 'next', null);
    },

    save: function(component, event, helper) {
        helper.sendMessage(component, 'save', null);
        //todo: add validation, put this in another listener function
        component.find("overlayLib").notifyClose();
    }

})