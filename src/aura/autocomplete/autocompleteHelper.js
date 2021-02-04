({
    handleInputChange: function(component) {
        
        if (component.get("v.disabledSearch")) {
            component.set("v.disabledSearch", false);
            return;
        }
        this.setListVisibility(component, false);

        var keyword = component.find('input').get('v.value');

        // IE 11 fires the input event when we tab off,
        // causing it to reopen.
        //
        // if this event is fired and the element is not focused, ignore
        if (component.get('v.inputFocused')) {
            component.set('v.keyword', keyword);

            if (!keyword) {
                // user has cleared the textbox, so clear our results
                component.set('v.items', []);
                return;
            }

            this.setListVisibility(component, true);
            component.set('v.showLoadingIndicator', true);

            var dataProvider = component.get('v.dataProvider')[0];
            var idDataCallback = component.get('v.idDataCallback');
            idDataCallback++;
            component.set('v.idDataCallback', idDataCallback);

            dataProvider.provide(
                keyword,
                idDataCallback,
                $A.getCallback(function (err, idDataCallback, items) {
                    if (!component || !component.isValid()) {
                        return;
                    }
                    if (err) {
                        component.set('v.showLoadingIndicator', false);
                        throw err;
                    }
                    var id = component.get('v.idDataCallback');
                    // only refresh the list if this callback is the most recent
                    if (idDataCallback >= id) {
                        component.set('v.items', items);
                        component.set('v.idDataCallback', idDataCallback);
                        component.set('v.showLoadingIndicator', false);
                    }
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
                250 // too small a number caused issues in IE and Firefox on Windows
            );
        } else {
            helper.setListVisibility(component, visible);
        }
    },

    setListVisibility: function (component, visible) {
        var listComponent = component.find('list');
        $A.util.toggleClass(listComponent, "slds-hide", !visible);
        component.set('v.isListVisible', visible);
    },

    // Handle the pressing of the arrow key down.
    // It updates the aria-activedescendant and notify the child elements
    handleArrowDownKey: function (component, helper) {
        const listbox = document.querySelector('[role="listbox"]');
        const elements = component.get("v.items");
        var currentFocussedElement = listbox.getAttribute('aria-activedescendant');
        
        if (currentFocussedElement == null || currentFocussedElement == '') {
            if (elements[0]) {
                currentFocussedElement = elements[0].value.Id
                listbox.setAttribute('aria-activedescendant', currentFocussedElement);
                helper.fireNewItemFocus(currentFocussedElement);
                return;
            } else {
                var showFooter = component.get('v.showListFooter');
                if (showFooter) {
                    helper.fireFocusOnFooter(component, listbox);
                    return;
                }
            }
            
        }

        var newFocussedElement = null; 
        for (var i = 0; i < elements.length; i++) {
            if (elements[i].value.Id == currentFocussedElement) {
                // I am in the middle of the list, setting the next descendant to the next element
                if (i < elements.length - 1) {
                    newFocussedElement = elements[i + 1].value.Id;
                    listbox.setAttribute('aria-activedescendant', newFocussedElement);
                    break;
                } else {
                    // reach the last element of the list, next one is footer(if present) or the first element if not present.
                    var showFooter = component.get('v.showListFooter');
                    if (showFooter) {
                        helper.fireFocusOnFooter(component, listbox);
                        return;
                    } else {
                        newFocussedElement =  elements[0].value.Id;
                        listbox.setAttribute('aria-activedescendant', newFocussedElement);
                        break;
                    }
                }
            }
        }
        
        helper.fireNewItemFocus(newFocussedElement);
    },

    // Handles the pressing of the arrow up key.
    // It updates the aria-activedescendant and notify the child elements
    handleArrowUpKey: function (component, helper) {
        const listbox = document.querySelector('[role="listbox"]');
        const elements = component.get("v.items");
        var currentFocussedElement = listbox.getAttribute('aria-activedescendant');
        
        if (currentFocussedElement == null || currentFocussedElement == '') {
            if (elements[elements.length - 1]) {
                currentFocussedElement = elements[elements.length - 1].value.Id
                listbox.setAttribute('aria-activedescendant', currentFocussedElement);
                helper.fireNewItemFocus(currentFocussedElement);
                return;
            }
        }
        
        if (currentFocussedElement == null || currentFocussedElement == '') {
            currentFocussedElement = elements[elements.length - 1].value.Id
            listbox.setAttribute('aria-activedescendant', currentFocussedElement);
        }

        var newFocussedElement = null; 
        for (var i = 0; i < elements.length; i++) { 
            if (elements[i].value.Id == currentFocussedElement) {
                if (i == 0) {
                    var showFooter = component.get('v.showListFooter');
                    if (showFooter) {
                        helper.fireFocusOnFooter(component, listbox);
                        return;
                    }
                } else {
                    newFocussedElement = elements[i - 1].value.Id;
                    listbox.setAttribute('aria-activedescendant', newFocussedElement);
                    break;
                }
            }
        }
        helper.fireNewItemFocus(newFocussedElement);
    },

    //Fires an event to notify the new focussed element
    fireNewItemFocus: function(id) {
        var event = $A.get("e.c:HH_NewFocussedElement");
        event.setParam("id", id);
        event.fire();
    },

    fireFocusOnFooter: function(component, listbox) {
        var event = component.getEvent('reachFooter');
        listbox.setAttribute('aria-activedescendant', "");
        event.fire();
    }
})