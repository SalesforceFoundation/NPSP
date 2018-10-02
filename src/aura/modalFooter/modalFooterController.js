({
    handleMessage: function(component, event) {
        //todo: see if the entire set of progress steps can be dynamic (appears there might be a bug?) https://success.salesforce.com/ideaView?id=0873A000000TuFUQA0
        var channel = event.getParam('channel');
        var message = event.getParam('message');

        if (channel === 'setStep') {
            component.set("v.currentStep", message);
        }
    },

    back: function(component, event) {
        var sendMessage = $A.get('e.ltng:sendMessage');
        sendMessage.setParams({
            'channel': 'back',
            'message': null
        });
        sendMessage.fire();
    },

    cancel: function(component, event) {
        var sendMessage = $A.get('e.ltng:sendMessage');
        sendMessage.setParams({
            'channel': 'cancel',
            'message': null
        });
        sendMessage.fire();
    },

    next: function(component, event) {
        var sendMessage = $A.get('e.ltng:sendMessage');
        sendMessage.setParams({
            'channel': 'next',
            'message': null
        });
        sendMessage.fire();
    },

    save: function(component, event) {
        component.find("overlayLib").notifyClose();
    }

})