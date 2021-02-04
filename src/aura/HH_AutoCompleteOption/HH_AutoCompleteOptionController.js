({
    handleClick : function(component, event, helper) {
        helper.fireOptionSelectedEvent(component);
    },
    // Handle keypress event on the elements of the list
    handleKeyPress : function(component, event, helper) {
        /*
          Need to check if the key pressed is enter. If so, the element has to trigger the selected element event
          if no, an event has to be raised to the autocomplete component to manage the new focus
          */

        //stopping propagation to avoid lastpass bug
        event.preventDefault();
        event.stopPropagation();
        var key = event.key;
        if (key == 'Enter') {
            helper.fireOptionSelectedEvent(component);;
            return;
        }
        
        var event = $A.get("e.c:HH_KeypressEvent");
        event.setParams({
            "keyPressed" : key
        });
        event.fire();
     },
    
     /* 
      * Event that handles the new focus on the right element after the autocomplete component has calculated the next element
      */
     handleNewFocussedElement : function(component, event, helper) {
        var id = event.getParam('id');
        if (id == null) { return; } 
        const thisElement = document.getElementById(id);
        if (!thisElement) { return; }
        const myId = thisElement.getAttribute("id");
        if (myId == id) {
            var element = document.getElementById(id);
            element.focus();
        }
        
     }
})