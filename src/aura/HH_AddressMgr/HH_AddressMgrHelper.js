({
	setDefaultAddress : function(component) {
        var iAddr = component.get('v.iAddrSelected');
        var listAddr = component.get('v.listAddr');
        var addr = listAddr[iAddr];
        addr.Default_Address__c = true;
        component.set('v.listAddr', listAddr);
        component.set('v.addrDefault', addr);
        
        // now notify other components the change occurred
        var event = $A.get("e.c:HH_AddressChangedEvent");
        event.setParams({ "addrDefault" : addr });
        event.fire();
	}
})