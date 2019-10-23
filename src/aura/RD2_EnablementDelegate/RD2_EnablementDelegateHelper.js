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
        this.clearError(component);

        var action = component.get('c.confirmEnablement');

        action.setCallback(this, function (response) {
            var state = response.getState();

            if (!component.isValid()) {
                return;
            }

            if (state === 'ERROR') {
                component.set('v.state.isConfirmed', false);
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
        this.clearError(component);
        this.disableEdit(component, "enable-toggle");

        var action = component.get('c.enableEnhancement');

        action.setCallback(this, function (response) {
            var state = response.getState();

            if (!component.isValid()) {
                return;
            }

            if (state === 'ERROR') {
                component.set('v.state.isEnabled', false);
                this.handleError(component, response.getError(), '1');
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
        this.clearError(component);

        var action = component.get('c.launchMetaDeploy');

        action.setCallback(this, function (response) {
            var state = response.getState();

            if (!component.isValid()) {
                return;
            }

            if (state === 'SUCCESS') {
                component.set('v.state.isMetaDeployLaunched', true);

                let url = 'https://metadeploy.herokuapp.com/products/npsp/RD2-enablement/npsp-rd2-pilot';
                window.open(url, '_blank');

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
        this.clearError(component);

        var action = component.get('c.confirmMetaDeploy');

        action.setCallback(this, function (response) {
            var state = response.getState();

            if (!component.isValid()) {
                return;
            }

            if (state === 'ERROR') {
                component.set('v.state.isMetaDeployConfirmed', false);
                this.handleError(component, response.getError(), '2');
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

        this.clearError(component);

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
        } else {
            message = $A.get('$Label.c.stgUnknownError');
        }

        component.set('v.errorSection', section);
        component.set('v.errorMessage', message);
        console.log('Unexpected Error: ' + component.get('v.errorMessage'));
    }
})
