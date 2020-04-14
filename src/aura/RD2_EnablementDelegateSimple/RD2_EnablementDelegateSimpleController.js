({
    doInit: function (component, event, helper) {
        helper.loadState(component);
        helper.getDeployURL(component);
    },

    refreshView: function (component, event, helper) {
        helper.refreshView(component);
    }
})
