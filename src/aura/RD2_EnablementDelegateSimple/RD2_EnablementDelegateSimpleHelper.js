({
    /****
    * @description Displays component's element
    */
   displayElement: function (component, elementName) {
    let element = component.find(elementName);
    $A.util.removeClass(element, "slds-hide");
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
    }
})
