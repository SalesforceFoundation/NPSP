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
    handleDryRunStop: function (component, event, helper) {
        helper.stopDryRun(component);
    },
    handleDryRunSkip: function (component, event, helper) {
        helper.skipDryRun(component);
    },
    handleDryRunStatusChange: function (component, event, helper) {
        helper.handleBatchEvent(component, event, 'v.dryRunBatch');
        helper.refreshDryRun(component);
        helper.refreshEnable(component);
    },
    handleDryRunError: function (component, event, helper) {
        helper.handleBatchError(component, event, 'dryRun');
    },
    handleMigrationRun: function (component, event, helper) {
        helper.runMigration(component);
    },
    handleMigrationStop: function (component, event, helper) {
        helper.stopMigration(component);
    },
    handleMigrationSkip: function (component, event, helper) {
        helper.skipMigration(component);
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