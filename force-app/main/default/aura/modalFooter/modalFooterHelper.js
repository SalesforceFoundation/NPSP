({
    /**
     * @description: handles ltng:sendMessage
     */
    sendMessage: function(component, channel, message) {
        var sendMessage = $A.get('e.ltng:sendMessage');
        sendMessage.setParams({
            'channel': channel,
            'message': message
        });
        sendMessage.fire();
    }
})