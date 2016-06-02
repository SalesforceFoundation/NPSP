({
    doInit : function(component /* , event, helper */) {
        var addr = {
            Mailing_Street__c : null,
            Mailing_Street2__c : null,
            Mailing_City__c : null,
            Mailing_State__c : null,
            Mailing_PostalCode__c : null,
            Mailing_Country__c : null
        };
        component.set('v.addrNew', addr);
    },

    onChangeListAddr : function(component /* , event, helper */) {
        var listAddr = component.get('v.listAddr');
        if (listAddr.length > 0) {

            // find the default address
            var iAddrDefault = 0;
            for (var i = 0; i < listAddr.length; i++) {
                if (listAddr[i].Default_Address__c) {
                    iAddrDefault = i;
                    break;
                }
            }
            component.set('v.addrDefault', listAddr[iAddrDefault]);
        }
    },

    openChangeAddress : function(component /* , event, helper */) {
        component.set('v.showChangeAddressPopup', true);
    },

    cancelChangeAddress : function(component /* , event, helper */) {
        component.set('v.showChangeAddressPopup', false);
    },

    saveChangeAddress : function(component, event, helper) {
        helper.setDefaultAddress(component);
        component.set('v.showChangeAddressPopup', false);
    },

    onPressAddrTile : function(component, event /* , helper */) {
        var iAddr = Number(event.currentTarget.getAttribute('data-iAddr'));
        component.set('v.iAddrSelected', iAddr);
        component.set('v.listAddr', component.get('v.listAddr'));
        component.set('v.showChangeAddressPopup', true);
    },

    toggleAddrSection : function(component /* , event, helper */) {
        var isOpen = component.get('v.isExistingAddrSectionOpen');
        component.set('v.isExistingAddrSectionOpen', !isOpen);
    },

})