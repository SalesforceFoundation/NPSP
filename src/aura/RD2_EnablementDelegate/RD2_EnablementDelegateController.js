({
    doInit: function (component, event, helper) {
        helper.loadState(component);
        helper.getDeployURL(component);
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
    handleMigrationStatusChange: function (component, event, helper) {
        helper.processMigrationStatusChange(component, event);
    },
    handleMigrationError: function (component, event, helper) {
        helper.processMigrationError(component, event);
    },
    refreshView: function (component, event, helper) {
        helper.refreshView(component);
    }
})