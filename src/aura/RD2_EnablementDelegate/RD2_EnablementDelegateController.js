({
    doInit: function (component, event, helper) {
        helper.loadState(component);
    },
    onEnableConfirm: function (component, event, helper) {
        helper.confirmEnablement(component);
    },
    onEnabled: function (component, event, helper) {
        helper.enable(component);
    },
    onMetaDeployConfirm: function (component, event, helper) {
        helper.confirmMetaDeploy(component);
    },
    refreshView: function (component, event, helper) {
        helper.refreshView(component);
    }
})