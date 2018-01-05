({
    handleMenuSelect: function(cmp, event, helper) {
        var selectedMenuItemValue = event.getParam("value");
    },

    setActiveRollup: function(cmp, event, helper) {
        var rollup = cmp.get("v.rollup");
        cmp.set("v.activeRollupId",rollup.id);
        console.log('activeRollupId SET IN ROW CONTROLLER');
    }
})