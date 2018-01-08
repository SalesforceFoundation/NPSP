({
    handleMenuSelect: function(cmp, event, helper) {
        var selectedMenuItemValue = event.getParam("value");
        var rollupId = cmp.get("v.rollup.id");
        if(selectedMenuItemValue == cmp.get("v.labels.edit")){
            cmp.set("v.mode", cmp.get("v.labels.edit"));
            cmp.set("v.activeRollupId",rollupId);
        } else if (selectedMenuItemValue == cmp.get("v.labels.clone")){
            cmp.set("v.mode", cmp.get("v.labels.clone"));
            cmp.set("v.activeRollupId",rollupId);
        } else if (selectedMenuItemValue == cmp.get("v.labels.delete")){
            //prompt to delete row
        }
    },

    setActiveRollup: function(cmp, event, helper) {
        var rollup = cmp.get("v.rollup");
        cmp.set("v.mode", cmp.get("v.labels.view"));
        cmp.set("v.activeRollupId",rollup.id);
        console.log('activeRollupId SET IN ROW CONTROLLER');
    }
})