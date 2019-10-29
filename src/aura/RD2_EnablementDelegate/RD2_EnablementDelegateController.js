({
    doInit: function (component, event, helper) {
        helper.loadState(component);
    },
    handleEnableConfirm: function (component, event, helper) {
        helper.confirmEnable(component);
    },
    handleEnable: function (component, event, helper) {
        helper.completeEnable(component);
    },
    handleMetaDeployLaunch: function (component, event, helper) {
        helper.launchDeploy(component);
    },
    handleMetaDeployConfirm: function (component, event, helper) {
        helper.confirmDeploy(component);
    },
    handleRunMigration: function (component, event, helper) {
        helper.runMigration(component);
    },
    refreshView: function (component, event, helper) {
        helper.refreshView(component);
    }
})