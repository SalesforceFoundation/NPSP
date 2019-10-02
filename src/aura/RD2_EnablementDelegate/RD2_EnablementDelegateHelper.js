({
    /****
    * @description 
    */
    loadState: function (component) {
        var action = component.get("c.loadState");

        console.log('*****loadState');

        action.setCallback(this, function (response) {
            let state = response.getState();

            if (component.isValid() && state === "SUCCESS") {
                var enablementState = JSON.parse(response.getReturnValue());

                if (!enablementState.isReady && !enablementState.isEnabled) {
                    this.displayElement(component, "enablement-disabled");
                    return;
                }

                this.displayElement(component, "enabler");

                component.set('v.isEnableConfirmed', enablementState.isConfirmed);
                component.set('v.isEnabled', enablementState.isEnabled);
                component.set("v.isMetaDeployConfirmed", enablementState.isMetaDeployConfirmed);
                component.set("v.isMigrationRun", enablementState.isMigrationRun);

                if (enablementState.isConfirmed) {
                    this.disableEdit(component, "enable-confirm");
                }

                if (!enablementState.isConfirmed || enablementState.isEnabled) {
                    this.disableEdit(component, "enable-toggle");
                }

            } else if (state === "ERROR") {
                let errors = response.getError();
                let errMessage = errors && errors[0] && errors[0].message
                    ? errors[0].message
                    : $A.get("Unexpected Error");
                console.log(errMessage);
            }
        });

        $A.enqueueAction(action);
    },
    /****
    * @description 
    */
    refreshView: function (component) {
        this.hideElement(component, "enablement-disabled");
        this.hideElement(component, "enabler");

        this.loadState(component);
    },
    /****
    * @description 
    */
    confirmEnablement: function (component) {
        this.disableEdit(component, "enable-confirm");

        var action = component.get('c.confirmEnablement');

        action.setCallback(this, function (response) {
            var state = response.getState();

            if (!component.isValid()) {
                return;
            }

            if (state === 'SUCCESS') {
                component.set('v.isEnableConfirmed', true);
                this.enableEdit(component, "enable-toggle");

            } else if (state === 'ERROR') {
                this.enableEdit(component, "enable-confirm");

                console.log(response.getError());//todo
            }
        });

        $A.enqueueAction(action);
    },
    /****
    * @description 
    */
    enable: function (component) {
        this.disableEdit(component, "enable-toggle");

        var action = component.get('c.enableEnhancement');

        action.setCallback(this, function (response) {
            var state = response.getState();

            if (!component.isValid()) {
                return;
            }

            if (state === 'SUCCESS') {
                component.set('v.isEnabled', true);

            } else if (state === 'ERROR') {
                this.enableEdit(component, "enable-toggle");
                console.log(response.getError());//todo
            }
        });

        $A.enqueueAction(action);
    },
    hideElement: function (component, elementName) {
        let element = component.find(elementName);
        $A.util.addClass(element, "slds-hide");
    },
    displayElement: function (component, elementName) {
        let element = component.find(elementName);
        $A.util.removeClass(element, "slds-hide");
    },
    disableEdit: function (component, inputName) {
        let inputComp = component.find(inputName);
        $A.util.addClass(inputComp, "editDisabled");
    },
    enableEdit: function (component, inputName) {
        let inputComp = component.find(inputName);
        $A.util.removeClass(inputComp, "editDisabled");
    }
})
