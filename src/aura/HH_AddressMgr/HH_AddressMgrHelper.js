({
	setDefaultAddress : function(component) {
        var addr;
        var listAddr = component.get('v.listAddr');
        
        // figure out if changing default address or creating a new one
        if (component.get('v.isExistingAddrSectionOpen')) {
            var iAddr = component.get('v.iAddrSelected');
            addr = listAddr[iAddr];
        } else {
            addr = component.get('v.addrNew');
            listAddr.push(addr);
        }   

        // update our hh default address and list of addresses
        addr.Default_Address__c = true;
        component.set('v.listAddr', listAddr);
        component.set('v.addrDefault', addr);
        
        // now notify other components the change occurred
        var event = $A.get("e.c:HH_AddressChangedEvent");
        event.setParams({ "addrDefault" : addr });
        event.fire();
	}
})