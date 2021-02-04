({
    isSysAdmin : function(component) {
        let userId = $A.get('$SObjectType.CurrentUser.Id');

        let action = component.get('c.isAdminUser');
        action.setParams({
            'userId' : userId
        });

        action.setCallback(this, function(response) {
            let state = response.getState();
            const SUCCESS = 'SUCCESS';
            const ERROR = 'ERROR';

            if (state === SUCCESS) {
                let isAdmin = response.getReturnValue();

                if (isAdmin) {
                    component.set('v.hasPermission', true);
                } else {
                    component.set('v.hasPermission', false);
                }

                $A.util.removeClass(component.find('wrapper'), 'slds-hide');
            } else if (state === ERROR) {
                let errors = response.getError();

                if (errors) {
                    if (errors[0] && errors[0].message) {
                        this.showToast('sticky', 'error', errors[0].message);
                    }
                }
            }
        });
        $A.enqueueAction(action);
    },

    showToast: function(mode, type, message) {
        let toastEvent = $A.get('e.force:showToast');

        toastEvent.setParams({
            mode: mode,
            message: message,
            type: type
        });
        toastEvent.fire();
    }
});