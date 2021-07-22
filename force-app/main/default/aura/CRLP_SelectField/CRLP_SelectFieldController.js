({
    /**
     * @description: gets the fieldAPIName of the the field and selected value
     * the intended recipient of the message is the rollup component
     */
    changeField: function(cmp, event){
        var fieldName = cmp.get('v.auraId');
        var value = event.getSource().get("v.value");
        if (value === undefined) {
            value = '';
        }

        //todo: is there an easier way to get the selected option text?
        var label = '';
        var options = cmp.get("v.options");
        for (var i = 0; i < options.length; i++) {
            if (options[i].name === value) {
                label = options[i].label;
                break;
            }
        }
        var message = [fieldName, value, label];

        var sendMessage = $A.get('e.ltng:sendMessage');
        sendMessage.setParams({
            'message': message,
            'channel': 'selectField'
        });
        sendMessage.fire();
    },

    /**
     * @description: handles the ltng:message event to check for an invalid lightning input
     */
    handleMessage: function(cmp, event) {
        if (event.getParam("channel") === 'validateCmp') {
            var inputCmp = cmp.find('selectField');
            inputCmp.showHelpMessageIfInvalid();
        }
    }
})