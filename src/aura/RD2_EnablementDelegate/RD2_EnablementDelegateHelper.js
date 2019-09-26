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

                if (!enablementState.isEnablementReady && !enablementState.isEnabled) {
                    let enablementDisabled = component.find("enablement-disabled");
                    $A.util.removeClass(enablementDisabled, "slds-hide");
                    return;
                }

                let enabler = component.find("enabler");
                $A.util.removeClass(enabler, "slds-hide");

                component.set('v.isEnabled', enablementState.isEnabled);
                component.set("v.isMetaDeployCompleted", enablementState.isMetaDeployCompleted);
                component.set("v.isMigrationCompleted", enablementState.isMigrationCompleted);

                if (enablementState.isEnabled) {
                    let toggleInput = component.find("step2-complete");
                    $A.util.addClass(toggleInput, "toggleEnabled");
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
        let enablementDisabled = component.find("enablement-disabled");
        $A.util.addClass(enablementDisabled, "slds-hide");

        let enabler = component.find("enabler");
        $A.util.addClass(enabler, "slds-hide");

        this.loadState(component);
    },
    /****
   * @description 
   */
    completeStep2: function (component) {
        let isEnabled = component.get("v.isEnabled");

        var action = component.get('c.enableEnancement');

        action.setCallback(this, function (response) {
            var state = response.getState();

            if (!component.isValid()) {
                return;
            }

            if (state === 'SUCCESS') {
                component.set('v.isEnabled', true);

                let toggleInput = component.find("step2-complete");
                $A.util.addClass(toggleInput, "toggleEnabled");

                //showToast()? //todo
            } else if (state === 'ERROR') {
                console.log(response.getError());//todo
            }
        });

        $A.enqueueAction(action);
    }
})
