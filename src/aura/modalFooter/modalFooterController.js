({
    handleMessage: function(component, event) {
        //todo: see if progress steps can be dynamic (appears there might be a bug?) https://success.salesforce.com/ideaView?id=0873A000000TuFUQA0
        var channel = event.getParam('channel');
        var message = event.getParam('message');

        if (channel === 'setProgressSteps') {
            component.set("v.progressSteps", message);
        }
    },

    back: function(component, event) {

    },

    cancel: function(component, event) {

    },

    next: function(component, event) {

    },

    save: function(component, event) {

    }

})