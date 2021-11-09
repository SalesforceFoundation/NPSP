({
    /*******************************************************************************************************
     * @description initialize our component, which is just creating an empty new address for our popup.
     */
    doInit : function(component /* , event, helper */) {
        component.set('v.addrNew', {});
    },

    /*******************************************************************************************************
     * @description called whenever v.listAddr is modified, to update v.addrDefault.
     */
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

    /*******************************************************************************************************
     * @description open the Change Address popup
     */
    openChangeAddress : function(component, event, helper) {
        if (event.type === 'keydown' && (event.code === 'Enter' || event.code === 'Space')){
            // If using keyboard controls, focus on Address Modal (the timeout makes this work consistently)
            window.setTimeout(
                $A.getCallback(function() {
                    document.getElementById('searchPopupLabel').focus();
                }), 0
            );
        } else if (event.type === 'click') {
            component.set('v.showChangeAddressPopup', true);
            component.set('v.isExistingAddrSectionOpen', true);
        }
    },

    /*******************************************************************************************************
     * @description close the Change Address popup, making no changes.
     */
    cancelChangeAddress : function(component, event, helper ) {
        if (event.type === 'click'
            || (event.type === 'keydown' && (event.code === 'Enter' || event.code === 'Space'))
        ) {
            component.set('v.showChangeAddressPopup', false);

        } else if (event.type === 'keydown' && event.shiftKey === true && event.code === 'Tab') {
            document.getElementById('modalEndFocus').focus();
        }
    },



    /*******************************************************************************************************
     * @description Save the new or existing address as the default, and close the Change Address popup
     */
    saveChangeAddress : function(component, event, helper) {
        if (event.type === 'click'
            || (event.type === 'keydown' && (event.code === 'Enter' || event.code === 'Space'))
        ) {
            helper.setDefaultAddress(component);
            component.set('v.showChangeAddressPopup', false);
            component.set('v.addrNew', {});

        } else if (event.type === 'keydown' && event.shiftKey === false && event.code === 'Tab') {
            document.getElementById('closeButton').focus();
        }
        
    },

    /*******************************************************************************************************
     * @description tracks which existing address was last selected in the popup
     */
    onPressAddrTile : function(component, event /* , helper */) {
        if (event.type === 'click'
            || (event.type === 'keyup' && (event.code === 'Enter' || event.code === 'Space'))
        ) {
            let iAddr = Number(event.currentTarget.getAttribute('data-iAddr'));
            component.set('v.iAddrSelected', iAddr);

        }
        
    }
})