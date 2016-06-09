({
    handleInputChange: function(component) {
        this.setListVisibility(component, false);

        var el = component.find('input').getElement();
        var keyword = el.value;

        // IE 11 fires the input event when we tab off,
        // causing it to reopen.
        //
        // if this event is fired and the element is not focused, ignore
        if (component.get('v.inputFocused')) {
            component.set('v.keyword', keyword);

            if (!keyword) {
                return;
            }

            this.setListVisibility(component, true);
            component.set('v.showLoadingIndicator', true);

            var dataProvider = component.get('v.dataProvider')[0];

            dataProvider.provide(
                keyword,
                $A.getCallback(function (err, items) {
                    if (!component || !component.isValid()) {
                        return;
                    }
                    component.set('v.showLoadingIndicator', false);
                    if (err) {
                        throw err;
                    }

                    component.set('v.items', items);
                })
            );

        }
    },

    setListVisibilityDelayed: function (component, visible) {
        var helper = this;
        if (component._focus) {
            component._focus(
                $A.getCallback(
                    function() {
                        if (component && component.isValid()) {
                            helper.setListVisibility(component, visible);
                        }
                    }
                ),
                20
            );
        } else {
            helper.setListVisibility(component, visible);
        }
    },

    setListVisibility: function (component, visible) {
        var listComponent = component.find('list');
        $A.util.toggleClass(listComponent, "slds-hide", !visible);
        component.set('v.isListVisible', visible);
    }
})