({
    changeMode: function (cmp, event, helper) {
        var mode = cmp.get("v.mode");
        console.log("Mode is " + mode);
        //set readonly fields if mode is View
        if(mode != "view"){
            cmp.set("v.isReadOnly",false);
        } else {
            cmp.set("v.isReadOnly", true);
        }
    },

    setModeEdit: function(cmp, event, helper) {
        cmp.set("v.mode", "edit");
    },

    setModeClone: function(cmp, event, helper) {
        cmp.set("v.mode", "clone");
    },

    setModeView: function(cmp, event, helper) {
        cmp.set("v.mode", "view");
    }

})