/**
 * Created by bbreisnes on 2018-09-05.
 */
({

    sendMessage: function (channel, message) {
        var sendMessage = $A.get('e.ltng:sendMessage');
        sendMessage.setParams({
            'channel': channel,
            'message': message
        });
        sendMessage.fire();
    }

})