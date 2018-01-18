({
    handleMenuSelect: function(cmp, event, helper) {
        var selectedMenuItemValue = event.getParam("value");
        var rollupId = cmp.get("v.rollup.id");
        if(selectedMenuItemValue == "edit"){
            cmp.set("v.mode", "edit");
            cmp.set("v.activeRollupId",rollupId);
        } else if (selectedMenuItemValue == "clone"){
            cmp.set("v.mode", "clone");
            cmp.set("v.activeRollupId",rollupId);
        } else if (selectedMenuItemValue == "delete"){
            //prompt to delete row
        }

        console.log('trying to fire event to change mode to edit or clone...');
        var changeModeEvt = cmp.getEvent("modeChanged");
        changeModeEvt.setParams({"mode" : selectedMenuItemValue});
        changeModeEvt.fire();
        console.log('past the fire');

    },

    setActiveRollup: function(cmp, event, helper) {
        var rollup = cmp.get("v.rollup");
        cmp.set("v.mode", "view");
        cmp.set("v.activeRollupId",rollup.id);

        console.log('trying to fire event to change mode to view...');
        var changeModeEvt = cmp.getEvent("modeChanged");
        changeModeEvt.setParams({"mode" : "view"});
        changeModeEvt.fire();

    }
})