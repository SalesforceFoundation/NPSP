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
    handleDryRun: function (component, event, helper) {
        helper.runDryRun(component);
    },
    handleDryRunStatusChange: function (component, event, helper) {
        helper.handleBatchEvent(component, event, 'v.dryRunBatch');
        helper.refreshDryRun(component);
    },
    handleDryRunError: function (component, event, helper) {
        helper.handleBatchError(component, event, 'dryRun');
    },
    handleRunMigration: function (component, event, helper) {
        helper.runMigration(component);
    },
    handleMigrationStatusChange: function (component, event, helper) {
        helper.handleBatchEvent(component, event, 'v.migrationBatch');
        helper.refreshMigration(component);
    },
    handleMigrationError: function (component, event, helper) {
        helper.handleBatchError(component, event, 'migration');
    },
    refreshView: function (component, event, helper) {
        helper.refreshView(component);
    }
})