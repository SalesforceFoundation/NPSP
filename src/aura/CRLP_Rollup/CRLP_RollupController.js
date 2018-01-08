({
    changeMode: function (cmp, event, helper) {
        var mode = cmp.get("v.mode");
        console.log("Mode is " + mode);
        //set readonly fields if mode is View
        if(mode != cmp.get("v.labels.view")){
            cmp.set("v.isReadOnly",false);
        } else {
            cmp.set("v.isReadOnly", true);
        }
    }
})