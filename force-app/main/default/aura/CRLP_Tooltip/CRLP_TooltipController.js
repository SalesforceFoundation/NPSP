({
    handleMouseOver: function(cmp, event){
        $A.util.removeClass(cmp.find("divSelectHelp"), 'slds-fall-into-ground');
        $A.util.addClass(cmp.find("divSelectHelp"), 'slds-rise-from-ground');
    },

    handleMouseOut: function(cmp, event){
        $A.util.addClass(cmp.find("divSelectHelp"), 'slds-fall-into-ground');
        $A.util.removeClass(cmp.find("divSelectHelp"), 'slds-rise-from-ground');
    },

    handleOnClick: function(cmp, event){
        $A.util.toggleClass(cmp.find("divSelectHelp"), 'slds-fall-into-ground');
        $A.util.toggleClass(cmp.find("divSelectHelp"), 'slds-rise-from-ground');
    },
})