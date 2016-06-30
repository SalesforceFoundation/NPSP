({
    setDefaultAddress : function(component) {
        var addr;
        var listAddr = component.get('v.listAddr');
        var iAddrSelected;

        // figure out if changing default address or creating a new one
        if (component.get('v.isExistingAddrSectionOpen')) {
            iAddrSelected = component.get('v.iAddrSelected');
            addr = listAddr[iAddrSelected];
        } else {
            // Salesforce is namespace prefixing the new address, so we must
            // remove the prefix before adding it to our list.
            var namespacePrefix = component.get('v.namespacePrefix');
            addr = component.get('v.addrNew');
            addr = this.processPrefixObjectFields(namespacePrefix, addr, false);
            iAddrSelected = listAddr.length;
            listAddr.push(addr);
        }

        // clear out current default address
        for (var i = 0; i < listAddr.length; i++) {
            listAddr[i].Default_Address__c = false;
        }

        // update our hh default address and list of addresses
        addr.Default_Address__c = true;
        component.set('v.listAddr', listAddr);
        // this will get set in onChangeListAddr()
        //component.set('v.addrDefault', addr);

        // now notify other components the change occurred
        var event = $A.get("e.c:HH_AddressChangedEvent");
        event.setParams({ "addrDefault" : addr });
        event.fire();
    },
    
    /*******************************************************************************************************
     * @description adds or removes namespace prefix from the object's custom fields
     */
    processPrefixObjectFields: function(namespacePrefix, object, isAdd) {
        if (namespacePrefix && namespacePrefix.length > 0) {

            var obj = {}; //create object

            // process namespace prefix from each custom field
            for (var fld in object) {
                if (isAdd) {
                    // see if custom field has no namespace prefix
                    if (fld.endsWith('__c') && fld.indexOf('__') === fld.lastIndexOf('__')) {
                        var fld2 = namespacePrefix + fld;
                        obj[fld2] = object[fld];
                    } else {
                        obj[fld] = object[fld];
                    }
                } else {
                    // see if custom field starts with our namespace prefix
                    if (fld.endsWith('__c') && fld.startsWith(namespacePrefix)) {
                        var fld2 = fld.replace(namespacePrefix, '');
                        obj[fld2] = object[fld];
                    } else {
                        obj[fld] = object[fld];
                    }
                }
            }
            return obj;
        } else {
            return object;
        }
    },
    
})