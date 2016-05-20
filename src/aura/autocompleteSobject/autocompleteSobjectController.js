({
    doInit: function (component, event, helper) {
        var iconSprite = component.get('v.iconSprite');
        var iconName = component.get('v.iconName');
        if (!iconSprite && !iconName) {
            var sobject = component.get('v.sobject');
            helper.setStandardIconAndSprite(component, sobject);
        }
    },

	handleOptionSelected: function(component, event, helper) {
		console.log('handling option selected...');
	}
})