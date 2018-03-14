({
    changeField: function(cmp, event, helper){
        //gets the fieldAPIName of the the field and selected value
        //the intended recipient of the message is the rollup component
        var fieldName = cmp.get('v.auraId');
        var value = event.getSource().get("v.value");
        var label = event.getSource().get("v.name");
        var message = [fieldName, value, label];
        var sendMessage = $A.get('e.ltng:sendMessage');
        sendMessage.setParams({
            'message': message,
            'channel': 'selectField'
        });
        sendMessage.fire();
    }
})