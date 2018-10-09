({
    /**
     * @description: handles ltng:sendMessage
     */
    handleMessage: function(component, event) {
        var channel = event.getParam('channel');
        var message = event.getParam('message');

        if (channel === 'setHeader') {
            component.set("v.header", message);
        }
    }
})