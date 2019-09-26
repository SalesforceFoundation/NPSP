({
    doInit: function (component, event, helper) {
        helper.loadState(component);
    },
    onStep2Complete: function (component, event, helper) {
        helper.completeStep2(component);
    },
    refreshView: function (component, event, helper) {
        helper.refreshView(component);
    }
})