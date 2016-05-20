({
    provide: function (component, event, helper) {
        var sobjectName = component.get('v.sobject');
        var fields = component.get('v.fields');
        var searchField = component.get('v.searchField');
        var args = event.getParam('arguments');
        if (args && args.keyword && args.callback) {
            var queryAction = component.get('c.queryObjects');
            queryAction.setParams({
                sobjectName: sobjectName,
                fields: fields,
                searchField: searchField,
                queryValue: args.keyword
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