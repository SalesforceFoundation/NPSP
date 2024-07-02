({
    /****
    * @description Loads the enablement state and enables/disables page elements based on it
    */
    loadState: function (component) {
        var action = component.get("c.loadState");

        action.setCallback(this, function (response) {
            if (!component.isValid()) {
                return;
            }
            const state = response.getState();

            if (state === "SUCCESS") {
                const enablementState = JSON.parse(response.getReturnValue());

                if (!enablementState.isReady && !enablementState.isEnabled) {
                    this.displayElement(component, "enablementDisabled");
                    return;
                }

                this.displayElement(component, "enabler");
                component.set('v.state', enablementState);

                this.refreshDryRun(component);
                this.refreshEnable(component);
                this.refreshMetaDeploy(component);
                this.refreshMigration(component);

            } else if (state === "ERROR") {
                this.handleError(component, response.getError());
            }
        });

        $A.enqueueAction(action);
    },
    /****
    * @description Confirms enhanced Recurring Donations enablement
    */
    confirmEnable: function (component) {
        //disable the current active step so the next step is enabled only on current step success
        component.set('v.state.isConfirmed', false);
        this.showSpinner(component, 'enableConfirmSpinner');
        this.clearError(component);

        var action = component.get('c.confirmEnablement');

        action.setCallback(this, function (response) {
            if (!component.isValid()) {
                return;
            }
            const state = response.getState();

            if (state === 'SUCCESS') {
                component.set('v.state.hideDryRun', true);
                component.set('v.state.isConfirmed', true);

            } else if (state === 'ERROR') {
                this.handleError(component, response.getError(), 'enablement');
            }

            this.refreshEnable(component);
            this.hideSpinner(component, 'enableConfirmSpinner');
        });

        $A.enqueueAction(action);
    },
    /****
    * @description Enables enhanced Recurring Donations
    */
    completeEnable: function (component) {
        //disable the current active step so the next step is enabled only on current step success
        component.set('v.state.isEnabled', false);
        this.clearError(component);
        this.disableEdit(component, "enableToggle");

        var action = component.get('c.enableEnhancement');

        action.setCallback(this, function (response) {
            if (!component.isValid()) {
                return;
            }
            const state = response.getState();

            if (state === 'SUCCESS') {
                component.set('v.state.isEnabled', true);

            } else if (state === 'ERROR') {
                this.handleError(component, response.getError(), 'enablement');
            }

            this.refreshEnable(component);
            this.refreshMetaDeploy(component);

            // notify NPSP Settings page about enhanced Recurring Donation enablement
            var event = $A.get("e.c:RD2_EnhancementEnabledEvent");
            event.fire();
        });

        $A.enqueueAction(action);
    },
    /****
    * @description Loads the enablement state and enables/disables page elements based on it
    */
    getDeployURL: function (component) {
        var action = component.get("c.getMetaDeployURL");

        action.setCallback(this, function (response) {
            if (!component.isValid()) {
                return;
            }
            let state = response.getState();

            if (state === "SUCCESS") {
                const metaDeployURL = response.getReturnValue();
                component.set('v.metaDeployURL', metaDeployURL);

            } else if (state === "ERROR") {
                component.set('v.metaDeployURL', 'https://install.salesforce.org/products/npsp/enhanced-recurring-donations');
            }
        });

        $A.enqueueAction(action);
    },
    /****
    * @description Confirms MetaDeploy has been launched
    */
    launchDeploy: function (component) {
        this.clearError(component);

        var action = component.get('c.launchMetaDeploy');

        action.setCallback(this, function (response) {
            if (!component.isValid()) {
                return;
            }
            const state = response.getState();

            if (state === 'SUCCESS') {
                component.set('v.state.isMetaLaunched', true);

            } else if (state === 'ERROR') {
                this.handleError(component, response.getError(), 'metadeploy');
            }

            this.refreshMetaDeploy(component);
        });

        $A.enqueueAction(action);

    },
    /****
    * @description Confirms MetaDeploy has been deployed
    */
    confirmDeploy: function (component) {
        //disable the current active step so the next step is enabled only on current step success
        component.set('v.state.isMetaConfirmed', false);
        this.showSpinner(component, 'metadeployConfirmSpinner');

        component.set('v.state.isDryRunInProgress', false);
        component.set('v.state.isDryRunStopped', false);

        this.clearError(component);

        var action = component.get('c.confirmMetaDeploy');

        action.setCallback(this, function (response) {
            if (!component.isValid()) {
                return;
            }
            const state = response.getState();

            if (state === 'SUCCESS') {
                component.set('v.state.isMetaConfirmed', true);

            } else if (state === 'ERROR') {
                this.handleError(component, response.getError(), 'metadeploy');
            }

            this.refreshMetaDeploy(component);
            this.hideSpinner(component, 'metadeployConfirmSpinner');
        });

        $A.enqueueAction(action);
    },
    /****
    * @description Starts data migration batch in dry run mode
    */
    runDryRun: function (component) {
        component.set('v.state.isDryRunInProgress', true);
        component.set('v.state.isDryRun2Completed', false);
        this.clearError(component);

        var action = component.get('c.runDryRun');
        action.setCallback(this, function (response) {
            if (!component.isValid()) {
                return;
            }
            const state = response.getState();
            const enablementState = component.get("v.state");

            if (state === 'SUCCESS') {
                component.set('v.state.isDryRunStopped', false);

                if (enablementState.isMetaConfirmed) {
                    component.set('v.state.isDryRun2', true);
                }

                const element = !enablementState.isConfirmed ? 'dryRunJob' : 'dryRun2Job';
                this.displayElement(component, element);
                component.find(element).handleLoadBatchJob();

            } else if (state === 'ERROR') {
                component.set('v.state.isDryRunInProgress', false);

                const section = !enablementState.isConfirmed ? 'dryRun' : 'migration';
                this.handleError(component, response.getError(), section);
            }
        });

        $A.enqueueAction(action);
    },
    /****
    * @description Stops data migration batch in dry run mode
    */
    stopDryRun: function (component) {
        const batchId = component.get("v.dryRunBatch.batchId");

        component.set('v.state.isDryRunStopped', true);
        this.clearError(component);

        var action = component.get("c.stopProcessing");
        action.setParams({
            batchId: batchId
        });
        action.setCallback(this, function (response) {
            if (!component.isValid()) {
                return;
            }
            const state = response.getState();

            if (state === 'ERROR') {
                component.set('v.state.isDryRunStopped', false);
                const enablementState = component.get("v.state");
                const section = !enablementState.isConfirmed ? 'dryRun' : 'migration';
                this.handleError(component, response.getError(), section);
            }
        });

        $A.enqueueAction(action);
    },
    /****
    * @description Skips dry run migration run before actual migration
    */
    skipDryRun: function (component) {
        component.set('v.state.isLoading', true);
        component.set('v.state.isMigrationEnabled', false);
        component.set('v.state.isMigrationInProgress', false);
        this.clearError(component);

        var action = component.get("c.skipDryRun");
        action.setCallback(this, function (response) {
            if (!component.isValid()) {
                return;
            }
            const state = response.getState();

            if (state === 'SUCCESS') {
                component.set('v.state.isMigrationEnabled', true);
                component.set('v.migrationProgress', 'runMigrationStep');

            } else if (state === 'ERROR') {
                this.handleError(component, response.getError(), 'migration');
            }
            component.set('v.state.isLoading', false);
        });

        $A.enqueueAction(action);
    },
    /****
    * @description Starts data migration batch
    */
    runMigration: function (component) {
        component.set('v.state.isMigrationInProgress', true);
        this.clearError(component);

        var action = component.get('c.runMigration');
        action.setCallback(this, function (response) {
            if (!component.isValid()) {
                return;
            }
            const state = response.getState();

            if (state === 'SUCCESS') {
                component.find('migrationJob').handleLoadBatchJob();
                component.set('v.state.isMigrationStopped', false);

            } else if (state === 'ERROR') {
                component.set('v.state.isMigrationInProgress', false);
                this.handleError(component, response.getError(), 'migration');
            }
        });

        $A.enqueueAction(action);
    },
    /****
    * @description Stops data migration batch
    */
    stopMigration: function (component) {
        const batchId = component.get("v.migrationBatch.batchId");

        component.set('v.state.isMigrationStopped', true);
        this.clearError(component);

        var action = component.get("c.stopProcessing");
        action.setParams({
            batchId: batchId
        });
        action.setCallback(this, function (response) {
            if (!component.isValid()) {
                return;
            }
            const state = response.getState();

            if (state === 'ERROR') {
                component.set('v.state.isMigrationStopped', false);
                this.handleError(component, response.getError(), 'migration');
            }
        });

        $A.enqueueAction(action);
    },
    /****
    * @description Skips migration and goes back to validation
    */
    skipMigration: function (component) {
        component.set('v.state.isLoading', true);
        component.set('v.state.isMigrationEnabled', false);
        this.clearError(component);

        var action = component.get("c.skipMigration");
        action.setCallback(this, function (response) {
            if (!component.isValid()) {
                return;
            }
            const state = response.getState();

            if (state === 'SUCCESS') {
                component.set('v.state.isMigrationEnabled', false);
                component.set('v.migrationProgress', 'dryRunStep');

            } else if (state === 'ERROR') {
                component.set('v.state.isMigrationEnabled', true);
                this.handleError(component, response.getError(), 'migration');
            }
            component.set('v.state.isLoading', false);
        });

        $A.enqueueAction(action);
    },
    /****
    * @description Updates page and settings based on the migration batch job status change
    */
    handleBatchEvent: function (component, event, element) {
        if (!component.isValid()) {
            return;
        }

        const batch = event.getParam('batchProgress');
        if (batch === undefined
            || batch === null
            || (batch.className !== 'RD2_DataMigration_BATCH' && batch.className !== 'RD2_DataMigrationDryRun_BATCH')
        ) {
            return;
        }

        component.set(element, batch);
    },
    /****
    * @description Displays an unexpected error generated during data migration batch execution
    */
    handleBatchError: function (component, event, section) {
        if (!component.isValid()) {
            return;
        }

        const state = component.get("v.state");
        if (state === undefined || state === null) {
            return;
        }

        const errorDetail = event.getParam('errorDetail');
        if (errorDetail === undefined
            || errorDetail === null
            || (errorDetail.className !== 'RD2_DataMigration_BATCH' && errorDetail.className !== 'RD2_DataMigrationDryRun_BATCH')
        ) {
            return;
        }

        this.clearError(component);

        if (section === 'dryRun') {
            this.handleError(component, response.getError(), !state.isConfirmed ? 'dryRun' : 'migration');

        } else {
            this.handleError(component, errorDetail, section);
        }
    },
    /****
    * @description Disables page elements and reloads the enablement state
    */
    refreshView: function (component) {
        this.hideElement(component, "enablementDisabled");
        this.hideElement(component, "enabler");

        this.loadState(component);
    },
    /****
    * @description Refreshes dry run migration section
    */
    refreshDryRun: function (component) {
        if (!component.isValid()) {
            return;
        }

        const state = component.get("v.state");
        if (state === undefined || state === null) {
            return;
        }

        let isOutdated = false;
        let hideDryRun = state.isEnabled || state.isConfirmed;
        let isInProgress = false;
        let isCompleted = hideDryRun;
        let isCompleted2 = false;

        if (state.isMigrationEnabled) {
            component.set('v.migrationProgress', 'runMigrationStep');
            isCompleted = true;
            isCompleted2 = true;
        }

        const batch = component.get("v.dryRunBatch");
        if (batch !== undefined && batch !== null) {
            const isBatchCompleted = batch.status === 'Completed' && batch.isSuccess;

            isOutdated = batch.completedDaysBetween > state.dryRunLimit;
            if (isOutdated) {
                state.isConfirmed = state.isEnabled ? true : false;
                component.set('v.state.isConfirmed', state.isConfirmed);
            }

            hideDryRun = state.isEnabled ? true : (state.isConfirmed ? !isOutdated : false);
            isInProgress = batch.isInProgress;
            isCompleted = state.isEnabled ? true : (isOutdated ? false : isBatchCompleted);
            isCompleted2 = state.isDryRun2 ? isBatchCompleted : false;
        }

        component.set('v.state.isDryRunOutdated', isOutdated);
        component.set('v.state.hideDryRun', hideDryRun);
        component.set('v.state.isDryRunInProgress', isInProgress);
        component.set('v.state.isDryRunCompleted', isCompleted);
        component.set('v.state.isDryRun2Completed', isCompleted2);
    },
    /****
    * @description Set data migration attributes
    */
    refreshMigration: function (component) {
        if (!component.isValid()) {
            return;
        }

        const state = component.get("v.state");
        if (state === undefined || state === null) {
            return;
        }

        const batch = component.get("v.migrationBatch");
        if (batch === undefined || batch === null) {
            component.set('v.state.isMigrationInProgress', false);
            component.set('v.state.isMigrationCompleted', false);

        } else {
            component.set('v.state.isMigrationInProgress', batch.isInProgress);

            const isCompleted = state.isMetaConfirmed
                && batch.status === 'Completed'
                && batch.isSuccess;
            component.set('v.state.isMigrationCompleted', isCompleted);
        }
    },
    /****
    * @description Refreshes enable Recurring Donations section
    */
    refreshEnable: function (component) {
        let state = component.get("v.state");

        let enableProgress = 0;
        if (state.isEnabled) {
            enableProgress = 100;
        } else if (state.isConfirmed) {
            enableProgress = 50;
        }
        component.set('v.state.enableProgress', enableProgress);

        if (!state.isConfirmed || state.isEnabled) {
            this.disableEdit(component, "enableToggle");
        } else {
            this.enableEdit(component, "enableToggle");
        }
    },
    /****
    * @description Refreshes MetaDeploy section
    */
    refreshMetaDeploy: function (component) {
        let state = component.get("v.state");

        let metaDeployProgress = 0;
        if (state.isMetaConfirmed) {
            metaDeployProgress = 100;
        } else if (state.isMetaLaunched) {
            metaDeployProgress = 50;
        }
        component.set('v.state.metaDeployProgress', metaDeployProgress);

        let linkIcon = component.find('metadeployIcon');
        if (state.isEnabled) {
            this.enableEdit(component, "metadeployLink");
            $A.util.addClass(linkIcon, "activeIcon");
        } else {
            this.disableEdit(component, "metadeployLink");
            $A.util.removeClass(linkIcon, "activeIcon");
        }
    },
    /****
    * @description Hides component's element
    */
    hideElement: function (component, elementName) {
        let element = component.find(elementName);
        $A.util.addClass(element, "slds-hide");
    },
    /****
    * @description Displays component's element
    */
    displayElement: function (component, elementName) {
        let element = component.find(elementName);
        $A.util.removeClass(element, "slds-hide");
    },
    /****
    * @description Disables input field edit
    */
    disableEdit: function (component, inputName) {
        let inputComp = component.find(inputName);
        $A.util.addClass(inputComp, "disabledEdit");
    },
    /****
    * @description Enables input field edit
    */
    enableEdit: function (component, inputName) {
        let inputComp = component.find(inputName);
        $A.util.removeClass(inputComp, "disabledEdit");
    },
    /****
    * @description Clears the errors on the page
    */
    clearError: function (component) {
        component.set('v.errorSection', '');
        component.set('v.errorMessage', '');
    },
    /**
     * @description: Displays errors thrown by Apex method invocations
     * @param errors: Error list
     */
    handleError: function (component, errors, section) {
        let message;
        if (errors && errors[0] && errors[0].message) {
            message = errors[0].message;

        } else if (errors && errors.message) {
            message = errors.message;

        } else {
            message = $A.get('$Label.c.stgUnknownError');
        }

        component.set('v.errorSection', section);
        component.set('v.errorMessage', message);
    },
    /**
     * @description: shows specific spinner
     */
    showSpinner: function (component, element) {
        var spinner = component.find(element);
        $A.util.removeClass(spinner, 'slds-hide');
    },
    /**
     * @description: hides specific spinner
     */
    hideSpinner: function (component, element) {
        var spinner = component.find(element);
        $A.util.addClass(spinner, 'slds-hide');
    },
    /**
     * @description: Autofocus 
     */
    setFocus: function (component, elementId) {
        window.setTimeout(() => { 
           try { var element = component.find(elementId); 
               if (element) { 
                   element.getElement().setAttribute('tabindex', '0'); 
                   element.getElement().focus(); 
                   element.getElement().setAttribute('tabindex', '-1'); 
               } 
           } catch (error) { 
                   console.error('Error setting focus on element:', error); 

           } 
           }, 0); 
   }
})
