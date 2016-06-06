({
    provide: function (component, event, helper) {
        var args = event.getParam('arguments');
        if (args && args.keyword && args.callback) {
            var queryAction = component.get('c.queryObjects');
			var listCon = component.get('v.listCon');
            queryAction.setParams({
                queryValue: args.keyword,
                listCon: listCon
            });
            queryAction.setCallback(
                this,
                function (response) {
                    var state = response.getState();

                    if ('SUCCESS' === state) {
                        args.callback(
                            null,
                            response.getReturnValue()
                        );
                    } else if ('ERROR' === state) {
                        var auraErrors = response.getError();
                        var errors = [];
                        if (auraErrors) {
                            for (error in auraErrors) {
                                if (error.message) {
                                    errors.push(new Error(error.message));
                                }
                            }
                        }
                        args.callback(
                            errors,
                            []
                        );
                    }
                }
            );
            $A.enqueueAction(queryAction);
        } else {
            args.callback(null, []);
        }
    },
})