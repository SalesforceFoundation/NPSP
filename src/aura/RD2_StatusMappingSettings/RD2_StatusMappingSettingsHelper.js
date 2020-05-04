({
    /****
     * @description Loads the status to state mapping
     */
    loadMapping: function (component) {
        var action = component.get("c.loadMapping");

        action.setCallback(this, function (response) {
            if (!component.isValid()) {
                return;
            }
            const state = response.getState();

            if (state === "SUCCESS") {

                const columns = [{ label: $A.get('$Label.c.RD2_StatusMappingColumnStatusLabel'), fieldName: 'label', type: 'string' }
                    , { label: $A.get('$Label.c.RD2_StatusMappingColumnStatus'), fieldName: 'status', type: 'string' }
                    , { label: $A.get('$Label.c.RD2_StatusMappingColumnState'), fieldName: 'state', type: 'string' }
                ];
                component.set("v.columns", columns);

                const data = response.getReturnValue();
                component.set('v.data', data);

            } else if (state === "ERROR") {
                this.handleError(component, response.getError());
            }
        });

        $A.enqueueAction(action);
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

        //component.set('v.errorSection', section);
        //component.set('v.errorMessage', message);
    }
})
