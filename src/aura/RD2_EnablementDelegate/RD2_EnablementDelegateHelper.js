({
    /****
    * @description Loads the enablement state and enables/disables page elements based on it
    */
    loadState: function (component) {
        var action = component.get("c.loadState");

        action.setCallback(this, function (response) {
            let state = response.getState();

            if (!component.isValid()) {
                return;
            }

            if (state === "SUCCESS") {
                var enablementState = JSON.parse(response.getReturnValue());

                if (!enablementState.isReady && !enablementState.isEnabled) {
                    this.displayElement(component, "enablement-disabled");
                    return;
                }

                this.displayElement(component, "enabler");
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
        var action = component.get('c.confirmEnablement');

        action.setCallback(this, function (response) {
            var state = response.getState();

            if (!component.isValid()) {
                return;
            }

            if (state === 'SUCCESS') {
                component.set('v.state.isEnableConfirmed', true);

            } else if (state === 'ERROR') {
                this.handleError(component, response.getError());
            }

            this.refreshEnable(component);
        });

        $A.enqueueAction(action);
    },
    /****
    * @description Enables enhanced Recurring Donations 
    */
    completeEnable: function (component) {
        var action = component.get('c.enableEnhancement');

        action.setCallback(this, function (response) {
            var state = response.getState();

            if (!component.isValid()) {
                return;
            }

            if (state === 'SUCCESS') {
                component.set('v.state.isEnabled', true);

            } else if (state === 'ERROR') {
                this.handleError(component, response.getError());
            }

            this.refreshEnable(component);
            this.refreshMetaDeploy(component);
        });

        $A.enqueueAction(action);
    },
    /****
    * @description Confirms MetaDeploy has been launched
    */
    launchDeploy: function (component) {
        var action = component.get('c.launchMetaDeploy');

        action.setCallback(this, function (response) {
            var state = response.getState();

            if (!component.isValid()) {
                return;
            }

            if (state === 'SUCCESS') {
                component.set('v.state.isMetaDeployLaunched', true);

            } else if (state === 'ERROR') {
                this.handleError(component, response.getError());
            }

            this.refreshMetaDeploy(component);
        });

        $A.enqueueAction(action);
    },
    /****
    * @description Confirms MetaDeploy has been deployed
    */
    confirmDeploy: function (component) {
        var action = component.get('c.confirmMetaDeploy');

        action.setCallback(this, function (response) {
            var state = response.getState();

            if (!component.isValid()) {
                return;
            }

            if (state === 'SUCCESS') {
                component.set('v.state.isMetaDeployConfirmed', true);

            } else if (state === 'ERROR') {
                this.handleError(component, response.getError());
            }

            this.refreshMetaDeploy(component);
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

        if (enablementState.isEnabled) {
            this.enableEdit(component, "metadeploy-link");
        } else {
            this.disableEdit(component, "metadeploy-link");
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
        $A.util.addClass(inputComp, "editDisabled");
    },
    /****
    * @description Enables input field edit
    */
    enableEdit: function (component, inputName) {
        let inputComp = component.find(inputName);
        $A.util.removeClass(inputComp, "editDisabled");
    },
    /**
     * @description: Displays errors thrown by Apex method invocations
     * @param errors: Error list
     */
    handleError: function (component, errors) {
        let message;
        if (errors && errors[0] && errors[0].message) {
            message = errors[0].message;
        } else {
            message = 'Unknown error';
        }
        console.log('Unexpected Error: ' + message);//TODO 
    }
})
