({
	onCheck : function(component, event) {
        debugger;
        
        // update our contact's exclusion property
        var checked = event.source.elements[0].checked;
        var con = component.get('v.contact');
        // the item's Id is the developer field name
        con[event.source.$localId$] = checked;
        component.set('v.contact', con);
        
        // now notify other components the change occurred
        var event = $A.get("e.c:HH_ContactChangedEvent");
        event.setParams({ "contact" : con });
        event.fire();
        
	},
    
})