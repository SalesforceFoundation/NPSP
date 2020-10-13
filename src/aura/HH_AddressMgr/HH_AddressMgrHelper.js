({
    /*******************************************************************************************************
     * @description From the Change Address popup, finds the selected existing or new address, and makes it
     * the new default, and fires the HH_AddressChangedEvent, so the container can update the contacts and
     * hh with the new default address.
     */
    setDefaultAddress : function(component) {
        var addr;
        var listAddr = component.get('v.listAddr');
        var iAddrSelected;

        // figure out if changing default address or creating a new one
        if (component.get('v.isExistingAddrSectionOpen') === true) {
            iAddrSelected = component.get('v.iAddrSelected');
            addr = listAddr[iAddrSelected];
        } else {
            addr = component.get('v.addrNew');
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

    /**
    * @description Control the state of the two sections.
    */
    toggleSections : function(component) {
        let buttons = component.find('sectionButton');
        for (let cmp in buttons) {
            let currentIcon = buttons[cmp].get("v.iconName");

            if (currentIcon === 'utility:chevronright') {
                buttons[cmp].set('v.iconName','utility:chevrondown');
            } else {
                buttons[cmp].set('v.iconName','utility:chevronright');
            }

            ariaExpaned = buttons[cmp].get('v.ariaExpanded');
            buttons[cmp].set('v.ariaExpanded', (ariaExpaned == 'true') ? 'false' : 'true');
        }

        let sections = component.find('accordionSection');
        for(let cmp in sections) {
            $A.util.toggleClass(sections[cmp], 'slds-show');  
            $A.util.toggleClass(sections[cmp], 'slds-hide');  
        }
      },
        
})