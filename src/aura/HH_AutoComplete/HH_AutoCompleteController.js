({
    handleNewContact: function(component, event, helper) {
       helper.fireNewContactEvent(component);
    },

    handleReachFooter : function(component, event, helper) {
        document.getElementById("newContact").focus();
    },

    clearList: function(component) {
        var autocomplete = component.find('autocomplete');
        autocomplete.clearList();
    },
    // Handle keypress event on the elements of the list
    handleKeyPress : function(component, event, helper) {
        /*
          Need to check if the key pressed is enter. If so, the element has to trigger the selected element event
          if no, an event has to be raised to the autocomplete component to manage the new focus
          */

        //stopping propagation to avoid lastpass bug
        event.preventDefault()
        event.stopPropagation()
        const key = event.key;
        if (key == 'Enter') {
            helper.fireNewContactEvent(component);
            return;
        }
        
        var event = $A.get("e.c:HH_KeypressEvent");
        event.setParams({
            "keyPressed" : key
        });
        event.fire();
     },


})