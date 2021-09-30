({
    doInit: function (component) {
        var inputCmp = component.find('input');

        if (inputCmp) {
            inputCmp.addHandler('keyup', component, 'c.handleInputChange');
            inputCmp.addHandler('focus', component, 'c.handleInputFocus');
            inputCmp.addHandler('blur', component, 'c.handleInputBlur');
        }

        // This calls a function (callback) in a delayed manner and it can be
        // cancelled.
        var makeDelay = function () {
            var timer = 0;
            return function(callback, ms) {
                window.clearTimeout(timer);
                timer = window.setTimeout(callback, ms);
            };
        };

        component._delay = makeDelay(); // this one is for pausing before doing autocomplete
        component._focus = makeDelay(); // this one is to accumulate focus/blur events to determine if component has focus
    },

    handleInputChange: function (component, event, helper) {
        if (component._delay) {
            component._delay(
                $A.getCallback(function() {
                    if (component && component.isValid()) {
                        helper.handleInputChange(component, event);
                    }
                }),
                300
            );
        } else {
            helper.handleInputChange(component, event);
        }
    },

    handleInputFocus: function (component, event, helper) {
        component.set('v.inputFocused', true);
        var inputCmp = component.find('input');
        if ('' !== inputCmp.get('v.value')) {
            helper.setListVisibilityDelayed(component, true);
        }
    },

    handleInputBlur: function (component, event, helper) {
        component.set('v.inputFocused', false);
        helper.setListVisibilityDelayed(component, false);
    },

    handleListFocus: function (component, event, helper) {
        helper.setListVisibilityDelayed(component, true);
    },

    handleListBlur: function (component, event, helper) {
        helper.setListVisibilityDelayed(component, false);
    },

    handleOptionSelected: function (component, event, helper) {
        var valueSelected = event.getParam('value');
        component.set('v.value', valueSelected);
        component.set('v.displayValue', valueSelected);
        helper.setListVisibilityDelayed(component, false);
    },

    handleRemovePill: function (component) {
        component.set('v.value', '');
        component.set('v.displayValue', '');
        component.set('v.keyword', '');
    },

    clearList: function (component) {
        component.set('v.items', []);
        component.set('v.value', '');
        component.set('v.displayValue', '');
        component.set('v.keyword', '');
        const listbox = document.querySelector('[role="listbox"]');
        listbox.setAttribute('aria-activedescendant', '');
    },

    handleKeypressOnList : function (component, event, helper) {
        
        const id = event.getParam("id");
        const key = event.getParam("keyPressed");
        
        switch (key) {
            case 'ArrowDown':
                helper.handleArrowDownKey(component, helper);
                break;
            case 'ArrowUp': 
                helper.handleArrowUpKey(component, helper);
                break;
            case 'Tab':
                helper.handleArrowDownKey(component, helper);
                break;

        }
    },

    handleKeypressOnInput: function(component, event, helper) {
        const key = event.getParams().keyCode; 
        switch (key) {
            case 40:
                component.set("v.disabledSearch", true);
                event.stopPropagation();
                event.preventDefault();
                helper.handleArrowDownKey(component, helper);
                break;
            case 38: 
                component.set("v.disabledSearch", true);
                event.stopPropagation();
                event.preventDefault();
                helper.handleArrowUpKey(component, helper);
                break;
        }
    },

    handleFocusInput : function (component, event, helper) {
        const listbox = document.querySelector('[role="listbox"]');
        listbox.setAttribute('aria-activedescendant', "");
    }
})