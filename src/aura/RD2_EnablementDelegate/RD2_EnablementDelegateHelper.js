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

                if (!enablementState.isEnablementReady) {
                    let enablementDisabled = component.find("enablement-disabled");
                    $A.util.removeClass(enablementDisabled, "slds-hide");
                    return;
                }

                let enabler = component.find("enabler");
                $A.util.removeClass(enabler, "slds-hide");

                component.set('v.isEnabled', enablementState.isEnabled);
                component.set("v.isMetaDeployCompleted", enablementState.isMetaDeployCompleted);
                component.set("v.isMigrationCompleted", enablementState.isMigrationCompleted);

                if (enablementState.isMigrationCompleted) {
                    let step3 = component.find("step3");
                    $A.util.removeClass(step3, "slds-is-active");
                    $A.util.removeClass(step3, "slds-is-current");
                    $A.util.addClass(step3, "slds-is-complete");
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
    }
})
