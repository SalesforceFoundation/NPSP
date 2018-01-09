({
    changeMode: function (cmp, event, helper) {
        var mode = cmp.get("v.mode");
        console.log("Mode is " + mode);
        console.log("In changeMode");
        //set readonly fields if mode is View
        if(mode != "view"){
            cmp.set("v.isReadOnly",false);
        } else {
            cmp.set("v.isReadOnly", true);
        }
        helper.setObjectAndFieldDependencies(cmp);
    },

    setModeEdit: function(cmp, event, helper) {
        cmp.set("v.mode", "edit");
        console.log("In setModeEdit");
        helper.setObjectAndFieldDependencies(cmp);
    },

    setModeClone: function(cmp, event, helper) {
        cmp.set("v.mode", "clone");
        helper.setObjectAndFieldDependencies(cmp);
    },

    setModeView: function(cmp, event, helper) {
        cmp.set("v.mode", "view");
    },

    changeDetailObject: function(cmp, event, helper){

    }

})