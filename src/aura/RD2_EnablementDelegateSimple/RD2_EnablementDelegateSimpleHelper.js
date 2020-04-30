({
    /****
    * @description Clears the errors on the page
    */
    clearError: function (component) {
        component.set('v.errorSection', '');
        component.set('v.errorMessage', '');
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
    * @description Disables input field edit
    */
    disableEdit: function (component, inputName) {
        let inputComp = component.find(inputName);
        $A.util.addClass(inputComp, "disabledEdit");
    },

    /****
    * @description Displays component's element
    */
    displayElement: function (component, elementName) {
        let element = component.find(elementName);
        $A.util.removeClass(element, "slds-hide");
    },

    /****
    * @description Enables input field edit
    */
    enableEdit: function (component, inputName) {
        let inputComp = component.find(inputName);
        $A.util.removeClass(inputComp, "disabledEdit");
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

                this.refreshEnable(component);
                this.refreshMetaDeploy(component);

            } else if (state === "ERROR") {
                this.handleError(component, response.getError());
            }
        });

        $A.enqueueAction(action);
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

        if (state.isEnabled) {
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
    * @description Disables page elements and reloads the enablement state
    */
    refreshView: function (component) {
        this.hideElement(component, "enablementDisabled");
        this.hideElement(component, "enabler");

        this.loadState(component);
    },

    /****
    * @description Hides component's element
    */
    hideElement: function (component, elementName) {
        let element = component.find(elementName);
        $A.util.addClass(element, "slds-hide");
    },

    /**
     * @description: hides specific spinner
     */
    hideSpinner: function (component, element) {
        var spinner = component.find(element);
        $A.util.addClass(spinner, 'slds-hide');
    },

    /**
     * @description: shows specific spinner
     */
    showSpinner: function (component, element) {
        var spinner = component.find(element);
        $A.util.removeClass(spinner, 'slds-hide');
    }
})
