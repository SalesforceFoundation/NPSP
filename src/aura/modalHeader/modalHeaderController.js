({
    handleMessage: function(component, event) {
        var channel = event.getParam('channel');
        var message = event.getParam('message');

        if (channel === 'changeHeader') {
            component.set("v.header", message);
        }
    }
})