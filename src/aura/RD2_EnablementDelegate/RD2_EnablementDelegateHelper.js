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
                    this.displayElement(component, "enablement-disabled");
                    return;
                }

                this.displayElement(component, "enabler");
                enablementState.isMigrationInProgress = false;
                component.set('v.state', enablementState);

                this.refreshEnable(component);
                this.refreshMetaDeploy(component);

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

        this.clearError(component);

        var action = component.get('c.confirmEnablement');

        action.setCallback(this, function (response) {
            if (!component.isValid()) {
                return;
            }
            const state = response.getState();

            if (state === 'SUCCESS') {
                component.set('v.state.isConfirmed', true);

            } else if (state === 'ERROR') {
                this.handleError(component, response.getError(), '1');
            }

            this.refreshEnable(component);
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
        this.disableEdit(component, "enable-toggle");

        var action = component.get('c.enableEnhancement');

        action.setCallback(this, function (response) {
            if (!component.isValid()) {
                return;
            }
            const state = response.getState();

            if (state === 'SUCCESS') {
                component.set('v.state.isEnabled', true);

            } else if (state === 'ERROR') {
                this.handleError(component, response.getError(), '1');
            }

            this.refreshEnable(component);
            this.refreshMetaDeploy(component);
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
                component.set('v.metaDeployURL', 'https://install.salesforce.org/products/npsp/npsp-rd2-pilot');
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
                component.set('v.state.isMetaDeployLaunched', true);

            } else if (state === 'ERROR') {
                this.handleError(component, response.getError(), '2');
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
        component.set('v.state.isMetaDeployConfirmed', false);

        this.clearError(component);

        var action = component.get('c.confirmMetaDeploy');

        action.setCallback(this, function (response) {
            if (!component.isValid()) {
                return;
            }
            const state = response.getState();

            if (state === 'SUCCESS') {
                component.set('v.state.isMetaDeployConfirmed', true);

            } else if (state === 'ERROR') {
                this.handleError(component, response.getError(), '2');
            }

            this.refreshMetaDeploy(component);
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
                component.find('rdMigrationBatchJob').handleLoadBatchJob();

            } else if (state === 'ERROR') {
                component.set('v.state.isMigrationInProgress', false);
                this.handleError(component, response.getError(), '3');
            }
        });

        $A.enqueueAction(action);
    },
    /****
    * @description Updates page and settings based on the migration batch job status change
    */
    processMigrationStatusChange: function (component, event) {
        if (!component.isValid()) {
            return;
        }

        const batchProgress = event.getParam('batchProgress');
        if (batchProgress === undefined
            || batchProgress === null
            || batchProgress.className !== 'RD2_DataMigration_BATCH'
        ) {
            return;
        }

        if (batchProgress.isInProgress) {
            component.set('v.state.isMigrationInProgress', true);

        } else if (batchProgress.isSuccess) {
            this.confirmMigration(component);

        } else {
            component.set('v.state.isMigrationInProgress', false);
        }
    },
    /****
    * @description Displays an unexpected error generated during data migration batch execution
    */
    processMigrationError: function (component, event) {
        if (!component.isValid()) {
            return;
        }

        const errorDetail = event.getParam('errorDetail');
        if (errorDetail === undefined
            || errorDetail === null
            || errorDetail.className !== 'RD2_DataMigration_BATCH'
        ) {
            return;
        }

        this.clearError(component);
        this.handleError(component, errorDetail, '3');
    },
    /****
    * @description Starts data migration batch
    */
    confirmMigration: function (component) {
        let enablementState = component.get("v.state");

        if (enablementState.isMigrationCompleted) {
            return;
        }

        component.set('v.state.isMigrationCompleted', true);

        this.clearError(component);

        var action = component.get('c.completeMigration');

        action.setCallback(this, function (response) {
            if (!component.isValid()) {
                return;
            }
            const state = response.getState();

            if (state === 'SUCCESS') {
                component.set('v.state.isMigrationInProgress', false);

            } else if (state === 'ERROR') {
                component.set('v.state.isMigrationCompleted', false);
                this.handleError(component, response.getError(), '3');
            }
        });

        $A.enqueueAction(action);
    },
    /****
    * @description Disables page elements and reloads the enablement state
    */
    refreshView: function (component) {
        this.hideElement(component, "enablement-disabled");
        this.hideElement(component, "enabler");

        this.loadState(component);
    },
    /****
    * @description Refreshes enable Recurring Donations section
    */
    refreshEnable: function (component) {
        let enablementState = component.get("v.state");

        let enableProgress = 0;
        if (enablementState.isEnabled) {
            enableProgress = 100;
        } else if (enablementState.isConfirmed) {
            enableProgress = 50;
        }
        component.set('v.state.enableProgress', enableProgress);

        if (!enablementState.isConfirmed || enablementState.isEnabled) {
            this.disableEdit(component, "enable-toggle");
        } else {
            this.enableEdit(component, "enable-toggle");
        }
    },
    /****
    * @description Refreshes MetaDeploy section
    */
    refreshMetaDeploy: function (component) {
        let enablementState = component.get("v.state");

        let metaDeployProgress = 0;
        if (enablementState.isMetaDeployConfirmed) {
            metaDeployProgress = 100;
        } else if (enablementState.isMetaDeployLaunched) {
            metaDeployProgress = 50;
        }
        component.set('v.state.metaDeployProgress', metaDeployProgress);

        let linkIcon = component.find('metadeploy-link-icon');
        if (enablementState.isEnabled) {
            this.enableEdit(component, "metadeploy-link");
            $A.util.addClass(linkIcon, "activeIcon");
        } else {
            this.disableEdit(component, "metadeploy-link");
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
    }
})
